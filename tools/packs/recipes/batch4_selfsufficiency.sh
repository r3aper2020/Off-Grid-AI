#!/usr/bin/env bash
# Batch 4 (self-sufficiency): household skills for long grid-down living,
# waste and pests, and more family preparedness.
#   content/17-self-sufficiency     id self-sufficiency    (needs-review)
#   content/17b-household-historical id household-historical (historical)
#   content/18b-preparedness-more   id preparedness-more   (verified)
#
# Usage: tools/packs/recipes/batch4_selfsufficiency.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All answered HTTP 200 on
#   2026-10-29. Run from the project root; then build each pack with
#   python3 tools/packs/build_pack.py content/<pack-dir>
#
# Licensing (checked 2026-10-29; every page/PDF/book scanned for "©",
# "copyright", "courtesy", "permission", "reprinted"):
# - Ready.gov (FEMA), USFA (FEMA), CISA, CFPB, USDA: U.S. Government works
#   (17 U.S.C. § 105). Third-party portions excluded as noted per source.
# - USDA Farmers' Bulletins are federal works whatever their date; the
#   Project Gutenberg transcriptions are used because the National
#   Agricultural Library scans (archive.org) are OCR with garbled numbers.
# - Non-government books: published in the U.S. before 1929 (public domain):
#   Ilgen, Forge Work (American Book Co., 1912); Griffith, Essentials of
#   Woodworking (Manual Arts Press, Peoria, 1908); Watson, Textiles and
#   Clothing (American School of Home Economics, Chicago, (c) 1906-07);
#   Beecher, Miss Beecher's Housekeeper and Healthkeeper (Harper, New York;
#   "Entered according to Act of Congress, in the year 1873").
#   Project Gutenberg header/footer (license, trademark) are stripped.
#
# Text is verbatim. Allowed changes only: page chrome removed (site banner,
# "Return to top", "Pictographs/Handouts/Video" download lists), Gutenberg
# =bold=/_italic_ markup removed, sections split at the source's own
# headings, held-back passages cut with a marker or skipped whole.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
XH="python3 tools/packs/extract_html.py"

RG=https://www.ready.gov
UF=https://www.usfa.fema.gov/prevention/home-fires
PG=https://www.gutenberg.org
CFPB_URL=$RG/sites/default/files/2020-03/cfpb-disaster-checklist-worksheet.pdf
CISA_URL=https://www.cisa.gov/sites/default/files/2025-03/personal-security-considerations-action-guide-critical-infrastructure-workers_06-07-2024_508.pdf

READY_PAGES="financial-preparedness recovering-disaster safety-skills home-fires
  home-fire-escape-plan space-weather cybersecurity mass-gatherings-incidents
  plan-for-locations low-and-no-cost get-tech-ready kids/make-a-plan
  kids/family-emergency-planning/build-a-kit kids/disaster-facts/power-outages
  kids/disaster-facts/home-fires"
USFA_PAGES="prepare-for-fire/smoke-alarms prepare-for-fire/home-fire-escape-plans
  prevent-fires/severe-weather prevent-fires/candle prevent-fires/batteries"
PG_BOOKS="53854 71855 21534 55734 18050 35542 62608 62605 59381"

key() { echo "$1" | tr / _; }
if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for p in $READY_PAGES; do dl "ready-$(key $p).html" "$RG/$p"; done
  for p in $USFA_PAGES; do dl "usfa-$(key $p).html" "$UF/$p/"; done
  dl cfpb-checklist.pdf "$CFPB_URL"
  dl cisa-personal-security.pdf "$CISA_URL"
  for n in $PG_BOOKS; do dl "pg$n.txt" "$PG/cache/epub/$n/pg$n.txt"; sleep 1; done
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# slice SRC OUT START END: wrap the HTML between two markers in <main>.
cat > "$TMP/slice.py" <<'PY'
import sys
src, out, start, end = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
i = s.index(start); j = s.index(end, i)
open(out, "w", encoding="utf-8").write("<html><body><main>" + s[i:j] + "</main></body></html>")
PY

