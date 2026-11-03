import 'dart:convert';

import '../../../core/database/app_database.dart';

/// Credit the map must show: the tiles are an OpenStreetMap-derived
/// Produced Work under the ODbL, built by Protomaps.
const mapAttribution = '© OpenStreetMap contributors · Protomaps';

/// Which raster layer kinds the installed rows provide.
Set<MapLayerKind> availableLayerKinds(List<MapRegion> regions) => {
  for (final r in regions)
    if (r.kind != MapLayerKind.streets) r.kind,
};

/// Builds a MapLibre style (JSON) that draws the bundled world overview
/// at [worldPath] and every installed region from its own archive on
/// the phone. Each is a `pmtiles://file://` source; the Protomaps
/// basemap [layers] are repeated per vector source, regions after the
/// world so they draw on top. With [basemap] topo or imagery, a region
/// that has that raster layer shows it instead of its streets (imagery
/// keeps the street labels on top); [hillshade] draws a region's
/// elevation layer under its lines and labels. Glyphs and the sprite
/// are `file://` paths under [assetsPath], where the bundled fonts and
/// sprites were copied, so nothing is fetched from anywhere.
String buildMapStyle({
  required List<MapRegion> regions,
  required String Function(MapRegion) pathFor,
  required String worldPath,
  required String assetsPath,
  required List<dynamic> layers,
  MapLayerKind basemap = MapLayerKind.streets,
  bool hillshade = false,
}) {
  final sources = <String, dynamic>{};
  final styled = <dynamic>[];
  var background = false;
  final typed = layers.cast<Map<String, dynamic>>();

  void addVectorSource(String source, String path) {
    sources[source] = {
      'type': 'vector',
      'url': 'pmtiles://file://$path',
      'attribution': mapAttribution,
    };
  }

  Map<String, dynamic> restyle(Map<String, dynamic> layer, String source) => {
    ...layer,
    'id': '${layer['id']}-$source',
    if (layer.containsKey('source')) 'source': source,
  };

  /// The basemap layers for one vector source; [under] (a hillshade) goes
  /// in above the fills and below lines and labels.
  void addVectorLayers(
    String source, {
    bool labelsOnly = false,
    Map<String, dynamic>? under,
  }) {
    var placed = under == null;
    for (final layer in typed) {
      if (layer['type'] == 'background') {
        if (!background) styled.add(layer);
        background = true;
        continue;
      }
      if (labelsOnly && layer['type'] != 'symbol') continue;
      if (!placed && layer['type'] != 'fill') {
        styled.add(under);
        placed = true;
      }
      styled.add(restyle(layer, source));
    }
    if (!placed) styled.add(under);
  }

  Map<String, dynamic> rasterSource(MapRegion r, {String? attribution}) => {
    'type': r.kind == MapLayerKind.terrain ? 'raster-dem' : 'raster',
    'url': 'pmtiles://file://${pathFor(r)}',
    'tileSize': 256,
    if (r.kind == MapLayerKind.terrain) 'encoding': 'terrarium',
    'attribution': ?attribution,
  };

  addVectorSource('world', worldPath);
  addVectorLayers('world');

  final children = <int, Map<MapLayerKind, MapRegion>>{};
  for (final r in regions) {
    final parent = r.parentId;
    if (parent != null) (children[parent] ??= {})[r.kind] = r;
  }
  for (final region in regions) {
    if (region.kind != MapLayerKind.streets) continue;
    final source = 'region-${region.id}';
    addVectorSource(source, pathFor(region));
    final mine = children[region.id] ?? const {};

    Map<String, dynamic>? shade;
    final terrain = mine[MapLayerKind.terrain];
    if (hillshade && terrain != null) {
      final dem = 'layer-${terrain.id}';
      sources[dem] = rasterSource(terrain);
      shade = {
        'id': 'hillshade-$dem',
        'type': 'hillshade',
        'source': dem,
        'paint': {
          'hillshade-exaggeration': 0.55,
          'hillshade-shadow-color': '#000000',
          'hillshade-highlight-color': '#ffffff',
          'hillshade-accent-color': '#000000',
        },
      };
    }

    final raster = basemap == MapLayerKind.streets ? null : mine[basemap];
    if (raster == null) {
      addVectorLayers(source, under: shade);
      continue;
    }
    final img = 'layer-${raster.id}';
    sources[img] = rasterSource(raster, attribution: 'USGS The National Map');
    styled.add({'id': 'raster-$img', 'type': 'raster', 'source': img});
    if (shade != null) styled.add(shade);
    if (basemap == MapLayerKind.imagery) {
      addVectorLayers(source, labelsOnly: true);
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
