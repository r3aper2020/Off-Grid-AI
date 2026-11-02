/// Why a position may not be available.
enum LocationAccess { granted, denied, deniedForever, servicesOff }

/// One GPS fix. Units: degrees, metres, metres per second, degrees
/// clockwise from north; [heading] is the direction of travel and is
/// only meaningful when moving.
class Fix {
  const Fix({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.time,
  });

  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime time;
}

/// Where positions come from. The app talks to this, never to a plugin,
/// so screens can be tested with a fake.
abstract class LocationSource {
  /// Asks for permission (and checks location services) once.
  Future<LocationAccess> request();

  /// Continuous fixes; only subscribe after [request] granted.
  Stream<Fix> fixes();
}

/// For tests and for platforms without location: never grants.
class NoLocationSource implements LocationSource {
  const NoLocationSource([this.access = LocationAccess.servicesOff]);
  final LocationAccess access;
  @override
  Future<LocationAccess> request() async => access;
  @override
  Stream<Fix> fixes() => const Stream.empty();
}