# post FILE [ops...]: chrome removal and cuts.
#   drop=REGEX          delete lines matching REGEX
#   cut=START|END|NOTE  delete from the line matching START up to (not
#                       including) the line matching END ("EOF" = to the
#                       end); insert NOTE if given
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
lines = open(path, encoding="utf-8").read().split("\n")
for op in ops:
    kind, _, arg = op.partition("=")
    if kind == "drop":
        r = re.compile(arg); lines = [l for l in lines if not r.search(l)]
    elif kind == "cut":
        start, end, note = arg.split("|")
        i = next(k for k, l in enumerate(lines) if re.search(start, l))
        j = len(lines) if end == "EOF" else next(k for k in range(i + 1, len(lines)) if re.search(end, lines[k]))
        lines[i:j] = ([note, ""] if note else [])
    else:
        sys.exit(f"unknown op {op}")
text = "\n".join(lines)
for a, b in {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}.items():
    text = text.replace(a, b)
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n")
PY
post() { python3 "$TMP/post.py" "$@"; }

# gtext: Project Gutenberg plain text -> Markdown (see its docstring).
cat > "$TMP/gtext.py" <<'PY'
"""Verbatim slice of a Project Gutenberg plain-text book -> pack Markdown.

gtext.py BOOK OUT --title T --source-url U --start RE --end RE
         [--after RE] [--skip RE ...] [--sidenote-heads]

- Strips the PG header/footer (*** START / *** END lines).
- Takes the lines from the first line matching --start (searched after the
  first line matching --after, to step over a table of contents) up to,
  not including, the first later line matching --end ("EOF" = to the end).
- Re-joins wrapped lines into paragraphs. Headings: short ALL-CAPS lines,
  and Gutenberg bold run-in heads "=12. Title.=--Text" of <= 12 words (the
  head becomes the section heading, the text stays as the paragraph).
- Only markup is removed: =bold= and _italic_ markers. Illustrations are
  marked "— not included".
- Plain-text tables: kept one row per line (column gaps shown as " | ")
  only when every multi-column row has the same number of columns, so no
  value can move to another row; otherwise replaced by "[Table not
  included: layout not preserved; see the original]".
- --skip RE drops every section whose heading matches RE (until the next
  heading that does not match).
- Reports words lost (text present in the slice but not in the output;
  expected for --skip sections).
"""
import argparse, re, sys

ap = argparse.ArgumentParser()
ap.add_argument("book"); ap.add_argument("out")
ap.add_argument("--title", required=True); ap.add_argument("--source-url", required=True)
ap.add_argument("--start", required=True); ap.add_argument("--end", required=True)
ap.add_argument("--after"); ap.add_argument("--skip", nargs="*", default=[])
ap.add_argument("--sidenote-heads", action="store_true",
                help="[Sidenote: X] starts a sub-section 'Heading: X'")
a = ap.parse_args()

raw = open(a.book, encoding="utf-8").read().replace("\r\n", "\n")
s = re.search(r"^\*\*\* ?START OF.*$", raw, re.M); e = re.search(r"^\*\*\* ?END OF.*$", raw, re.M)
lines = raw[s.end():e.start()].split("\n")
k0 = 0
if a.after:
    k0 = next(i for i, l in enumerate(lines) if re.search(a.after, l)) + 1
i = next((k for k in range(k0, len(lines)) if re.search(a.start, lines[k])), None)
if i is None: sys.exit(f"start not found: {a.start}")
if a.end == "EOF":
    j = len(lines)
else:
    j = next((k for k in range(i + 1, len(lines)) if re.search(a.end, lines[k])), None)
    if j is None: sys.exit(f"end not found: {a.end}")
chunk = "\n".join(lines[i:j])

