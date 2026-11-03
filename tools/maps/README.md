# Offline maps

The Navigation tool draws Protomaps vector tiles (OpenStreetMap data)
from `.pmtiles` region files on the phone, with MapLibre. No tile server,
no network.

Regions are downloaded in the app (Settings → Offline maps → Download a
region): the phone cuts them out of the daily planet build by byte range,
the same thing `pmtiles extract` does. These tools are for the rest:

- `extract_region.sh` — cut a region on a computer, to sideload.
- `build_style.mjs` — regenerate the basemap style layers asset.
- Fonts and sprites: `assets/maps/` (see `build_style.mjs` for sources).
- `assets/maps/world.pmtiles` — the bundled world overview (zoom 0–5):
  `pmtiles extract https://build.protomaps.com/<YYYYMMDD>.pmtiles assets/maps/world.pmtiles --maxzoom=5`,
  then bump `mapAssetsVersion` in `lib/features/maps/map_providers.dart`.
- `test/fixtures/smokies_z10-12.pmtiles` — a CLI-made archive the PMTiles
  reader/writer tests check themselves against.

Licences: tiles ODbL (show "© OpenStreetMap contributors"), Protomaps
style and sprites BSD-3, Noto fonts OFL. See docs/decisions.md.
