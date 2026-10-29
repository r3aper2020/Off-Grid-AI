#!/usr/bin/env bash
# Batch 4 (preservation): home canning (USDA Complete Guide to Home Canning)
# and food storage / power outages (FDA).
# Usage: tools/packs/recipes/batch4_preservation.sh <source-dir> [--fetch]
#   --fetch downloads every source into <source-dir> first.
# Then: python3 tools/packs/build_pack.py content/08-food-preservation
#       python3 tools/packs/build_pack.py content/05b-food-storage
#
# Sources re-verified 2026-10-29.
#
# ---------------------------------------------------------------------------
# 08 Home Canning — USDA Complete Guide to Home Canning, Agriculture
# Information Bulletin No. 539, revised 2015 (still the current edition).
# Issued by USDA's National Institute of Food and Agriculture (cover: "United
# States Department of Agriculture, National Institute of Food and
# Agriculture"). The PDFs carry no copyright notice; the only trademark/
# credit text is the USDA non-endorsement note for Clear Jel® and Splenda®.
# USDA distributes the guide's PDFs through the USDA-funded National Center
# for Home Food Preservation (nchfp.uga.edu); there is no usda.gov copy. The
# acknowledgments credit university co-developers (Penn State, Univ. of
# Georgia) under NIFA projects/grants — flagged for review in the import
# report. NCHFP's own web pages are NOT used (their site is © NCHFP).
#
# Why the guide was held back, and how this recipe fixes it (every step is
# verified; the guide's printed pages are never changed):
#  1. Font glyph "/HT" is the guide's word space (advance = the font's space
#     width: Arial 0.278 em, Times 0.25 em; no ink) but its ToUnicode entry is
#     U+FFFD, so captions read "process�time". prep_canning.py remaps
#     exactly those ToUnicode entries (/HT in the font's /Differences) to
#     U+0020 and aborts on any other U+FFFD.
#  2. The process tables were placed as clipped pages of another PDF: whole
#     other tables (2,298 text objects in Guide 1, 6,424 in Guide 6, …) sit
#     outside the clip — invisible, but text extraction read them. Their
#     text-showing operators (and the invisible paths) are removed; pdfium
#     then confirms no text/path object lies outside its clip, and every page
#     is rendered before and after: pixel-identical (max diff 0).
#  3. extract_figures.py found the "Recommended process time …" captions but
#     its regions swallowed the next recipe's title/ingredients and sometimes
#     stopped above a table's last row. fix_regions.py re-derives each table
#     region from the caption's shaded bar down the chain of horizontal rules
#     to the table's closing rule, and adds the four pie-filling ingredient
#     tables it missed. Every one of the 202 table images was reviewed by eye
#     (contact sheets): one table each, complete, nothing from neighbours.
#     Image count = caption count per guide (5/43/40/40/24/38/12).
#  4. Numbers check: every number in the text (outside table images) of every
#     page matches pdfium's independent text of the same pages (multiset);
#     the only differences are page numbers and chapter-tab digits.
#     Reading-order check (word 4-grams vs pdfium) found one reordered bold
#     line (Guide 1 p. 1-20), fixed below; the rest were soft hyphens.
# Source quirks kept verbatim: Guide 6 p. 13 prints "1/1 6-inch"; Guide 3
# Water-Packed Whole Tomatoes weighted-gauge table prints process time "1"
# for the third row (image of the original page).
# Skipped: covers, contents, Guide 1 glossary and index (pp. 33-40: the
# two-column glossary pairs terms with the wrong definitions), Intro contents.
# ---------------------------------------------------------------------------
# 05b Food Storage — FDA web pages (U.S. Government works; no third-party
# notices on these pages) and FDA's Refrigerator & Freezer Storage Chart
# (March 2018, fda.gov/media/74435). The chart is one big two-column table:
# it is kept as two images of the original page (logos/seals excluded).
#
# NOT available (bot wall, 403 to scripts — not circumvented): fsis.usda.gov
# (Jerky and Food Safety, Shelf-Stable Food Safety, Food Product Dating,
# Freezing and Food Safety, Smoking Meat and Poultry), foodsafety.gov,
# cdc.gov (botulism / home-canned foods), fema.gov, usda.gov.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
CAN=https://nchfp.uga.edu/papers/guide
FDA=https://www.fda.gov
CHART_URL=$FDA/media/74435/download
GUIDES="INTRO_HomeCanrev0715 GUIDE01_HomeCan_rev0715 GUIDE02_HomeCan_rev0715
  GUIDE03_HomeCan_rev0715 GUIDE04_HomeCan_rev0715 GUIDE05_HomeCan_rev0715
  GUIDE06_HomeCan_rev0715 GUIDE07_HomeCan_rev0715"
