#!/usr/bin/env bash
# Batch 4 (wilderness area): signaling for rescue, sea/water survival, lost
# in the woods + more wildlife, storm shelter, and solar water disinfection.
#
# Usage: tools/packs/recipes/batch4_wilderness.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-29. Run from the project root; then build each pack with
#   python3 tools/packs/build_pack.py content/<pack-dir>
#
# Everything here is a U.S. Government work (17 U.S.C. § 105) except the
# SODIS manual (explicit copy/adapt grant, quoted below). Every page/PDF was
# scanned for "©", "copyright", "courtesy", "permission", "reprinted";
# third-party portions are excluded as noted per source. Text is verbatim.
# Post-processing (post() below) only removes page chrome and photo captions,
# promotes existing lines to "## " headings (where the PDF heading style was
# not detected), normalizes ligatures (ﬁ→fi) and the minus sign used as a
# hyphen in the FAA AIM ("6−2−4" → "6-2-4", so search matches), and cuts
# held-back tables/diagrams with a bracketed "not included" marker.
#
# NOT FILLED (see report): ATP 3-50.21 has no signaling chapter (ch. 1-8 +
# App. A are all already shipped; signaling moved to ATP 3-50.3/3-50.22,
# which are not public on armypubs — CAC-only). FEMA P-320 and FCC/FEMA
# ham-radio pages: fema.gov and fcc.gov return 403 to scripts. AFH 10-644,
# NETC P1552, marines.mil, DTIC, uscg.mil/navcen: 403. CDC mosquito pages:
# 403. GTA 05-02-013: only on the CAC-protected Central Army Registry.
# USAP Field Manual: written by the Antarctic Support Contract (a
# contractor), no public-domain statement, NSF's own photos are CC BY-NC-ND
# — not cleared. Aids to Survival (WA Police): no copy on police.wa.gov.au /
# wa.gov.au, only mirrors — skipped (content/16d-aids-to-survival not made).
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
XH="python3 tools/packs/extract_html.py"

AIM_URL="https://www.faa.gov/air_traffic/publications/media/AIM_Basic_w_Chg_1_and_2_and_3_dtd_7-9-26_FINAL.pdf"
USCG_URL="https://www.uscgboating.org/assets/1/AssetManager/Boaters-Guide-to-Federal-Requirements-for-Receational-Boats-20231108.pdf"
SODIS_URL="https://www.eawag.ch/fileadmin/Domain1/Abteilungen/sandec/publikationen/SWP/SODIS_manual_2016.pdf"
SARSAT=https://www.sarsat.noaa.gov
NWS=https://www.weather.gov
NPS=https://www.nps.gov
HTML_PAGES="
sarsat-beacons=$SARSAT/emergency-406-beacons/
sarsat-false=$SARSAT/preventing-false-alerts/
sarsat-faqs=$SARSAT/faqs/
nws-skywarn=$NWS/skywarn/
nws-coldwater=$NWS/safety/coldwater
nos-ripcurrent=https://oceanservice.noaa.gov/facts/ripcurrent.html
nps-sharks=$NPS/articles/sharkawareness.htm
nps-emergencyplan=$NPS/articles/gtgemergencyplan.htm
usfs-lost=https://www.fs.usda.gov/visit/know-before-you-go/if-you-get-lost
nps-10essentials=$NPS/articles/10essentials.htm
nps-lion=$NPS/articles/mountain-lion-safety.htm
nps-moose=$NPS/wrst/planyourvisit/moose-safety.htm
nps-bicy-safety=$NPS/bicy/planyourvisit/safety.htm
nps-ever-safety=$NPS/ever/planyourvisit/safety.htm
spc-safety=https://www.spc.noaa.gov/faq/tornado/safety.html
nws-tornado-prepare=$NWS/safety/tornado-prepare
nws-tornado-ww=$NWS/safety/tornado-ww"
url_of() { printf '%s\n' $HTML_PAGES | grep "^$1=" | cut -d= -f2-; }

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for kv in $HTML_PAGES; do dl "${kv%%=*}.html" "${kv#*=}"; done
  dl aim.pdf "$AIM_URL"
  dl uscg-boaters-guide.pdf "$USCG_URL"
  dl sodis-manual-2016.pdf "$SODIS_URL"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# slice SRC START END OUT: wrap the article part of a page that has no
