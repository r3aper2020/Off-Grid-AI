#!/usr/bin/env bash
# Batch 5 (energy): content/20-home-energy (id home-energy) from DOE Energy Saver pages, plus one
# TC 21-305-20 chapter 12 extract (jump starting) added to content/11b-vehicles.
# Usage: tools/packs/recipes/batch5_energy.sh <source-dir>  (pages saved 2026-10-30 as <slug>.html;
#   extract with: python3 tools/packs/extract_html.py <src>/<slug>.html --container main -o content/20-home-energy/NN-<slug>.md
#   then add the Aliases: line; TC 21-305-20 pp. for chapter 12 via extract_pdf.py --pages, re-joining lines the
#   extractor split mid-sentence).
# LICENSE: DOE Energy Saver pages are U.S. Government works (17 U.S.C. § 105); three pages mention
#   "courtesy"/"permission" only in image credits, and no images are shipped. TC 21-305-20 is
#   approved for public release, distribution unlimited (already shipped in the vehicles pack).
# EXCLUDED: fireplaces, portable-heaters (duplicate of small-space-heaters), passive-solar-home-design
#   (older duplicate), off-grid-or-stand-alone (duplicate URL); ATP 6-02.53 radiotelephone procedure
#   (extraction done but not shipped in this batch — see decisions).
set -euo pipefail
D=content/20-home-energy
# file | url
# 01-insulation.md | https://www.energy.gov/energysaver/insulation
# 02-where-insulate-home.md | https://www.energy.gov/energysaver/where-insulate-home
# 03-types-insulation.md | https://www.energy.gov/energysaver/types-insulation
# 04-insulation-materials.md | https://www.energy.gov/energysaver/insulation-materials
# 05-air-sealing-your-home.md | https://www.energy.gov/energysaver/air-sealing-your-home
# 06-caulking.md | https://www.energy.gov/energysaver/caulking
# 07-weatherstripping.md | https://www.energy.gov/energysaver/weatherstripping
# 08-passive-solar-homes.md | https://www.energy.gov/energysaver/passive-solar-homes
# 09-home-heating-systems.md | https://www.energy.gov/energysaver/home-heating-systems
# 10-wood-and-pellet-heating.md | https://www.energy.gov/energysaver/wood-and-pellet-heating
# 11-small-space-heaters.md | https://www.energy.gov/energysaver/small-space-heaters
# 12-planning-home-solar-electric-system.md | https://www.energy.gov/energysaver/planning-home-solar-electric-system
# 13-grid-connected-renewable-energy-systems.md | https://www.energy.gov/energysaver/grid-connected-renewable-energy-systems
# 14-grid-or-stand-alone-renewable-energy-systems.md | https://www.energy.gov/energysaver/grid-or-stand-alone-renewable-energy-systems
# 15-balance-system-equipment-required-renewable-energy-systems.md | https://www.energy.gov/energysaver/balance-system-equipment-required-renewable-energy-systems
# 16-solar-water-heaters.md | https://www.energy.gov/energysaver/solar-water-heaters
# 17-small-wind-electric-systems.md | https://www.energy.gov/energysaver/small-wind-electric-systems
# 18-microhydropower-systems.md | https://www.energy.gov/energysaver/microhydropower-systems
for f in 01-insulation.md 02-where-insulate-home.md 03-types-insulation.md 04-insulation-materials.md 05-air-sealing-your-home.md 06-caulking.md 07-weatherstripping.md 08-passive-solar-homes.md 09-home-heating-systems.md 10-wood-and-pellet-heating.md 11-small-space-heaters.md 12-planning-home-solar-electric-system.md 13-grid-connected-renewable-energy-systems.md 14-grid-or-stand-alone-renewable-energy-systems.md 15-balance-system-equipment-required-renewable-energy-systems.md 16-solar-water-heaters.md 17-small-wind-electric-systems.md 18-microhydropower-systems.md; do [ -f "$D/$f" ] || { echo "missing $f"; exit 1; }; done
echo "home-energy: $(ls $D/*.md | wc -l) documents present"
# --- Added 2026-10-30, communications pack (version 2026.10.30.2):
#   30-radiotelephone.md  TC 3-21.75 (Aug 2013, "Approved for public release; distribution is unlimited"),
#     pages 204-207 only (Section II Radiotelephone Procedures; Section III COMSEC not taken):
#     tools/.venv/bin/python tools/packs/extract_pdf.py <src>/tc3-21-75.pdf --pages 204-207 --caps-headings --figures auto ...
#     Figure 11-1 (prowords table) shipped as an image. Only this radio section of the manual is used.
#   31-faa-phonetic-alphabet.md  FAA AIM Chapter 4 Section 2 (public domain), paragraphs 4-2-1, 4-2-2, 4-2-7, 4-2-8, 4-2-12;
#     the phonetic table re-joined one line per letter (letter — word (pronunciation) — Morse) and checked by eye.