FDA_PAGES="
storing=consumers/consumer-updates/are-you-storing-food-safely
outages=food/buy-store-serve-safe-food/food-and-water-safety-during-power-outages-and-floods"

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sfL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for g in $GUIDES; do dl "$g.pdf" "$CAN/$g.pdf"; done
  for kv in $FDA_PAGES; do dl "fda-${kv%%=*}.html" "$FDA/${kv#*=}"; done
  dl fda-storage-chart.pdf "$CHART_URL"
fi
# SHA-1 of the guide PDFs used (2026-10-29): INTRO f3036401, G1 2baa013c,
# G2 85d74ef5, G3 e1c12120, G4 53a1a4b2, G5 e8dc1e23, G6 3b15b2a7, G7 ed2079d3.

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# ---- prep_canning.py IN OUT: fixes 1 and 2 above, with verification -------
cat > "$TMP/prep_canning.py" <<'PY'
import sys, re, io, ctypes
import pypdf, pypdfium2 as pdfium, pypdfium2.raw as R
from pypdf.generic import ContentStream, NameObject
from PIL import ImageChops
src, dst = sys.argv[1:3]
rd = pypdf.PdfReader(src); wr = pypdf.PdfWriter(clone_from=rd)
def diffmap(d):
    m, code = {}, None
    for x in d:
        if isinstance(x, int): code = x
        else: m[code] = str(x); code += 1
    return m
def fonts(res, seen):
    if not res: return
    res = res.get_object()
    for fr in (res.get('/Font') or {}).values():
        if fr.idnum not in seen: seen.add(fr.idnum); yield fr.get_object()
    for xo in (res.get('/XObject') or {}).values():
        xo = xo.get_object()
        if xo.get('/Subtype') == '/Form': yield from fonts(xo.get('/Resources'), seen)
seen, patched = set(), 0
for pg in wr.pages:
    for f in fonts(pg.get('/Resources'), seen):
        tu = f.get('/ToUnicode')
        if tu is None: continue
        tu = tu.get_object(); data = tu.get_data().decode('latin1')
        if 'FFFD' not in data.upper(): continue
        enc = f.get('/Encoding'); enc = enc.get_object() if enc is not None else None
        dm = diffmap(enc['/Differences']) if hasattr(enc, 'get') and '/Differences' in enc else {}
        def fix(m):
            global patched
            code = int(m.group(1), 16)
            if dm.get(code) != '/HT':
                sys.exit(f'U+FFFD for code {code:#x} (glyph {dm.get(code)}) in {f["/BaseFont"]}')
            patched += 1
            return f'<{m.group(1)}> <0020>'
        new = re.sub(r'(?mi)^\s*<([0-9A-F]{2})>\s*<FFFD>\s*$', fix, data)
        if 'FFFD' in new.upper(): sys.exit(f'unhandled U+FFFD mapping in {f["/BaseFont"]}')
        tu.set_data(new.encode('latin1'))
def mul(a, b):
    return [a[0]*b[0]+a[1]*b[2], a[0]*b[1]+a[1]*b[3], a[2]*b[0]+a[3]*b[2],
            a[2]*b[1]+a[3]*b[3], a[4]*b[0]+a[5]*b[2]+b[4], a[4]*b[1]+a[5]*b[3]+b[5]]