TABLE_NOTE = "[Table not included: layout not preserved; see the original]"
def is_table(block):
    ls = [l for l in block.split("\n") if l.strip()]
    if sum(1 for l in ls if l.count("|") >= 2) >= 1: return True
    if any(re.match(r"^\s*[-+=]{6,}\s*$", l) for l in ls) and len(ls) > 2: return True
    gaps = sum(1 for l in ls if re.search(r"\S {3,}\S", l.strip()))
    return len(ls) >= 2 and gaps >= 2

def table_rows(block):
    """Rows kept one per line, column gaps shown as " | ", only when every
    multi-column line has the same number of columns (no wrapped cells)."""
    ls = [l.strip() for l in block.split("\n") if l.strip()]
    if any("|" in l or re.match(r"^[-+=]{6,}$", l) for l in ls): return None
    rows = [re.split(r"\s{2,}", l) for l in ls]
    n = {len(r) for r in rows if len(r) > 1}
    if len(n) != 1: return None
    return [" | ".join(r) for r in rows]

def caps_heading(block):
    t = block.strip()
    return ("\n" not in t and t == t.upper() and re.search(r"[A-Z]{3}", t)
            and 1 <= len(t.split()) <= 12 and not t.startswith("[") and not re.match(r"^[\d.\s]+$", t))

def titled(h):
    return " ".join(w if re.fullmatch(r"[IVXLC]+\.?", w) else w.capitalize() for w in h.split())

def clean(t):
    t = re.sub(r"=([^=\n]+)=", r"\1", t)
    t = re.sub(r"(?<![\w])_([^_]+)_(?![\w])", r"\1", t)
    return t

out = [f"# {a.title}", f"Source: {a.source_url}", ""]
section, paras, pending, skipping = None, [], [], False
def flush():
    global paras
    if paras and not skipping:
        head = section or a.title
        out.extend([f"## {head}", "\n\n".join(paras), ""])
    paras = []
def set_heading(h):
    global section, skipping, pending
    h = h.strip().rstrip(".").strip()
    if paras or section is None or not pending:
        flush(); pending = [h]
    else:
        pending.append(h)
    section = ": ".join(pending) if len(pending) > 1 else pending[0]
    skipping = any(re.search(r, section, re.I) for r in a.skip)

tables = kept = 0
parent = None
# Join illustration captions that span several blank-line-separated blocks.
blocks, buf = [], None
for block in re.split(r"\n\s*\n", chunk):
    if buf is not None:
        buf += " " + block.strip()
        if "]" in block: blocks.append(buf); buf = None
        continue
    if block.strip().startswith("[Illustration") and "]" not in block:
        buf = block.strip(); continue
    blocks.append(block)
if buf is not None: blocks.append(buf)

for block in blocks:
    if not block.strip(): continue
    if is_table(block):
        rows = table_rows(block)
        if rows: paras.append(clean("\n".join(rows))); kept += 1
        else: paras.append(TABLE_NOTE); tables += 1
        pending = []; continue
    if caps_heading(block):
        h = block.strip()
        set_heading(titled(h)); parent = section; continue
    sn = re.fullmatch(r"\[Sidenote: ([^\]]+)\]", block.strip().replace("\n", " "))
    if sn and a.sidenote_heads:
        label = sn.group(1)
        if not paras and section and section.startswith(f"{parent}: ") and section != parent:
            label = section[len(parent) + 2:] + ", " + label   # consecutive sidenotes
        flush(); pending.clear()
        set_heading(f"{parent}: {label}" if parent else label); continue
    text = re.sub(r"\s*\n\s*", " ", block.strip())
    m = re.match(r"^=([^=]{2,160})=\s*(?:—|--|-)?\s*(.*)$", text)
    if m and len(m.group(1).split()) <= 12:
        set_heading(clean(m.group(1)))
        text = m.group(2).strip()
        if not text: continue
    if text.startswith("[Illustration"):
        text = text.rstrip("]") + " — not included]"
    paras.append(clean(text)); pending = []
