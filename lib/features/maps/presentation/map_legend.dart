import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';

/// How a legend swatch is drawn.
enum LegendSwatch { line, thickLine, dashedLine, dottedLine, fill, dot }

class LegendEntry {
  const LegendEntry(this.label, this.color, this.swatch, {this.note});
  final String label;
  final Color color;
  final LegendSwatch swatch;
  final String? note;
}

/// What the current basemap's marks mean, plus how to read it.
class MapLegend {
  const MapLegend({
    required this.title,
    required this.paper,
    required this.entries,
    this.tips = const [],
  });

  final String title;

  /// Background the swatches sit on: the map's own ground colour.
  final Color paper;
  final List<LegendEntry> entries;
  final List<String> tips;
}

/// The Streets legend, with colours read from the style layers so it
/// always matches what the map draws.
MapLegend streetsLegend(List<dynamic> layers) {
  final byId = {
    for (final l in layers.cast<Map<String, dynamic>>()) l['id'] as String: l,
  };
  Color paint(String id, String key, Color fallback) {
    final v = byId[id]?['paint']?[key];
    return styleColor(v) ?? fallback;
  }

  final earth = paint('earth', 'fill-color', AppColors.background);
  return MapLegend(
    title: 'Streets',
    paper: earth,
    entries: [
      LegendEntry(
        'Highway',
        paint('roads_highway', 'line-color', AppColors.textTertiary),
        LegendSwatch.thickLine,
      ),
      LegendEntry(
        'Main road',
        paint('roads_major', 'line-color', AppColors.textTertiary),
        LegendSwatch.line,
      ),
      LegendEntry(
        'Street',
        paint('roads_minor', 'line-color', AppColors.textTertiary),
        LegendSwatch.line,
      ),
      LegendEntry(
        'Path or trail',
        paint('roads_other', 'line-color', AppColors.textTertiary),
        LegendSwatch.line,
        note: 'thin',
      ),
      LegendEntry(
        'Railway',
        paint('roads_rail', 'line-color', AppColors.textPrimary),
        LegendSwatch.dottedLine,
      ),
      LegendEntry(
        'River or stream',
        paint('water_stream', 'line-color', AppColors.textTertiary),
        LegendSwatch.line,
      ),
      LegendEntry(
        'Water',
        paint('water', 'fill-color', AppColors.textTertiary),
        LegendSwatch.fill,
      ),
      LegendEntry(
        'Park, forest, protected land',
        paint('landuse_park', 'fill-color', AppColors.accentMuted),
        LegendSwatch.fill,
      ),
      LegendEntry(
        'Buildings',
        paint('buildings', 'fill-color', AppColors.background),
        LegendSwatch.fill,
      ),
      LegendEntry(
        'Boundary',
        paint('boundaries', 'line-color', AppColors.textTertiary),
        LegendSwatch.dashedLine,
      ),
      LegendEntry(
        'Peaks, parks, forests',
        paint('pois', 'text-color', AppColors.accent),
        LegendSwatch.dot,
        note: 'green labels',
      ),
      const LegendEntry('You', AppColors.accent, LegendSwatch.dot),
    ],
  );
}

