#!/usr/bin/env bash
# Rebuilds the PDF-derived library documents from official sources.
# Usage: tools/packs/recipes/batch1_pdfs.sh <dir-with-downloaded-sources>
#
# Each source's official URL, release status and page selection is recorded
# here so the library can be audited and regenerated. Download the files
# listed in SOURCES (below) into the given directory first.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir>}"
PY=tools/.venv/bin/python
X="$PY tools/packs/extract_pdf.py --figures auto"

# --- SOURCES (official URLs; all U.S. Government works) -------------------
AP=https://armypubs.army.mil/epubs/DR_pubs/DR_a/pdf/web
ATP_URL="$AP/ARN12086_ATP%203-50x21%20FINAL%20WEB%202.pdf"   # Dist A, 2018
TC_HYG_URL="$AP/tc4_02x3.pdf"                                # Dist A, 2015
FM_NAV_URL="https://archive.org/download/MManuals/Fm3-25.26MapReadingAndLandNavigation.pdf"  # Dist A, 2001 (superseded)
NWSS_URL="https://www.osti.gov/servlets/purl/5866926"        # ORNL-5037, 1979
CAN=https://nchfp.uga.edu/papers/guide                       # USDA AIB 539, 2015
AYR_URL="https://www.ready.gov/sites/default/files/2021-11/are-you-ready-guide.pdf"

