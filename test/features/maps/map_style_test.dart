import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/domain/map_style.dart';

MapRegion region(
  int id, {
  MapLayerKind kind = MapLayerKind.streets,
  int? parentId,
}) => MapRegion(
  id: id,
  displayName: 'r$id',
  kind: kind,
  parentId: parentId,
  fileName: 'r$id.pmtiles',
  sizeBytes: 1,
  minLon: -1,
  minLat: -1,
  maxLon: 1,
  maxLat: 1,
  minZoom: 0,
  maxZoom: 14,
  installedAt: DateTime(2026),
);

void main() {
  const layers = [
    {'id': 'background', 'type': 'background', 'paint': {}},
    {
      'id': 'water',
      'type': 'fill',
      'source': 'protomaps',
      'source-layer': 'water',
    },
    {
      'id': 'roads',
      'type': 'line',
      'source': 'protomaps',
      'source-layer': 'roads',
    },
    {
      'id': 'places',
      'type': 'symbol',
      'source': 'protomaps',
      'source-layer': 'places',
    },
  ];

  Map<String, dynamic> build(
    List<MapRegion> regions, {
    MapLayerKind basemap = MapLayerKind.streets,
    bool hillshade = false,
  }) => jsonDecode(
    buildMapStyle(
      regions: regions,
      pathFor: (r) => '/maps/${r.fileName}',
      worldPath: '/maps/assets/world.pmtiles',
      assetsPath: '/maps/assets',
      layers: layers,
      basemap: basemap,
      hillshade: hillshade,
    ),
  ) as Map<String, dynamic>;

  List<String> ids(Map<String, dynamic> style) =>
      (style['layers'] as List).map((l) => l['id'] as String).toList();

  test('the world first, then one source and layer copy per region', () {
    final style = build([region(1), region(2)]);
    final sources = style['sources'] as Map<String, dynamic>;
    expect(sources.keys, ['world', 'region-1', 'region-2']);
    expect(
      sources['world']['url'],
      'pmtiles://file:///maps/assets/world.pmtiles',
    );
    expect(sources['region-1']['url'], 'pmtiles://file:///maps/r1.pmtiles');
    expect(sources['region-1']['attribution'], mapAttribution);
    expect(ids(style), [
      'background',
      'water-world',
      'roads-world',
      'places-world',
      'water-region-1',
      'roads-region-1',
      'places-region-1',
      'water-region-2',
      'roads-region-2',
      'places-region-2',
    ]);
    expect((style['layers'] as List)[4]['source'], 'region-1');
    expect(
      style['glyphs'],
      'file:///maps/assets/fonts/{fontstack}/{range}.pbf',
    );
    expect(style['sprite'], 'file:///maps/assets/sprites/dark');
    expect(jsonEncode(style), isNot(contains('http')));
  });

  test('raster layers are ignored in streets mode without hillshade', () {
    final rows = [
      region(1),
      region(2, kind: MapLayerKind.topo, parentId: 1),
      region(3, kind: MapLayerKind.terrain, parentId: 1),
    ];
    final style = build(rows);
    expect((style['sources'] as Map).keys, ['world', 'region-1']);
    expect(availableLayerKinds(rows), {
      MapLayerKind.topo,
      MapLayerKind.terrain,
    });
  });

  test('topo mode draws the raster instead of the region streets', () {
    final style = build([
      region(1),
      region(2, kind: MapLayerKind.topo, parentId: 1),
      region(4),
    ], basemap: MapLayerKind.topo);
    final sources = style['sources'] as Map<String, dynamic>;
    expect(sources['layer-2'], {
      'type': 'raster',
      'url': 'pmtiles://file:///maps/r2.pmtiles',
      'tileSize': 256,
      'attribution': 'USGS The National Map',
    });
    expect(ids(style), [
      'background',
      'water-world', 'roads-world', 'places-world',
      'raster-layer-2',
      // Region 4 has no topo layer: its streets still draw.
      'water-region-4', 'roads-region-4', 'places-region-4',
    ]);
  });

  test('imagery keeps the labels on top; hillshade sits above the fills', () {
    final rows = [
      region(1),
      region(2, kind: MapLayerKind.imagery, parentId: 1),
      region(3, kind: MapLayerKind.terrain, parentId: 1),
    ];
    final imagery = build(rows, basemap: MapLayerKind.imagery, hillshade: true);
    expect(ids(imagery).sublist(4), [
      'raster-layer-2',
      'hillshade-layer-3',
      'places-region-1',
    ]);
    final dem = (imagery['sources'] as Map)['layer-3'] as Map;
    expect(dem['type'], 'raster-dem');
    expect(dem['encoding'], 'terrarium');

    final streets = build(rows, hillshade: true);
    expect(ids(streets).sublist(4), [
      'water-region-1',
      'hillshade-layer-3',
      'roads-region-1',
      'places-region-1',
    ]);
    final shade = (streets['layers'] as List)[5] as Map;
    expect(shade['type'], 'hillshade');
    expect(shade['source'], 'layer-3');
  });
}
