#!/usr/bin/env bash
# Batch 4 (power): pack 10 "Power & Electricity" (id "power").
#
# Usage: tools/packs/recipes/batch4_power.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-29. Run from the project root; then build with
#   python3 tools/packs/build_pack.py content/10-power
#
# Every source is a U.S. Government work (17 U.S.C. § 105). Every page/PDF
# was scanned for "©", "copyright", "courtesy", "permission", "reprinted";
# none of the text used carries a third-party notice (photo blocks and their
# credits are dropped). Licence evidence per publisher:
#  - DOE (energy.gov/web-policies): "Government information at DOE websites
#    is in the public domain. Public domain information may be freely
#    distributed and copied, but it is requested that in any subsequent use
#    the Department of Energy be given appropriate acknowledgement."
#  - EIA (eia.gov/about/copyrights_reuse.php): "U.S. government publications
#    are in the public domain and are not subject to copyright protection.
#    You may use and/or distribute any of our data, files, databases,
#    reports, graphs, charts, and other information products ..." Photos are
#    licensed (not used: the page's image carousels are dropped).
#  - USFA (FEMA), Ready.gov (FEMA), FDA, FAA: federal web pages/handouts with
#    no copyright or third-party notice.
# Text is verbatim. Post-processing (post() below) only removes page chrome
# (related-page cards, newsletter sign-ups, photo captions and credits,
# "Last updated" lines, handout/video link lists), normalizes PDF bullet
# glyphs to "- ", rejoins lines the PDF text layer broke mid-sentence, and
# turns mis-nested FDA sub-headings into their own "## " headings.
#
# NOT INCLUDED (and why):
#  - CPSC (cpsc.gov pages and s3fs-public PDFs), OSHA (osha.gov), fema.gov
#    and CDC/NIOSH (cdc.gov, stacks.cdc.gov): HTTP 403 / bot wall to
#    automated requests; not circumvented. This leaves portable-generator
#    placement distances, transfer switches/backfeed, downed power lines and
#    flooded electrical systems covered only by the short USFA/FDA/Ready.gov
#    lines below.
#  - DOE Energy Saver pages (estimating appliance energy use, off-grid /
#    stand-alone systems, planning a home solar system, small wind,
#    microhydropower): all URLs now return 404 (removed from energy.gov in
#    the 2026 restructuring); no rehosted copies used.
#  - DOE/WINDExchange Small Wind Guidebook (energy.gov/cmei/systems/
#    windexchange/small-wind-guidebook): its Publication Information says
#    "This work was authored by NLR for the U.S. Department of Energy ...
#    The U.S. government retains ... a nonexclusive ... license" — a
#    contractor-authored (copyrighted) work, not a federal work. Excluded.
#    NREL/NLR publications are excluded for the same reason.
#  - FDA "Home Use Devices: How to Prepare for and Handle Power Outages"
#    booklet (fda.gov/media/80782): a fill-in form (blank name/phone
#    fields, Yes/No checkboxes); text layer also contains U+FFFD.
#  - ATP 3-34.45 / TM 3-34.46 (Army electric power): not found on
#    armypubs.army.mil (only rehosts such as irp.fas.org); military prime
#    power planning in any case.
#  - EIA "science of electricity", "electricity use in homes", wind
#    generation statistics, energy storage (grid-scale tables): background
#    or statistics only.
#  - USFA electrical infographic: co-references NFPA statistics;
#    electrical/appliance card: same text as the USFA web page used.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
XH="python3 tools/packs/extract_html.py"
V=2026.10.29.6

