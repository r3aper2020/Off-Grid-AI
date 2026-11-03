import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/theme/app_colors.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/presentation/map_legend.dart';

void main() {
  test('style colours parse from strings and expressions', () {
    expect(styleColor('#474747'), const Color(0xFF474747));
    expect(styleColor('#abc'), const Color(0xFFAABBCC));
    expect(styleColor('rgba(30, 41, 31, 1)'), const Color(0xFF1E291F));
    expect(styleColor('rgb(1, 2, 3)'), const Color(0xFF010203));
    expect(
      styleColor([
        'interpolate',
        ['exponential', 1.6],
        ['zoom'],
        11,
        '#3d3d3d',
        16,
        '#333333',
      ]),
      const Color(0xFF3D3D3D),
    );
    expect(styleColor(null), isNull);
    expect(styleColor('red'), isNull);
  });

  test('the streets legend takes its colours from the style layers', () {
    const layers = [
      {
        'id': 'earth',
        'type': 'fill',
        'paint': {'fill-color': '#1f1f1f'},
      },
      {
        'id': 'roads_highway',
        'type': 'line',
        'paint': {'line-color': '#474747'},
      },
      {
        'id': 'roads_minor',
        'type': 'line',
        'paint': {
          'line-color': [
            'interpolate',
            ['exponential', 1.6],
            ['zoom'],
            11,
            '#3d3d3d',
          ],
        },
      },
    ];
    final legend = streetsLegend(layers);
    expect(legend.paper, const Color(0xFF1F1F1F));
    expect(legend.entries.first.label, 'Highway');
    expect(legend.entries.first.color, const Color(0xFF474747));
    expect(legend.entries[2].color, const Color(0xFF3D3D3D));
    // Missing layers fall back to a palette colour rather than crashing.
    expect(legend.entries.last.color, AppColors.accent);
    expect(legendFor(MapLayerKind.topo, layers).title, 'Topo (USGS)');
    expect(legendFor(MapLayerKind.topo, layers).tips, hasLength(3));
    expect(legendFor(MapLayerKind.imagery, layers).entries, hasLength(2));
  });
}