# --- 16 Wilderness & Environmental Survival: ATP 3-50.21 ------------------
D=content/16-wilderness-survival; mkdir -p $D
atp() { $X "$SRC/atp3-50-21.pdf" --pages "$1" --source-url "$ATP_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
atp 13-18   "Survival Overview and Psychology (ATP 3-50.21 Ch. 1)" 01-overview
atp 19-54   "Survival Medicine (ATP 3-50.21 Ch. 2)" 02-medicine
atp 55-70   "Finding and Purifying Water (ATP 3-50.21 Ch. 3)" 03-water
atp 71-116  "Food: Plants, Trapping, Fishing and Cooking (ATP 3-50.21 Ch. 4)" 04-food
atp 117-134 "Fire (ATP 3-50.21 Ch. 5)" 05-fire
atp 135-152 "Shelter and Clothing (ATP 3-50.21 Ch. 6)" 06-shelter
atp 153-180 "Movement and Navigation (ATP 3-50.21 Ch. 7)" 07-navigation
atp 181-194 "Survival Equipment and Tools (ATP 3-50.21 Ch. 8)" 08-equipment
atp 195-220 "Knots, Rope and Lashing (ATP 3-50.21 App. A)" 09-knots

# --- 04 Water & Sanitation: TC 4-02.3 Field Hygiene and Sanitation ---------
D=content/04-water-sanitation
$X "$SRC/tc4-02-3.pdf" --pages 7-22 --source-url "$TC_HYG_URL" --bold-headings \
  --title "Field Hygiene: Disease Prevention, Waste and Heat/Cold Injury (TC 4-02.3)" -o $D/04-field-hygiene.md
# App. A (pages 33-40, field water disinfection) is held back: its dosing
# tables lose their layout in text extraction. Same fix as the canning guide.

# --- 12 Navigation & Geography: FM 3-25.26 (2001; superseded) -------------
D=content/12-navigation; mkdir -p $D
nav() { $X "$SRC/fm3-25-26.pdf" --pages "$1" --source-url "$FM_NAV_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Page ranges follow the manual's own CHAPTER/APPENDIX headings. Skipped:
# Ch. 1 (training strategy), 7 (overlays), 8 (aerial photos), 12 (mounted
# navigation), 14 (unit sustainment), and military-specific appendices.
nav 9-16    "Maps: Care, Types and Use (FM 3-25.26 Ch. 2)" 01-maps
nav 17-49   "Map Symbols, Grids and Coordinates (FM 3-25.26 Ch. 3–4)" 02-grids
nav 50-63   "Scale and Distance (FM 3-25.26 Ch. 5)" 03-distance
nav 64-83   "Direction and Azimuths (FM 3-25.26 Ch. 6)" 04-direction
nav 110-122 "Compasses and Navigation Methods (FM 3-25.26 Ch. 9)" 05-compass
nav 123-146 "Elevation and Relief (FM 3-25.26 Ch. 10)" 06-relief
nav 147-164 "Terrain Association (FM 3-25.26 Ch. 11)" 07-terrain
nav 173-183 "Navigating Desert, Mountain, Jungle and Arctic Terrain (FM 3-25.26 Ch. 13)" 08-terrain-types
nav 196-216 "Orienteering (FM 3-25.26 App. F)" 09-orienteering

# --- 15 Chemical, Biological & Radiological: Nuclear War Survival Skills ----
D=content/15-cbrn; mkdir -p $D
# Scanned book: figure/table detection is unreliable on page images (it
# clipped ration-table labels), so no images — tables stay as text marked
# "layout not preserved".
nw() { $PY tools/packs/extract_pdf.py "$SRC/nwss1979.pdf" --pages "$1" --source-url "$NWSS_URL" --title "$2" -o "$D/$3.md" --caps-headings; }
nw 20-27   "Nuclear Weapon Dangers: Myths and Facts (NWSS Ch. 1)" 01-dangers
nw 28-43   "Psychology, Warnings and Evacuation (NWSS Ch. 2–4)" 02-warning-evacuation
nw 44-63   "Fallout Shelter, Ventilation and Cooling (NWSS Ch. 5–6)" 03-shelter
nw 64-79   "Fires, Carbon Monoxide and Water (NWSS Ch. 7–8)" 04-fire-water
nw 80-97   "Food (NWSS Ch. 9)" 05-food
nw 98-111  "Fallout Meters and Light (NWSS Ch. 10–11)" 06-meters-light
nw 112-119 "Sanitation and Surviving Without Doctors (NWSS Ch. 12–13)" 07-medical
nw 120-137 "Shelter Furnishings, Clothing and Preparations (NWSS Ch. 14–16)" 08-preparations
nw 138-179 "Six Expedient Fallout Shelters (NWSS App. A)" 09-expedient-shelters
nw 180-199 "Homemade Shelter-Ventilating Pump (NWSS App. B)" 10-ventilation-pump
nw 200-226 "Homemade Fallout Meter, the KFM (NWSS App. C)" 11-fallout-meter
nw 227-245 "Expedient Blast Shelters (NWSS App. D)" 12-blast-shelters

# --- HELD BACK (again): 08 Home Canning, USDA Complete Guide (2015) -------
# Table images work (Guide 3 verified by eye: every table separate and
# exact), but Guides 1-2 and 4-7 use a font that maps the SPACE glyph (and
# possibly the degree sign) to an undecodable character, so their text and
# captions extract as "process\ufffdtime\ufffdfor..." and Guide 2 captured only
# 71 of 110 tables. build_pack.py now refuses \ufffd. Next: decode that font
# glyph explicitly, and require table-image count == caption count.
# To re-enable, remove `exit 0` below.
exit_canning() { :; }
# ----------------------------------------------------------------------------
# Processing-time tables are rendered as images of the original page
# (--table-caption matches USDA's "Recommended process time …" captions), and
# the text inside them is dropped — so times can't be paired with the wrong
# jar size or altitude. Every table image was reviewed by eye.
# D=content/08-home-canning; mkdir -p $D   (held back)
can() { $X "$SRC/$1" --source-url "$CAN/$2" --title "$3" -o "$D/$4.md" --bold-headings \
  --table-caption '^Recommended process time'; }
# can canning-intro.pdf INTRO_HomeCanrev0715.pdf "Home Canning: Introduction and Cautions (USDA)" 00-intro
# can canning-01.pdf GUIDE01_HomeCan_rev0715.pdf "Principles of Home Canning (USDA Guide 1)" 01-principles
# can canning-02.pdf GUIDE02_HomeCan_rev0715.pdf "Canning Fruit and Fruit Products (USDA Guide 2)" 02-fruit
# can canning-03.pdf GUIDE03_HomeCan_rev0715.pdf "Canning Tomatoes and Tomato Products (USDA Guide 3)" 03-tomatoes
# can canning-04.pdf GUIDE04_HomeCan_rev0715.pdf "Canning Vegetables (USDA Guide 4)" 04-vegetables
# can canning-05.pdf GUIDE05_HomeCan_rev0715.pdf "Canning Poultry, Red Meats and Seafoods (USDA Guide 5)" 05-meat
# can canning-06.pdf GUIDE06_HomeCan_rev0715.pdf "Fermented Foods and Pickled Vegetables (USDA Guide 6)" 06-pickles
# can canning-07.pdf GUIDE07_HomeCan_rev0715.pdf "Jams and Jellies (USDA Guide 7)" 07-jams

# --- 18 Family & Community Preparedness: FEMA Are You Ready? ---------------
D=content/18-family-preparedness
$X "$SRC/are-you-ready.pdf" --pages 4-36 --source-url "$AYR_URL" \
  --title "Are You Ready? An In-Depth Guide to Citizen Preparedness (FEMA)" \
  --skip "Table of Contents" -o $D/05-are-you-ready.md
