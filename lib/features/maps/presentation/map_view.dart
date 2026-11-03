import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../domain/map_bounds.dart';

/// What screens may do to a live map. Wraps the MapLibre controller so
/// screens (and their tests) never touch it directly.
abstract class MapHandle {
  Future<void> zoomIn();
  Future<void> zoomOut();
  Future<void> moveTo(double lat, double lon, double zoom);
  Future<void> setFollowHeading(bool on);

  /// The puck's position, when the map has one.
  Future<(double lat, double lon)?> myLocation();

  /// The box the map currently shows.
  Future<MapBounds> visibleBounds();
}

class MapLibreHandle implements MapHandle {
  MapLibreHandle(this._c);
  final MapLibreMapController _c;

  @override
  Future<void> zoomIn() => _c.animateCamera(CameraUpdate.zoomIn());
  @override
  Future<void> zoomOut() => _c.animateCamera(CameraUpdate.zoomOut());
  @override
  Future<void> moveTo(double lat, double lon, double zoom) =>
      _c.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), zoom));
  @override
  Future<void> setFollowHeading(bool on) => _c.updateMyLocationTrackingMode(
    on ? MyLocationTrackingMode.trackingCompass : MyLocationTrackingMode.none,
  );
  @override
  Future<(double, double)?> myLocation() async {
    final p = await _c.requestMyLocationLatLng();
    return p == null ? null : (p.latitude, p.longitude);
  }

  @override
  Future<MapBounds> visibleBounds() async {
    final b = await _c.getVisibleRegion();
    return MapBounds(
      minLon: b.southwest.longitude,
      minLat: b.southwest.latitude,
      maxLon: b.northeast.longitude,
      maxLat: b.northeast.latitude,
    );
  }
}

/// What a screen asks of the map widget. Kept apart from the MapLibre
/// types so screens can be tested with a stand-in.
class MapViewSpec {
  const MapViewSpec({
    required this.style,
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.locationEnabled,
    required this.followHeading,
    required this.onMapCreated,
    required this.onHeading,
    required this.onFollowDismissed,
    this.onCameraIdle,
  });

  final String style;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final bool locationEnabled;
  final bool followHeading;
  final void Function(MapHandle map) onMapCreated;

  /// Compass heading from the map's location puck, degrees from north.
  final void Function(double? heading) onHeading;
  final VoidCallback onFollowDismissed;

  /// The user stopped panning or zooming.
  final VoidCallback? onCameraIdle;
}

typedef MapViewBuilder = Widget Function(MapViewSpec spec);

/// Builds the live MapLibre map; tests override it with a placeholder.
final mapViewBuilderProvider = Provider<MapViewBuilder>(
  (_) => buildMapLibreView,
);

Widget buildMapLibreView(MapViewSpec spec) {
  return MapLibreMap(
    styleString: spec.style,
    initialCameraPosition: CameraPosition(
      target: LatLng(spec.centerLat, spec.centerLon),
      zoom: spec.zoom,
    ),
    myLocationEnabled: spec.locationEnabled,
    myLocationTrackingMode: spec.followHeading
        ? MyLocationTrackingMode.trackingCompass
        : MyLocationTrackingMode.none,
    myLocationRenderMode: spec.locationEnabled
        ? MyLocationRenderMode.compass
        : MyLocationRenderMode.normal,
    trackCameraPosition: true,
    compassEnabled: true,
    logoEnabled: false,
    attributionButtonPosition: AttributionButtonPosition.topRight,
    attributionButtonMargins: const Point(12, 72),
    onMapCreated: (c) => spec.onMapCreated(MapLibreHandle(c)),
    onUserLocationUpdated: (loc) {
      final h = loc.heading;
      spec.onHeading(h?.trueHeading ?? h?.magneticHeading);
    },
    onCameraTrackingDismissed: spec.onFollowDismissed,
    onCameraIdle: spec.onCameraIdle,
  );
}
