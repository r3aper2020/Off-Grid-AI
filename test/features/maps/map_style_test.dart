import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/domain/map_style.dart';

MapRegion region(int id) => MapRegion(
  id: id,
  displayName: 'r$id',
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
    {'id': 'water', 'type': 'fill', 'source': 'protomaps', 'source-layer': 'water'},
  ];

  test('one source and one copy of the layers per region, all local', () {
    final style = jsonDecode(
      buildMapStyle(
        regions: [region(1), region(2)],
        pathFor: (r) => '/maps/${r.fileName}',
        assetsPath: '/maps/assets',
        layers: layers,
      ),
    ) as Map<String, dynamic>;
    final sources = style['sources'] as Map<String, dynamic>;
    expect(sources.keys, ['region-1', 'region-2']);
    expect(sources['region-1']['url'], 'pmtiles://file:///maps/r1.pmtiles');
    expect(sources['region-1']['attribution'], mapAttribution);
    final ids = (style['layers'] as List).map((l) => l['id']).toList();
    expect(ids, ['background', 'water-region-1', 'water-region-2']);
    expect((style['layers'] as List)[2]['source'], 'region-2');
    expect(style['glyphs'], 'file:///maps/assets/fonts/{fontstack}/{range}.pbf');
    expect(style['sprite'], 'file:///maps/assets/sprites/dark');
    expect(jsonEncode(style), isNot(contains('http')));
  });
}