USFA=https://www.usfa.fema.gov
UPDF=$USFA/downloads/pdf/publications
RG=https://www.ready.gov
EIA=https://www.eia.gov/energyexplained
DOE=https://www.energy.gov/cmei
FDA=https://www.fda.gov/medical-devices/emergency-situations-medical-devices
FAA_URL=https://www.faa.gov/hazmat/packsafe/lithium-batteries

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  dl usfa-carbon-monoxide.html "$USFA/prevention/life-safety-hazards/carbon-monoxide/"
  dl usfa-severe-weather.html "$USFA/prevention/home-fires/prevent-fires/severe-weather/"
  dl usfa-appliance-and-electrical.html "$USFA/prevention/home-fires/prevent-fires/appliance-and-electrical/"
  dl usfa-batteries.html "$USFA/prevention/home-fires/prevent-fires/batteries/"
  for f in portable_generators_winter_storms_flyer prevent_home_electrical_fires_flyer \
           lithium-ion-battery-safety-handout lithium-ion-battery-after-flooding-handout; do
    dl "usfa-$f.pdf" "$UPDF/$f.pdf"
  done
  dl faa-lithium.html "$FAA_URL"
  dl fda-devices.html "$FDA/fda-offers-tips-about-medical-devices-and-natural-disasters"
  dl fda-refrig.html "$FDA/medical-devices-requiring-refrigeration"
  dl ready-space-weather.html "$RG/space-weather"
  dl ready-get-tech-ready.html "$RG/get-tech-ready"
  dl eia-measuring.html "$EIA/electricity/measuring-electricity.php"
  dl eia-batteries.html "$EIA/electricity/batteries-circuits-and-transformers.php"
  dl eia-pv.html "$EIA/solar/photovoltaics-and-electricity.php"
  dl doe-pv-basics.html "$DOE/systems/solar-photovoltaic-technology-basics"
  dl doe-pv-design.html "$DOE/systems/solar-photovoltaic-system-design-basics"
  dl doe-storage.html "$DOE/systems/solar-integration-solar-energy-and-storage-basics"
  dl doe-wind-how.html "$DOE/systems/how-do-wind-turbines-work"
  dl doe-hydro-how.html "$DOE/water/how-hydropower-works"
  dl doe-hydro-types.html "$DOE/water/types-hydropower-plants"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# usfa_slice SRC OUT: USFA pages have no <main>; keep the content column
# (side navigation and the "More resources" aside are outside it).
cat > "$TMP/usfa_slice.py" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read()
i = s.index('<div class="col-12 col-lg-9'); j = s.index('<aside id="aside"', i)
open(sys.argv[2], "w", encoding="utf-8").write("<html><body><main>" + s[i:j] + "</main></body></html>")
PY

# eia_slice SRC OUT: EIA Energy Explained article body sits between
# "EE page content" comments; image carousels (licensed photos, charts,
# captions) are marked so extract_html drops them.
cat > "$TMP/eia_slice.py" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read()
i = s.index("<!--EE page content-->"); j = s.index("<!--end EE page content-->", i)
body = s[i:j].replace('class="article-image"', 'class="sidebar article-image"')
open(sys.argv[2], "w", encoding="utf-8").write("<html><body><main>" + body + "</main></body></html>")
PY

# doe_prep SRC OUT: energy.gov (Drupal) markup fixes, markup only:
#  - class names containing "reference" trip extract_html's MediaWiki
#    "reference" drop marker (the whole article was dropped); renamed.
#  - related-page card lists and photo blocks (image, caption, credit) are
#    marked so extract_html drops them.
#  - USWDS accordions: titles in <button> become <h2>; accordion ul/li
#    become divs (otherwise every paragraph would become a bullet).
cat > "$TMP/doe_prep.py" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s = re.sub(r"([_-])reference", r"\1refx", s)
s = s.replace("paragraph--type--collection", "sidebar-collection")
s = s.replace("paragraph--type--media", "sidebar-media")
head, s, tail = s[:s.index("<main")], s[s.index("<main"):s.index("</main>")], s[s.index("</main>"):]
s = re.sub(r'<span class="usa-accordion__heading">\s*<button[^>]*>\s*(.*?)\s*</button>\s*</span>',
           r"<h2>\1</h2>", s, flags=re.S)
outp, pos, stack = [], 0, []
for m in re.finditer(r"<(/?)(ul|li)\b([^>]*)>", s):
    close, tag, attrs = m.group(1), m.group(2), m.group(3)
    outp.append(s[pos:m.start()]); pos = m.end()
    if not close:
        conv = (tag == "ul" and "usa-accordion" in attrs) or \
               (tag == "li" and bool(stack) and stack[-1] == ("ul", True))
        stack.append((tag, conv))
        outp.append(f"<div{attrs}>" if conv else m.group(0))
    else:
        conv = False
        for k in range(len(stack) - 1, -1, -1):
            if stack[k][0] == tag:
                conv = stack[k][1]; del stack[k:]; break
        outp.append("</div>" if conv else m.group(0))