flush()
md = re.sub(r"\n{3,}", "\n\n", "\n".join(out)).rstrip() + "\n"
words = lambda x: set(re.findall(r"[a-z0-9]+", x.lower()))
lost = sorted(words(chunk) - words(md) - {"not", "included"})
if lost and not tables: print(f"warning: words lost: {lost[:40]}", file=sys.stderr)
elif lost: print(f"note: {tables} table(s) cut; words only in tables/markup: {lost[:40]}", file=sys.stderr)
open(a.out, "w", encoding="utf-8").write(md)
print(f"wrote {a.out}: {md.count(chr(10) + '## ')} sections, {len(md)} chars, {tables} tables cut, {kept} kept as rows")
PY
gtext() { python3 "$TMP/gtext.py" "$@"; }

BANNER='^If you are a disaster survivor, please visit FEMA.gov'
TOP='^(Return to top|Back to top)$'
ready() {  # ready <page> <title> <out.md> [extract args...]
  local p=$1 t=$2 o=$3; shift 3
  $XH "$SRC/ready-$(key $p).html" --source-url "$RG/$p" --title "$t" -o "$o" "$@"
  post "$o" "drop=$BANNER" "drop=$TOP"
}
usfa() {   # usfa <page> <title> <out.md> [post ops...]
  local p=$1 t=$2 o=$3; shift 3
  python3 "$TMP/slice.py" "$SRC/usfa-$(key $p).html" "$TMP/u.html" '<div class="col-12 col-lg-9' '<aside id="aside"'
  $XH "$TMP/u.html" --source-url "$UF/$p/" --title "$t" -o "$o" \
    --skip "Pictographs" "Handouts" "Video" "Videos"
  post "$o" "$@"
}

# =========================================================================
# 18b-preparedness-more (verified): current Ready.gov, USFA, CFPB and CISA
# guidance on money and documents, utilities, home fire escape and smoke
# alarms, space weather and cyberattacks on the grid, personal and home
# security, and preparing children.
# Excluded: FEMA/Operation HOPE "Emergency Financial First Aid Kit" (EFFAK,
#   ready.gov PDF): "The EFFAK, Third Edition, dated April 2019, is a
#   copyrighted work of Operation HOPE, Inc. ... not for commercial use or
#   sale." Ready.gov "caregivers" (co-created with the Rosalynn Carter
#   Institute), "home-safety" (first-aid kit list credited to the American
#   Red Cross), kids "be-ready-kids"/"prepare-your-family"/"teens" (link
#   hubs; Prepare with Pedro is Red Cross material). The kids power-outage
#   page's "Learn More" list (Red Cross Pedro links) and the kids home-fire
#   page's "Learn More" list (incl. Sesame Street materials) are dropped,
#   as are "Downloadable Resources" link stubs.
# USFA: the "Did you know" statistics credited "Source: NFPA" (candle,
#   batteries pages) are dropped with their credit line.
# FEMA flyers "Safeguard Critical Documents", "Be Prepared for a Financial
#   Emergency", "Document and Insure Your Property": multi-column layouts
#   come out with headings fused to sentences — not used (the Ready.gov
#   financial page carries the same document list).
# CFPB "Your disaster checklist" (hosted on ready.gov): pages 1, 2 and 4;
#   page 3 is a fill-in account table; the closing "About us / Connect with
#   us" agency blurbs are dropped.
# CISA "Personal Security Considerations Action Guide: Critical
#   Infrastructure Workers" (06-07-2024): federal, no third-party notice;
#   footnotes cite FBI/CISA. Skipped: IMPROVISED EXPLOSIVE DEVICES section
#   and the per-app social-media settings (X, Instagram, Facebook, Snapchat,
#   TikTok: device menus that change often) and the closing RESOURCES link
#   lists (one is a non-federal stalking centre). CISA De-escalation Series and
#   the Active Shooter Pocket Card: multi-column layouts scrambled the
#   "Instead of / Say" pairs and Run/Hide/Fight columns — not used.
# Ready.gov "mass-gatherings-incidents" (same page as /active-shooter) is
#   DHS Run-Hide-Fight guidance and is kept verbatim, including its
#   "fight only as a last resort" lines.
# =========================================================================
D=content/18b-preparedness-more; mkdir -p $D
ready financial-preparedness "Financial Preparedness (Ready.gov)" $D/01-financial-preparedness.md
$XP "$SRC/cfpb-checklist.pdf" --pages 1-2 4 --source-url "$CFPB_URL" \
  --title "Your Disaster Checklist: Protect Your Personal Finances (CFPB)" -o $D/02-cfpb-disaster-checklist.md