def pt(m, x, y): return (m[0]*x+m[2]*y+m[4], m[1]*x+m[3]*y+m[5])
SHOW = {b'Tj', b'TJ', b"'", b'"'}
NUMOPS = (b'cm', b'Tm', b'Td', b'TD', b're', b'm', b'l', b'c', b'v', b'y', b'TL')
removed = hidden_paths = 0
for pg in wr.pages:
    cs = ContentStream(pg.get_contents(), wr)
    ctm = [1, 0, 0, 1, 0, 0]; clip = None; stack = []
    path = []; pending_clip = False; tm = tlm = None; TL = 0; ops = []
    for operands, o in cs.operations:
        f = [float(v) for v in operands] if o in NUMOPS else None
        if o == b'q': stack.append((ctm[:], clip))
        elif o == b'Q': ctm, clip = stack.pop()
        elif o == b'cm': ctm = mul(f, ctm)
        elif o == b're':
            x, y, w, h = f
            path += [pt(ctm, x, y), pt(ctm, x+w, y), pt(ctm, x, y+h), pt(ctm, x+w, y+h)]
        elif o in (b'm', b'l'): path.append(pt(ctm, f[0], f[1]))
        elif o in (b'c', b'v', b'y'): path += [pt(ctm, f[i], f[i+1]) for i in range(0, len(f), 2)]
        elif o in (b'W', b'W*'): pending_clip = True
        elif o in (b'n', b'S', b's', b'f', b'F', b'f*', b'B', b'B*', b'b', b'b*'):
            if o != b'n' and not pending_clip and path and clip is not None:
                xs = [p[0] for p in path]; ys = [p[1] for p in path]
                if not (max(xs) > clip[0] and min(xs) < clip[2] and max(ys) > clip[1] and min(ys) < clip[3]):
                    ops.append(([], b'n')); hidden_paths += 1; path = []  # paints nothing
                    continue
            if pending_clip and path:
                xs = [p[0] for p in path]; ys = [p[1] for p in path]
                r = (min(xs), min(ys), max(xs), max(ys))
                clip = r if clip is None else (max(clip[0], r[0]), max(clip[1], r[1]), min(clip[2], r[2]), min(clip[3], r[3]))
            pending_clip = False; path = []
        elif o == b'BT': tm = tlm = [1, 0, 0, 1, 0, 0]
        elif o == b'Tm': tm = tlm = f
        elif o == b'TL': TL = f[0]
        elif o in (b'Td', b'TD'):
            if o == b'TD': TL = -f[1]
            tm = tlm = mul([1, 0, 0, 1, f[0], f[1]], tlm)
        elif o in (b'T*', b"'", b'"'):
            tm = tlm = mul([1, 0, 0, 1, 0, -TL], tlm)
        if o in SHOW and clip is not None:
            x, y = pt(mul(tm, ctm), 0, 0)
            if not (clip[0] - 1 <= x <= clip[2] + 1 and clip[1] - 1 <= y <= clip[3] + 1):
                removed += 1
                if o == b"'": ops.append(([], b'T*'))
                elif o == b'"': ops += [(operands[:1], b'Tw'), (operands[1:2], b'Tc'), ([], b'T*')]
                continue
        ops.append((operands, o))
    if len(ops) != len(cs.operations) or any(a is not b for a, b in zip(ops, cs.operations)):
        cs.operations = ops
        pg[NameObject('/Contents')] = wr._add_object(cs)
wr.write(dst)
def clip_boxes(o):
    cp = R.FPDFPageObj_GetClipPath(o.raw); out = []
    if not cp: return out
    for i in range(R.FPDFClipPath_CountPaths(cp)):
        pts = []
        for j in range(R.FPDFClipPath_CountPathSegments(cp, i)):
            s = R.FPDFClipPath_GetPathSegment(cp, i, j)
            x = ctypes.c_float(); y = ctypes.c_float()
            R.FPDFPathSegment_GetPoint(s, ctypes.byref(x), ctypes.byref(y)); pts.append((x.value, y.value))
        if pts: out.append((min(a for a, _ in pts), min(b for _, b in pts), max(a for a, _ in pts), max(b for _, b in pts)))
    return out
