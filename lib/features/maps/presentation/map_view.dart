import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// What the navigation screen asks of the map widget. Kept apart from
/// the MapLibre types so the screen can be tested with a stand-in.
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
  });

  final String style;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final bool locationEnabled;
  final bool followHeading;
  final void Function(MapLibreMapController controller) onMapCreated;

  /// Compass heading from the map's location puck, degrees from north.
  final void Function(double? heading) onHeading;
  final VoidCallback onFollowDismissed;
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
    onMapCreated: spec.onMapCreated,
    onUserLocationUpdated: (loc) {
      final h = loc.heading;
      spec.onHeading(h?.trueHeading ?? h?.magneticHeading);
    },
    onCameraTrackingDismissed: spec.onFollowDismissed,
  );
}
