#!/usr/bin/env bash
# Make an offline map region for OFFGRID AI from the Protomaps daily
# planet build (OpenStreetMap data, ODbL).
#
#   tools/maps/extract_region.sh <name> <minLon> <minLat> <maxLon> <maxLat> [maxzoom]
#
# Example (Great Smoky Mountains, 7 MB at zoom 14):
#   tools/maps/extract_region.sh smokies -83.95 35.40 -83.00 35.80
#
# Needs the pmtiles CLI:  brew install pmtiles
# Output: build/maps/<name>.pmtiles. Copy it to the phone (USB, AirDrop,
# cloud drive) and import it under Settings → Offline maps.
#
# Size guide: zoom 14 shows streets and trails; each extra zoom level
# roughly doubles the file. A US state at zoom 14 is a few hundred MB.
set -euo pipefail

if [ $# -lt 5 ]; then
  sed -n 2,16p "$0"; exit 1
fi
name=$1; minlon=$2; minlat=$3; maxlon=$4; maxlat=$5; maxzoom=${6:-14}
command -v pmtiles >/dev/null || { echo "pmtiles CLI not found: brew install pmtiles" >&2; exit 1; }

# The newest build that exists (they are published daily, with gaps).
build=""
for i in 0 1 2 3 4 5 6 7; do
  d=$(date -v-"${i}"d +%Y%m%d 2>/dev/null || date -d "-${i} day" +%Y%m%d)
  if curl -sfI "https://build.protomaps.com/$d.pmtiles" >/dev/null; then build=$d; break; fi
done
[ -n "$build" ] || { echo "No Protomaps build found in the last week" >&2; exit 1; }

mkdir -p build/maps
out="build/maps/$name.pmtiles"
echo "Extracting $name from build $build at zoom <= $maxzoom …"
pmtiles extract "https://build.protomaps.com/$build.pmtiles" "$out" \
  --bbox="$minlon,$minlat,$maxlon,$maxlat" --maxzoom="$maxzoom"
ls -lh "$out"
echo "Done. Import $out on the phone under Settings → Offline maps."