a = pdfium.PdfDocument(src); b = pdfium.PdfDocument(dst)
assert len(a) == len(b)
left = worst = 0
for p in range(len(a)):
    for o in b[p].get_objects(max_depth=0):
        if o.type not in (R.FPDF_PAGEOBJ_TEXT, R.FPDF_PAGEOBJ_PATH): continue
        l, bo, r, t = o.get_bounds()
        if any(not (r > x0 and l < x1 and t > y0 and bo < y1) for x0, y0, x1, y1 in clip_boxes(o)): left += 1
    ia = a[p].render(scale=150/72).to_pil().convert('RGB'); ib = b[p].render(scale=150/72).to_pil().convert('RGB')
    d = ImageChops.difference(ia, ib)
    if d.getbbox(): worst = max(worst, max(d.getextrema()[c][1] for c in range(3)))
print(f'{src}: {patched} /HT ToUnicode entries -> U+0020; {removed} hidden text ops and '
      f'{hidden_paths} hidden paths removed; hidden objects left {left}; render max diff {worst}')
if left or worst: sys.exit('verification failed')
PY

# ---- fix_regions.py PDF IMAGES_DIR CAPTION_REGEX: fix 3 above --------------
cat > "$TMP/fix_regions.py" <<'PY'
import json, os, re, sys
import pypdfium2 as pdfium
from pdfminer.high_level import extract_pages
from pdfminer.layout import LAParams, LTCurve, LTLine, LTRect, LTTextBox, LTTextLine
pdf_path, d, cap_re = sys.argv[1:4]
CAP = re.compile(cap_re, re.I); DPI = 150
idx_path = os.path.join(d, 'index.json'); index = json.load(open(idx_path))
pdf = pdfium.PdfDocument(pdf_path)
def walk(o):
    yield o
    if hasattr(o, '__iter__') and not isinstance(o, LTTextLine):
        for c in o: yield from walk(c)
norm = lambda t: ' '.join(t.split())
pages = sorted({e['page'] for e in index})
by_page = {}
for e in index: by_page.setdefault(e['page'], []).append(e)
out = []
for pno, lay in zip(pages, extract_pages(pdf_path, page_numbers=[p - 1 for p in pages], laparams=LAParams())):
    boxes = [b for b in lay if isinstance(b, LTTextBox)]
    caps = sorted([b for b in boxes if CAP.search(norm(b.get_text()))], key=lambda b: -b.y1)
    rules = [o for o in walk(lay) if isinstance(o, (LTLine, LTRect, LTCurve)) and o.height <= 2.5 and o.width >= 20]
    bars = [o for o in walk(lay) if isinstance(o, LTRect) and 2.5 < o.height < 40 and o.width > 100]
    old = by_page.get(pno, [])
    def bar_of(c):
        return [b for b in bars if b.x0 - 1 <= (c.x0 + c.x1) / 2 <= b.x1 + 1 and b.y0 - 1 <= (c.y0 + c.y1) / 2 <= b.y1 + 1]
    for k, c in enumerate(caps):
        # stop above the next caption's shaded bar (its top border is a rule)
        limit = max([caps[k + 1].y1] + [b.y1 for b in bar_of(caps[k + 1])]) + 1.5 if k + 1 < len(caps) else 0
        bar = bar_of(c)
        top = max([c.y1] + [b.y1 for b in bar])
        cx0 = min([c.x0] + [b.x0 for b in bar]); cx1 = max([c.x1] + [b.x1 for b in bar])
        cand = sorted([r for r in rules if r.y1 <= top + 1 and r.y0 >= limit
                       and r.x1 > cx0 - 250 and r.x0 < cx1 + 250], key=lambda r: -r.y0)
        chain, edge = [], min([c.y0] + [b.y0 for b in bar])
        for r in cand:
            if edge - r.y0 > 60: break
            chain.append(r); edge = min(edge, r.y0)
        if not chain: sys.exit(f'p{pno}: no rules under caption {norm(c.get_text())[:60]!r}')
        bottom = min(r.y0 for r in chain)
        x0 = min([cx0] + [r.x0 for r in chain]) - 6; x1 = max([cx1] + [r.x1 for r in chain]) + 6
        y0 = bottom - 4; y1 = top + 3
        e = next((o for o in old if norm(o['caption'])[:40] in norm(c.get_text())[:200]
                  or norm(c.get_text())[:40] in norm(o['caption'])), None)
        if e is None:
            e = {'file': f'tab-p{pno}-x{k + 1}.webp', 'caption': norm(c.get_text())[:140],
                 'kind': 'table', 'page': pno, 'bbox': None}
            print(f"  p{pno}: added table {e['caption'][:50]!r}")
        old = [o for o in old if o is not e]
        page = pdf[pno - 1]; pw, ph = page.get_size()
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(pw, x1), min(ph, y1)
        page.render(scale=DPI / 72, crop=(x0, y0, pw - x1, ph - y1), grayscale=True).to_pil() \
            .save(os.path.join(d, e['file']), 'WEBP', quality=70)
        e['bbox'] = [round(x0, 1), round(y0, 1), round(x1, 1), round(y1, 1)]
        out.append(e)
    if old: sys.exit(f'p{pno}: regions not matched to a caption: {[o["caption"] for o in old]}')
