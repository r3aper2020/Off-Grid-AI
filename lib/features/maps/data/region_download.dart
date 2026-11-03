import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/database/app_database.dart';
import '../domain/map_bounds.dart';
import '../domain/pmtiles.dart';
import '../domain/pmtiles_header.dart';
import 'map_store.dart';
import 'range_reader.dart';

/// The area is too big to download in one go.
class RegionTooLargeException implements Exception {
  const RegionTooLargeException(this.tiles);
  final int tiles;
  @override
  String toString() =>
      'That area is $tiles tiles; the limit is ${RegionDownload.maxTiles}. '
      'Zoom in or choose less detail.';
}

/// What a download will fetch, worked out from the planet's directories
/// before any tile is downloaded: so the size shown is exact.
class RegionPlan {
  const RegionPlan({
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.entries,
    required this.chunks,
    required this.prefix,
    required this.tileBytes,
    required this.sourceTileOffset,
  });

  final MapBounds bounds;
  final int minZoom;
  final int maxZoom;

  /// Source entries, sorted by tile id, one per distinct tile id.
  final List<PmtilesEntry> entries;

  /// Distinct tile data to fetch, sorted by source offset.
  final List<({int offset, int length})> chunks;

  /// Header, directories and metadata of the archive being made.
  final Uint8List prefix;
  final int tileBytes;

  /// Where the planet's tile section starts; [chunks] are relative to it.
  final int sourceTileOffset;

  int get tileCount => entries.fold(0, (n, e) => n + e.runLength);
  int get totalBytes => prefix.length + tileBytes;
}

/// Cuts a region out of a PMTiles planet archive by byte range, the way
/// `pmtiles extract` does, and streams the new archive into [MapStore].
/// This and the model downloader are the only network code in the app;
/// both run only when the user taps Download.
class RegionDownload {
  RegionDownload(this._store, this._reader);

  final MapStore _store;
  final RangeReader _reader;

  /// Tiles per download; past this the user is asked to zoom in.
  static const maxTiles = 300000;

  /// Gaps up to this many bytes between wanted tiles are fetched rather
  /// than paid for as another request.
  static const maxGap = 128 << 10;

  final _leaves = <int, List<PmtilesEntry>>{};

  /// Reads the planet's header and the directories covering [bounds]
  /// (a few hundred KB) and returns exactly what a download would fetch.
  Future<RegionPlan> plan({
    required MapBounds bounds,
    required int maxZoom,
  }) async {
    final header = PmtilesHeader.parse(
      await _reader.read(0, PmtilesHeader.length),
    );
    if (header == null || !header.isVector) {
      throw const MapImportException(
        'The map server did not return a PMTiles planet archive.',
      );
    }
    final minZoom = header.minZoom;
    final top = math.min(maxZoom, header.maxZoom);
    final count = tileCount(bounds, minZoom, top);
    if (count > maxTiles) throw RegionTooLargeException(count);

    final root = await _directory(header.rootDirOffset, header.rootDirLength);
    var metadata = await _reader.read(
      header.metadataOffset,
      header.metadataLength,
    );
    if (header.internalCompression != PmtilesHeader.compressionGzip) {
      metadata = gzipBytes(metadata);
    }

    final found = <int, PmtilesEntry>{};
    for (final id in tileIdsIn(bounds, minZoom, top)) {
      var e = findEntry(root, id);
      if (e != null && e.isLeaf) {
        final leaf = _leaves[e.offset] ??= await _directory(
          header.leafDirsOffset + e.offset,
          e.length,
        );
        e = findEntry(leaf, id);
      }
      if (e != null) found[e.tileId] = e;
    }
    final entries = found.values.toList()
      ..sort((a, b) => a.tileId.compareTo(b.tileId));

    // Distinct tile data in source order gets packed back to back.
    final lengthAt = <int, int>{for (final e in entries) e.offset: e.length};
    final offsets = lengthAt.keys.toList()..sort();
    final newOffset = <int, int>{};
    var tileBytes = 0;
    for (final o in offsets) {
      newOffset[o] = tileBytes;
      tileBytes += lengthAt[o]!;
    }
    final rewritten = [
      for (final e in entries) e.withOffset(newOffset[e.offset]!),
    ];
    final prefix = buildArchivePrefix(
      source: header,
      entries: rewritten,
      metadata: metadata,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: top,
      tileDataLength: tileBytes,
      addressedTiles: rewritten.fold(0, (n, e) => n + e.runLength),
      tileContents: offsets.length,
    );
    return RegionPlan(
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: top,
      entries: entries,
      chunks: [for (final o in offsets) (offset: o, length: lengthAt[o]!)],
      prefix: prefix,
      tileBytes: tileBytes,
      sourceTileOffset: header.tileDataOffset,
    );
  }

