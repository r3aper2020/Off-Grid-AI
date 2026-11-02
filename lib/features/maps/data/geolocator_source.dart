import 'package:geolocator/geolocator.dart';

import '../domain/location_source.dart';

/// GPS through the geolocator plugin. Permission is requested only when
/// the navigation screen asks, never at startup.
class GeolocatorSource implements LocationSource {
  const GeolocatorSource();

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.servicesOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationAccess.denied,
    };
  }

  @override
  Stream<Fix> fixes() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).map(
      (p) => Fix(
        latitude: p.latitude,
        longitude: p.longitude,
        altitude: p.altitude,
        accuracy: p.accuracy,
        heading: p.heading < 0 ? null : p.heading,
        speed: p.speed < 0 ? null : p.speed,
        time: p.timestamp,
      ),
    );
  }
}
