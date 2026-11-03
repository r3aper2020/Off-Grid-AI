import 'dart:io' show gzip;
import 'dart:math' as math;
import 'dart:typed_data';

import 'map_bounds.dart';
import 'pmtiles_header.dart';

/// One PMTiles v3 directory entry. A [runLength] of 0 marks a pointer to
/// a leaf directory ([offset] into the leaf section, [length] its
/// compressed size); otherwise [runLength] consecutive tile ids from
/// [tileId] share the tile data at [offset] in the tile section.
class PmtilesEntry {
  const PmtilesEntry({
    required this.tileId,
    required this.offset,
    required this.length,
    required this.runLength,
  });

  final int tileId;
  final int offset;
  final int length;
  final int runLength;

  bool get isLeaf => runLength == 0;

  PmtilesEntry withOffset(int offset) => PmtilesEntry(
    tileId: tileId,
    offset: offset,
    length: length,
    runLength: runLength,
  );

  @override
  String toString() => 'Entry($tileId @$offset+$length x$runLength)';
}

/// Tile id of z/x/y on the Hilbert curve the spec orders tiles by: all
/// tiles of lower zooms come first, then this zoom's curve position.
int zxyToTileId(int z, int x, int y) {
  assert(z >= 0 && z <= 26);
  assert(x >= 0 && x < (1 << z) && y >= 0 && y < (1 << z));
  var acc = 0;
  for (var t = 0; t < z; t++) {
    acc += 1 << (2 * t);
  }
  final n = 1 << z;
  var tx = x, ty = y, d = 0;
  for (var s = n >> 1; s > 0; s >>= 1) {
    final rx = (tx & s) > 0 ? 1 : 0;
    final ry = (ty & s) > 0 ? 1 : 0;
    d += s * s * ((3 * rx) ^ ry);
    if (ry == 0) {
      if (rx == 1) {
        tx = n - 1 - tx;
        ty = n - 1 - ty;
      }
      final t = tx;
      tx = ty;
      ty = t;
    }
  }
  return acc + d;
}

/// The x/y tile range of [bounds] at zoom [z] (Web Mercator).
({int minX, int minY, int maxX, int maxY}) tileRange(MapBounds bounds, int z) {
  final n = 1 << z;
  int x(double lon) => ((lon + 180) / 360 * n).floor().clamp(0, n - 1);
  int y(double lat) {
    final r = lat.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    final v = (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2;
    return (v * n).floor().clamp(0, n - 1);
  }

  return (
    minX: x(bounds.minLon),
    maxX: x(bounds.maxLon),
    minY: y(bounds.maxLat),
    maxY: y(bounds.minLat),
  );
}

/// How many tiles [bounds] covers from [minZoom] to [maxZoom].
int tileCount(MapBounds bounds, int minZoom, int maxZoom) {
  var count = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final r = tileRange(bounds, z);
    count += (r.maxX - r.minX + 1) * (r.maxY - r.minY + 1);
  }
  return count;
}

/// Sorted ids of every tile in [bounds] from [minZoom] to [maxZoom].
List<int> tileIdsIn(MapBounds bounds, int minZoom, int maxZoom) {
  final ids = <int>[];
  for (var z = minZoom; z <= maxZoom; z++) {
    final r = tileRange(bounds, z);
    for (var x = r.minX; x <= r.maxX; x++) {
      for (var y = r.minY; y <= r.maxY; y++) {
        ids.add(zxyToTileId(z, x, y));
      }
    }
  }
  ids.sort();
  return ids;
}

/// The entry covering [tileId] in a directory sorted by tile id: a leaf
/// pointer to descend into, a run containing the id, or null.
PmtilesEntry? findEntry(List<PmtilesEntry> dir, int tileId) {
  var lo = 0, hi = dir.length - 1, found = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (dir[mid].tileId <= tileId) {
      found = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  if (found < 0) return null;
  final e = dir[found];
  if (e.isLeaf) return e;
  return tileId < e.tileId + e.runLength ? e : null;
}

/// Decodes an uncompressed directory.
List<PmtilesEntry> decodeDirectory(Uint8List bytes) {
  final r = _VarintReader(bytes);
  final n = r.next();
  final ids = List<int>.filled(n, 0);
  var last = 0;
  for (var i = 0; i < n; i++) {
    last += r.next();
    ids[i] = last;
  }
  final runs = List<int>.generate(n, (_) => r.next());
  final lengths = List<int>.generate(n, (_) => r.next());
  final entries = <PmtilesEntry>[];
  for (var i = 0; i < n; i++) {
    final v = r.next();
    final offset = (i > 0 && v == 0)
        ? entries[i - 1].offset + entries[i - 1].length
        : v - 1;
    entries.add(
      PmtilesEntry(
        tileId: ids[i],
        offset: offset,
        length: lengths[i],
        runLength: runs[i],
      ),
    );
  }
  return entries;
}

/// Encodes a directory (sorted by tile id), uncompressed.
Uint8List encodeDirectory(List<PmtilesEntry> entries) {
  final w = _VarintWriter();
  w.write(entries.length);
  var last = 0;
  for (final e in entries) {
    w.write(e.tileId - last);
    last = e.tileId;
  }
  for (final e in entries) {
    w.write(e.runLength);
  }
  for (final e in entries) {
    w.write(e.length);
  }
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final contiguous =
        i > 0 && e.offset == entries[i - 1].offset + entries[i - 1].length;
    w.write(contiguous ? 0 : e.offset + 1);
  }
  return w.bytes;
}

