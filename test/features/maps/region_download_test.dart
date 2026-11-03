import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/data/map_store.dart';
import 'package:offgrid_ai/features/maps/data/range_reader.dart';
import 'package:offgrid_ai/features/maps/data/region_download.dart';
import 'package:offgrid_ai/features/maps/domain/map_bounds.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles_header.dart';

import '../../support/memory_range_reader.dart';
import '../../support/test_db.dart';
import 'pmtiles_test.dart' show addressedIds;

/// Tile bytes by tile id, read straight from an archive in memory.
Map<int, Uint8List> tilesOf(Uint8List archive) {
  final h = PmtilesHeader.parse(archive)!;
  final root = decodeDirectory(
    gunzipBytes(
      Uint8List.sublistView(
        archive,
        h.rootDirOffset,
        h.rootDirOffset + h.rootDirLength,
      ),
    ),
  );
  expect(root.every((e) => !e.isLeaf), isTrue, reason: 'fixture has no leaves');
  return {
    for (final e in root)
      e.tileId: Uint8List.sublistView(
        archive,
        h.tileDataOffset + e.offset,
        h.tileDataOffset + e.offset + e.length,
      ),
  };
}

void main() {
  final planet = File('test/fixtures/smokies_z10-12.pmtiles').readAsBytesSync();
  const part = MapBounds(
    minLon: -83.55,
    minLat: 35.55,
    maxLon: -83.45,
    maxLat: 35.65,
  );

  late AppDatabase db;
  late Directory dir;
  late MapStore store;
  setUp(() async {
    db = testDatabase();
    dir = await Directory.systemTemp.createTemp('regiondl');
    store = MapStore(db, dir);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('plans exactly the tiles in the bounds and knows the size', () async {
    final reader = MemoryRangeReader(planet);
    final plan = await RegionDownload(
      store,
      reader,
    ).plan(bounds: part, maxZoom: 11);
    expect(plan.minZoom, 10);
    expect(plan.maxZoom, 11);
    expect(plan.entries.map((e) => e.tileId), tileIdsIn(part, 10, 11));
    expect(plan.tileCount, tileCount(part, 10, 11));
    final source = tilesOf(planet);
    expect(
      plan.tileBytes,
      plan.entries.fold(0, (n, e) => n + source[e.tileId]!.length),
    );
    // Header, root, metadata only: nothing from the tile section yet.
    expect(reader.bytesServed, lessThan(2000));
  });

  test('downloads a valid archive whose tiles match the planet', () async {
    final reader = MemoryRangeReader(planet, chunkSize: 1000);
    final download = RegionDownload(store, reader);
    final plan = await download.plan(bounds: part, maxZoom: 12);
    final progress = <int>[];
    final region = await download.run(
      plan,
      displayName: 'Little Smokies',
      onProgress: progress.add,
    );
    expect(region.displayName, 'Little Smokies');
    expect(region.fileName, 'little-smokies.pmtiles');
    expect(region.sizeBytes, plan.totalBytes);
    expect((region.minZoom, region.maxZoom), (10, 12));
    expect(region.minLon, closeTo(part.minLon, 1e-6));
    expect(progress.last, plan.totalBytes);

    final out = await store.fileFor(region).readAsBytes();
    final h = PmtilesHeader.parse(out)!;
    expect(h.clustered, isTrue);
    expect(h.tileType, 1);
    expect(h.tileCompression, PmtilesHeader.parse(planet)!.tileCompression);
    expect(h.tileEntries, plan.entries.length);
    expect(h.tileDataOffset + h.tileDataLength, out.length);
    expect(addressedIds(out), tileIdsIn(part, 10, 12).toSet());
    final source = tilesOf(planet);
    final got = tilesOf(out);
    for (final id in got.keys) {
      expect(got[id], source[id], reason: 'tile $id');
    }
    // Metadata was carried over (compressed JSON with the layer list).
    final meta = gunzipBytes(
      Uint8List.sublistView(
        out,
        h.metadataOffset,
        h.metadataOffset + h.metadataLength,
      ),
    );
    expect(String.fromCharCodes(meta), contains('vector_layers'));
  });

  test(
    'refuses an area with too many tiles before fetching anything',
    () async {
      final reader = MemoryRangeReader(planet);
      const world = MapBounds(
        minLon: -180,
        minLat: -85,
        maxLon: 180,
        maxLat: 85,
      );
      // The fixture's zoom range is 10-12; the whole world there is millions.
      await expectLater(
        RegionDownload(store, reader).plan(bounds: world, maxZoom: 12),
        throwsA(isA<RegionTooLargeException>()),
      );
      expect(reader.bytesServed, PmtilesHeader.length);
    },
  );

  test('merges nearby chunks into one request and keeps the gaps out', () {
    final ranges = mergeChunks([
      (offset: 0, length: 10),
      (offset: 10, length: 5),
      (offset: 50, length: 5),
      (offset: 1000, length: 1),
    ], maxGap: 40);
    expect(ranges.map((r) => (r.start, r.end)), [(0, 55), (1000, 1001)]);
    expect(ranges.first.chunks.length, 3);
  });

  test('slug names are safe file names', () {
    expect(fileSlug('Great Smoky Mtns!'), 'great-smoky-mtns');
    expect(fileSlug('  '), 'region');
  });

  group('HttpRangeReader', () {
    late HttpServer server;
    final data = Uint8List.fromList(List.generate(50000, (i) => i % 251));
    var dropOnce = false;
    var requests = <String>[];

    setUp(() async {
      requests = [];
      dropOnce = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final range = req.headers.value(HttpHeaders.rangeHeader);
        requests.add('${req.method} ${req.uri.path} $range');
        if (req.method == 'HEAD') {
          req.response.statusCode = req.uri.path == '/20261102.pmtiles'
              ? HttpStatus.ok
              : HttpStatus.notFound;
          await req.response.close();
          return;
        }
        final m = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range!)!;
        final from = int.parse(m[1]!), to = int.parse(m[2]!);
        req.response.statusCode = HttpStatus.partialContent;
        if (dropOnce) {
          // Send the headers and 100 bytes, then drop the connection.
          dropOnce = false;
          final socket = await req.response.detachSocket(writeHeaders: false);
          socket.add(
            'HTTP/1.1 206 Partial Content\r\n'
                    'Content-Range: bytes $from-$to/${data.length}\r\n'
                    'Content-Length: ${to - from + 1}\r\n\r\n'
                .codeUnits,
          );
          socket.add(data.sublist(from, from + 100));
          await socket.flush();
          socket.destroy();
          return;
        }
        req.response.add(data.sublist(from, to + 1));
        await req.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    test('reads a range and resumes after a dropped connection', () async {
      final reader = HttpRangeReader(
        url('/planet.pmtiles'),
        retryDelay: (_) => Duration.zero,
      );
      expect(await reader.read(100, 10), data.sublist(100, 110));
      dropOnce = true;
      expect(await reader.read(1000, 30000), data.sublist(1000, 31000));
      expect(requests.last, endsWith('bytes=1100-30999'));
      reader.close();
    });

    test('finds the newest build by HEAD', () async {
      final uri = await latestPlanetBuild(
        base: url('/'),
        today: DateTime.utc(2026, 11, 5),
      );
      expect(uri.path, '/20261102.pmtiles');
      expect(requests.length, 4);
      await expectLater(
        latestPlanetBuild(base: url('/'), today: DateTime.utc(2026, 11, 20)),
        throwsA(isA<MapImportException>()),
      );
    });

    test('cancel stops the download and leaves no file', () async {
      final reader = HttpRangeReader(url('/planet.pmtiles'));
      // A memory planet with an HTTP tile section is more than the test
      // needs; cancelling before the first request is enough to prove
      // the clean-up path.
      final download = RegionDownload(store, MemoryRangeReader(planet));
      final plan = await download.plan(bounds: part, maxZoom: 12);
      download.cancel();
      await expectLater(
        download.run(plan, displayName: 'x'),
        throwsA(isA<RegionDownloadCancelled>()),
      );
      expect(dir.listSync().where((f) => f.path.endsWith('.pmtiles')), isEmpty);
      expect(await store.regions(), isEmpty);
      reader.close();
    });
  });
}
