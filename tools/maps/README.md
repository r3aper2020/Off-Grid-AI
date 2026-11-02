# Offline maps

The Navigation tool draws Protomaps vector tiles (OpenStreetMap data)
from `.pmtiles` region files on the phone, with MapLibre. No tile server,
no network.

- `extract_region.sh` — cut a region out of the daily planet build.
- `build_style.mjs` — regenerate the basemap style layers asset.
- Fonts and sprites: `assets/maps/` (see `build_style.mjs` for sources).

Licences: tiles ODbL (show "© OpenStreetMap contributors"), Protomaps
style and sprites BSD-3, Noto fonts OFL. See docs/decisions.md.
