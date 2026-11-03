import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../domain/map_bounds.dart';
import '../domain/pmtiles.dart';
import '../domain/pmtiles_header.dart';
import '../domain/raster_sources.dart';
import 'map_store.dart';
import 'range_reader.dart';
import 'region_download.dart'
    show RegionTooLargeException, RegionDownload, fileSlug;

/// What a raster layer download will fetch, with a size estimated from
/// sample tiles (tile services don't say how big a tile is in advance).
class RasterPlan {
  const RasterPlan({
    required this.parent,
    required this.source,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.estimatedBytes,
  });

  final MapRegion parent;
  final RasterTileSource source;
  final MapBounds bounds;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int estimatedBytes;
}

/// Downloads one raster layer (topo, imagery or elevation) for a streets
/// region: every tile of the region's box from [rasterMinZoom] to the
/// source's limit, written into a PMTiles archive the map reads
/// offline. Tiles are fetched a few at a time, in tile-id order, so the
/// archive comes out clustered; identical tiles (blank sea, no data)
/// are stored once. Network use only on the user's tap, like the others.
class RasterLayerDownload {
  RasterLayerDownload(
    this._store,
    this.source, {
    this.concurrency = 4,
    this.sampleSize = 12,
    Duration Function(int attempt)? retryDelay,
  }) : _retryDelay = retryDelay ?? _defaultDelay;

  final MapStore _store;
  final RasterTileSource source;
  final int concurrency;
  final int sampleSize;
  final Duration Function(int attempt) _retryDelay;

  final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'offgrid-ai';
  bool _cancelled = false;
  final _cancelSignal = Completer<void>();

  static const _maxAttempts = 8;
  static Duration _defaultDelay(int attempt) => Duration(
    seconds: [2, 4, 8, 15, 30, 30, 30, 30][(attempt - 1).clamp(0, 7)],
  );

  /// Zoom range and tile count for [parent], plus a size estimate from
  /// [sampleSize] tiles spread over the deepest zoom.
  Future<RasterPlan> estimate(MapRegion parent) async {
    final bounds = MapBounds(
      minLon: parent.minLon,
      minLat: parent.minLat,
      maxLon: parent.maxLon,
      maxLat: parent.maxLat,
    );
    final minZoom = math.min(rasterMinZoom, parent.maxZoom);
    final maxZoom = math.min(parent.maxZoom, source.maxZoom);
    final count = tileCount(bounds, minZoom, maxZoom);
    if (count > RegionDownload.maxTiles) throw RegionTooLargeException(count);

    final deep = tileRange(bounds, maxZoom);
    final cols = deep.maxX - deep.minX + 1, rows = deep.maxY - deep.minY + 1;
    final n = math.min(sampleSize, cols * rows);
    var total = 0;
    for (var i = 0; i < n; i++) {
      // Walk a diagonal-ish path so samples cover the box.
      final x = deep.minX + (i * cols ~/ n + i) % cols;
      final y = deep.minY + (i * rows ~/ n) % rows;
      total += (await _fetch(maxZoom, x, y))?.length ?? 0;
    }
    final perTile = n == 0 ? 0 : total ~/ n;
    return RasterPlan(
      parent: parent,
      source: source,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      tileCount: count,
      estimatedBytes: perTile * count,
    );
  }