json.dump(out, open(idx_path, 'w'), indent=1)
print(f'  {len(out)} table images')
PY

# ---- tidy.py MD: structure-only heading repairs -----------------------------
# 1. A wrapped bold paragraph became a "## " heading. Headings starting
#    lower-case go back into the paragraph they continue (previous line +
#    heading + next line); long ones (> 12 words) or ones starting
#    "Procedure:" become a body paragraph joined with their next line (and
#    with the previous line when that ends with "Caution:").
# 2. A recipe title carried as a bold lead under its own subtitle ("## Can be
#    canned whole…" / "**14-DAY SWEET PICKLES**") becomes the heading; the
#    subtitle becomes the first body line. No words are changed.
cat > "$TMP/tidy.py" <<'PY'
import re, sys
path = sys.argv[1]
L = open(path, encoding='utf-8').read().split('\n')
body = lambda s: s.strip() and not s.startswith(('#', '!', '**', '[', 'Source:'))
def prev_nonblank(out):
    for k in range(len(out) - 1, -1, -1):
        if out[k].strip(): return k
out, i = [], 0
while i < len(L):
    l = L[i]
    if l.startswith('## '):
        h = l[3:]; nxt = L[i + 1] if i + 1 < len(L) else ''
        lower = h[:1].islower()
        if lower or len(h.split()) > 12 or h.startswith('Procedure:'):
            text = h
            if body(nxt): text += ' ' + nxt; i += 1
            k = prev_nonblank(out)
            if k is not None and body(out[k]) and (lower or out[k].rstrip().endswith('Caution:')):
                out[k] = out[k].rstrip() + ' ' + text; del out[k + 1:]
            else:
                out.append(text)
            i += 1; continue
        m = re.match(r'^\*\*(.+)\*\*$', L[i + 1]) if i + 1 < len(L) else None
        if m and h != h.upper() and re.match(r'^[A-Z0-9][A-Z0-9-]{2,}\b', m.group(1)):
            out += ['## ' + m.group(1), h]; i += 2; continue
    out.append(l); i += 1
open(path, 'w', encoding='utf-8').write('\n'.join(out))
PY

# ---- replace.py FILE OLD NEW: exact one-time replacement, fails if absent --
cat > "$TMP/replace.py" <<'PY'
import sys
path, old, new = sys.argv[1:4]
old = old.encode().decode('unicode_escape'); new = new.encode().decode('unicode_escape')
t = open(path, encoding='utf-8').read()
if t.count(old) != 1: sys.exit(f'replace: expected 1 match in {path}, found {t.count(old)}: {old[:60]!r}')
open(path, 'w', encoding='utf-8').write(t.replace(old, new))
PY