outp.append(s[pos:])
open(sys.argv[2], "w", encoding="utf-8").write(head + "".join(outp) + tail)
PY

# post FILE [ops...]: chrome removal and formatting (see header).
#   drop=REGEX          delete lines matching REGEX
#   cut=START|END       delete from line matching START up to (not
#                       including) the line matching END (END may be EOF)
#   sub=REGEX|REPL      regex substitution on the whole text (headings only)
#   bullets             PDF bullet glyphs ("ĵ ", "o ") at line start -> "- "
#   rejoin              join a paragraph onto the previous one when the PDF
#                       text layer broke a sentence (previous paragraph does
#                       not end in . ! ? : and this one starts lowercase)
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
text = open(path, encoding="utf-8").read()
LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}
for op in ops:
    kind, _, arg = op.partition("=")
    lines = text.split("\n")
    if kind == "drop":
        r = re.compile(arg); lines = [l for l in lines if not r.search(l)]
    elif kind == "cut":
        start, end = arg.split("|")
        i = next(k for k, l in enumerate(lines) if re.search(start, l))
        j = len(lines) if end == "EOF" else next(
            k for k in range(i + 1, len(lines)) if re.search(end, lines[k]))
        del lines[i:j]
    elif kind == "sub":
        pat, repl = arg.split("|")
        new = re.sub(pat, repl, text, flags=re.M)
        if new == text: sys.exit(f"sub matched nothing: {pat}")
        lines = new.split("\n")
    elif kind == "bullets":
        lines = [re.sub(r"^(ĵ|o) ", "- ", l) for l in lines]
    elif kind == "rejoin":
        paras = re.split(r"\n\n+", "\n".join(lines))
        out = []
        for p in paras:
            if out and not out[-1].split("\n")[-1].startswith("#") and re.match(r"[a-z]", p) \
                    and not re.search(r"[.!?:]$", out[-1].rstrip()):
                out[-1] = out[-1].rstrip() + " " + p
            else:
                out.append(p)
        lines = "\n\n".join(out).split("\n")
    else:
        sys.exit(f"unknown op {op}")
    text = "\n".join(lines)
# A heading left with no text by chrome removal is dropped (build rejects it).
text = re.sub(r"^## [^\n]*\n\s*(?=## |\Z)", "", text, flags=re.M)
for a, b in LIG.items():
    text = text.replace(a, b)
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text))
PY
post() { python3 "$TMP/post.py" "$@"; }

usfa() {   # usfa <src-key> <url-path> <title> <out.md>
  python3 "$TMP/usfa_slice.py" "$SRC/usfa-$1.html" "$TMP/usfa-$1.html"
  $XH "$TMP/usfa-$1.html" --source-url "$USFA/$2" --title "$3" -o "$4" \
    --skip "Pictographs" "Handouts" "Videos" "Video"
}
updf() {   # updf <file> <title> <out.md>
  $XP "$SRC/usfa-$1.pdf" --source-url "$UPDF/$1.pdf" --title "$2" -o "$3"
  post "$3" bullets rejoin
}
eia() {    # eia <key> <url-path> <title> <out.md>
  python3 "$TMP/eia_slice.py" "$SRC/eia-$1.html" "$TMP/eia-$1.html"
  $XH "$TMP/eia-$1.html" --source-url "$EIA/$2" --title "$3" -o "$4"
  post "$4" 'drop=^Last updated:' 'drop=^Click to enlarge$'
}
DOE_CHROME='^(Subscribe to the .*|Sign up to receive the latest news.*|Home » .*)$'
doe() {    # doe <key> <url-path> <title> <out.md> [extract args...]
  local k=$1 p=$2 t=$3 o=$4; shift 4
  python3 "$TMP/doe_prep.py" "$SRC/doe-$k.html" "$TMP/doe-$k.html"
  $XH "$TMP/doe-$k.html" --source-url "$DOE/$p" --title "$t" -o "$o" "$@"
  post "$o" "drop=$DOE_CHROME"
}

