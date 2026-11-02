import 'dart:convert';

import '../../../core/database/app_database.dart';

/// Credit the map must show: the tiles are an OpenStreetMap-derived
/// Produced Work under the ODbL, built by Protomaps.
const mapAttribution = '© OpenStreetMap contributors · Protomaps';

/// Builds a MapLibre style (JSON) that draws every installed region from
/// its own archive on the phone. Each region is a `pmtiles://file://`
/// vector source; the Protomaps basemap [layers] are repeated per region
/// with the region's id in each layer id. Glyphs and the sprite are
/// `file://` paths under [assetsPath], where the bundled fonts and
/// sprites were copied, so nothing is fetched from anywhere.
String buildMapStyle({
  required List<MapRegion> regions,
  required String Function(MapRegion) pathFor,
  required String assetsPath,
  required List<dynamic> layers,
}) {
  final sources = <String, dynamic>{};
  final styled = <dynamic>[];
  var background = false;
  for (final region in regions) {
    final source = 'region-${region.id}';
    sources[source] = {
      'type': 'vector',
      'url': 'pmtiles://file://${pathFor(region)}',
      'attribution': mapAttribution,
    };
    for (final layer in layers.cast<Map<String, dynamic>>()) {
      if (layer['type'] == 'background') {
        if (!background) styled.add(layer);
        background = true;
        continue;
      }
      styled.add({
        ...layer,
        'id': '${layer['id']}-$source',
        if (layer.containsKey('source')) 'source': source,
      });
    }
  }
  return jsonEncode({
    'version': 8,
    'name': 'OFFGRID offline',
    'glyphs': 'file://$assetsPath/fonts/{fontstack}/{range}.pbf',
    'sprite': 'file://$assetsPath/sprites/dark',
    'sources': sources,
    'layers': styled,
  });
}
