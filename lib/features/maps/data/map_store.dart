import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../domain/pmtiles_header.dart';

class MapImportException implements Exception {
  const MapImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Offline map regions: PMTiles archives in app-private storage and their
/// rows in `map_regions`. Mirrors `ModelStore`: `.part` file while
/// writing, header check, atomic rename.
class MapStore {
  MapStore(this._db, this._dir);

  final AppDatabase _db;
  final Directory _dir;

  Directory get directory => _dir;

  Stream<List<MapRegion>> watchRegions() {
    return (_db.select(
      _db.mapRegions,
    )..orderBy([(r) => OrderingTerm.asc(r.displayName)])).watch();
  }

  Future<List<MapRegion>> regions() => _db.select(_db.mapRegions).get();

  File fileFor(MapRegion region) => File(p.join(_dir.path, region.fileName));

  /// Copies [bytes] into storage as [originalName] and registers the
  /// region with the bounds from the archive header. [onProgress]
  /// receives bytes written so far.
  Future<MapRegion> import({
    required String originalName,
    required Stream<List<int>> bytes,
    void Function(int written)? onProgress,
    String? displayName,
  }) async {
    if (p.extension(originalName).toLowerCase() != '.pmtiles') {
      throw const MapImportException(
        'That isn\'t a map region file. Choose a file ending in .pmtiles.',
      );
    }
    await _dir.create(recursive: true);
    final fileName = await _uniqueName(p.basename(originalName));
    final target = File(p.join(_dir.path, fileName));
    final part = File('${target.path}.part');

    var written = 0;
    final head = BytesBuilder(copy: false);
    PmtilesHeader? header;
    final sink = part.openWrite();
    try {
      await for (final chunk in bytes) {
        if (head.length < PmtilesHeader.length) {
          head.add(chunk.take(PmtilesHeader.length - head.length).toList());
          if (head.length >= PmtilesHeader.length) {
            header = PmtilesHeader.parse(head.toBytes());
            if (header == null) {
              throw const MapImportException(
                'That file isn\'t a PMTiles v3 archive.',
              );
            }
            if (!header.isVector) {
              throw const MapImportException(
                'Only vector (MVT) PMTiles archives are supported.',
              );
            }
          }
        }
        sink.add(chunk);
        written += chunk.length;
        onProgress?.call(written);
      }
      await sink.flush();
      await sink.close();
      if (header == null) {
        throw const MapImportException('That file is too short to be a map.');
      }
    } catch (_) {
      await sink.close().catchError((_) {});
      await part.delete().catchError((_) => part);
      rethrow;
    }
    await part.rename(target.path);

    final h = header;
    final id = await _db
        .into(_db.mapRegions)
        .insert(
          MapRegionsCompanion.insert(
            displayName: displayName ?? _nameFrom(originalName),
            fileName: fileName,
            sizeBytes: written,
            minLon: h.minLon,
            minLat: h.minLat,
            maxLon: h.maxLon,
            maxLat: h.maxLat,
            minZoom: h.minZoom,
            maxZoom: h.maxZoom,
            installedAt: DateTime.now(),
          ),
        );
    return (_db.select(
      _db.mapRegions,
    )..where((r) => r.id.equals(id))).getSingle();
  }

  Future<void> delete(MapRegion region) async {
    await (_db.delete(
      _db.mapRegions,
    )..where((r) => r.id.equals(region.id))).go();
    final f = fileFor(region);
    if (await f.exists()) await f.delete();
  }

  /// Removes `.part` files left by an interrupted import.
  Future<void> cleanUpPartials() async {
    if (!await _dir.exists()) return;
    await for (final e in _dir.list()) {
      if (e is File && e.path.endsWith('.part')) await e.delete();
    }
  }

  static String _nameFrom(String fileName) {
    final base = p.basenameWithoutExtension(fileName);
    return base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  Future<String> _uniqueName(String name) async {
    var candidate = name;
    var n = 2;
    while (await File(p.join(_dir.path, candidate)).exists()) {
      candidate = '${p.basenameWithoutExtension(name)}-$n${p.extension(name)}';
      n++;
    }
    return candidate;
  }
}

/// A fake archive for tests: a valid v3 header followed by [padding]
/// zero bytes.
Uint8List fakePmtiles({
  int tileType = 1,
  int minZoom = 0,
  int maxZoom = 14,
  double minLon = -83.95,
  double minLat = 35.4,
  double maxLon = -83.0,
  double maxLat = 35.8,
  int padding = 64,
}) {
  final b = Uint8List(PmtilesHeader.length + padding);
  b.setRange(0, 7, 'PMTiles'.codeUnits);
  b[7] = 3;
  final d = ByteData.sublistView(b);
  void e7(int offset, double v) =>
      d.setInt32(offset, (v * 1e7).round(), Endian.little);
  b[99] = tileType;
  b[100] = minZoom;
  b[101] = maxZoom;
  e7(102, minLon);
  e7(106, minLat);
  e7(110, maxLon);
  e7(114, maxLat);
  b[118] = minZoom;
  e7(119, (minLon + maxLon) / 2);
  e7(123, (minLat + maxLat) / 2);
  return b;
}
