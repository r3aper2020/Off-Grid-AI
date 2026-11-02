// Regenerates assets/maps/layers-dark.json: the Protomaps basemap layers
// (dark flavor, English labels) that lib/features/maps/domain/map_style.dart
// repeats per installed region. Run after upgrading @protomaps/basemaps
// (the tile schema and the style are versioned together):
//
//   cd tools/maps && npm install @protomaps/basemaps && node build_style.mjs
//
// Fonts and sprites come from https://github.com/protomaps/basemaps-assets
// (fonts: Noto, OFL; sprites: BSD-3). assets/maps/fonts holds the Latin
// glyph ranges (0–1023) of Noto Sans Regular/Medium/Italic; copy more
// ranges from that repository to label other scripts.
import { layers, namedFlavor } from '@protomaps/basemaps';
import { writeFileSync } from 'node:fs';

const out = layers('protomaps', namedFlavor('dark'), { lang: 'en' });
writeFileSync('../../assets/maps/layers-dark.json', JSON.stringify(out));
console.log(`wrote ${out.length} layers`);