/// The USGS Topo legend: the conventions US Topo maps use.
const topoLegend = MapLegend(
  title: 'Topo (USGS)',
  paper: AppColors.usgsPaper,
  entries: [
    LegendEntry(
      'Contour line',
      AppColors.usgsContour,
      LegendSwatch.line,
      note: 'same elevation all along it',
    ),
    LegendEntry(
      'Index contour',
      AppColors.usgsIndexContour,
      LegendSwatch.thickLine,
      note: 'every 5th line, labelled in feet',
    ),
    LegendEntry(
      'Stream, lake, river',
      AppColors.usgsWater,
      LegendSwatch.line,
      note: 'dashed = dry part of the year',
    ),
    LegendEntry('Woodland', AppColors.usgsWoodland, LegendSwatch.fill),
    LegendEntry('Highway', AppColors.usgsHighway, LegendSwatch.thickLine),
    LegendEntry('Road', AppColors.usgsRoad, LegendSwatch.line),
    LegendEntry('Trail', AppColors.usgsTrail, LegendSwatch.dashedLine),
    LegendEntry('Building', AppColors.usgsBuilding, LegendSwatch.fill),
    LegendEntry(
      'Boundary',
      AppColors.usgsBoundary,
      LegendSwatch.dashedLine,
      note: 'state, county, park',
    ),
    LegendEntry('Shaded relief', AppColors.usgsRelief, LegendSwatch.fill),
    LegendEntry('You', AppColors.accent, LegendSwatch.dot),
  ],
  tips: [
    'Lines close together mean steep ground; far apart means flat.',
    'Where contours cross a stream they bend into a V that points uphill, '
        'upstream.',
    'Closed rings are a hilltop; rings with tick marks inside are a hollow.',
  ],
);

const imageryLegend = MapLegend(
  title: 'Satellite (USGS)',
  paper: AppColors.surfaceRaised,
  entries: [
    LegendEntry(
      'Street and place names',
      AppColors.textPrimary,
      LegendSwatch.dot,
      note: 'from the streets map, on top',
    ),
    LegendEntry('You', AppColors.accent, LegendSwatch.dot),
  ],
  tips: ['Imagery is a few years old; treat buildings and roads as a guide.'],
);

MapLegend legendFor(MapLayerKind basemap, List<dynamic> layers) =>
    switch (basemap) {
      MapLayerKind.topo => topoLegend,
      MapLayerKind.imagery => imageryLegend,
      _ => streetsLegend(layers),
    };

/// A colour from a style paint value: a `#rrggbb`/`#rgb` string, an
/// `rgba(r, g, b, a)` string, or the first such string inside an
/// expression. Null when there is none.
Color? styleColor(dynamic v) {
  if (v is String) {
    if (v.startsWith('#')) {
      var hex = v.substring(1);
      if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
      if (hex.length == 6) hex = 'ff$hex';
      final n = int.tryParse(hex, radix: 16);
      return n == null ? null : Color(n);
    }
    final m = RegExp(
      r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)',
    ).firstMatch(v);
    if (m != null) {
      final a = m[4] == null ? 1.0 : double.parse(m[4]!);
      return Color.fromARGB(
        (a * 255).round(),
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
    }
    return null;
  }
  if (v is List) {
    for (final x in v) {
      final c = styleColor(x);
      if (c != null) return c;
    }
  }
  return null;
}

/// The legend panel over the map.
class MapLegendPanel extends StatelessWidget {
  const MapLegendPanel({
    super.key,
    required this.legend,
    required this.onClose,
  });
  final MapLegend legend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 236,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.42,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${legend.title} legend',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Hide legend',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textTertiary,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                for (final e in legend.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Swatch(entry: e, paper: legend.paper),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.label, style: theme.textTheme.bodySmall),
                              if (e.note != null)
                                Text(
                                  e.note!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final tip in legend.tips)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '• $tip',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.entry, required this.paper});
  final LegendEntry entry;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 18,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(painter: _SwatchPainter(entry)),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.entry);
  final LegendEntry entry;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = entry.color;
    final y = size.height / 2;
    switch (entry.swatch) {
      case LegendSwatch.fill:
        canvas.drawRect(
          Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
          paint,
        );
      case LegendSwatch.dot:
        canvas.drawCircle(Offset(size.width / 2, y), 4, paint);
      case LegendSwatch.line:
      case LegendSwatch.thickLine:
        paint
          ..strokeWidth = entry.swatch == LegendSwatch.thickLine ? 4 : 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
      case LegendSwatch.dashedLine:
      case LegendSwatch.dottedLine:
        final dash = entry.swatch == LegendSwatch.dashedLine ? 6.0 : 2.0;
        paint
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var x = 4.0; x < size.width - 4; x += dash * 2) {
          canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        }
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.entry != entry;
}
