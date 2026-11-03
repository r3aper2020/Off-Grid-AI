/// A longitude/latitude box, as the map, region rows and archive headers
/// all use it.
class MapBounds {
  const MapBounds({
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });

  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  double get centerLon => (minLon + maxLon) / 2;
  double get centerLat => (minLat + maxLat) / 2;

  @override
  String toString() => 'MapBounds($minLon, $minLat, $maxLon, $maxLat)';
}