# <main> in <main>. USWDS accordion headings are <button>s (which
# extract_html.py drops as chrome), so the button tags are unwrapped and
# their text stays as the heading it already is.
cat > "$TMP/slice.py" <<'PY'
import re, sys
src, start, end, out = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
i = s.index(start); j = s.index(end, i)
s = re.sub(r'<button[^>]*usa-accordion__button[^>]*>(.*?)</button>', r'\1', s[i:j], flags=re.S)
open(out, "w", encoding="utf-8").write("<html><body><main>" + s + "</main></body></html>")
PY
slice() { python3 "$TMP/slice.py" "$@"; }

# post FILE [ops...]
#   drop=REGEX          delete lines matching REGEX
#   plus                strip accordion "+" from "## +Heading" / "## A: +B"
#   h2=REGEX            lines matching REGEX become "## " headings
#   sub=OLD|NEW         literal replacement, \n = newline (heading fixes only)
#   cut=START|END|NOTE  delete from line matching START up to (not incl.)
#                       line matching END; insert NOTE
#   cutend=START|NOTE   delete from line matching START to the end
#   lead=REGEX          paragraphs whose start matches REGEX get a "## " +
#                       group(1) heading inserted before them (text kept)
#   keepfrom=REGEX      delete body lines before the line matching REGEX
#                       (keeps the "# title" and "Source:" header)
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
text = open(path, encoding="utf-8").read()
for a, b in {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl", "−": "-"}.items():
    text = text.replace(a, b)
lines = text.split("\n")
for op in ops:
    kind, _, arg = op.partition("=")
    if kind == "drop":
        r = re.compile(arg); lines = [l for l in lines if not r.search(l)]
    elif kind == "plus":
        lines = [re.sub(r"^(## (?:.*: )?)\+", r"\1", l) for l in lines]
    elif kind == "h2":
        r = re.compile(arg)
        lines = [("## " + l.lstrip("#* ").rstrip("* ")) if r.search(l) and not l.startswith("# ") else l for l in lines]
    elif kind == "sub":
        old, new = (x.replace("\\n", "\n") for x in arg.split("|"))
        t = "\n".join(lines)
        if old not in t:
            sys.exit(f"{path}: sub target not found: {old!r}")
        lines = t.replace(old, new).split("\n")
    elif kind == "cut":
        start, end, note = arg.split("|")
        i = next(k for k, l in enumerate(lines) if re.search(start, l))
        j = next(k for k in range(i + 1, len(lines)) if re.search(end, lines[k]))
        lines[i:j] = ([note, ""] if note else [])
    elif kind == "cutend":
        start, note = arg.split("|")
        i = next(k for k, l in enumerate(lines) if re.search(start, l))
        lines[i:] = ([note, ""] if note else [])
    elif kind == "lead":
        # A paragraph that opens with "Label:" gets "## Label" before it.
        r = re.compile(arg); out = []
        for l in lines:
            m = r.match(l)
            if m:
                out += ["## " + m.group(1), ""]
            out.append(l)
        lines = out
    elif kind == "keepfrom":
        i = next(k for k, l in enumerate(lines) if k > 1 and re.search(arg, l))
        lines[3:i] = []
    else:
        sys.exit(f"unknown op {op}")
text = "\n".join(lines)
text = re.sub(r"^## [^\n]*\n\s*(?=## |\Z)", "", text, flags=re.M)  # empty sections
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n")
PY
post() { python3 "$TMP/post.py" "$@"; }

nps() {  # nps <key> <title> <out.md> [post ops...]
  local k=$1 t=$2 o=$3; shift 3
  slice "$SRC/$k.html" '<div id="main"' 'Last updated' "$TMP/$k.html"
  $XH "$TMP/$k.html" --source-url "$(url_of $k)" --title "$t" -o "$o" --skip "You Might Also Like"
  post "$o" 'drop=^Loading results\.\.\.$' 'drop=^Tags: ' 'drop=^The requested video is no longer available\.$' "$@"
}
nws() {  # nws <key> <title> <out.md> [post ops...]  (NWS_START overrides start marker)
  local k=$1 t=$2 o=$3; shift 3
  slice "$SRC/$k.html" "${NWS_START:-<div class=\"cms-content\">}" '<div class="footer">' "$TMP/$k.html"
  $XH "$TMP/$k.html" --source-url "$(url_of $k)" --title "$t" -o "$o"
  post "$o" plus "$@"
}
sarsat() {  # sarsat <key> <title> <out.md> [extract args...]
  local k=$1 t=$2 o=$3; shift 3
  slice "$SRC/$k.html" '<div class="entry-content"' '<footer' "$TMP/$k.html"
  $XH "$TMP/$k.html" --source-url "$(url_of $k)" --title "$t" -o "$o" "$@"
  # Photo/illustration credits (images are Cospas-Sarsat's, not used) and
  # image-viewer chrome.
  post "$o" 'drop=(?i)^(photo|image|images|illustration|photo sequence) courtesy' \
    'drop=^Click image to zoom$' 'drop=^T$'
}

# =========================================================================
# 13b-signaling (verified): signaling for rescue.
# - FAA Aeronautical Information Manual (AIM) ch. 6 sec. 2, pages 489-503 of
#   the Basic w/ Change 1-3 PDF (7/9/26): ELTs, search and rescue, survival
#   equipment, body signals, ground-air visual code. FAA work, no notices.
#   6-2-5 (K-9 explosives detection teams) is cut — not survival content.
#   Held back: TBL 6-2-2..6-2-5 (rescue coordination center phone numbers;
#   commercial/DSN columns scrambled), replaced by a marker.
#   AIM captions ("FIG 6-2-1" above the figure) don't match
#   extract_figures.py, so capfig.py (below) renders them; all 17 crops
#   reviewed by eye on a contact sheet (fig 6-2-1 instructions legible).
# - USCG "A Boater's Guide to the Federal Requirements for Recreational
#   Boats" (Nov 2023, uscgboating.org, USCG Boating Safety Division):
#   pp. 16-19 visual distress signals; pp. 44-47 EPIRBs/SARSAT, VHF
#   radio, DSC, MAYDAY. Only "courtesy" hit is "courtesy examination".
# - NOAA SARSAT pages (406 MHz beacons, false alerts, FAQ): NOAA text; the
#   pages' photos/illustrations are credited to Cospas-Sarsat/DVIDS and are
#   not used (credit lines removed).
# - NWS SKYWARN page (volunteer spotter / reporting network). The site's
#   ® trademark notice is kept; the NWS-ARRL MOU link is not followed.
# Not filled: signal mirror / fire-smoke signal technique (no public Army
# source: ATP 3-50.3 and 3-50.22 are CAC-only), ham radio getting-started
# (fcc.gov and fema.gov 403; ARRL not permitted).
# =========================================================================
D=content/13b-signaling; mkdir -p $D
# capfig.py PDF --pages A-B --out DIR: figure index for caption-above
# "FIG n-n-n" figures, same index.json format as extract_figures.py.
cat > "$TMP/capfig.py" <<'PY'
import argparse, json, os, re
import pypdfium2 as pdfium
from pdfminer.high_level import extract_pages
from pdfminer.layout import LAParams, LTTextBox, LTCurve, LTLine, LTRect, LTFigure, LTImage
CAP = re.compile(r"^\s*FIG\s+(\d+)[−\-](\d+)[−\-](\d+)\s*$")
def walk(o):
    yield o
    if hasattr(o, "__iter__") and not isinstance(o, LTTextBox):
        for c in o:
            yield from walk(c)
ap = argparse.ArgumentParser()
ap.add_argument("pdf"); ap.add_argument("--pages", required=True)
ap.add_argument("--out", required=True); ap.add_argument("--dpi", type=int, default=200)
a = ap.parse_args()
lo, _, hi = a.pages.partition("-"); pages = list(range(int(lo) - 1, int(hi or lo)))
os.makedirs(a.out, exist_ok=True)
pdf = pdfium.PdfDocument(a.pdf)
index = []
for pno, layout in zip(pages, extract_pages(a.pdf, page_numbers=pages, laparams=LAParams())):
    H, W = layout.height, layout.width
    foot, head = H * 0.08, H * 0.92
    objs = [o for o in walk(layout) if o is not layout
            and isinstance(o, (LTTextBox, LTCurve, LTLine, LTRect, LTFigure, LTImage))
            and o.y0 > foot and o.y1 < head]
    caps = []
    for t in (o for o in objs if isinstance(o, LTTextBox)):
        lines = t.get_text().strip().split("\n")
        m = CAP.match(lines[0])
        if m:
            caps.append((t, "-".join(m.groups()), " ".join(lines[1:2]).strip()))
    caps.sort(key=lambda c: -c[0].y1)
    for k, (t, num, title) in enumerate(caps):
        top = t.y1
        limit = caps[k + 1][0].y1 + 2 if k + 1 < len(caps) else foot
        inside = [o for o in objs if o.y1 <= top + 1 and o.y0 >= limit - 1]
        if not title:
            nxt = [o for o in inside if isinstance(o, LTTextBox) and o is not t and o.y1 <= t.y0 + 1]
            title = max(nxt, key=lambda o: o.y1).get_text().strip().split("\n")[0] if nxt else ""
        title = title.replace("−", "-")
        y0, y1 = min(o.y0 for o in inside) - 6, top + 6
        x0, x1 = max(0, min(o.x0 for o in inside) - 6), min(W, max(o.x1 for o in inside) + 6)
        page = pdf[pno]; w, h = page.get_size()
        bmp = page.render(scale=a.dpi / 72, crop=(x0, y0, w - x1, h - y1), grayscale=True)
        name = f"fig-{num}.webp"
        bmp.to_pil().save(os.path.join(a.out, name), "WEBP", quality=70)
        index.append({"file": name, "caption": f"Figure {num}. {title}", "kind": "figure",
                      "page": pno + 1, "bbox": [round(x0, 1), round(y0, 1), round(x1, 1), round(y1, 1)]})
json.dump(index, open(os.path.join(a.out, "index.json"), "w"), indent=1)
print(f"{len(index)} images -> {a.out}")
PY
rm -rf $D/images/01-aim-search-rescue
$PY "$TMP/capfig.py" "$SRC/aim.pdf" --pages 495-503 --out $D/images/01-aim-search-rescue
$XP "$SRC/aim.pdf" --pages 489-503 --figures $D/images/01-aim-search-rescue --bold-headings \
  --source-url "$AIM_URL" -o $D/01-aim-search-rescue.md \
  --title "Emergency Locator Transmitters, Search and Rescue, and Ground-Air Signals (FAA AIM 6-2)"
post $D/01-aim-search-rescue.md 'keepfrom=^## 6-2-4\.' \
  'cut=^## 6-2-5\. FAA K-9|^## 6-2-6\. Search and Rescue|' 'drop=^## L L L$' \
  'sub=## REFERENCE-\n14 CFR SECTION 91.207.|REFERENCE- 14 CFR SECTION 91.207.' \
  'cut=^## Coast Guard Rescue Coordination Centers$|^f\. Emergency and Overdue Aircraft\.$|[Tables 6-2-2 to 6-2-5 (Coast Guard, Air Force and Joint Rescue Coordination Center phone numbers) not included: the table layout was not preserved; see the original document.]' \
  'sub=f. Emergency and Overdue Aircraft.|## 6-2-6. Search and Rescue: Emergency and Overdue Aircraft\n\nf. Emergency and Overdue Aircraft.' \
  'sub=i. Body Signal Illustrations.|## 6-2-6. Search and Rescue: Body Signals and Ground-Air Visual Code\n\ni. Body Signal Illustrations.'

$XP "$SRC/uscg-boaters-guide.pdf" --pages 16-19 --bold-headings --source-url "$USCG_URL" \
  --title "Visual Distress Signals: Flares, Smoke, Distress Flag and Lights (USCG Boater's Guide)" \
  -o $D/02-uscg-visual-distress.md
post $D/02-uscg-visual-distress.md 'sub=## Overview|## Visual Distress Signals' \
  'h2=^(Pyrotechnic Devices|Non-Pyrotechnic Devices)$'
$XP "$SRC/uscg-boaters-guide.pdf" --pages 44-47 --bold-headings --source-url "$USCG_URL" \
  --title "EPIRBs, VHF Radio and MAYDAY Calls (USCG Boater's Guide)" -o $D/03-uscg-radio-mayday.md
post $D/03-uscg-radio-mayday.md 'keepfrom=^## SARSAT'

sarsat sarsat-beacons "406 MHz Emergency Beacons: PLBs, EPIRBs and ELTs (NOAA SARSAT)" $D/04-sarsat-beacons.md
sarsat sarsat-false "Preventing False Beacon Alerts (NOAA SARSAT)" $D/05-sarsat-false-alerts.md
post $D/05-sarsat-false-alerts.md 'drop=^- SARSAT Inadvertent Activation Poster'
# FAQ: only the beacon, registration and return-link sections (program
# administration, satellites, ground stations and USMCC are cut).
sarsat sarsat-faqs "Emergency Beacon FAQs (NOAA SARSAT)" $D/06-sarsat-faqs.md
post $D/06-sarsat-faqs.md 'cut=^## Overview$|^## 406 MHz EMERGENCY BEACONS$|' \
  'cut=^## SATELLITES$|^## BEACON REGISTRATION$|' 'drop=^\.$'
NWS_START='id="home_page_content"' nws nws-skywarn "SKYWARN Storm Spotter Program (NWS)" $D/07-skywarn.md \
  'drop=^id="home_page_content">$' 'sub=## Overview|## SKYWARN: volunteer severe weather spotters'

# =========================================================================
# 16c-sea-survival (verified): USCG Boater's Guide (life jackets pp. 12-14;
# safety and survival tips pp. 38-44: capsizing, staying afloat, cold-water
# survival, life rafts, severe weather), NWS cold water page, NOAA Ocean
# Service rip current fact page, NPS shark awareness.
# Excluded third-party: NWS cold-water page's rewarming steps "developed by
# the Red Cross" (Red Cross content is not licensed for us); its image
# captions (H.E.L.P., Huddle position) dropped.
# Held back: life jacket label diagram (p. 15; graphic labels scramble).
# NWS rip current pages are link lists/infographics (no text to extract).
# Not filled: life-raft survival at sea manuals (AFH 10-644, Navy NETC
# P1552, MCRP water survival — every .mil/DTIC host returned 403).
# =========================================================================
D=content/16c-sea-survival; mkdir -p $D
$XP "$SRC/uscg-boaters-guide.pdf" --pages 12-14 --bold-headings --source-url "$USCG_URL" \
  --title "Life Jackets (PFDs) and Engine Cut-Off Switches (USCG Boater's Guide)" -o $D/01-uscg-life-jackets.md
post $D/01-uscg-life-jackets.md 'keepfrom=^## Equipment Requirements' \
  'h2=^Personal Flotation Devices \(33 CFR 175\)|^(Stowage|Child Life Jacket Requirements|Inflatable Life Jackets)$' \
  'sub=## Personal Flotation Devices (33 CFR 175) https|## Personal Flotation Devices (33 CFR 175)\n\nhttps'
$XP "$SRC/uscg-boaters-guide.pdf" --pages 38-44 --bold-headings --source-url "$USCG_URL" \
  --title "Boating Safety and Survival Tips: Capsizing, Cold Water, Life Rafts, Severe Weather (USCG Boater's Guide)" \
  -o $D/02-uscg-survival-tips.md
post $D/02-uscg-survival-tips.md 'keepfrom=^## Boat Operator Training' \
  'h2=^(Safe Loading \(33 CFR 183, subpart C\)|Maritime Telecommunications|Life Rafts|EPIRBs and PLBs|Immersion Suits|Determining Your Location|Staying Afloat|Cold-Water Survival|Cold-Related Injury|Fuel Management|What to Do in Severe Weather)$' \
  'cutend=^## SARSAT|'
nws nws-coldwater "Cold Water Can Be Dangerous: Cold Shock and Hypothermia (NWS)" $D/03-cold-water.md \
  'drop=^Surf/Rip Resources$' 'cutend=^## .*Resources, Links and Partner Information|' \
  'drop=^(H\.E\.L\.P\.|Huddle position)$' \
  'cutend=developed by the Red Cross|[Rewarming steps credited by NWS to the Red Cross are not included (third-party content).]'
python3 "$TMP/slice.py" "$SRC/nos-ripcurrent.html" '<h1' 'id="footer-main"' "$TMP/nos-ripcurrent.html"
$XH "$TMP/nos-ripcurrent.html" --source-url "$(url_of nos-ripcurrent)" \
  --title "What Is a Rip Current? (NOAA National Ocean Service)" -o $D/04-rip-currents.md
post $D/04-rip-currents.md 'drop=^(More Information|Get Social|Last updated:|[0-9/]+|Author: NOAA|How to cite this article)$'
nps nps-sharks "Shark Awareness (National Park Service)" $D/05-sharks.md \
  'sub=## Overview|## Reducing the chance of a shark encounter'

# =========================================================================
# 16b-wilderness-more (verified): lost in the woods and more wildlife.
# NPS Outdoor Emergency Plan (lost/injured, whistle/SOS/mirror signals),
# USFS "If you get lost", NPS Ten Essentials (NPS text; its footnote credits
# the system to The Mountaineers — kept as attribution, no book text used),
# NPS mountain lion, moose (Wrangell-St. Elias), Big Cypress and Everglades
# safety (alligators, panthers, snakes, mosquitoes, lost signals). Pages
# carry only "NPS Photo" banner credits (images not used).
# Not filled: CDC mosquito-bite prevention (cdc.gov 403); FWS/NOAA alligator
# and shark pages with procedure text were not found beyond the NPS ones.
# =========================================================================
D=content/16b-wilderness-more; mkdir -p $D
nps nps-emergencyplan "Outdoor Emergency Plan: If You Get Lost or Injured (National Park Service)" $D/01-outdoor-emergency-plan.md \
  'drop=^Want to learn more\? Learn how to become a Junior Ranger' 'h2=^\*\*[^*]+\*\*$'
python3 "$TMP/slice.py" "$SRC/usfs-lost.html" '<main' '</main>' "$TMP/usfs-lost.html"
$XH "$TMP/usfs-lost.html" --source-url "$(url_of usfs-lost)" --title "If You Get Lost (USDA Forest Service)" -o $D/02-usfs-if-you-get-lost.md
post $D/02-usfs-if-you-get-lost.md 'sub=## Overview|## If you get lost: plan, stop, think, observe, plan'
nps nps-10essentials "The Ten Essentials (National Park Service)" $D/03-ten-essentials.md \
  'drop=^Watch this video on the Ten Essentials!$' 'drop=^Tags: '
nps nps-lion "Mountain Lion Safety (National Park Service)" $D/04-mountain-lions.md
nps nps-moose "Moose Safety (National Park Service, Wrangell-St. Elias)" $D/05-moose.md \
  'sub=## Overview|## Moose Safety'
nps nps-bicy-safety "Swamp and Subtropical Backcountry Safety: Alligators, Panthers, Snakes (National Park Service, Big Cypress)" \
  $D/06-big-cypress-safety.md 'drop=^Click here for a short video' 'h2=^\*\*[^*]+\*\*$'
nps nps-ever-safety "Everglades Safety: Alligators, Crocodiles, Mosquitoes (National Park Service)" $D/07-everglades-safety.md \
  'cutend=^## Warning - Vultures May Damage Vehicles$|' \
  'drop=^Learn more about (outdoor activities|bringing pets)' 'drop=^Additional information on Zika$' \
  'h2=^(Physical fitness and Weather|Local Knowledge of Terrain|For Outdoor Activities Preparations|Supervise Small Children|Pets|Do Not Feed Wildlife|Mosquitoes|Alligators and Crocodiles|Poisonous Plants)$'

# =========================================================================
# 03b-storm-shelter (verified): where to shelter from a tornado by building
# type (NOAA Storm Prediction Center tornado FAQ, Roger Edwards, SPC — a
# federal employee's work), NWS tornado preparation and watch/warning pages.
# Not filled: FEMA P-320 safe room guide (fema.gov 403). A 2014 4th-edition
# copy exists at weather.gov/media/bis/FEMA_P-320_2014_508.pdf (federal
# rehost of a superseded edition) — not used per the original-source rule.
# =========================================================================
D=content/03b-storm-shelter; mkdir -p $D
$XH "$SRC/spc-safety.html" --container body --source-url "$(url_of spc-safety)" \
  --title "Tornado Safety: Where to Shelter in Homes, Mobile Homes, Vehicles and Buildings (NOAA Storm Prediction Center)" \
  -o $D/01-spc-tornado-safety.md
post $D/01-spc-tornado-safety.md 'drop=^(Tornado Safety \(Online Tornado FAQ\)|Tornado Safety|Roger Edwards|Storm Prediction Center|Norman, Oklahoma)$' \
  'drop=^TRANSLATIONS:' 'drop=^(Back to Tornado FAQ|SPC Home Page)$' \
  'sub=## Roger Edwards|## Tornado safety' 'h2=^\*\*[^*]+\*\*$' \
  'lead=^(Prevention and practice before the storm|Know the signs of a tornado|In a house with a basement|In a house with no basement, a dorm, or an apartment|In an office building, hospital, nursing home or skyscraper|In a mobile or manufactured home|At school|In a car or truck|In the open outdoors|In a shopping mall or large store|In a church or theater): ?'
nws nws-tornado-prepare "Prepare for a Tornado: Plans and Safe Rooms (NWS)" $D/02-nws-tornado-prepare.md \
  'drop=^Tornadoes, Wind, Hail$' 'sub=## Overview|## Prepare for a tornado'
nws nws-tornado-ww "Tornado Watch, Warning and Emergency: What to Do (NWS)" $D/03-nws-tornado-alerts.md \
  'drop=^Tornadoes, Wind, Hail$' 'sub=## Overview|## Tornado watch, warning and emergency'

# =========================================================================
# 04c-sodis (needs-review; non-U.S. publisher): Eawag/Sandec "SODIS manual:
# Guidance on solar water disinfection" (January 2016), downloaded from
# eawag.ch. Grant (p. 2): "Copyright: This document is an open-source
# document – copying and adapting is allowed provided that proper
# acknowledgement of the source is made." Photos: "All photos are from
# Sandec if not mentioned otherwise. Photos from Bolivia are from Fundación
# SODIS" — no photos are used; photo captions are removed.
# Kept: 1.1 the method (pp. 8-9), 2.2.3-2.2.8 practical factors (pp. 20-23),
# 2.4 application rules (pp. 26-27). Skipped: pathogen/irradiation data
# tables (Tables 1-7, captions "Table N:" are not detected as tables and
# their cells scramble), history, promotion/behaviour-change chapter 3.
# The Safe Water School Training Manual (2nd ed., 2014; grant: "Any part of
# this handbook may be cited, copied, translated ... or adapted ... without
# prior permission from SODIS or Antenna provided the source is clearly
# mentioned") is a school-lesson curriculum; not used.
# =========================================================================
D=content/04c-sodis; mkdir -p $D
SODIS_DROP=('drop=^(Children in Nepal drinking SODIS water|SODIS bottles in (India|Cameroun)|Family applying SODIS in Laos|Estimating the water turbidity|Application of SODIS in India|Mother and child in Cameroun)$' \
  'drop=^Figure [0-9]+: ' 'drop=^Source: \(' 'drop=^Table [0-9]+: ')
$XP "$SRC/sodis-manual-2016.pdf" --pages 8-9 --bold-headings --source-url "$SODIS_URL" \
  --title "SODIS: The Solar Water Disinfection Method at a Glance (Eawag SODIS Manual 1.1)" -o $D/01-sodis-method.md
post $D/01-sodis-method.md "${SODIS_DROP[@]}" 'drop=^\*\*(1 )?SODIS at a glance\*\*$' \
  'sub=## 1.1 The SODIS method: Specific comparative|## Specific comparative' 'cutend=^## 1\.2 Niche|'
rm -rf $D/images/02-sodis-factors
$XP "$SRC/sodis-manual-2016.pdf" --pages 20-23 --figures auto --bold-headings --source-url "$SODIS_URL" \
  --title "SODIS: Bottle Placement, Bottles, Turbidity, Temperature and Re-growth (Eawag SODIS Manual 2.2.3-2.2.8)" \
  -o $D/02-sodis-factors.md
# Figure 5 is reproduced from Sommer et al. 1997 (third-party graph): its
# image is dropped and not shipped; the paragraphs are kept.
# The two-column layout puts the 2.2.7 heading after 2.2.8's; headings are
# moved back to the paragraphs they belong to (text unchanged).
post $D/02-sodis-factors.md "${SODIS_DROP[@]}" 'drop=^!\[Figure 5\.' \
  'sub=## 2.2.8 Re-growth\n**2.2.7 Water temperature**|## 2.2.7 Water temperature' \
  'sub=The available literature does not provide|## 2.2.8 Re-growth\n\nThe available literature does not provide'
rm -rf $D/images
$XP "$SRC/sodis-manual-2016.pdf" --pages 26-27 --bold-headings --source-url "$SODIS_URL" \
  --title "SODIS: Rules for Applying Solar Water Disinfection (Eawag SODIS Manual 2.4)" -o $D/03-sodis-application.md
post $D/03-sodis-application.md "${SODIS_DROP[@]}" 'drop=^\*\*Technical aspects\*\*$' \
  'sub=## 2.4 Implications for the application of the SODIS method: |## '
