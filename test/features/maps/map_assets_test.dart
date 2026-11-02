import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/maps/map_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled fonts, sprites and layers are copied beside the regions',
      () async {
    final dir = await Directory.systemTemp.createTemp('map_assets');
    addTearDown(() => dir.delete(recursive: true));
    final c = ProviderContainer(
      overrides: [mapsDirectoryProvider.overrideWithValue(dir)],
    );
    addTearDown(c.dispose);

    final assets = await c.read(mapAssetsProvider.future);
    expect(assets.path, '${dir.path}/assets');
    for (final font in ['Noto Sans Regular', 'Noto Sans Medium', 'Noto Sans Italic']) {
      for (final range in ['0-255', '256-511', '512-767', '768-1023']) {
        expect(File('${assets.path}/fonts/$font/$range.pbf').existsSync(), isTrue,
            reason: '$font $range');
      }
    }
    expect(File('${assets.path}/sprites/dark.json').existsSync(), isTrue);
    expect(File('${assets.path}/sprites/dark@2x.png').existsSync(), isTrue);
    expect(File('${assets.path}/.v$mapAssetsVersion').existsSync(), isTrue);

    final layers = await c.read(mapLayersProvider.future);
    expect(layers.length, greaterThan(50));
    final fonts = jsonEncode(layers);
    expect(fonts, contains('Noto Sans Regular'));
    // Every layer the style builder repeats names the one source it
    // expects.
    for (final l in layers.cast<Map<String, dynamic>>()) {
      if (l['type'] != 'background') expect(l['source'], 'protomaps');
    }
  });
}