D=content/10-power; mkdir -p $D
cat > $D/pack.json <<JSON
{
 "id": "power",
 "title": "Power & Electricity",
 "category": "guide",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. Fire Administration (FEMA), Ready.gov (FEMA), U.S. Food and Drug Administration, Federal Aviation Administration, U.S. Energy Information Administration, and U.S. Department of Energy",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105)",
 "attribution": "Text from U.S. Fire Administration web pages and handouts, Ready.gov (Federal Emergency Management Agency), FDA medical-device emergency pages, the FAA PackSafe lithium batteries page, EIA Energy Explained (Source: U.S. Energy Information Administration), and U.S. Department of Energy solar, wind and hydropower basics pages, retrieved October 2026; reformatted into sections without changing substance; photos and figures not included. Use does not imply endorsement by USFA, FEMA, DHS, FDA, FAA, EIA, DOE, or the U.S. Government.",
 "description": "Generator, carbon monoxide and electrical fire safety; lithium-ion battery safety (charging, storage, flooding, travel); keeping medical devices and phones powered in outages; space weather and the grid; watts and watthours; how batteries, solar PV, storage, inverters, wind turbines and hydropower work."
}
JSON

# --- Safety: generators, carbon monoxide, electrical fires ---------------
# USFA pages: "Did you know" boxes cite CPSC / NFIRS / NFPA statistics as
# their source (facts attributed, no reproduced third-party text).
usfa carbon-monoxide prevention/life-safety-hazards/carbon-monoxide/ \
  "Carbon Monoxide Safety (U.S. Fire Administration)" $D/01-carbon-monoxide.md
updf portable_generators_winter_storms_flyer \
  "Portable Generators and Winter Storms (U.S. Fire Administration)" $D/02-generators-winter-storms.md
post $D/02-generators-winter-storms.md 'drop=^\*\*Winter Fire Safety\*\*$' 'drop=^For more information and free resources'
usfa severe-weather prevention/home-fires/prevent-fires/severe-weather/ \
  "Fire Hazards During Severe Weather: Generators, Downed Lines and Outages (U.S. Fire Administration)" $D/03-severe-weather-fire-hazards.md
usfa appliance-and-electrical prevention/home-fires/prevent-fires/appliance-and-electrical/ \
  "Appliance and Electrical Fire Safety: Outlets, Extension Cords and Power Strips (U.S. Fire Administration)" $D/04-appliance-electrical-fire-safety.md
updf prevent_home_electrical_fires_flyer \
  "Prevent Home Electrical Fires (U.S. Fire Administration)" $D/05-prevent-electrical-fires.md
post $D/05-prevent-electrical-fires.md 'sub=^## Did you know\?$|## Prevent Home Electrical Fires' \
  'drop=^\*\*Prevent Home Electrical Fires\*\*$' 'drop=^For more information and free fire-safety'

# --- Batteries --------------------------------------------------------------
usfa batteries prevention/home-fires/prevent-fires/batteries/ \
  "Lithium-Ion and Other Battery Fire Safety (U.S. Fire Administration)" $D/06-battery-fire-safety.md
updf lithium-ion-battery-safety-handout \
  "Lithium-Ion Battery Safety for Electronic Devices (U.S. Fire Administration)" $D/07-lithium-ion-device-safety.md
post $D/07-lithium-ion-device-safety.md 'drop=^\*\*Lithium-Ion Battery Safety for Electronic Devices\*\*$' \
  'cut=^## .*To learn more, visit|EOF'
updf lithium-ion-battery-after-flooding-handout \
  "Lithium-Ion Battery Safety After Flooding (U.S. Fire Administration)" $D/08-lithium-ion-after-flooding.md
post $D/08-lithium-ion-after-flooding.md \
  'sub=^## Lithium-Ion Battery Safety After Flooding: It is important to properly dispose of flood\ndamaged lithium-ion powered products\.$|## Disposing of Flood-Damaged Lithium-Ion Products\n\nIt is important to properly dispose of flood damaged lithium-ion powered products.'
$XH "$SRC/faa-lithium.html" --source-url "$FAA_URL" \
  --title "Lithium Batteries: Thermal Runaway, Spares and Terminal Protection (FAA PackSafe)" -o $D/09-faa-lithium-batteries.md
post $D/09-faa-lithium-batteries.md 'drop=^For additional information, view our'

# --- Medical devices, phones and outages -----------------------------------
# FDA page: its sub-headings are mis-nested under the generator heading in
# the markup; restored as their own sections. The in-page jump list and the
# "Additional Information" link list are dropped.
$XH "$SRC/fda-devices.html" --source-url "$FDA/fda-offers-tips-about-medical-devices-and-natural-disasters" \
  --title "Medical Devices in Power Outages and Natural Disasters (FDA)" -o $D/10-fda-medical-devices.md \
  --skip "Special Information about Using Blood Glucose Meters: Additional Information"