post $D/02-cfpb-disaster-checklist.md 'cut=^## After a disaster: About us|EOF|' 
ready recovering-disaster "Recovering from Disaster (Ready.gov)" $D/03-recovering-disaster.md
ready safety-skills "Safety Skills: Shutting Off Utilities, Fire Extinguishers, First Aid (Ready.gov)" $D/04-safety-skills.md
ready home-fires "Home Fires (Ready.gov)" $D/05-home-fires.md
ready home-fire-escape-plan "Home Fire Escape Plan (Ready.gov)" $D/06-home-fire-escape-plan.md
usfa prepare-for-fire/smoke-alarms "Smoke Alarms (U.S. Fire Administration)" $D/07-smoke-alarms.md
usfa prepare-for-fire/home-fire-escape-plans "Home Fire Escape Plans (U.S. Fire Administration)" $D/08-usfa-escape-plans.md
usfa prevent-fires/severe-weather "Fire Hazards During and After Severe Weather (U.S. Fire Administration)" $D/09-severe-weather-fires.md
usfa prevent-fires/candle "Candle Fire Safety (U.S. Fire Administration)" $D/10-candle-safety.md \
  'drop=^On average, 20 home candle fires' 'drop=^Source: NFPA'
usfa prevent-fires/batteries "Lithium-Ion Battery Fire Safety (U.S. Fire Administration)" $D/11-battery-safety.md \
  'drop=^You should store lithium-ion batteries at room temperature' 'drop=^Source: NFPA'
ready space-weather "Space Weather: Geomagnetic Storms and the Power Grid (Ready.gov)" $D/12-space-weather.md
ready cybersecurity "Cybersecurity and Cyberattacks (Ready.gov)" $D/13-cybersecurity.md
ready get-tech-ready "Get Tech Ready (Ready.gov)" $D/14-get-tech-ready.md
ready mass-gatherings-incidents "Mass Gathering Incidents and Attacks: Run, Hide, Fight (Ready.gov)" $D/15-mass-gatherings.md
$XP "$SRC/cisa-personal-security.pdf" --source-url "$CISA_URL" \
  --title "Personal Security Considerations: Home, Situational Awareness and Online Safety (CISA)" -o $D/16-cisa-personal-security.md
post $D/16-cisa-personal-security.md \
  'cut=^## PHYSICAL SECURITY: IMPROVISED EXPLOSIVE DEVICES|^## PHYSICAL SECURITY: PROTESTS AND DEMONSTRATIONS|' \
  'cut=^## ONLINE SECURITY: X, formerly known as Twitter|^## ONLINE SECURITY: DOXING|' \
  'cut=^## RESOURCES: PHYSICAL SECURITY|EOF|'
ready plan-for-locations "Plan for Locations: Home, School, Work, High-Rises and Vehicles (Ready.gov)" $D/17-plan-for-locations.md
ready low-and-no-cost "Low- and No-Cost Ways to Prepare (Ready.gov)" $D/18-low-no-cost.md
ready kids/make-a-plan "Make a Plan with Your Kids (Ready.gov Kids)" $D/19-kids-make-a-plan.md \
  --drop-after "Downloadable Resources"
ready kids/family-emergency-planning/build-a-kit "Build a Kit with Your Kids (Ready.gov Kids)" $D/20-kids-build-a-kit.md \
  --drop-after "Downloadable Resources"
ready kids/disaster-facts/power-outages "Power Outages: Facts for Kids (Ready.gov Kids)" $D/21-kids-power-outages.md \
  --drop-after "Learn More"