# =====================================================================
# 08 Home Canning (verified)
# =====================================================================
D=content/08-food-preservation
mkdir -p $D
for g in $GUIDES; do $PY "$TMP/prep_canning.py" "$SRC/$g.pdf" "$TMP/$g.pdf"; done
# Table captions: USDA's process-time captions plus the guide's other
# number tables (syrups, acid foods in pressure canners, pie-filling and jam
# ingredient tables, jelly juice-extraction and boiling-point tables, the
# worked examples and the preservation-plan worksheet in Guide 1).
TC='^(Table for Example [A-C] )?Recommended process time|^Process times for some acid foods|^Suggested Preservation Plan|^Preparing and using syrups|^Quantities of Ingredients Needed|^To Extract Juice|^Sea Level|^Ingredient Quantities'
can() {  # can FILE PAGES TITLE OUT
  local img="$D/images/$4"
  rm -rf "$img"
  $PY tools/packs/extract_figures.py "$TMP/$1.pdf" --pages "$2" --out "$img" --table-caption "$TC"
  $PY "$TMP/fix_regions.py" "$TMP/$1.pdf" "$img" "$TC"
  $PY tools/packs/extract_pdf.py "$TMP/$1.pdf" --pages "$2" --figures "$img" --bold-headings \
    --source-url "$CAN/$1.pdf" --title "$3" -o "$D/$4.md"
  python3 "$TMP/tidy.py" "$D/$4.md"
}
can INTRO_HomeCanrev0715 2-6 "Complete Guide to Home Canning: Introduction and Cautions (USDA AIB 539, 2015)" 00-intro
can GUIDE01_HomeCan_rev0715 5-32 "Principles of Home Canning (USDA Complete Guide, Guide 1)" 01-principles
can GUIDE02_HomeCan_rev0715 5-32 "Canning Fruit and Fruit Products (USDA Complete Guide, Guide 2)" 02-fruit
can GUIDE03_HomeCan_rev0715 5-26 "Canning Tomatoes and Tomato Products (USDA Complete Guide, Guide 3)" 03-tomatoes
can GUIDE04_HomeCan_rev0715 5-21 "Canning Vegetables and Vegetable Products (USDA Complete Guide, Guide 4)" 04-vegetables
can GUIDE05_HomeCan_rev0715 5-15 "Canning Poultry, Red Meats and Seafoods (USDA Complete Guide, Guide 5)" 05-meat
can GUIDE06_HomeCan_rev0715 5-35 "Fermented Foods and Pickled Vegetables (USDA Complete Guide, Guide 6)" 06-pickles
can GUIDE07_HomeCan_rev0715 5-13 "Jams and Jellies (USDA Complete Guide, Guide 7)" 07-jams
# Guide 1 p. 1-20: the bold lead of item 2 was extracted after the first
# half of its own sentence; restore the printed order (structure only).
python3 "$TMP/replace.py" $D/01-principles.md \
'- 1. Internal canner temperatures are lower at higher altitudes. To correct this error,\n\ncanners must be operated at the increased pressures specified in this publication for appropriate altitude ranges. of pressure and results in under processing. The highest volume of air trapped in a\n**2. Air trapped in a canner lowers the temperature obtained at 5, 10, or 15 pounds**\n\ncanner occurs' \
'- 1. Internal canner temperatures are lower at higher altitudes. To correct this error, canners must be operated at the increased pressures specified in this publication for appropriate altitude ranges.\n\n- 2. Air trapped in a canner lowers the temperature obtained at 5, 10, or 15 pounds of pressure and results in under processing. The highest volume of air trapped in a canner occurs'

# =====================================================================
# 05b Food Storage and Power Outages (verified)
# =====================================================================
D=content/05b-food-storage
mkdir -p $D
# FDA "Are You Storing Food Safely?" (Consumer Update, content current as of
# 01/18/2023).
python3 tools/packs/extract_html.py "$SRC/fda-storing.html" --source-url "$FDA/consumers/consumer-updates/are-you-storing-food-safely" \
  --title "Are You Storing Food Safely? (FDA)" -o $D/01-storing-food-safely.md
# FDA "Food and Water Safety During Power Outages and Floods" (content current
# as of 03/05/2024). Page chrome removed: "Print & Share (PDF)", language
# links, the on-page contents list and "Return to … Main Page". The two
# immersion methods are re-indented under "Sanitize cans … in one of the two
# following ways:" (the extractor flattened that nested list).
python3 tools/packs/extract_html.py "$SRC/fda-outages.html" --source-url "$FDA/food/buy-store-serve-safe-food/food-and-water-safety-during-power-outages-and-floods" \
  --title "Food and Water Safety During Power Outages and Floods (FDA)" -o $D/02-power-outages-floods.md