post $D/10-fda-medical-devices.md 'cut=^## Overview$|^## General Safety$' \
  'sub=^## Warning about Potential Carbon Monoxide Problems when Using Generators: |## ' \
  'sub=^## Special Information about Using Blood Glucose Meters: Additional Information\n(- .*\n?)*|'
# Refrigeration page: only the general power-out / power-restored advice and
# laboratory reagents / glucose meter notes; the clinical product list
# (dialysis, sterilants, implants, named brands) from "Dialysis" on is not
# taken.
$XH "$SRC/fda-refrig.html" --source-url "$FDA/medical-devices-requiring-refrigeration" \
  --title "Medical Devices Requiring Refrigeration During a Power Outage (FDA)" -o $D/11-fda-refrigerated-devices.md \
  --drop-after "Dialysis"
$XH "$SRC/ready-space-weather.html" --source-url "$RG/space-weather" \
  --title "Space Weather and Power Grid Outages (Ready.gov)" -o $D/12-space-weather.md
post $D/12-space-weather.md 'drop=^If you are a disaster survivor, please visit FEMA.gov' 'drop=^(Return to top|Back to top)$'
$XH "$SRC/ready-get-tech-ready.html" --source-url "$RG/get-tech-ready" \
  --title "Get Tech Ready: Keeping Phones and Devices Powered (Ready.gov)" -o $D/13-get-tech-ready.md
post $D/13-get-tech-ready.md 'drop=^If you are a disaster survivor, please visit FEMA.gov' 'drop=^(Return to top|Back to top)$'

# --- Electricity basics, solar, storage, wind, hydro ------------------------
eia measuring electricity/measuring-electricity.php \
  "Measuring Electricity: Watts, Kilowatts and Watthours (EIA)" $D/14-measuring-electricity.md
eia batteries electricity/batteries-circuits-and-transformers.php \
  "Batteries, Circuits, and Transformers (EIA)" $D/15-batteries-circuits.md
eia pv solar/photovoltaics-and-electricity.php \
  "Photovoltaics and Electricity (EIA)" $D/16-photovoltaics.md
doe pv-basics systems/solar-photovoltaic-technology-basics \
  "Solar Photovoltaic Technology Basics (DOE)" $D/17-solar-pv-basics.md --skip "Learn More" "Photovoltaic Technology Basics"
doe pv-design systems/solar-photovoltaic-system-design-basics \
  "Solar Photovoltaic System Design Basics: Mounting, Inverters and Storage (DOE)" $D/18-solar-pv-system-design.md
post $D/18-solar-pv-system-design.md 'cut=^\*\*Additional Information\*\*$|EOF'
doe storage systems/solar-integration-solar-energy-and-storage-basics \
  "Solar Energy and Storage Basics (DOE)" $D/19-solar-and-storage.md --skip "Additional Information"
post $D/19-solar-and-storage.md 'drop=^The AES Lawai Solar Project in Kauai' 'drop=^National Renewable Energy Laboratory$' \
  'cut=^## Additional Information|EOF'
doe wind-how systems/how-do-wind-turbines-work \
  "How Do Wind Turbines Work? (DOE)" $D/20-wind-turbines.md --skip "Learn More"
post $D/20-wind-turbines.md 'drop=^Click on the link below to see how a wind turbine works\.$' \
  'drop=^Dennis Schroeder \| NLR' 'sub=^## Explore A Wind Turbine$|## How Wind Turbines Make Electricity'
doe hydro-how water/how-hydropower-works \
  "How Hydropower Works (DOE)" $D/21-hydropower.md --skip "Hydropower News"
doe hydro-types water/types-hydropower-plants \
  "Types and Sizes of Hydropower Plants, Including Micro Hydropower (DOE)" $D/22-hydropower-types.md --skip "Hydropower News"
for f in $D/21-hydropower.md $D/22-hydropower-types.md; do
  post $f 'cut=^\*\*LEARN MORE\*\*$|^## '
done
post $D/22-hydropower-types.md 'sub=^## Overview: |## '

echo "batch4_power: done"
