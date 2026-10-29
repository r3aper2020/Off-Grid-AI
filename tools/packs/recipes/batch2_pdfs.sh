#!/usr/bin/env bash
# Batch 2: current Army first aid, mountaineering, cold-weather and desert
# manuals (all Distribution A, verified on each title page 2026-10-29).
# Usage: tools/packs/recipes/batch2_pdfs.sh <dir-with-downloaded-sources>
# Combat-only chapters are skipped; each selection is listed below.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir>}"
X="tools/.venv/bin/python tools/packs/extract_pdf.py --figures auto"
AP=https://armypubs.army.mil/epubs/DR_pubs/DR_a

# --- 01 First Aid: ATP 4-02.11 (Mar 2026; supersedes TC 4-02.1) ----------
FA_URL="$AP/ARN46159-ATP_4-02.11-000-WEB-1.pdf"
D=content/01-first-aid
fa() { $X "$SRC/atp4-02-11.pdf" --pages "$1" --source-url "$FA_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 1 (tactical casualty response), 3 (TCCC phases), 14–15
# (casualty monitoring for medics), 18 (sickle cell trait), App. B.
fa 37-41   "Moving an Injured Person (ATP 4-02.11 Ch. 2)" 10-moving-casualties
fa 57-72   "Stopping Severe Bleeding (ATP 4-02.11 Ch. 4)" 11-bleeding
fa 73-86   "Opening and Protecting the Airway (ATP 4-02.11 Ch. 5)" 12-airway
fa 87-96   "Breathing and Chest Injuries (ATP 4-02.11 Ch. 6)" 13-breathing
fa 97-102  "Circulation and Shock (ATP 4-02.11 Ch. 7)" 14-circulation
fa 103-106 "Preventing Hypothermia in the Injured (ATP 4-02.11 Ch. 8)" 15-hypothermia
fa 107-110 "Wounds, Pain and Splinting Assessment (ATP 4-02.11 Ch. 9)" 16-secondary
fa 111-120 "Eye Injuries (ATP 4-02.11 Ch. 10)" 17-eye
fa 121-128 "Head Injuries (ATP 4-02.11 Ch. 11)" 18-head
fa 129-134 "Burns (ATP 4-02.11 Ch. 12)" 19-burns
fa 135-154 "Fractures and Splinting (ATP 4-02.11 Ch. 13)" 20-fractures
fa 173-186 "Bites and Stings (ATP 4-02.11 Ch. 16)" 21-bites-stings
fa 187-198 "Heat, Cold and Environmental Injuries (ATP 4-02.11 Ch. 17)" 22-environmental
fa 203-222 "First Aid in Chemical, Biological and Radiological Incidents (ATP 4-02.11 Ch. 19)" 23-cbrn-first-aid
fa 223-230 "Stress and Psychological First Aid (ATP 4-02.11 Ch. 20)" 24-stress
fa 231-236 "First Aid Kit Contents (ATP 4-02.11 App. A)" 25-first-aid-kit

# --- 16 Wilderness: TC 3-97.61 Military Mountaineering (Nov 2025) --------
MT_URL="$AP/ARN45366-TC_3-97.61-000-WEB-1.pdf"
D=content/16-wilderness-survival
mt() { $X "$SRC/tc3-97-61.pdf" --pages "$1" --source-url "$MT_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 2 (unit training), 6 (technical climbing), 9–12 (anchors,
# climbing rope systems, fixed ropes, hauling), 14 (glacier travel), apps.
mt 21-36   "The Mountain Environment (TC 3-97.61 Ch. 1)" 20-mountain-environment
mt 45-60   "Mountain Environmental Injuries and Altitude Sickness (TC 3-97.61 Ch. 3)" 21-mountain-injuries
mt 61-82   "Food, Water and Living in the Mountains (TC 3-97.61 Ch. 4)" 22-mountain-sustainment
mt 83-102  "Avalanche Safety and Rescue (TC 3-97.61 Ch. 5)" 23-avalanche
mt 159-168 "Navigating Mountainous Terrain (TC 3-97.61 Ch. 7)" 24-mountain-navigation
mt 169-214 "Knot Tying and Rope Management (TC 3-97.61 Ch. 8)" 25-knots-rope
mt 343-352 "Crossing Mountain Streams (TC 3-97.61 Ch. 13)" 26-stream-crossing
mt 373-390 "Mountain Rescue and Evacuation (TC 3-97.61 Ch. 15)" 27-rescue
mt 391-404 "Rope Bridges (TC 3-97.61 Ch. 16)" 28-rope-bridges

# --- 16 Wilderness: cold weather and desert environments ------------------
CW_URL="$AP/pdf/web/atp3_90x97.pdf"   # ATP 3-90.97 (2016)
$X "$SRC/atp3-90-97.pdf" --pages 11-26 --source-url "$CW_URL" --bold-headings \
  --title "Mountain and Cold Weather Environments (ATP 3-90.97 Ch. 1)" -o $D/30-cold-environment.md
$X "$SRC/atp3-90-97.pdf" --pages 121-126 --source-url "$CW_URL" --bold-headings \
  --title "Altitude and Environmental Hazards (ATP 3-90.97 App. A)" -o $D/31-altitude-hazards.md
DS_URL="$AP/ARN44090-ATP_3-90.99-001-WEB-2.pdf"   # ATP 3-90.99 (2021, C1 2025)
$X "$SRC/atp3-90-99.pdf" --pages 15-42 --source-url "$DS_URL" --bold-headings \
  --title "The Desert Environment (ATP 3-90.99 Ch. 1)" -o $D/32-desert-environment.md
$X "$SRC/atp3-90-99.pdf" --pages 143-150 --source-url "$DS_URL" --bold-headings \
  --title "Living and Staying Healthy in the Desert (ATP 3-90.99 App. C)" -o $D/33-desert-health.md