Uint8List gzipBytes(List<int> bytes) => Uint8List.fromList(gzip.encode(bytes));
Uint8List gunzipBytes(List<int> bytes) =>
    Uint8List.fromList(gzip.decode(bytes));

/// Root and leaf directories for [entries] (sorted by tile id, offsets
/// already relative to the new tile section). The root is kept under
/// [maxRootBytes] compressed, as the spec recommends, by moving entries
/// into leaves when needed.
({Uint8List root, Uint8List leaves}) buildDirectories(
  List<PmtilesEntry> entries, {
  int maxRootBytes = 16384 - PmtilesHeader.length,
}) {
  final rootOnly = gzipBytes(encodeDirectory(entries));
  if (rootOnly.length <= maxRootBytes) {
    return (root: rootOnly, leaves: Uint8List(0));
  }
  for (var leafSize = 4096; ; leafSize *= 2) {
    final leaves = BytesBuilder(copy: false);
    final root = <PmtilesEntry>[];
    for (var i = 0; i < entries.length; i += leafSize) {
      final chunk = entries.sublist(i, math.min(i + leafSize, entries.length));
      final leaf = gzipBytes(encodeDirectory(chunk));
      root.add(
        PmtilesEntry(
          tileId: chunk.first.tileId,
          offset: leaves.length,
          length: leaf.length,
          runLength: 0,
        ),
      );
      leaves.add(leaf);
    }
    final rootBytes = gzipBytes(encodeDirectory(root));
    if (rootBytes.length <= maxRootBytes || root.length == 1) {
      return (root: rootBytes, leaves: leaves.takeBytes());
    }
  }
}

/// Everything in an archive before the tile data: header, root
/// directory, metadata, leaf directories. [entries] carry their new
/// offsets; [tileDataLength] is the tile section the caller appends.
Uint8List buildArchivePrefix({
  required PmtilesHeader source,
  required List<PmtilesEntry> entries,
  required Uint8List metadata,
  required MapBounds bounds,
  required int minZoom,
  required int maxZoom,
  required int tileDataLength,
  required int addressedTiles,
  required int tileContents,
}) {
  final dirs = buildDirectories(entries);
  final rootOffset = PmtilesHeader.length;
  final metadataOffset = rootOffset + dirs.root.length;
  final leafOffset = metadataOffset + metadata.length;
  final tileOffset = leafOffset + dirs.leaves.length;
  final header = source.copyWith(
    rootDirOffset: rootOffset,
    rootDirLength: dirs.root.length,
    metadataOffset: metadataOffset,
    metadataLength: metadata.length,
    leafDirsOffset: leafOffset,
    leafDirsLength: dirs.leaves.length,
    tileDataOffset: tileOffset,
    tileDataLength: tileDataLength,
    addressedTiles: addressedTiles,
    tileEntries: entries.length,
    tileContents: tileContents,
    clustered: true,
    internalCompression: PmtilesHeader.compressionGzip,
    minZoom: minZoom,
    maxZoom: maxZoom,
    minLon: bounds.minLon,
    minLat: bounds.minLat,
    maxLon: bounds.maxLon,
    maxLat: bounds.maxLat,
    centerZoom: math.min(maxZoom, 12),
    centerLon: bounds.centerLon,
    centerLat: bounds.centerLat,
  );
  final out = BytesBuilder(copy: false)
    ..add(header.toBytes())
    ..add(dirs.root)
    ..add(metadata)
    ..add(dirs.leaves);
  return out.takeBytes();
}

class _VarintReader {
  _VarintReader(this._bytes);
  final Uint8List _bytes;
  var _pos = 0;

  int next() {
    var result = 0, shift = 0;
    while (true) {
      if (_pos >= _bytes.length) {
        throw const FormatException('Truncated PMTiles directory');
      }
      final b = _bytes[_pos++];
      result |= (b & 0x7f) << shift;
      if (b < 0x80) return result;
      shift += 7;
    }
  }
}

class _VarintWriter {
  final _out = BytesBuilder(copy: false);

  void write(int v) {
    assert(v >= 0);
    while (v >= 0x80) {
      _out.addByte((v & 0x7f) | 0x80);
      v >>= 7;
    }
    _out.addByte(v);
  }

  Uint8List get bytes => _out.takeBytes();
}
