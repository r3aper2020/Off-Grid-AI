import 'dart:typed_data';

/// The fixed 127-byte header at the start of a PMTiles v3 archive
/// (https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md).
class PmtilesHeader {
  const PmtilesHeader({
    required this.rootDirOffset,
    required this.rootDirLength,
    required this.metadataOffset,
    required this.metadataLength,
    required this.leafDirsOffset,
    required this.leafDirsLength,
    required this.tileDataOffset,
    required this.tileDataLength,
    required this.addressedTiles,
    required this.tileEntries,
    required this.tileContents,
    required this.clustered,
    required this.internalCompression,
    required this.tileCompression,
    required this.tileType,
    required this.minZoom,
    required this.maxZoom,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.centerZoom,
    required this.centerLon,
    required this.centerLat,
  });

  static const length = 127;
  static const _magic = 'PMTiles';
  static const _version = 3;

  /// Compression bytes: 1 = none, 2 = gzip.
  static const compressionNone = 1;
  static const compressionGzip = 2;

  final int rootDirOffset;
  final int rootDirLength;
  final int metadataOffset;
  final int metadataLength;
  final int leafDirsOffset;
  final int leafDirsLength;
  final int tileDataOffset;
  final int tileDataLength;

  /// Tiles the directories address (runs count every tile in the run).
  final int addressedTiles;

  /// Directory entries that point at tile data.
  final int tileEntries;

  /// Distinct tile contents (entries can share data).
  final int tileContents;
  final bool clustered;
  final int internalCompression;
  final int tileCompression;

  /// Tile type byte: 1 = MVT vector tiles, 2 = PNG, 3 = JPEG, 4 = WebP.
  final int tileType;
  final int minZoom;
  final int maxZoom;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final int centerZoom;
  final double centerLon;
  final double centerLat;

  bool get isVector => tileType == 1;

  /// Parses the first [length] bytes of an archive; null when they are
  /// not a PMTiles v3 header.
  static PmtilesHeader? parse(Uint8List bytes) {
    if (bytes.length < length) return null;
    if (String.fromCharCodes(bytes.sublist(0, 7)) != _magic) return null;
    if (bytes[7] != _version) return null;
    final d = ByteData.sublistView(bytes);
    int u64(int offset) => d.getUint64(offset, Endian.little);
    double e7(int offset) => d.getInt32(offset, Endian.little) / 1e7;
    return PmtilesHeader(
      rootDirOffset: u64(8),
      rootDirLength: u64(16),
      metadataOffset: u64(24),
      metadataLength: u64(32),
      leafDirsOffset: u64(40),
      leafDirsLength: u64(48),
      tileDataOffset: u64(56),
      tileDataLength: u64(64),
      addressedTiles: u64(72),
      tileEntries: u64(80),
      tileContents: u64(88),
      clustered: bytes[96] == 1,
      internalCompression: bytes[97],
      tileCompression: bytes[98],
      tileType: bytes[99],
      minZoom: bytes[100],
      maxZoom: bytes[101],
      minLon: e7(102),
      minLat: e7(106),
      maxLon: e7(110),
      maxLat: e7(114),
      centerZoom: bytes[118],
      centerLon: e7(119),
      centerLat: e7(123),
    );
  }

  Uint8List toBytes() {
    final b = Uint8List(length);
    b.setRange(0, 7, _magic.codeUnits);
    b[7] = _version;
    final d = ByteData.sublistView(b);
    void u64(int offset, int v) => d.setUint64(offset, v, Endian.little);
    void e7(int offset, double v) =>
        d.setInt32(offset, (v * 1e7).round(), Endian.little);
    u64(8, rootDirOffset);
    u64(16, rootDirLength);
    u64(24, metadataOffset);
    u64(32, metadataLength);
    u64(40, leafDirsOffset);
    u64(48, leafDirsLength);
    u64(56, tileDataOffset);
    u64(64, tileDataLength);
    u64(72, addressedTiles);
    u64(80, tileEntries);
    u64(88, tileContents);
    b[96] = clustered ? 1 : 0;
    b[97] = internalCompression;
    b[98] = tileCompression;
    b[99] = tileType;
    b[100] = minZoom;
    b[101] = maxZoom;
    e7(102, minLon);
    e7(106, minLat);
    e7(110, maxLon);
    e7(114, maxLat);
    b[118] = centerZoom;
    e7(119, centerLon);
    e7(123, centerLat);
    return b;
  }

  PmtilesHeader copyWith({
    int? rootDirOffset,
    int? rootDirLength,
    int? metadataOffset,
    int? metadataLength,
    int? leafDirsOffset,
    int? leafDirsLength,
    int? tileDataOffset,
    int? tileDataLength,
    int? addressedTiles,
    int? tileEntries,
    int? tileContents,
    bool? clustered,
    int? internalCompression,
    int? minZoom,
    int? maxZoom,
    double? minLon,
    double? minLat,
    double? maxLon,
    double? maxLat,
    int? centerZoom,
    double? centerLon,
    double? centerLat,
  }) {
    return PmtilesHeader(
      rootDirOffset: rootDirOffset ?? this.rootDirOffset,
      rootDirLength: rootDirLength ?? this.rootDirLength,
      metadataOffset: metadataOffset ?? this.metadataOffset,
      metadataLength: metadataLength ?? this.metadataLength,
      leafDirsOffset: leafDirsOffset ?? this.leafDirsOffset,
      leafDirsLength: leafDirsLength ?? this.leafDirsLength,
      tileDataOffset: tileDataOffset ?? this.tileDataOffset,
      tileDataLength: tileDataLength ?? this.tileDataLength,
      addressedTiles: addressedTiles ?? this.addressedTiles,
      tileEntries: tileEntries ?? this.tileEntries,
      tileContents: tileContents ?? this.tileContents,
      clustered: clustered ?? this.clustered,
      internalCompression: internalCompression ?? this.internalCompression,
      tileCompression: tileCompression,
      tileType: tileType,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      minLon: minLon ?? this.minLon,
      minLat: minLat ?? this.minLat,
      maxLon: maxLon ?? this.maxLon,
      maxLat: maxLat ?? this.maxLat,
      centerZoom: centerZoom ?? this.centerZoom,
      centerLon: centerLon ?? this.centerLon,
      centerLat: centerLat ?? this.centerLat,
    );
  }
}