  /// Fetches every tile of [plan] and installs the archive under the
  /// parent region. [onProgress] gets tiles done and bytes so far.
  Future<MapRegion> run(
    RasterPlan plan, {
    void Function(int tiles, int bytes)? onProgress,
  }) async {
    final parent = plan.parent;
    final slug = '${fileSlug(parent.displayName)}-${source.kind.name}';
    await _store.directory.create(recursive: true);
    final tiles = File(p.join(_store.directory.path, '$slug.tiles.part'));
    final sink = tiles.openWrite();
    final entries = <PmtilesEntry>[];
    final seen = <String, ({int offset, int length})>{};
    var offset = 0;
    var done = 0;
    int? tileType;
    try {
      final ids = tileIdsIn(plan.bounds, plan.minZoom, plan.maxZoom);
      final coords = _coordsFor(plan.bounds, plan.minZoom, plan.maxZoom);
      for (var i = 0; i < ids.length; i += concurrency) {
        final batch = ids.sublist(i, math.min(i + concurrency, ids.length));
        final fetched = await Future.wait([
          for (final id in batch)
            () {
              final c = coords[id]!;
              return _fetch(c.$1, c.$2, c.$3);
            }(),
        ]);
        for (var j = 0; j < batch.length; j++) {
          final bytes = fetched[j];
          done++;
          if (bytes == null) continue; // No tile there (outside coverage).
          tileType ??= _tileType(bytes);
          final key = sha1.convert(bytes).toString();
          var slot = seen[key];
          if (slot == null) {
            slot = (offset: offset, length: bytes.length);
            seen[key] = slot;
            sink.add(bytes);
            offset += bytes.length;
          }
          entries.add(
            PmtilesEntry(
              tileId: batch[j],
              offset: slot.offset,
              length: slot.length,
              runLength: 1,
            ),
          );
        }
        onProgress?.call(done, offset);
        if (_cancelled) throw const RegionDownloadCancelled();
      }
      await sink.flush();
      await sink.close();
      if (entries.isEmpty) {
        throw MapImportException('${source.label} has no tiles for this area.');
      }
      final header = PmtilesHeader(
        rootDirOffset: 0,
        rootDirLength: 0,
        metadataOffset: 0,
        metadataLength: 0,
        leafDirsOffset: 0,
        leafDirsLength: 0,
        tileDataOffset: 0,
        tileDataLength: 0,
        addressedTiles: 0,
        tileEntries: 0,
        tileContents: 0,
        clustered: true,
        internalCompression: PmtilesHeader.compressionGzip,
        tileCompression: PmtilesHeader.compressionNone,
        tileType: tileType!,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
        minLon: plan.bounds.minLon,
        minLat: plan.bounds.minLat,
        maxLon: plan.bounds.maxLon,
        maxLat: plan.bounds.maxLat,
        centerZoom: plan.minZoom,
        centerLon: plan.bounds.centerLon,
        centerLat: plan.bounds.centerLat,
      );
      final prefix = buildArchivePrefix(
        source: header,
        entries: entries,
        metadata: gzipBytes(
          utf8.encode(
            jsonEncode({
              'name': '${parent.displayName} ${source.label}',
              'attribution': source.attribution,
              if (source.isElevation) 'encoding': 'terrarium',
            }),
          ),
        ),
        bounds: plan.bounds,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
        tileDataLength: offset,
        addressedTiles: entries.length,
        tileContents: seen.length,
      );
      Stream<List<int>> archive() async* {
        yield prefix;
        yield* tiles.openRead();
      }

      return await _store.import(
        originalName: '$slug.pmtiles',
        displayName: '${parent.displayName} · ${source.label}',
        bytes: archive(),
        kind: source.kind,
        parentId: parent.id,
      );
    } on RegionDownloadCancelled {
      rethrow;
    } on MapImportException {
      if (_cancelled) throw const RegionDownloadCancelled();
      rethrow;
    } on Object catch (e) {
      if (_cancelled) throw const RegionDownloadCancelled();
      throw MapImportException(networkMessage(e));
    } finally {
      await sink.close().catchError((_) {});
      await tiles.delete().catchError((_) => tiles);
      _client.close(force: true);
    }
  }

  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    _client.close(force: true);
  }

  void close() => _client.close(force: true);

  /// GET one tile; null when the service has none there (404). Transient
  /// failures are retried with backoff.
  Future<Uint8List?> _fetch(int z, int x, int y) async {
    var attempt = 0;
    while (true) {
      try {
        final request = await _client.getUrl(source.tileUrl(z, x, y));
        final response = await request.close();
        if (response.statusCode == HttpStatus.notFound ||
            response.statusCode == HttpStatus.noContent) {
          await response.drain<void>();
          return null;
        }
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>().catchError((_) {});
          throw HttpException('HTTP ${response.statusCode}');
        }
        final b = BytesBuilder(copy: false);
        await for (final chunk in response.timeout(
          const Duration(seconds: 60),
        )) {
          b.add(chunk);
        }
        final bytes = b.takeBytes();
        if (bytes.isEmpty) return null;
        return bytes;
      } on Object catch (e) {
        if (_cancelled || !_isTransient(e) || ++attempt >= _maxAttempts) {
          rethrow;
        }
        await Future.any([
          Future<void>.delayed(_retryDelay(attempt)),
          _cancelSignal.future,
        ]);
        if (_cancelled) rethrow;
      }
    }
  }

  static bool _isTransient(Object e) =>
      e is SocketException ||
      e is HttpException ||
      e is HandshakeException ||
      e is TimeoutException;

  /// PMTiles tile type from the image's magic bytes.
  static int _tileType(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 2; // PNG
    if (b.length > 2 && b[0] == 0xFF && b[1] == 0xD8) return 3; // JPEG
    if (b.length > 4 && b[0] == 0x52 && b[1] == 0x49) return 4; // WebP
    return 2;
  }

  static Map<int, (int, int, int)> _coordsFor(
    MapBounds bounds,
    int minZoom,
    int maxZoom,
  ) {
    final out = <int, (int, int, int)>{};
    for (var z = minZoom; z <= maxZoom; z++) {
      final r = tileRange(bounds, z);
      for (var x = r.minX; x <= r.maxX; x++) {
        for (var y = r.minY; y <= r.maxY; y++) {
          out[zxyToTileId(z, x, y)] = (z, x, y);
        }
      }
    }
    return out;
  }
}