ready kids/disaster-facts/home-fires "Home Fires: Facts for Kids (Ready.gov Kids)" $D/22-kids-home-fires.md \
  --drop-after "Learn More"

# =========================================================================
# 17b-household-historical (historical): pre-1929 household skills.
# Forge Work (PG #53854): Ch. I-V (tools, forging, practice exercises,
#   tool steel: annealing, hardening, tempering; tool making). Skipped:
#   Ch. VI steam hammer, VII art smithing, VIII-IX iron/steel manufacture
#   (Figs. 145-166 there are third-party: International Textbook Co.,
#   Inland Steel, Columbia Tool Steel — figures are never included anyway),
#   formulas and tables appendix, "Questions for Review". The tempering
#   colour/temperature charts are plain-text tables kept row by row.
#   Ch. IV mentions cyanide of potassium for casehardening — kept verbatim
#   (historical; flagged in the pack description).
# Essentials of Woodworking (PG #71855): Ch. I-V (laying-out tools, saws
#   and saw filing, planes, boring tools, chisels, grinding, oilstones and
#   sharpening). Ch. XII's quoted Forest Service matter is not used.
# Textiles and Clothing (PG #21534): Part II hand and machine sewing,
#   patching and darning; Part III care of clothing, cleaning, repairing.
#   Its cleaning section uses benzine, gasoline and chloroform (flagged).
# Miss Beecher's Housekeeper and Healthkeeper (PG #55734): Ch. XXII
#   Washing, Ironing and Cleansing (lye, soft and potash soap), and Part II
#   Ch. XX Fires and Lights (lamps, kerosene safety, candles).
# USDA Farmers' Bulletin 1408, The House Fly and How to Suppress It (1926;
#   PG #18050). Skipped: "Fly Papers and Poisons", chemical manure
#   treatments (hellebore, borax, calcium cyanamid).
# USDA Farmers' Bulletin 896, House Rats and Mice (1917; PG #35542).
#   Skipped: poisons (barium carbonate, strychnine, arsenic, phosphorus,
#   squills), fumigation (carbon bisulphide, sulphur, hydrocyanic acid) and
#   rat viruses — dangerous and long banned.
# NOT included: USDA FB 1334 Home Tanning of Leather and Small Fur Skins
#   (1923): only the NAL scan exists and its OCR garbles the chemical
#   quantities ("3 J pounds", "1£ gallons"); no transcription found.
# =========================================================================
D=content/17b-household-historical; mkdir -p $D
U=$PG/ebooks
gtext "$SRC/pg53854.txt" $D/01-forge-work.md --source-url $U/53854 \
  --title "Forge Work: Blacksmithing Tools, Forging, Welding and Tempering (W. L. Ilgen, 1912)" \
  --after "^  DEDICATED" --start "^CHAPTER I$" --end "^CHAPTER VI$" --skip "QUESTIONS FOR REVIEW"
gtext "$SRC/pg71855.txt" $D/02-woodworking-tools.md --source-url $U/71855 \
  --title "Woodworking Hand Tools and Sharpening (I. S. Griffith, Essentials of Woodworking, 1908)" \
  --after "^TOOLS AND ELEMENTARY PROCESSES" --start "^CHAPTER I\.$" --end "^CHAPTER VI\.$"
gtext "$SRC/pg21534.txt" $D/03-hand-sewing-mending.md --source-url $U/21534 \
  --title "Hand Sewing, Patching and Darning (K. H. Watson, Textiles and Clothing, 1907)" \
  --start "^HAND SEWING$" --end "^TEXTILES AND CLOTHING$" --sidenote-heads
gtext "$SRC/pg21534.txt" $D/04-care-of-clothing.md --source-url $U/21534 \
  --title "Care, Cleaning and Repair of Clothing (K. H. Watson, Textiles and Clothing, 1907)" \
  --start "^CARE OF CLOTHING$" --end "^BIBLIOGRAPHY$" --sidenote-heads
