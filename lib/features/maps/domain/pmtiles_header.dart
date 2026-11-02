import 'dart:typed_data';

/// The fixed 127-byte header at the start of a PMTiles v3 archive
/// (https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md).
/// Only the fields the app needs are kept: the zoom range, bounds and
/// center, and the tile type.
class PmtilesHeader {
  const PmtilesHeader({
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
    double e7(int offset) => d.getInt32(offset, Endian.little) / 1e7;
    return PmtilesHeader(
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
}
