#!/usr/bin/env bash
# Batch 3 (skills): shelter/construction, tools and repairs, vehicles,
# power/electrical safety, fire and heat, communications, water systems.
# Usage: tools/packs/recipes/batch3_skills.sh <dir-with-downloaded-sources>
#
# Release evidence was read on each source's own title page / site on
# 2026-10-29. Download the files named below into <dir> first
# (curl -sL -A "Mozilla/5.0" --retry 3). Combat/military-only chapters and
# table-dependent sections are skipped; each selection is listed below.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir>}"
X="tools/.venv/bin/python tools/packs/extract_pdf.py"
H="python3 tools/packs/extract_html.py"
AP=https://armypubs.army.mil/epubs/DR_pubs/DR_a

# cut FILE START END: remove the lines from the first line starting with
# START up to (not including) the next line starting with END. Used only to
# HOLD BACK scrambled table cells whose numbers are safety-critical (load,
# span, capacity, mix tables). The extractor's "[Table … — table layout not
# preserved; verify values against the original document]" caption stays,
# so readers are pointed to the original. END=EOF cuts to the end of file.
# Fails if either line is missing.
cut() {
  python3 - "$@" <<'EOF'
import sys
path, start, end = sys.argv[1:4]
lines = open(path, encoding="utf-8").read().split("\n")
key = lambda l: l.lstrip("\uf06c\uf0b7\u2022 ")  # ignore PDF bullet glyphs
i = next((n for n, l in enumerate(lines) if key(l).startswith(start)), None)
if i is None: sys.exit(f"cut: start not found in {path}: {start!r}")
j = len(lines) if end == "EOF" else next(
    (n for n in range(i + 1, len(lines)) if key(lines[n]).startswith(end)), None)
if j is None: sys.exit(f"cut: end not found in {path}: {end!r}")
open(path, "w", encoding="utf-8").write("\n".join(lines[:i] + lines[j:]))
print(f"cut {path}: dropped {j - i} table lines after {start[:40]!r}")
EOF
}

# cuttab FILE "Table 3-2." ...: for each named table, keep its caption
# marker and drop the scrambled cell lines after it, up to the next numbered
# paragraph ("3-14. ..."), figure/table marker or chapter section; a "## "
# heading directly above that paragraph is kept; a table at the end of a
# document is cut to the end. Army manuals number every
# prose paragraph, so only table cells and table notes are dropped. Set
# CUTTAB_SHOW=1 to print every dropped line for audit.
cuttab() {
  python3 - "$@" <<'EOF'
import os, re, sys
path, names = sys.argv[1], sys.argv[2:]
lines = open(path, encoding="utf-8").read().split("\n")
para = re.compile(r"^[• ]*([0-9A-Z]{1,2}-[0-9]{1,3}\.\s|\[Figure |\[Table |Section [IVX]+)")
for name in names:
    i = next((n for n, l in enumerate(lines) if l.startswith("[" + name)), None)
    if i is None: sys.exit(f"cuttab: no marker for {name} in {path}")
    j = i + 1
    while j < len(lines) and not para.match(lines[j]): j += 1
    # (a table at the very end of the document is cut to the end)
    k = j  # keep a heading (and blank lines) directly above the paragraph
    while k > i + 1 and (not lines[k - 1].strip() or lines[k - 1].startswith("## ")):
        k -= 1
        if lines[k].startswith("## "): break
    if k > i + 1 and not lines[k].startswith("## "): k = j
    dropped = [l for l in lines[i + 1:k] if l.strip()]
    if os.environ.get("CUTTAB_SHOW"):
        print(f"--- {path} {name}:"); [print("   x", l[:110]) for l in dropped]
    lines = lines[:i + 1] + [""] + lines[k:]
    print(f"cuttab {path}: {name} dropped {len(dropped)} lines")
open(path, "w", encoding="utf-8").write("\n".join(lines))
EOF
}

# =====================================================================
# 03 Shelter & Construction (verified)
# =====================================================================
D=content/03-shelter-construction; mkdir -p $D