gtext "$SRC/pg55734.txt" $D/05-washing-soap.md --source-url $U/55734 \
  --title "Washing, Ironing, Soap and Lye Making (C. E. Beecher, Housekeeper and Healthkeeper, 1873)" \
  --after "^CHAPTER XXI\.$" --start "^CHAPTER XXII\.$" --end "^CHAPTER XXIII"
gtext "$SRC/pg55734.txt" $D/06-fires-lamps-candles.md --source-url $U/55734 \
  --title "Fires, Lamps and Candle Making (C. E. Beecher, Housekeeper and Healthkeeper, 1873)" \
  --after "brethren of Jesus Christ" --start "^FIRES AND LIGHTS\.$" --end "^CHAPTER XXI\.$"
gtext "$SRC/pg18050.txt" $D/07-house-fly.md --source-url $U/18050 \
  --title "The House Fly and How to Suppress It (USDA Farmers' Bulletin 1408, 1926)" \
  --start "^KINDS OF FLIES FOUND IN HOUSES" --end "^ORGANIZATION OF THE UNITED STATES DEPARTMENT" \
  --skip "^Fly Papers And Poisons" "^Chemical Treatment" "^Treatment With"
gtext "$SRC/pg35542.txt" $D/08-house-rats-mice.md --source-url $U/35542 \
  --title "House Rats and Mice: Rat-Proofing, Food Protection and Trapping (USDA Farmers' Bulletin 896, 1917)" \
  --after "^HOUSE RATS AND MICE\.$" --start "^DESTRUCTIVE HABITS" --end "^FOOTNOTES:" \
  --skip "^Poisons" "^Caution" "^Barium" "^Strychnin" "^Arsenic" "^Phosphorus" "^Squills" "^Poison in" "^Fumigation" "^Rat Viruses"

# =========================================================================
# 17-self-sufficiency (needs-review): later USDA home and farmstead
# bulletins (1930-1972), superseded but federal and practical.
# FB 1638 Rat Proofing Buildings and Premises (1930; PG #62608): skipped
#   the model city ordinances.
# FB 1950 Sewage and Garbage Disposal on the Farm (1944, rev. 1946; PG
#   #62605): septic tanks, privies, chemical closets, garbage and trash
#   (burning, burial, composting). Septic-tank capacity and disposal-field
#   tables are cut (multi-line headers; marker inserted).
# FB 2202 Simple Plumbing Repairs for the Home and Farmstead (rev. 1972;
#   PG #59381): faucets, leaks, frozen pipes, toilets, drains, emergencies.
# NOT included: FB 1474 Stain Removal from Fabrics (1942/1951) — built on
#   carbon tetrachloride; FB 754 The Bedbug (1916/1934) — hydrocyanic-acid
#   fumigation is its main remedy.
# =========================================================================
D=content/17-self-sufficiency; mkdir -p $D
gtext "$SRC/pg62608.txt" $D/01-rat-proofing.md --source-url $U/62608 \
  --title "Rat Proofing Buildings and Premises (USDA Farmers' Bulletin 1638, 1930)" \
  --after "^CONTENTS" --start "^INTRODUCTION$" --end "^ORGANIZATION OF THE UNITED STATES" \
  --skip "Ordinance"
gtext "$SRC/pg62605.txt" $D/02-sewage-garbage.md --source-url $U/62605 \
  --title "Sewage and Garbage Disposal: Septic Tanks, Privies and Trash (USDA Farmers' Bulletin 1950, 1946)" \
  --after "^  Disposal of garbage and trash" --start "^CHARACTERISTICS OF SEWAGE" --end "^U\. S\. GOVERNMENT PRINTING OFFICE"
gtext "$SRC/pg59381.txt" $D/03-plumbing-repairs.md --source-url $U/59381 \
  --title "Simple Plumbing Repairs for the Home and Farmstead (USDA Farmers' Bulletin 2202, 1972)" \
  --after "^0100-02684" --start "^REPAIRING WATER FAUCETS AND VALVES" --end "^U\.S\. GOVERNMENT PRINTING OFFICE"

echo "batch4_selfsufficiency: done"
