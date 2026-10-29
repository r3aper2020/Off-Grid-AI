import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';

/// Raised for import problems the user can act on. [message] is shown as-is.
class ModelImportException implements Exception {
  const ModelImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Owns GGUF files in app-private storage and their registry rows.
///
/// Imports are written to a `.part` file and renamed only after the whole
/// file is copied and validated, so an interrupted import never leaves a
/// half-written model that could be activated.
class ModelStore {
  ModelStore(this._db, this._dir);

  final AppDatabase _db;
  final Directory _dir;

  static final _ggufMagic = Uint8List.fromList('GGUF'.codeUnits);

  Stream<List<InstalledModel>> watchModels() {
    return (_db.select(
      _db.installedModels,
    )..orderBy([(m) => OrderingTerm.asc(m.displayName)])).watch();
  }

  Stream<InstalledModel?> watchActive() {
    return (_db.select(
      _db.installedModels,
    )..where((m) => m.isActive.equals(true))).watchSingleOrNull();
  }

  File fileFor(InstalledModel model) => File(p.join(_dir.path, model.fileName));

  /// Copies [bytes] into storage as [originalName]. The first model
  /// imported becomes active. [onProgress] receives bytes written so far.
  ///
  /// When [expectedSize] or [expectedSha256] are given (downloads from the
  /// catalog), the file is only installed if both match.
  Future<InstalledModel> import({
    required String originalName,
    required Stream<List<int>> bytes,
    void Function(int written)? onProgress,
    String? displayName,
    int? expectedSize,
    String? expectedSha256,
  }) async {
    if (p.extension(originalName).toLowerCase() != '.gguf') {
      throw const ModelImportException(
        'That isn\'t a GGUF model file. Choose a file ending in .gguf.',
      );
    }

    final dir = _dir;
    await dir.create(recursive: true);
    final fileName = await _uniqueName(dir, p.basename(originalName));
    final target = File(p.join(dir.path, fileName));
    final part = File('${target.path}.part');

    var written = 0;
    final header = BytesBuilder(copy: false);
    final digest = _DigestSink();
    final hasher = expectedSha256 == null
        ? null
        : sha256.startChunkedConversion(digest);
    final sink = part.openWrite();
    try {
      await for (final chunk in bytes) {
        if (header.length < _ggufMagic.length) {
          header.add(chunk.take(_ggufMagic.length - header.length).toList());
          if (header.length >= _ggufMagic.length &&
              !_isGguf(header.toBytes())) {
            throw const ModelImportException(
              'This file is not a valid GGUF model. It may be corrupt or '
              'a different format.',
            );
          }
        }
        sink.add(chunk);
        hasher?.add(chunk);
        written += chunk.length;
        onProgress?.call(written);
      }
      await sink.flush();
      await sink.close();
      if (written < _ggufMagic.length) {
        throw const ModelImportException('The model file is empty.');
      }
      if (expectedSize != null && written != expectedSize) {
        throw const ModelImportException(
          'The download was incomplete. Please try again.',
        );
      }
      if (hasher != null) {
        hasher.close();
        if (digest.value.toString() != expectedSha256!.toLowerCase()) {
          throw const ModelImportException(
            'The downloaded file failed its integrity check and was '
            'discarded. Please try again.',
          );
        }
      }
      await part.rename(target.path);
    } on FileSystemException catch (e) {
      await _discard(sink, part);
      // ENOSPC is errno 28 on both Linux/Android and Darwin.
      throw ModelImportException(
        e.osError?.errorCode == 28
            ? 'Not enough storage to import this model. Free up space and '
                  'try again.'
            : 'Couldn\'t save the model: ${e.message}',
      );
    } catch (_) {
      await _discard(sink, part);
      rethrow;
    }

    return _db.transaction(() async {
      final hasActive = await (_db.select(
        _db.installedModels,
      )..where((m) => m.isActive.equals(true))).getSingleOrNull();
      final id = await _db
          .into(_db.installedModels)
          .insert(
            InstalledModelsCompanion.insert(
              displayName: displayName ?? p.basenameWithoutExtension(fileName),
              fileName: fileName,
              sizeBytes: written,
              isActive: Value(hasActive == null),
              installedAt: DateTime.now(),
            ),
          );
      return (_db.select(
        _db.installedModels,
      )..where((m) => m.id.equals(id))).getSingle();
    });
  }

  Future<void> setActive(int id) {
    return _db.transaction(() async {
      await _db
          .update(_db.installedModels)
          .write(const InstalledModelsCompanion(isActive: Value(false)));
      await (_db.update(_db.installedModels)..where((m) => m.id.equals(id)))
          .write(const InstalledModelsCompanion(isActive: Value(true)));
    });
  }

  Future<void> delete(InstalledModel model) async {
    await (_db.delete(
      _db.installedModels,
    )..where((m) => m.id.equals(model.id))).go();
    final file = fileFor(model);
    if (await file.exists()) await file.delete();
  }

  /// Removes `.part` files left by imports that were interrupted.
  Future<void> cleanUpPartials() async {
    if (!await _dir.exists()) return;
    await for (final entity in _dir.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        await entity.delete();
      }
    }
  }

  static bool _isGguf(Uint8List header) {
    for (var i = 0; i < _ggufMagic.length; i++) {
      if (header[i] != _ggufMagic[i]) return false;
    }
    return true;
  }

  static Future<void> _discard(IOSink sink, File part) async {
    try {
      await sink.close();
    } catch (_) {}
    if (await part.exists()) await part.delete();
  }

  static Future<String> _uniqueName(Directory dir, String name) async {
    final base = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    var candidate = name;
    for (var n = 2; await File(p.join(dir.path, candidate)).exists(); n++) {
      candidate = '$base-$n$ext';
    }
    return candidate;
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