# --- TM 3-34.47/MCRP 3-40D.3 Carpentry (2022) -> tm3-34-47.pdf ----------
# Title page: "DISTRIBUTION RESTRICTION: Approved for public release;
# distribution is unlimited." Supersedes the 2013 edition.
CP_URL="$AP/ARN35831-TM_3-34.47-000-WEB-1.pdf"
cp_() { $X "$SRC/tm3-34-47.pdf" --pages "$1" --source-url "$CP_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 1 (construction drawings — mostly figures), 3 (bill of
# materials), 10 (nonstandard fixed bridge — load-class tables),
# 11 (timber-pile wharves), App. A (conversion tables), B (abbreviations),
# C (labor-estimate tables).
cp_ 39-58   "Construction Materials, Lumber and Fasteners (TM 3-34.47 Ch. 2)" 01-materials
cp_ 63-72   "Building Layout and Foundations (TM 3-34.47 Ch. 4)" 02-layout-foundation
cp_ 73-86   "Forms for Concrete (TM 3-34.47 Ch. 5)" 03-concrete-forms
cp_ 87-142  "Rough Framing: Floors, Walls and Stairs (TM 3-34.47 Ch. 6)" 04-rough-framing
cp_ 143-176 "Roof Systems and Roof Coverings (TM 3-34.47 Ch. 7)" 05-roofing
cp_ 177-196 "Doors and Windows (TM 3-34.47 Ch. 8)" 06-doors-windows
cp_ 197-210 "Finish Carpentry (TM 3-34.47 Ch. 9)" 07-finish-carpentry
cp_ 261-264 "Tile, Insulation and General Information (TM 3-34.47 App. D)" 08-general-info
# Hold back structural load/span tables (scrambled cells; safety-critical).
F=$D/04-rough-framing.md
cut $F "(Based on Douglas fir" "## Rough Framing: LOAD AREA"             # Table 6-1 girder sizes
cut $F "## Rough Framing: Without Plastered Ceiling Below" "[Figure 6-22"  # Table 6-2 joist spans
cut $F "## Rough Framing: Group I" "## Rough Framing: FLOOR OPENINGS"      # Table 6-3 lumber groups
# --- TM 3-34.44/MCRP 3-40D.4 Concrete and Masonry (2012, Change 1 2 Sep 2021)
# -> tm3-34-44.pdf. Title page: "DISTRIBUTION RESTRICTION: Approved for
# public release; distribution is unlimited." Content identical to FM 5-428
# (1998) as updated by C1 (2021); current Army publication.
CM_URL="$AP/ARN33491-TM_3-34.44-001-WEB-3.pdf"
cm() { $X "$SRC/tm3-34-44.pdf" --pages "$1" --source-url "$CM_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# HELD BACK: Ch. 3 (proportioning concrete mixtures — mix-proportion tables),
# Ch. 4 (form design — allowable load/shore/span tables; TM 3-34.47 Ch. 5
# covers forms in prose), Ch. 6 (reinforced concrete — bar/design tables),
# App. A (conversion table), App. B–C (slump test, moisture adjustment).
cm 19-38   "Concrete: Properties, Cement, Water, Aggregates and Admixtures (TM 3-34.44 Ch. 1–2)" 10-concrete-components
cm 107-152 "Concrete Construction: Site, Mixing, Placing, Finishing, Curing and Repair (TM 3-34.44 Ch. 5)" 11-concrete-construction
cm 173-184 "Mason's Tools, Mortar and Scaffolding (TM 3-34.44 Ch. 7)" 12-masonry-basics
cm 185-216 "Concrete Block and Rubble Stone Masonry (TM 3-34.44 Ch. 8)" 13-concrete-masonry
cm 217-284 "Brick and Tile Masonry (TM 3-34.44 Ch. 9)" 14-brick-masonry
# Hold back mix-proportion, cold-weather protection, form-stripping,
# fire-rating and lintel tables (scrambled cells; safety-critical numbers).
# Prose statements of the same values (e.g. mortar Types M/S/N/O) remain.
cut $D/10-concrete-components.md "## Concrete Components: Moderate Exposure" "## Concrete Components: TESTS FOR AIR CONTENT"  # Table 2-7 air content
cut $D/10-concrete-components.md "## Concrete Components: Maximum Water Soluble" EOF                                   # Table 2-8 chloride limits
F=$D/11-concrete-construction.md
cut $F "## Construction Procedures: Placing and Curing Conditions" "[Table 5-7."               # Table 5-6 cold-weather temperatures
cut $F "## Construction Procedures: High-Early-Strength Concrete" "## Construction Procedures: EFFECTS ON LOW"  # Table 5-7 protection days
cut $F "## Construction Procedures: Setting Time" "## Construction Procedures: REMOVING RIDGES"  # Table 5-8 form stripping times
cut $D/12-masonry-basics.md "## Basic Equipment and Components: Hydrated Lime" "Type S mortar"  # Table 7-1 mortar mix proportions
F=$D/14-brick-masonry.md
cut $F "## Brick and Tile Masonry: Plaster on Two Sides" "## Brick and Tile Masonry: ABRASION RESISTANCE"  # Table 9-1 fire resistance
cut $F "## Brick and Tile Masonry: Wall" "[Figure 9-31."                                                    # Table 9-5 lintel sizes

# =====================================================================
# 11 Tools & Repairs (needs-review: 1990s–2001 content — rigging (FM 5-125,
# 1995), welding (TC 9-237, 1993), plumbing (FM 3-34.471, 2001); materials,
# codes and equipment may be dated)
# =====================================================================
D=content/11-tools-repairs; mkdir -p $D

# --- TM 3-34.86/MCRP 3-17.7J Rigging Techniques, Procedures and Applications
# (2012; identical to FM 5-125, 1995) -> tm3-34-86.pdf. Title page:
# "DISTRIBUTION RESTRICTION: Approved for public release; distribution is
# unlimited."
RG_URL="$AP/pdf/web/tm3_34x86.pdf"
rg() { $X "$SRC/tm3-34-86.pdf" --pages "$1" --source-url "$RG_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
rg 11-30   "Rope: Fiber and Wire Rope Care and Use (TM 3-34.86 Ch. 1)" 01-rope
rg 31-78   "Knots, Splices, Attachments and Ladders (TM 3-34.86 Ch. 2)" 02-knots-splices
rg 79-104  "Hoists, Blocks and Tackle (TM 3-34.86 Ch. 3)" 03-hoists
rg 105-124 "Anchors and Guy Lines (TM 3-34.86 Ch. 4)" 04-anchors
rg 125-142 "Lifting and Moving Equipment (TM 3-34.86 Ch. 5)" 05-lifting-moving
rg 143-150 "Scaffolds (TM 3-34.86 Ch. 6)" 06-scaffolds
# Skipped: App. A (tables of rope/chain/hook capacities — load tables).

# --- TC 9-237 Welding Theory and Application (1993) -> tc9-237.pdf --------
# Title page: "DISTRIBUTION RESTRICTION: Approved for public release;
# distribution is unlimited." Text PDF (not OCR).
WD_URL="$AP/pdf/web/tc9_237.pdf"
wd() { $X "$SRC/tc9-237.pdf" --pages "$1" --source-url "$WD_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 1, 3–5, 7–9, 12–13, apps. (theory, symbols, joint design,
# equipment catalog, metals ID, electrodes, special/military applications,
# testing) and the GTAW/GMAW/SAW/other-process parts of Ch. 10.
wd 23-65   "Welding Safety Precautions (TC 9-237 Ch. 2)" 10-welding-safety
# HELD BACK: Ch. 6 (techniques, pp. 160-229), Ch. 10 (arc welding,
# pp. 369-494) and Ch. 11 (oxyfuel, pp. 495-552) — these pages are an old
# OCR text layer: lines are out of reading order (e.g. para 11-3a(1)) and
# words are misrecognized ("flare" for "flame", "loW"), including in flame
# adjustment and gas-pressure instructions. Only Ch. 2 (cleanly re-typeset)
# is shipped. Tables 11-1/11-2 (tip pressures) would be held back anyway.

# --- TM 3-34.70/MCRP 3-17.7E Plumbing, Pipe Fitting, and Sewerage (2012;
# identical to FM 3-34.471, 2001) -> tm3-34-70.pdf. Title page:
# "DISTRIBUTION RESTRICTION: Approved for public release; distribution is
# unlimited."
PL_URL="$AP/pdf/web/tm3_34x70.pdf"
pl() { $X "$SRC/tm3-34-70.pdf" --pages "$1" --source-url "$PL_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 2 (central heating plants), 8 (stacks/branches — pipe-size
# tables), 10 (steam/gas/air piping), 12 (insulation), App. A–E
# (conversion, drawings, BOM, pipe-sizing design tables).
pl 13-62   "Water Supply, Sewerage, Latrines and Waste Disposal (TM 3-34.70 Ch. 1)" 20-plumbing-systems
pl 73-82   "Basic Plumbing Repairs and Maintenance (TM 3-34.70 Ch. 3)" 21-plumbing-repairs
pl 83-108  "Plumbing Fixtures (TM 3-34.70 Ch. 4)" 22-fixtures
pl 109-114 "Water Heaters (TM 3-34.70 Ch. 5)" 23-water-heaters
pl 115-156 "Pipes and Fittings (TM 3-34.70 Ch. 6)" 24-pipes-fittings
pl 157-170 "Valves and Faucets (TM 3-34.70 Ch. 7)" 25-valves-faucets
pl 177-188 "Traps and Vents (TM 3-34.70 Ch. 9)" 26-traps-vents
pl 193-198 "Centrifugal Pumps (TM 3-34.70 Ch. 11)" 27-pumps
# Hold back load/capacity tables (rope and wire-rope strength, safety
# factors, sheave sizes, chain/hook/sling SWCs, picket and deadman holding
# power, gin-pole capacity, wire-rope clip count/spacing/torque) and plumbing
# design tables (chlorine dosage, pipe sizing, DFUs, soil absorption and
# sewage application rates, vent sizes, thread lengths). Prose rules of thumb
# stay; captions point to the original.
cuttab $D/01-rope.md "Table 1-1. Properties" "Table 1-2." "Table 1-3." "Table 1-4."
cuttab $D/02-knots-splices.md "Table 2-2." "Table 2-3."
cuttab $D/03-hoists.md "Table 3-1." "Table 3-2. Safe" "Table 3-3." "Table 3-4." "Table 3-5."
cuttab $D/04-anchors.md "Table 4-1." "Table 4-2."
cuttab $D/05-lifting-moving.md "Table 5-1."
cuttab $D/20-plumbing-systems.md "Table 1-1." "Table 1-2." "Table 1-3." "Table 1-4." "Table 1-5." "Table 1-6." "Table 1-7." "Table 1-8." "Table 1-9." "Table 1-10" "Table 1-11." "Table 1-12."
cuttab $D/22-fixtures.md "Table 4-1."
cuttab $D/24-pipes-fittings.md "Table 6-2." "Table 6-3." "Table 6-4."
cuttab $D/26-traps-vents.md "Table 9-1." "Table 9-2." "Table 9-3."

# =====================================================================
# 11b Vehicle Operation (verified)
# =====================================================================
D=content/11b-vehicles; mkdir -p $D
# --- TC 21-305-20/AFMAN 24-306(I) Manual for the Wheeled Vehicle Operator
# (2016) -> tc21-305-20.pdf. Title page: "DISTRIBUTION RESTRICTION:
# Approved for public release; distribution is unlimited."
VH_URL="$AP/pdf/web/tc21_305_20.pdf"
vh() { $X "$SRC/tc21-305-20.pdf" --pages "$1" --source-url "$VH_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# Skipped: Ch. 1–2 (military regulations, traffic controls), 5 (accident
# reporting forms), 7 (mounted land navigation), 8–9 (dispatch, troop
# transport), 11–15 (engine/transmission specifics, tractor-trailers,
# hazardous cargo, CBRN), 18 (night vision devices), 19 (convoys),
# 20 (flight line), 21–23 (loading, MHE, camouflage), App. A, B, D–G.
vh 33-56   "Basic Operating Practices and Maneuvers (TC 21-305-20 Ch. 3)" 01-operating-practices
vh 57-62   "Driving Emergencies (TC 21-305-20 Ch. 4)" 02-emergencies
vh 71-80   "Driving Hazards and Safety Measures (TC 21-305-20 Ch. 6)" 03-hazards
vh 107-112 "Operator Maintenance and Checks (TC 21-305-20 Ch. 10)" 04-maintenance
vh 163-172 "Off-Road and Winter Driving (TC 21-305-20 Ch. 16)" 05-off-road-winter
vh 173-186 "Vehicle Recovery (TC 21-305-20 Ch. 17)" 06-recovery
vh 301-304 "Vehicle Rollover Prevention (TC 21-305-20 App. C)" 07-rollover
# Drop text labels lifted from inside diagrams (repeated 3–5 times each,
# e.g. "ANCHOR ANCHOR ANCHOR"); they belong to figures, which are not
# included. Each cut ends at that figure's caption marker.
cut $D/02-emergencies.md "## Emergencies: WHEEL IN DIRECTION" "[Figure 4-1."
F=$D/06-recovery.md
cut $F "## Vehicle Recovery: WINCHING – SPREADER" "[Figure 17-2."
cut $F "## Vehicle Recovery: WIND UP ROPES" "[Figure 17-3."
cut $F "## Vehicle Recovery: CHAINS OR ROPE" "[Figure 17-7."
cut $F "## Vehicle Recovery: FIFTH STEP" "[Figure 17-8."
cut $F "## Vehicle Recovery: AFTER LIFTING" "[Figure 17-9."

# ---------------------------------------------------------------------
# HTML helpers. Output goes to a temp dir, never into the project.
# slice IN OUT START END: keep the raw HTML from START up to END (page
#   chrome such as side navigation and footers is outside it) and wrap it in
#   <main> for extract_html.py. The page's own text is not changed.
# ecprep IN OUT [DIV_ID...]: eCFR renderer HTML -> remove the named section
#   or subpart <div>s (held back), and turn section headings (<h4>) into
#   <h3> so each CFR section becomes its own library section.
# alttext IN OUT ALT...: put an image's own alt text (e.g. "class A") into the
#   text where the image stands, for images whose alt text is the only label
#   for the adjacent words (USFA extinguisher classes).
# ---------------------------------------------------------------------
T=$(mktemp -d)
slice() {
  python3 - "$@" <<'EOF'
import sys
src, out, start, end = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
i = s.index(start); j = s.index(end, i)
open(out, "w", encoding="utf-8").write("<html><body><main>" + s[i:j] + "</main></body></html>")
EOF
}
ecprep() {
  python3 - "$@" <<'EOF'
import re, sys
src, out, *drop = sys.argv[1:]
s = open(src, encoding="utf-8").read()
def remove_div(s, start):
    depth = 0
    for m in re.compile(r"<(/?)div\b[^>]*>").finditer(s, start):
        depth += -1 if m.group(1) else 1
        if depth == 0:
            return s[:start] + s[m.end():]
    sys.exit("ecprep: unbalanced div")
for d in drop:
    m = re.search(r'<div[^>]*\bid="%s"' % re.escape(d), s)
    if not m: sys.exit(f"ecprep: no div id={d} in {src}")
    s = remove_div(s, m.start())
s = re.sub(r"<h4 (data-hierarchy-metadata[^>]*)>(.*?)</h4>", r"<h3 \1>\2</h3>", s, flags=re.S)
open(out, "w", encoding="utf-8").write("<html><body><main>" + s + "</main></body></html>")
EOF
}
alttext() {
  python3 - "$@" <<'EOF'
import re, sys
src, out, *alts = sys.argv[1:]
s = open(src, encoding="utf-8").read()
for a in alts:
    pat = re.compile(r'<img[^>]*alt="\s*%s"[^>]*>' % re.escape(a))
    if not pat.search(s): sys.exit(f"alttext: no image alt={a!r}")
    s = pat.sub("<p>%s</p>" % a, s)
open(out, "w", encoding="utf-8").write(s)
EOF
}

# =====================================================================
# 13 Communications (verified)
# =====================================================================
D=content/13-communications; mkdir -p $D

# --- CISA National Interoperability Field Operations Guide v2.02 (Jan 2025)
# -> nifog.pdf. U.S. Government work (CISA/DHS); no distribution limits
# stated. The only third-party notice in the full text is the RJ-45 pinout
# figure on p. 166 ("Copyright © 2021 ShowMeCables") — not extracted.
NF_URL="https://www.cisa.gov/sites/default/files/2024-12/NIFOG%202.02_508%20FINAL%20VERSION%2012%2003%202024.pdf"
nf() { $X "$SRC/nifog.pdf" --pages "$1" --source-url "$NF_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
# HELD BACK (channel/frequency tables — layout not preserved): pp. 32-73
# (interoperability channel plans, CTCSS/CDCSS codes), 74 (line-of-sight
# range table), 75-123 (city plans, encryption, aviation, marine, business,
# railroad, SAR, time, HF, maritime distress, amateur, CB/FRS/GMRS/MURS
# channel tables), 128-178 (contacts, carrier services, satellite, IT,
# cybersecurity, RJ-45 © figure), 188-190 (time zone and phonetic tables).
nf 8-31    "Using Interoperability Channels: Rules, Licensing and Conventions (CISA NIFOG v2.02)" 01-nifog-rules
nf 124-127 "Radio Interference Management (CISA NIFOG v2.02)" 02-nifog-interference
nf 191     "Reporting a Medical Emergency by Radio (CISA NIFOG v2.02)" 03-nifog-medical-report

# --- TC 9-64 Communications-Electronics Fundamentals: Wave Propagation,
# Transmission Lines, and Antennas (2004) -> tc9-64.pdf. Title page:
# "DISTRIBUTION RESTRICTION: Approved for public release; distribution is
# unlimited." Only Ch. 4 (antennas, incl. RF safety); Ch. 1-3 are theory.
AN_URL="$AP/pdf/web/tc9_64.pdf"
$X "$SRC/tc9-64.pdf" --pages 167-236 --source-url "$AN_URL" --bold-headings \
  --skip "Check-On-Learning Questions" \
  --title "Antennas and RF Safety (TC 9-64 Ch. 4)" -o $D/04-antennas.md

# --- eCFR Title 47 (FCC) Parts 97 and 95, current text "up to date as of
# 2026-10-27" (eCFR versioner API). Federal regulations are public domain.
# The www.ecfr.gov HTML page answers automated requests with a "Request
# Access" page, so the official eCFR renderer API is used instead:
#   https://www.ecfr.gov/api/renderer/v1/content/enhanced/current/title-47?part=97
#   ...?part=95&subpart={A,B,D,E,J}
# Save as ecfr97.html and ecfr95A.html, ecfr95B.html, ... in <dir>.
# HELD BACK (multi-column tables): §97.301 bands, §97.303 sharing, §97.305
# emissions, §95.371 emissions, unwanted-emission limits (§95.979, §95.1779,
# §95.2779); Part 97 Subpart F (exams) and Appendix 1. Two-column channel
# lists (§95.563 FRS, §95.963 CB) keep their HTML row order and are kept.
EC=https://www.ecfr.gov/current/title-47/chapter-I/subchapter-D
ecprep "$SRC/ecfr97.html" $T/97.html 97.301 97.303 97.305 subpart-F Appendix-1-to-Part-97
$H $T/97.html --source-url "$EC/part-97" --title "Amateur Radio Service Rules (47 CFR Part 97, eCFR as of 2026-10-27)" -o $D/10-cfr-part97.md
ecprep "$SRC/ecfr95A.html" $T/95A.html 95.371
$H $T/95A.html --source-url "$EC/part-95/subpart-A" --title "Personal Radio Services: General Rules (47 CFR Part 95 Subpart A, eCFR as of 2026-10-27)" -o $D/11-cfr-part95-general.md
ecprep "$SRC/ecfr95B.html" $T/95B.html
$H $T/95B.html --source-url "$EC/part-95/subpart-B" --title "Family Radio Service (47 CFR Part 95 Subpart B, eCFR as of 2026-10-27)" -o $D/12-cfr-frs.md
ecprep "$SRC/ecfr95D.html" $T/95D.html 95.979
$H $T/95D.html --source-url "$EC/part-95/subpart-D" --title "CB Radio Service (47 CFR Part 95 Subpart D, eCFR as of 2026-10-27)" -o $D/13-cfr-cb.md
ecprep "$SRC/ecfr95E.html" $T/95E.html 95.1779
$H $T/95E.html --source-url "$EC/part-95/subpart-E" --title "General Mobile Radio Service (47 CFR Part 95 Subpart E, eCFR as of 2026-10-27)" -o $D/14-cfr-gmrs.md
ecprep "$SRC/ecfr95J.html" $T/95J.html 95.2779
$H $T/95J.html --source-url "$EC/part-95/subpart-J" --title "Multi-Use Radio Service (47 CFR Part 95 Subpart J, eCFR as of 2026-10-27)" -o $D/15-cfr-murs.md

# --- NOAA Weather Radio All Hazards (weather.gov/nwr), NWS web pages
# (U.S. Government work). Content is the page body between the side
# navigation and the footer. Product/manufacturer listings and recalls on
# the receivers page are not included. The NWR FAQ page is links only.
NW=https://www.weather.gov/nwr
$H "$SRC/nwr.html" --container body --source-url "$NW/" \
  --drop-before "NOAA Weather Radio All Hazards" --drop-after "Special Notices" \
  --title "NOAA Weather Radio All Hazards: Overview and Frequencies" -o $D/20-nwr-overview.md
slice "$SRC/nwr-reception.html" $T/rec.html '<div id="divMain"' '<!-- end of'
$H $T/rec.html --source-url "$NW/reception" --title "NOAA Weather Radio: Improving Reception" -o $D/21-nwr-reception.md
slice "$SRC/nwr-nwrsame.html" $T/same.html '<div id="divMain"' '<!-- end of'
$H $T/same.html --source-url "$NW/nwrsame" --title "NOAA Weather Radio: SAME Alerts and Coverage" -o $D/22-nwr-same.md
slice "$SRC/nwr-nwr_receivers.html" $T/rcv.html '<div id="divMain"' '<!-- end of'
$H $T/rcv.html --source-url "$NW/nwr_receivers" --drop-after "Receiver Recalls" \
  --title "NOAA Weather Radio: Choosing and Programming a Receiver" -o $D/23-nwr-receivers.md

# =====================================================================
# 09 Fire & Heating Safety (verified) — U.S. Fire Administration (FEMA)
# =====================================================================
D=content/09-fire-heat; mkdir -p $D
# USFA web pages (U.S. Government work; no third-party notices on either
# page). The content column is sliced out (side navigation and the
# "More resources" aside are outside it). On the extinguisher page the class
# letters exist only as image alt text ("class A" … "class K"); alttext puts
# those labels back next to their descriptions.
UF=https://www.usfa.fema.gov/prevention/home-fires
slice "$SRC/usfa-heating.html" $T/heat.html '<div class="col-12 col-lg-9' '<aside id="aside"'
$H $T/heat.html --source-url "$UF/prevent-fires/heating/" --skip "Pictographs" "Handouts" "Videos" \
  --title "Heating Fire Safety (U.S. Fire Administration)" -o $D/01-heating-fire-safety.md
alttext "$SRC/usfa-ext.html" $T/ext0.html "class A" "class B" "class C" "class D" "class K"
slice $T/ext0.html $T/ext.html '<div class="col-12 col-lg-9' '<aside id="aside"'
$H $T/ext.html --source-url "$UF/prepare-for-fire/fire-extinguishers/" \
  --title "Choosing and Using Fire Extinguishers (U.S. Fire Administration)" -o $D/02-fire-extinguishers.md

# =====================================================================
# 09b Wood Burning (verified content; EPA licensing pending owner decision)
# =====================================================================
# EPA pages carry no third-party copyright notice; EPA-authored web text is a
# U.S. Government work. EPA's general disclaimer page says its "Copyright
# Status" paragraph applies only where a document incorporates it — none of
# these pages do. Kept in EPA-only packs so they can be dropped wholesale if
# the owner keeps EPA deferred (docs/decisions.md, "Starter library sources").
# EPA pages use a "page-has-sidebar" wrapper that extract_html.py treats as
# chrome, so the <article> element is used as the container.
D=content/09b-wood-burning; mkdir -p $D
BW=https://www.epa.gov/burnwise
$H "$SRC/bw-best.html" --container article --source-url "$BW/best-wood-burning-practices" \
  --title "Best Wood-Burning Practices (EPA Burn Wise)" -o $D/01-best-practices.md
$H "$SRC/bw-tips-better-burn.html" --container article --source-url "$BW/tips-better-burn" \
  --title "Tips for a Better Burn (EPA Burn Wise)" -o $D/02-tips-better-burn.md
$H "$SRC/bw-wood-burning-installation-and-maintenance.html" --container article \
  --source-url "$BW/wood-burning-installation-and-maintenance" \
  --title "Wood-Burning Installation and Maintenance (EPA Burn Wise)" -o $D/03-installation-maintenance.md
$H "$SRC/bw-wood-smoke-and-your-health.html" --container article --source-url "$BW/wood-smoke-and-your-health" \
  --skip "Wood Smoke & Asthma Videos" "Related Information" \
  --title "Wood Smoke and Your Health (EPA Burn Wise)" -o $D/04-wood-smoke-health.md
$H "$SRC/bw-backyard-recreational-fires.html" --container article --source-url "$BW/backyard-recreational-fires" \
  --title "Backyard Recreational Fires (EPA Burn Wise)" -o $D/05-backyard-fires.md
# Not used: chimney-sweeps (outreach page for sweeps, quotes a named
# private individual), build-firewood-storage and moisture-meter (video and
# PDF links only).

# =====================================================================
# 04b Water Systems: wells and septic (verified content; EPA licensing
# pending owner decision — see note above)
# =====================================================================
D=content/04b-water-systems; mkdir -p $D
PW=https://www.epa.gov/privatewells
$H "$SRC/wells-learn-about-private-water-wells.html" --container article \
  --source-url "$PW/learn-about-private-water-wells" --skip "Well components2" \
  --title "Learn About Private Water Wells (EPA)" -o $D/01-private-wells.md
# "Well components" is skipped: EPA notes it is "adapted from the National
# Ground Water Association" (third-party text).
$H "$SRC/wells-protect-your-homes-water.html" --container article \
  --source-url "$PW/protect-your-homes-water" \
  --title "Protect Your Home's Water: Well Testing, Treatment and Flood Response (EPA)" -o $D/02-protect-well-water.md
$H "$SRC/wells-potential-well-water-contaminants-and-their-impacts.html" --container article \
  --source-url "$PW/potential-well-water-contaminants-and-their-impacts" \
  --title "Potential Well Water Contaminants and Their Impacts (EPA)" -o $D/03-well-contaminants.md
$H "$SRC/epa-emdis.html" --container article \
  --source-url "https://www.epa.gov/ground-water-and-drinking-water/emergency-disinfection-drinking-water" \
  --title "Emergency Disinfection of Drinking Water (EPA)" -o $D/04-emergency-disinfection.md
SP=https://www.epa.gov/septic
$H "$SRC/septic-how-your-septic-system-works.html" --container article --source-url "$SP/how-your-septic-system-works" \
  --title "How Septic Systems Work (EPA)" -o $D/10-septic-how-it-works.md
$H "$SRC/septic-how-care-your-septic-system.html" --container article --source-url "$SP/how-care-your-septic-system" \
  --title "How to Care for Your Septic System (EPA)" -o $D/11-septic-care.md
$H "$SRC/septic-types-septic-systems.html" --container article --source-url "$SP/types-septic-systems" \
  --title "Types of Septic Systems (EPA)" -o $D/12-septic-types.md
# HELD BACK / not used:
#  - SepticSmart Homeowner's Guide PDF (2015-06/documents/epa_septicsmart_
#    print_guide_homeownersguide508.pdf): its only text layer is the
#    one-page printing instructions; the booklet is not extractable (the HTML
#    septic pages above cover the same guidance).
#  - Composting Toilets fact sheet EPA 832-F-99-066 (1999, comp.pdf): two-
#    column layout extracts out of order (sentence fragments displaced); also
#    names commercial brands and has cost tables.
#  - Soak Up the Rain: Rain Barrels page: almost entirely links to state
#    and university resources; no usable guidance text.

# =====================================================================
# 10 Power & Electrical Safety — NOT BUILT (no shippable source yet)
# =====================================================================
#  - OSHA 3080, 3075, 3286, 4105 (osha.gov): automated downloads are
#    refused (HTML block page instead of the PDF); not attempted further.
#  - CPSC Safety Alert, Portable Generator Hazards (5123, Oct 2021): its
#    text layer drops the "fi" ligature ("fre" for "fire", "confned",
#    "certifed", "specifcally"), corrupting safety text. HELD BACK.
#  - cpsc.gov HTML pages: "Access Denied" to automated requests.
rm -rf "$T"