python3 - $D/02-power-outages-floods.md <<'PY'
import re, sys
p = sys.argv[1]; L = open(p, encoding='utf-8').read().split('\n')
drop = re.compile(r'^(Print & Share \(PDF\)|Español \(Spanish\).*|Return to the Protect Food and Water During Storms Main Page|'
                  r'- (Prepare Yourself Before Power Emergencies|Power Outages: During and After|If Flooding Occurs|'
                  r'How To Save Undamaged Food Packages Exposed to Flood Water|About Foodborne Illness|Take Action))$')
n = len(L); L = [l for l in L if not drop.match(l)]
assert n - len(L) == 9, n - len(L)
k = 0
for i, l in enumerate(L):
    if re.match(r'^- Place (in water and allow the water to come to a boil|in a solution of 1 cup)', l):
        L[i] = '  ' + l; k += 1
assert k == 2
open(p, 'w', encoding='utf-8').write(re.sub(r'\n{3,}', '\n\n', '\n'.join(L)))
PY
# FDA Refrigerator & Freezer Storage Chart (March 2018). The chart's two
# columns of storage times are kept as two images of the original page
# (regions measured from the PDF; the FDA logo and HHS seal at the bottom
# right are outside them); the intro text and tips stay as text.
IMG=$D/images/03-storage-chart; rm -rf $IMG; mkdir -p $IMG
$PY - "$SRC/fda-storage-chart.pdf" $IMG <<'PY'
import json, os, sys
import pypdfium2 as pdfium
pdf, out = sys.argv[1:3]
page = pdfium.PdfDocument(pdf)[0]; w, h = page.get_size()
regions = [("tab-left.webp", "Refrigerator & Freezer Storage Chart: Eggs; TV Dinners, Frozen Casseroles; Deli & Vacuum-Packed Products; Raw Hamburger, Ground & Stew Meat; Ham, Corned Beef; Hot Dogs & Lunch Meats", (18, 44, 305, 632)),
           ("tab-right.webp", "Refrigerator & Freezer Storage Chart: Soups & Stews; Bacon & Sausage; Fresh Meat (Beef, Veal, Lamb, & Pork); Meat Leftovers; Fresh Poultry; Cooked Poultry, Leftover; Fish & Shellfish", (309, 102, 597, 632))]
index = []
for f, cap, (x0, y0, x1, y1) in regions:
    page.render(scale=150 / 72, crop=(x0, y0, w - x1, h - y1), grayscale=True).to_pil().save(os.path.join(out, f), 'WEBP', quality=70)
    index.append({"file": f, "caption": cap, "kind": "table", "page": 1, "bbox": [x0, y0, x1, y1]})
json.dump(index, open(os.path.join(out, 'index.json'), 'w'), indent=1)
PY
$PY tools/packs/extract_pdf.py "$SRC/fda-storage-chart.pdf" --figures $IMG --source-url "$CHART_URL" \
  --title "Refrigerator & Freezer Storage Chart (FDA, 2018)" -o $D/03-storage-chart.md
# Structure only: put the chart's left column before its right column, and
# rejoin the tip that wrapped onto a second line.
F=$D/03-storage-chart.md
python3 "$TMP/replace.py" $F 'heavy-duty\n\nfoil, plastic wrap' 'heavy-duty foil, plastic wrap'
python3 - $F <<'PY'
import sys
p = sys.argv[1]; t = open(p, encoding='utf-8').read()
L = t.split('\n')
r = [i for i, l in enumerate(L) if l.startswith('![') and 'tab-right.webp' in l]
l_ = [i for i, l in enumerate(L) if l.startswith('![') and 'tab-left.webp' in l]
assert len(r) == len(l_) == 1
if r[0] < l_[0]: L[r[0]], L[l_[0]] = L[l_[0]], L[r[0]]
open(p, 'w', encoding='utf-8').write('\n'.join(L))
PY