  /// Downloads [plan] into the store as [displayName]. [onProgress] gets
  /// bytes written out of [RegionPlan.totalBytes].
  Future<MapRegion> run(
    RegionPlan plan, {
    required String displayName,
    void Function(int written)? onProgress,
  }) async {
    try {
      return await _store.import(
        originalName: '${fileSlug(displayName)}.pmtiles',
        displayName: displayName,
        bytes: _archive(plan),
        onProgress: onProgress,
      );
    } on MapImportException {
      if (_cancelled) throw const RegionDownloadCancelled();
      rethrow;
    } on RegionDownloadCancelled {
      rethrow;
    } on Object catch (e) {
      if (_cancelled) throw const RegionDownloadCancelled();
      throw MapImportException(networkMessage(e));
    } finally {
      _reader.close();
    }
  }

  bool _cancelled = false;

  /// Aborts a download in flight; [run] then throws
  /// [RegionDownloadCancelled] and leaves no file behind.
  void cancel() {
    _cancelled = true;
    final r = _reader;
    if (r is HttpRangeReader) r.cancel();
  }

  /// Drops the connection of a plan that won't be downloaded.
  void close() => _reader.close();

  Stream<List<int>> _archive(RegionPlan plan) async* {
    yield plan.prefix;
    var emitted = 0;
    for (final range in mergeChunks(plan.chunks, maxGap: maxGap)) {
      var pos = range.start;
      var next = 0; // index into range.chunks
      final source = plan.sourceTileOffset + range.start;
      await for (final buf in _reader.stream(source, range.end - range.start)) {
        if (_cancelled) throw const RegionDownloadCancelled();
        final bufStart = pos, bufEnd = pos + buf.length;
        while (next < range.chunks.length) {
          final c = range.chunks[next];
          final cStart = c.offset, cEnd = c.offset + c.length;
          if (cStart >= bufEnd) break;
          final from = math.max(cStart, bufStart) - bufStart;
          final to = math.min(cEnd, bufEnd) - bufStart;
          if (to > from) {
            yield buf.sublist(from, to);
            emitted += to - from;
          }
          if (cEnd <= bufEnd) {
            next++;
          } else {
            break;
          }
        }
        pos = bufEnd;
      }
    }
    if (emitted != plan.tileBytes) {
      throw MapImportException(
        'The map server sent $emitted of ${plan.tileBytes} tile bytes.',
      );
    }
  }

  Future<List<PmtilesEntry>> _directory(int offset, int length) async =>
      decodeDirectory(gunzipBytes(await _reader.read(offset, length)));
}

/// One HTTP request: [start]–[end) covering [chunks], which may leave
/// small gaps that are fetched and dropped.
class ByteRange {
  const ByteRange({
    required this.start,
    required this.end,
    required this.chunks,
  });
  final int start;
  final int end;
  final List<({int offset, int length})> chunks;
}

/// Groups chunks (sorted by offset) into ranges, joining neighbours
/// closer than [maxGap].
List<ByteRange> mergeChunks(
  List<({int offset, int length})> chunks, {
  required int maxGap,
}) {
  final ranges = <ByteRange>[];
  var start = -1, end = -1;
  var group = <({int offset, int length})>[];
  for (final c in chunks) {
    if (start >= 0 && c.offset - end <= maxGap) {
      group.add(c);
      end = math.max(end, c.offset + c.length);
      continue;
    }
    if (start >= 0) {
      ranges.add(ByteRange(start: start, end: end, chunks: group));
    }
    start = c.offset;
    end = c.offset + c.length;
    group = [c];
  }
  if (start >= 0) ranges.add(ByteRange(start: start, end: end, chunks: group));
  return ranges;
}

/// "Great Smoky Mtns" → "great-smoky-mtns".
String fileSlug(String name) {
  final s = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'region' : s;
}
