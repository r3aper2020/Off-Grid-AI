import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/models/data/model_catalog.dart';
import 'package:offgrid_ai/features/models/data/model_downloader.dart';
import 'package:offgrid_ai/features/models/data/model_store.dart';

import '../../support/test_db.dart';

final body = [...'GGUF'.codeUnits, ...List.filled(64 * 1024, 7)];
final bodySha = sha256.convert(body).toString();

void main() {
  late AppDatabase db;
  late Directory dir;
  late ModelStore store;
  late HttpServer server;
  late Future<void> Function(HttpRequest) handler;

  setUp(() async {
    db = testDatabase();
    dir = await Directory.systemTemp.createTemp('dl');
    store = ModelStore(db, dir);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    handler = (req) async {
      req.response.add(body);
      await req.response.close();
    };
    server.listen((req) => handler(req));
  });
  tearDown(() async {
    await server.close(force: true);
    await db.close();
    await dir.delete(recursive: true);
  });

  CatalogModel catalog({String? sha, int? size, bool vision = false}) =>
      CatalogModel(
        displayName: 'Test Model',
        fileName: 'test.gguf',
        url: Uri.parse('http://127.0.0.1:${server.port}/test.gguf'),
        sizeBytes: size ?? body.length,
        sha256: sha ?? bodySha,
        license: 'MIT',
        summary: '',
        projector: vision
            ? CatalogProjector(
                fileName: 'test-mmproj.gguf',
                url: Uri.parse('http://127.0.0.1:${server.port}/mmproj.gguf'),
                sizeBytes: body.length,
                sha256: bodySha,
              )
            : null,
      );

  List<FileSystemEntity> files() => dir.listSync();

  test('downloads, verifies and installs as active', () async {
    final model = await ModelDownload(store, catalog()).run();

    expect(model.displayName, 'Test Model');
    expect(model.isActive, isTrue);
    expect(await store.fileFor(model).readAsBytes(), body);
  });

  test('a vision model downloads its projector too and deletes both', () async {
    var progress = 0;
    final model = await ModelDownload(
      store,
      catalog(vision: true),
    ).run(onProgress: (w) => progress = w);

    expect(model.projectorFileName, 'test-mmproj.gguf');
    expect(await store.projectorFor(model)!.exists(), isTrue);
    expect(progress, 2 * body.length);
    expect(files().where((f) => f.path.endsWith('.gguf')), hasLength(2));

    await store.delete(model);
    expect(files().where((f) => f.path.endsWith('.gguf')), isEmpty);
  });

  test('checksum mismatch discards the file', () async {
    await expectLater(
      ModelDownload(store, catalog(sha: 'ab' * 32)).run(),
      throwsA(
        isA<ModelImportException>().having(
          (e) => e.message,
          'message',
          contains('integrity'),
        ),
      ),
    );
    expect(files(), isEmpty);
    expect(await store.watchModels().first, isEmpty);
  });

  test('truncated download is rejected', () async {
    await expectLater(
      ModelDownload(store, catalog(size: body.length + 10)).run(),
      throwsA(isA<ModelImportException>()),
    );
    expect(files(), isEmpty);
  });

  test('server error is reported', () async {
    handler = (req) async {
      req.response.statusCode = 404;
      await req.response.close();
    };
    await expectLater(
      ModelDownload(store, catalog()).run(),
      throwsA(
        isA<ModelImportException>().having(
          (e) => e.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('cancel mid-download leaves nothing behind', () async {
    final release = Completer<void>();
    handler = (req) async {
      req.response
        ..bufferOutput = false
        ..contentLength = body.length
        ..add(body.sublist(0, 16 * 1024));
      await req.response.flush();
      await release.future; // hold the connection open
      await req.response.close().catchError((_) {});
    };

    final download = ModelDownload(store, catalog());
    final written = Completer<void>();
    final result = download.run(
      onProgress: (_) {
        if (!written.isCompleted) written.complete();
      },
    );
    await written.future;
    download.cancel();

    await expectLater(result, throwsA(isA<DownloadCancelled>()));
    release.complete();
    expect(files(), isEmpty);
    expect(await store.watchModels().first, isEmpty);
  });

  test('unreachable server gives a connection message', () async {
    final model = catalog();
    await server.close(force: true);
    await expectLater(
      ModelDownload(store, model).run(),
      throwsA(
        isA<ModelImportException>().having(
          (e) => e.message,
          'message',
          contains('internet connection'),
        ),
      ),
    );
  });

  group('resume', () {
    late ServerSocket raw;

    /// Minimal HTTP server on a raw socket so tests can genuinely cut a
    /// connection mid-body. [respond] gets the path and Range start (null
    /// if no Range header) and writes the response.
    Future<void> startRaw(
      Future<void> Function(Socket socket, String path, int? from) respond,
    ) async {
      raw = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      raw.listen((socket) {
        final buffer = StringBuffer();
        late StreamSubscription<List<int>> sub;
        sub = socket.listen((data) {
          buffer.write(String.fromCharCodes(data));
          final text = buffer.toString();
          if (!text.contains('\r\n\r\n')) return;
          sub.pause();
          final path = text.split(' ')[1];
          final m = RegExp(
            r'range: bytes=(\d+)-',
            caseSensitive: false,
          ).firstMatch(text);
          respond(socket, path, m == null ? null : int.parse(m.group(1)!));
        });
      });
      addTearDown(() => raw.close());
    }

    void writeHead(Socket s, int status, int length, {String? extra}) {
      final reason = status == 206 ? 'Partial Content' : 'OK';
      s.write(
        'HTTP/1.1 $status $reason\r\n'
        'Content-Length: $length\r\n'
        '${extra ?? ''}'
        'Connection: close\r\n\r\n',
      );
    }

    /// Sends part of the range then kills the connection.
    Future<void> sendAndDrop(Socket s, int from, int status) async {
      writeHead(s, status, body.length - from);
      s.add(body.sublist(from, from + 10000));
      await s.flush();
      s.destroy();
    }

    Future<void> sendRest(Socket s, int from, int status) async {
      writeHead(s, status, body.length - from);
      s.add(body.sublist(from));
      await s.flush();
      await s.close();
    }

    CatalogModel rawCatalog() => CatalogModel(
      displayName: 'Test Model',
      fileName: 'test.gguf',
      url: Uri.parse('http://127.0.0.1:${raw.port}/test.gguf'),
      sizeBytes: body.length,
      sha256: bodySha,
      license: 'MIT',
      summary: '',
    );

    ModelDownload downloader({int maxRetries = 6}) => ModelDownload(
      store,
      rawCatalog(),
      maxRetries: maxRetries,
      retryDelay: (_) => Duration.zero,
    );

    test('reconnects after dropped connections and resumes', () async {
      final ranges = <int?>[];
      await startRaw((s, path, from) async {
        ranges.add(from);
        if (ranges.length <= 2) {
          await sendAndDrop(s, from ?? 0, from == null ? 200 : 206);
        } else {
          await sendRest(s, from!, 206);
        }
      });

      final model = await downloader().run();

      expect(await store.fileFor(model).readAsBytes(), body);
      expect(ranges, [null, 10000, 20000]);
    });

    test('keeps the Range header across redirects', () async {
      final ranges = <int?>[];
      await startRaw((s, path, from) async {
        if (path == '/test.gguf') {
          s.write(
            'HTTP/1.1 302 Found\r\nLocation: /cdn/blob\r\n'
            'Content-Length: 0\r\nConnection: close\r\n\r\n',
          );
          await s.close();
          return;
        }
        ranges.add(from);
        if (from == null) {
          await sendAndDrop(s, 0, 200);
        } else {
          await sendRest(s, from, 206);
        }
      });

      final model = await downloader().run();

      expect(await store.fileFor(model).readAsBytes(), body);
      expect(ranges, [null, 10000]);
    });

    test('gives up after too many consecutive failures', () async {
      await startRaw((s, path, from) async {
        if (from == null) {
          await sendAndDrop(s, 0, 200);
        } else {
          s.destroy();
        }
      });

      await expectLater(
        downloader(maxRetries: 2).run(),
        throwsA(
          isA<ModelImportException>().having(
            (e) => e.message,
            'message',
            contains('kept dropping'),
          ),
        ),
      );
      expect(files(), isEmpty);
    });

    test('server that ignores Range is reported, not corrupted', () async {
      await startRaw((s, path, from) async {
        if (from == null) {
          await sendAndDrop(s, 0, 200);
        } else {
          await sendRest(s, 0, 200); // whole file again, not a 206
        }
      });

      await expectLater(
        downloader().run(),
        throwsA(
          isA<ModelImportException>().having(
            (e) => e.message,
            'message',
            contains('resume'),
          ),
        ),
      );
      expect(files(), isEmpty);
    });
  });
}
