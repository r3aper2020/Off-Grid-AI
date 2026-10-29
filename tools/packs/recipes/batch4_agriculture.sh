#!/usr/bin/env bash
# Batch 4 (agriculture): food production for long-term self-sufficiency —
# home garden, compost, staple crops, cover crops; small-farm livestock,
# backyard chickens, rabbits, sheep; home slaughter; hand grain stacking.
#
# Usage: tools/packs/recipes/batch4_agriculture.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). Run from the project root, then
#   python3 tools/packs/build_pack.py content/07-gardening
#   python3 tools/packs/build_pack.py content/07b-livestock
#   python3 tools/packs/build_pack.py content/07c-farm-historical
#
# Sources re-checked 2026-10-29.
#
# LICENSE EVIDENCE
# - USDA publications (Farmers' Bulletins, Agriculture Fact Sheets, Leaflet
#   160) are U.S. Government works (17 U.S.C. § 105), issued by USDA and sold
#   by the GPO. FB 2222 and FB 2263 print USDA's grant: "Department
#   publications contain public information. They are not copyrighted and
#   can [may] be reproduced in whole or in part with or without credit."
#   Some were written or co-written by land-grant university staff (noted
#   per document, as for the CMS dialysis guide in docs/decisions.md); none
#   carries a copyright notice (each file was searched for "copyright",
#   "©", "courtesy", "reprinted", "permission", "adapted from").
#   Third-party items are excluded: tables marked "Adapted from Smith,
#   King & Carpenter, 1975" (FB 2264, FB 2265) and photo captions marked
#   "(Courtesy of Small Stock Magazine.)" (FB 2131). No images are used.
# - NAL scans at the Internet Archive (collection
#   usdanationalagriculturallibrary; rights "The contributing institution
#   believes that this item is not in copyright"). Text comes from each
#   item's OCR full text (<file>_djvu.txt), which keeps column reading
#   order; the PDF text layer of these 2-3 column leaflets interleaves
#   columns (checked: a sudangrass prussic-acid CAUTION came out scrambled).
#   PDF page 1 (NAL "Historic, archived document" notice) is never used.
# - Project Gutenberg transcriptions (proofread; PG header/footer and
#   transcriber notes stripped) are used for USDA FB 2263/2264/2265 and
#   Leaflet 160 (federal works; cleaner than OCR for numbers), and for two
#   pre-1929 books (public domain): F. F. Rockwell, Home Vegetable
#   Gardening (1911) and J. N. DeLamater, A Revised and Illustrated
#   Treatise on Grain Stacking (Norwalk, Ohio, 1884; "Copyright 1884" —
#   expired).
#
# VERBATIM / HELD BACK
# Text is verbatim (OCR errors in the scans are left as found, e.g.
# "Using Compos!"). Structure-only fixes are listed per document (--op):
# joining sentences split by page/column breaks, moving a block back into
# reading order, dropping photo negative numbers, credit lines and garbled
# sidebars. Every passage whose quantity is illegible in the scan
# ("IV2", "l1/*", "% pound" for fractions) and every table (rations,
# seeding rates, cost tables, sowing guides, cooking timetables, cut
# yields) is replaced by a bracketed "not included … see the original"
# marker. Curing (nitrite/nitrate dosing), smoking of cured meat and home
# canning in FB 2263/2265 are held back (obsolete processing guidance;
# nitrite is toxic in excess). Obsolete insecticides (Paris green,
# arsenate of lead, hellebore) in Rockwell are held back.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
V=2026.10.29.6
IA=https://archive.org/download
PG=https://www.gutenberg.org

# name=IA-item/file  (PDF = Source URL; _djvu.txt = text used)
IA_ITEMS="
smallfarms=CAT31108251/CAT31108251
layers=CAT31376150/CAT31376150
rabbits=CAT87205715/farmbul2131rev1964
sheep=CAT87206120/farmbul2222rev1977
compost=IND80100392/IND80100392
seeds=CAT31376174/CAT31376174
peanuts=CAT31376139/CAT31376139"
PG_BOOKS="beef=62848 lamb=62838 pork=62859 crimson=63170 rockwell=7123 stacking=37034"

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for kv in $IA_ITEMS; do dl "${kv%%=*}_djvu.txt" "$IA/${kv#*=}_djvu.txt"; done
  for kv in $PG_BOOKS; do dl "pg-${kv%%=*}.txt" "$PG/cache/epub/${kv#*=}/pg${kv#*=}.txt"; done
fi
iapdf() { printf '%s\n' $IA_ITEMS | grep "^$1=" | cut -d= -f2 | sed "s|^|$IA/|; s|$|.pdf|"; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/djvu2md.py" <<'PY'
#!/usr/bin/env python3
"""Internet Archive OCR full text (<id>_djvu.txt) -> pack Markdown, verbatim.

usage: djvu2md.py IN_djvu.txt OUT.md --title T --source-url U --start TEXT
                  --end TEXT [--heading TEXT ...] [--plain TEXT ...] [--op OP ...]

Used for NAL scans whose PDF text layer interleaves columns: the IA full
text (ABBYY layout analysis of the same scan) keeps column reading order.
Structure only — no words are changed:
- keeps paragraphs from the first one starting with --start up to (not
  including) the first one starting with --end;
- drops the NAL "Historic, archived document" notice, bare page numbers,
  USDA photo negative numbers ("83091-B", "BN-26562") and lines that are
  scan noise from photos (mostly non-alphanumeric);
- short ALL-CAPS paragraphs (and --heading ones) become "## " headings;
  short title-case run-in heads ("Feeding Practices") become
  "## PARENT: Sub" under the current ALL-CAPS heading; --plain keeps a
  would-be heading as text;
- re-joins lines (a line-end hyphen is kept: "prin-cipally");
- --op runs ordered fixes for column/page-break order, written per
  document in the recipe: join|END|START (append the paragraph starting
  START to the one ending END), move|START|END|AFTER, drop|START (photo
  credit or caption text that interrupts a sentence, garbled sidebars);
  then a paragraph cut off mid-sentence is joined to the next paragraph
  (or the next after figure captions) if that starts in lower case;
  then cutpara|START / cutrange|START|END replace held-back passages
  (illegible quantities, tables) with a bracketed "not included" marker;
- "Figure N.—caption" paragraphs become "[Figure N.—caption — figure not
  included]".
"""
import argparse
import re
import sys

ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("out")
ap.add_argument("--title", required=True)
ap.add_argument("--source-url", required=True)
ap.add_argument("--start", required=True)
ap.add_argument("--end", required=True)
ap.add_argument("--heading", nargs="*", default=[])
ap.add_argument("--plain", nargs="*", default=[])
ap.add_argument("-v", action="store_true", help="list dropped noise lines")
ap.add_argument("--op", action="append", default=[],
                help="ordered structure ops, '|'-separated: join|END|START, "
                     "move|START|END|AFTER, cutpara|START, cutrange|START|END, drop|START")
ap.add_argument("--no-autojoin", action="store_true")
a = ap.parse_args()

raw = open(a.src, encoding="utf-8", errors="replace").read().replace("\r\n", "\n")
raw = raw.replace("¬\n", "-\n").replace("¬ ", "-")  # OCR line-end hyphen sign


DROPPED = []


def noise(line):
    t = line.strip()
    if not t:
        return False
    if re.fullmatch(r"[ivxlcdm\d]{1,4}", t, re.I):
        return True  # bare page number
    if re.fullmatch(r"((?:[A-Z]{1,3}-\d{3,6}|[0-9A-Z]{4,6}-[A-Z]{1,2})[,;.\s]*)+", t):
        DROPPED.append(t)
        return True  # photo negative numbers (USDA photo IDs)
    alnum = len(re.findall(r"[A-Za-z0-9]", t))
    words = re.findall(r"[A-Za-z]+|\d+", t)
    bad = alnum < 0.5 * len(t.replace(" ", "")) or not words
    if bad:
        DROPPED.append(t)
    return bad


paras = []
for block in re.split(r"\n\s*\n", raw):
    ls = [l for l in block.split("\n") if l.strip() and not noise(l)]
    if not ls:
        continue
    text = ""
    for l in ls:
        l = re.sub(r"\s+", " ", l.strip())
        if not text:
            text = l
        elif text.endswith("-") and not text.endswith(" -"):
            text += l
        else:
            text += " " + l
    paras.append(text)

drop = re.compile(r"^(Historic, archived document|Historic, Archive Document|Do not assume content reflects)", re.I)
paras = [p for p in paras if not drop.match(p)]

try:
    i = next(k for k, p in enumerate(paras) if p.startswith(a.start))
except StopIteration:
    sys.exit(f"start not found: {a.start!r}")
try:
    j = next(k for k in range(i + 1, len(paras)) if paras[k].startswith(a.end))
except StopIteration:
    if a.end != "EOF":
        sys.exit(f"end not found: {a.end!r}")
    j = len(paras)
P = paras[i:j]
src_words = " ".join(P)

heads = {h.lower() for h in a.heading}
plain = {h.lower() for h in a.plain}


def is_heading(p):
    if p.lower() in plain:
        return False
    if p.lower() in heads:
        return True
    letters = re.sub(r"[^A-Za-z]", "", p)
    return (p.upper() == p and len(letters) >= 3 and len(p.split()) <= 8
            and not re.search(r"\d", p) and not p.endswith((".", ","))
            and not p.startswith(("•", "-")))


def is_sub(p):
    """Short title-case run-in heading line ("Feeding Practices")."""
    if p.lower() in plain or is_heading(p):
        return False
    return (len(p.split()) <= 6 and p[:1].isupper() and not re.search(r"\d", p)
            and not re.search(r"[.,;:!—-]$", p) and not p.startswith(("•", "Figure")))


ENDP = re.compile(r"[.:;?!\"”)\]—]$")
MARK = "[Passage not included here: a quantity in it is illegible in the scanned original; see the original publication]"
TMARK = "[Table not included here: its layout or values could not be reproduced exactly from the scan; see the original publication]"


def find(pred, what, start=0):
    for k in range(start, len(P)):
        if pred(P[k]):
            return k
    sys.exit(f"op target not found: {what!r}")


def run_ops(kinds):
  for op in a.op:
    kind, *args = op.split("|")
    if kind not in kinds:
        continue
    if kind == "join":
        e_, s_ = args
        x = find(lambda p: p.endswith(e_), e_)
        y = find(lambda p: p.startswith(s_), s_)
        P[x] = P[x] + ("" if P[x].endswith("-") else " ") + P[y]
        del P[y]
    elif kind == "move":
        s_, e_, af = args
        x = find(lambda p: p.startswith(s_), s_)
        y = find(lambda p: p.startswith(e_), e_, x + 1)
        chunk = P[x:y]
        del P[x:y]
        z = find(lambda p: p.startswith(af), af)
        P[z + 1:z + 1] = chunk
    elif kind == "cutpara":
        x = find(lambda p: p.startswith(args[0]), args[0])
        P[x] = MARK
    elif kind == "cutrange":
        s_, e_ = args
        x = find(lambda p: p.startswith(s_), s_)
        y = find(lambda p: p.startswith(e_), e_, x + 1)
        P[x:y] = [TMARK]
    elif kind == "drop":
        x = find(lambda p: p.startswith(args[0]), args[0])
        del P[x]
    elif kind not in ("join", "move", "cutpara", "cutrange", "drop"):
        sys.exit(f"unknown op {op}")


run_ops({"join", "move", "drop"})

# Safe joins: a paragraph cut off mid-sentence (no closing punctuation) and
# the next paragraph — or the next one after figure captions only — starts
# in lower case: the same sentence split by a page/column break.
k = 0
while not a.no_autojoin and k < len(P):
    p = P[k]
    if (not is_heading(p) and not is_sub(p) and not ENDP.search(p)
            and not p.startswith(("Figure", "FIGURE", "Fig."))):
        m = k + 1
        while m < len(P) and re.match(r"(Figure|FIGURE|Fig\.) ?\d+", P[m]):
            m += 1
        if m < len(P) and P[m][:1].islower():
            P[k] = p + ("" if p.endswith("-") and not p.endswith(" -") else " ") + P[m]
            del P[m]
            continue
    k += 1

run_ops({"cutpara", "cutrange"})

out = []
parent = None
for p in P:
    mixed = re.fullmatch(r"([A-Z][A-Z ,&]+[A-Z]) ([A-Z][a-z][\w ,'-]*)", p)
    if mixed and len(p.split()) <= 9 and p.lower() not in plain:
        parent = mixed.group(1)
        out += [f"## {parent}: {mixed.group(2)}", ""]
        continue
    if is_heading(p):
        h = p.rstrip(":")
        prev = [x for x in out if x.strip()]
        if prev and prev[-1] == f"## {parent}":
            while out and out[-1] != f"## {parent}":
                out.pop()
            out[-1] = f"## {parent}: {h}"
        else:
            out.append("## " + h)
        parent = h
        out.append("")
        continue
    if is_sub(p):
        prev = [x for x in out if x.strip()]
        if parent and prev and prev[-1] == f"## {parent}":
            while out and out[-1] != f"## {parent}":
                out.pop()
            out.pop()
        out.append(f"## {parent}: {p}" if parent else f"## {p}")
        out.append("")
        continue
    m = re.match(r"(Figure|FIGURE|Fig\.) ?\d+", p)
    if m:
        out.append(f"[{p} — figure not included]")
        out.append("")
        continue
    out.append(p)
    out.append("")

# A heading with no text of its own is carried into the next section as a
# bold lead line (the extractor's convention), never dropped.
final, carried = [], []
for n, l in enumerate(out):
    if l.startswith("## "):
        rest = [x for x in out[n + 1:] if x.strip()]
        if rest and rest[0].startswith("## "):
            carried.append(l[3:].split(": ")[-1])
            continue
        final += [l, ""] + [f"**{h}**\n" for h in carried]
        carried = []
        continue
    if not l.strip() and final and not final[-1].strip():
        continue
    final.append(l)
out = final
text = "\n".join(out).strip()
if not text.startswith("## "):
    text = "## Overview\n\n" + text
md = f"# {a.title}\nSource: {a.source_url}\n\n{text}\n"
open(a.out, "w", encoding="utf-8").write(md)
w = lambda x: set(re.findall(r"[a-z0-9]+", x.lower()))
lost = sorted(w(src_words) - w(md))
print("  noise lines dropped: " + " | ".join(DROPPED[:400]), file=sys.stderr) if a.v else None
print(f"wrote {a.out}: {md.count(chr(10) + '## ')} sections, {len(md)} chars; lost: {lost[:30]}",
      file=sys.stderr)
PY
cat > "$TMP/pg2md.py" <<'PY'
#!/usr/bin/env python3
"""Project Gutenberg plain text -> pack Markdown, verbatim (structure only).

usage: pg2md.py BOOK.txt OUT.md --title T --source-url U --start LINE --end LINE
                [--caps-only] [--skip HEADING ...]

- Keeps the text between the first line equal (stripped) to --start (searched
  after the PG header; the LAST occurrence before --end is not used — the
  first occurrence after --after, if given) and the first line equal to
  --end (exclusive). PG header/footer and transcriber notes are never kept.
- Centered lines (8+ leading spaces, short, no final period) preceded by a
  blank line become "## " headings. An ALL-CAPS heading followed directly by
  a sub-heading is carried as "PARENT: Sub" (no words added). With
  --caps-only, only ALL-CAPS centered lines become headings.
- Indented blocks that start with "Table" (PG preformatted tables) are
  replaced by "[Table …: <caption> — not included; see the original]"
  because column layout cannot be kept in the pack's plain text.
- "[Illustration: …]" lines are dropped and the printed figure caption that
  follows is kept as "[Figure …: <caption> — figure not included]".
- PG markup is removed: _italics_ underscores, =bold= signs.
- --skip HEADING drops that section (to the next heading of the same or
  higher level) — used only to hold back passages (see recipe).
Wrapped lines are re-joined into paragraphs; list items stay one per line.
A coverage check reports words lost (other than held-back sections/tables).
"""
import argparse
import re
import sys

ap = argparse.ArgumentParser()
ap.add_argument("book")
ap.add_argument("out")
ap.add_argument("--title", required=True)
ap.add_argument("--source-url", required=True)
ap.add_argument("--start", required=True)
ap.add_argument("--after", default=None)
ap.add_argument("--end", required=True)
ap.add_argument("--caps-only", action="store_true")
ap.add_argument("--skip", nargs="*", default=[])
a = ap.parse_args()

raw = open(a.book, encoding="utf-8").read().replace("\r\n", "\n").replace("﻿", "")
s = re.search(r"^\*\*\* ?START OF.*$", raw, re.M)
e = re.search(r"^\*\*\* ?END OF.*$", raw, re.M)
lines = raw[s.end():e.start()].split("\n")
i0 = 0
if a.after:
    i0 = next(i for i, l in enumerate(lines) if l.strip() == a.after) + 1
i = next(k for k in range(i0, len(lines)) if lines[k].strip() == a.start)
j = next(k for k in range(i + 1, len(lines)) if lines[k].strip() == a.end)
L = lines[i:j]

# Mark preformatted tables (any block containing a ruled line of dashes):
# the caption is the run of non-blank lines directly above the first rule;
# the block runs on over indented/blank lines until unindented text or a
# line preceded by two blank lines. Each block becomes one marker line.
def _ind(l):
    return len(l) - len(l.lstrip(" "))
_out, _k = [], 0
while _k < len(L):
    if re.match(r"\s*-{10,}\s*$", L[_k]):
        cap = []
        while _out and _out[-1].strip():
            cap.insert(0, _out.pop().strip())
        _k += 1
        while _k < len(L):
            t = L[_k]
            if t.strip() and _ind(t) == 0 and not re.match(r"-{10,}", t.strip()):
                break
            if t.strip() and _k >= 2 and not L[_k - 1].strip() and not L[_k - 2].strip():
                break
            _k += 1
        c = " ".join(cap) or "Table"
        _out += ["@@TABLE@@" + c, ""]
        continue
    _out.append(L[_k])
    _k += 1
L = _out


def indent(l):
    return len(l) - len(l.lstrip(" "))


def is_heading(k):
    l = L[k]
    t = l.strip()
    if not t or indent(l) < 8 or len(t) > 70 or t.endswith((".", ",", ";")):
        return False
    if t.startswith(("[", "Figure", "Table", "*", "Page")) or re.search(r"\d\s*$", t) and not t.isupper():
        return False
    if k > 0 and L[k - 1].strip():
        return False
    if k + 1 < len(L) and L[k + 1].strip() and indent(L[k + 1]) >= 8:
        return False  # part of a centered block (title page, table)
    if a.caps_only and not t.isupper():
        return False
    return True


def clean(t):
    t = re.sub(r"(?<![\w])_(\S(?:.*?\S)?)_(?![\w])", r"\1", t)
    t = re.sub(r"(?<![\w=])=(\S(?:.*?\S)?)=(?![\w=])", r"\1", t)
    return t


out, kept_text = [], []
parent = None
k = 0
para = []


def flush():
    if para:
        out.append(clean(" ".join(x.strip() for x in para)))
        out.append("")
        para.clear()


while k < len(L):
    l = L[k]
    t = l.strip()
    if not t:
        flush()
        k += 1
        continue
    if is_heading(k):
        flush()
        if t.isupper():
            parent = t
            out.append("## " + clean(t))
        else:
            h = clean(t)
            prev = [x for x in out if x.strip()]
            if parent and prev and prev[-1] == "## " + clean(parent):
                while out and out[-1] != "## " + clean(parent):
                    out.pop()
                out[-1] = f"## {clean(parent)}: {h}"
            else:
                out.append("## " + h)
        out.append("")
        k += 1
        continue
    if t.startswith("@@TABLE@@"):
        flush()
        out.append(f"[{clean(t[9:]).rstrip()} — table not included; see the original]")
        out.append("")
        k += 1
        continue
    if indent(l) >= 1 and re.match(r"Table \d+", t):
        flush()
        cap = [t]
        k += 1
        while k < len(L) and L[k].strip() and not L[k].strip().startswith("-"):
            cap.append(L[k].strip())
            k += 1
        # consume the table: indented or blank lines, until a non-indented
        # text line or a heading (preceded by 2+ blank lines)
        while k < len(L):
            if L[k].strip() and indent(L[k]) == 0:
                break
            if L[k].strip() and k >= 2 and not L[k - 1].strip() and not L[k - 2].strip():
                break
            k += 1
        capt = clean(" ".join(cap)).rstrip()
        out.append(f"[{capt} — table not included; see the original]")
        out.append("")
        continue
    if t.startswith("[Illustration"):
        flush()
        ill = []
        while k < len(L) and "]" not in L[k]:
            ill.append(L[k].strip())
            k += 1
        ill.append(L[k].strip() if k < len(L) else "")
        k += 1
        inner = " ".join(ill).strip()
        inner = re.sub(r"^\[Illustration:?\s*", "", inner).rstrip("]").strip()
        if re.match(r"(Figure|Fig\.|FIG\.)\s*\d", inner):
            out.append(f"[{clean(inner)} — figure not included]")
            out.append("")
        cap = []
        while k < len(L) and L[k].strip() and not L[k].strip().startswith("[Illustration"):
            cap.append(L[k].strip())
            k += 1
        if cap:
            out.append(f"[{clean(' '.join(cap))} — figure not included]")
            out.append("")
        continue
    if indent(l) >= 2 and re.match(r"(\d+\.|•|\*|\[\d+\]|[a-z]\.)\s", t):
        flush()
        para.append(t)
        k += 1
        while k < len(L) and L[k].strip() and indent(L[k]) > indent(l) and not re.match(r"(\d+\.|•|\[\d+\])\s", L[k].strip()):
            para.append(L[k].strip())
            k += 1
        flush()
        out[-1:] = []  # list items: no blank line between them
        out.append("")
        continue
    para.append(t)
    k += 1
flush()

# --skip: drop named sections
text = "\n".join(out)
for sk in a.skip:
    m = re.search(r"^## " + re.escape(sk) + r"\s*$", text, re.M)
    if not m:
        sys.exit(f"skip heading not found: {sk}")
    n = re.search(r"^## ", text[m.end():], re.M)
    text = text[:m.start()] + (text[m.end() + n.start():] if n else "")
    print(f"skipped section: {sk}", file=sys.stderr)

body = re.sub(r"\n{3,}", "\n\n", text).strip()
if not body.startswith("## "):
    body = "## Overview\n\n" + body
md = f"# {a.title}\nSource: {a.source_url}\n\n" + body + "\n"
open(a.out, "w", encoding="utf-8").write(md)
w = lambda x: set(re.findall(r"[a-z0-9]+", x.lower()))
lost = sorted(w("\n".join(L)) - w(md))
print(f"wrote {a.out}: {md.count(chr(10) + '## ')} sections, {len(md)} chars; "
      f"words not in output ({len(lost)}): {lost[:40]}", file=sys.stderr)
PY
DJ="python3 $TMP/djvu2md.py"
PGM="python3 $TMP/pg2md.py"
ops() { local a=(); while IFS= read -r l; do [[ -n "$l" ]] && a+=(--op "$l"); done
       if (( ${#a[@]} )); then printf '%s\0' "${a[@]}"; fi; }
dj() {  # dj <name> <out.md> <title> <start> <end> [extra args...] ; ops on stdin
  local n=$1 o=$2 t=$3 s=$4 e=$5; shift 5
  local -a O=(); while IFS= read -r -d '' x; do O+=("$x"); done < <(ops)
  $DJ "$SRC/${n}_djvu.txt" "$o" --title "$t" --source-url "$(iapdf "$n")" \
    --start "$s" --end "$e" "$@" ${O[@]+"${O[@]}"}
}

# =========================================================================
# 07-gardening (needs-review): USDA, 1947-1980. Superseded/older official
# guidance; varieties, fertilizer products and pesticide advice are dated.
# =========================================================================
D=content/07-gardening; mkdir -p $D

# Agriculture Fact Sheet AFS-4-5-1, Making and Using Compost (USDA Office of
# Communication, 1980; "Orginally prepared by: Cooperative Extension
# Service, University of Missouri"). Whole sheet; the bin cross-section
# figure label is dropped.
dj compost $D/01-making-and-using-compost.md \
  "Making and Using Compost (USDA Agriculture Fact Sheet 4-5-1, 1980)" \
  "What is Compost?" "Agriculture Fact Sheet" --heading "Using Compos!" <<'OPS'
drop|Cross Section of Layering
OPS

# AFS-8-9-1, Starting Plants From Seeds (USDA Office of Communication, 1977;
# written by R. R. Rothenberger, University of Missouri Extension). Held
# back: Table 1 (vegetable sowing guide) and Table 2 (annual flower sowing
# guide) — their cells are scattered through the OCR text, and Table 2's
# last cell is fused with the "Light"/"Temperature" text that follows it,
# so those two paragraphs go with it. Figure 1 labels dropped.
dj seeds $D/02-starting-plants-from-seeds.md \
  "Starting Plants From Seeds (USDA Agriculture Fact Sheet 8-9-1, 1977)" \
  "Growing plants from seeds" "Agriculture Fact Sheet" <<'OPS'
drop|Cover seeds with dry vermiculite
drop|. -vermiculite
drop|- Soil mixture
drop|Sphagnum over drainage cracks
cutrange|TABLE 1. GUIDE|6. Slip the flats
cutrange|Plants need some red and infrared|Moisture end Watering
OPS

# AFS-8-3-1, Growing Peanuts — on an Acre or Less (USDA Science and
# Education Administration, December 1979; R. K. Howell, SEA research
# plant pathologist). Whole sheet up to the company-name disclaimer.
dj peanuts $D/03-growing-peanuts.md \
  "Growing Peanuts on an Acre or Less (USDA Agriculture Fact Sheet 8-3-1, 1979)" \
  "Peanuts are a versatile crop" "Company names are used" <<'OPS'
join|stakes in center of|shocks. Lids
OPS

# Leaflet 160, Crimson Clover (USDA, issued June 1938, revised January 1947;
# E. A. Hollowell, Bureau of Plant Industry), PG #63170. Cover crop, green
# manure, and hand-harvested seed. "=Heading=" lines (PG bold markup) are
# turned into centered heading lines for pg2md.py. Figure 1 (map) precedes
# the extract.
python3 - "$SRC/pg-crimson.txt" "$TMP/crimson.txt" <<'PY2'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s = re.sub(r"(?m)^=([^=\n]+)=$", lambda m: "\n          " + m.group(1) + "\n", s)
open(sys.argv[2], "w", encoding="utf-8").write(s)
PY2
$PGM "$TMP/crimson.txt" $D/04-crimson-clover.md \
  --title "Crimson Clover (USDA Leaflet 160, rev. 1947)" --source-url "$PG/ebooks/63170" \
  --start "CRIMSON clover (_Trifolium incarnatum_) is the most important winter" \
  --end "U. S. GOVERNMENT PRINTING OFFICE: 1947"

# =========================================================================
# 07b-livestock (needs-review): USDA, 1964-1981.
# =========================================================================
D=content/07b-livestock; mkdir -p $D

# Raising Livestock on Small Farms (USDA Agricultural Research Service,
# 1977). From the title through "Housing" for hogs; the "Additional
# information" publication list is not used. Fixes: a garbled "for more
# information" sidebar is dropped; captions split around photos joined.
# Held back (illegible quantities): chick and poult floor space ("IV2"),
# hardware-cloth size ("21//9"), goat winter ration ("l1/*"), goat
# pregnancy grain ("V2"), sheep winter grain ("14 to %"), hutch depth ("2^2").
dj smallfarms $D/01-raising-livestock-on-small-farms.md \
  "Raising Livestock on Small Farms (USDA ARS, 1977)" \
  "RAISING LIVESTOCK ON SMALL FARMS" "ADDITIONAL INFORMATION" --plain "Percent of ration" <<'OPS'
drop|For additional or more specific cultural college
drop|ST-481-22
drop|LA-D7-2
join|grazing on improved pasture of clover and|dallisgrass.
join|Sheep are sheared in the spring|or early summer
join|In addition to raising rabbits|for the home meat supply
join|Flemish Giant|a large
join|a large|breed of rabbit
join|A number of ingredients or|combinations of ingredients
join|combinations of these. In the|South, bermudagrass
join|churned for 30 to|40 minutes, butter
cutpara|Day-old chicks require a well-built
cutpara|Poults require a well-built
cutpara|Use sand for litter
cutpara|If a goat giving milk is not on pasture
cutpara|Pregnant does should be fed all the roughage
cutpara|In the winter when no pasture is available, sheep
cutpara|Rabbits are usually kept in hutches
OPS

# AFS-3-6-2, Keeping Layers for the Family Egg Supply (USDA Office of
# Communication, 1977; written by Glenn Geiger and Walter Russell,
# University of Missouri). Whole sheet except the reference list. Held
# back: two paragraphs whose sizes read "1 l/4-inch" and "2 l/2-inch".
dj layers $D/02-keeping-layers-for-family-eggs.md \
  "Keeping Layers for the Family Egg Supply (USDA Agriculture Fact Sheet 3-6-2, 1977)" \
  "Many farm families" "References" --heading "Suggestions For Building A Colony Cage" <<'OPS'
join|Figure 3 - Cutting the floor|Take a piece of
join|create tension;|then fasten with staples
cutpara|Use a candling light to detect
cutpara|6. Leave a 2 l/2-inch space
OPS

# Farmers' Bulletin 2131, Raising Rabbits (USDA ARS Animal Husbandry Research
# Division, revised 1964). Body from "RAISING RABBITS" to the GPO imprint.
# Dropped: the two captions credited "(Courtesy of Small Stock Magazine.)",
# a photo number, a stray "I _". Held back: breed descriptions (every
# weight fraction illegible, e.g. "IOV2", "3V2"), hutch-card and buck
# record forms (layout), and paragraphs with illegible sizes or amounts.
dj rabbits $D/03-raising-rabbits.md \
  "Raising Rabbits (USDA Farmers' Bulletin 2131, rev. 1964)" \
  "RAISING RABBITS" "U.S. GOVERNMENT PRINTING OFFICE" \
  --heading "Feeding Pregnant Does and Does With Litters" <<'OPS'
join|meat rabbits.|Left, New
join|Left, New|Zealand. Right, Californian.
join|weaned and ready|for market.
join|from the records can be|used to cull
drop|Figure 2. — Rabbitry adapted
drop|Figure 3. -Typical rabbitry
drop|1 1527-D
drop|I _
join|should be fed spar-|ingly to rabbits
join|Try to maintain one buck for|each 10 breeding does
cutrange|American Chinchilla. — Show|SELECTING FOUNDATION STOCK
cutrange|HUTCH CARD|Hot Weather Care
cutpara|Provide individual hutches for mature rabbits
cutpara|If mesh flooring is used
cutpara|Nail kegs also make
cutpara|Junior does and bucks
cutpara|Does that are maintained in good
cutpara|A box 9 inches long
OPS

# Farmers' Bulletin 2222, Raising a Small Flock of Sheep (USDA ARS, issued
# July 1966, revised November 1977). Fixes: the shearing column printed out
# of order is moved back. Held back: costs-and-returns table, and the three
# daily rations whose fractions are illegible ("^ to *A", "Vi to 3 A").
dj sheep $D/04-raising-a-small-flock-of-sheep.md \
  "Raising a Small Flock of Sheep (USDA Farmers' Bulletin 2222, rev. 1977)" \
  "If you have grassland" "Reviewed by" <<'OPS'
cutrange|COSTS AND RETURNS FOR A BREEDING EWE|Figure 1.
join|If ewes nurse lambs|after lambing, continue grain
cutrange|For a pregnant or fresh ewe getting|It will take about 500 pounds
cutrange|A pregnant or fresh ewe that gets|An efficient concentrate
cutrange|An excellent ration for creep|This amount of mixture would feed
move|paper twine.|dry shed.|Then roll the fleece
join|in a warm,|dry shed.
join|Tie the fleece with|paper twine.
join|Agricultural Stabilization|and Conservation office
OPS

# Farmers' Bulletins 2263 (Beef, issued 1977), 2264 (Lamb, August 1977) and
# 2265 (Pork, June 1978, slightly revised April 1981): "… Slaughtering,
# Cutting, Preserving, and Cooking on the Farm", by H. R. Cross and A. W.
# Kotula (ARS), E. C. Green (AMS/FSQS), W. R. Jones (Auburn University
# Extension) and R. L. West (University of Florida); PG #62848, #62838,
# #62859. From "Selection and care of animal before slaughter" to the end.
# Tables are replaced by markers (cut yields "Adapted from Smith, King &
# Carpenter, 1975" — third party; beef roasting timetable). Held back:
# beef Curing, Corned Beef, Dried Beef, Canning; pork Curing Pork, Dry
# Curing, Sweet Pickle Cure, Pumping Hams and Shoulders, Smoking (with its
# Smokehouses / Smoking Process / Storage of Smoked Meats parts), Canning,
# and Pickled Pigs’ Feet (it uses the held-back ham-curing brine).
$PGM "$SRC/pg-beef.txt" $D/05-beef-slaughtering.md \
  --title "Beef Slaughtering, Cutting, and Cooking on the Farm (USDA Farmers' Bulletin 2263, 1977)" \
  --source-url "$PG/ebooks/62848" --start "SELECTION AND CARE OF ANIMAL BEFORE SLAUGHTER" \
  --after "BEEF SLAUGHTERING, CUTTING, PRESERVING, AND COOKING ON THE FARM" \
  --end "U.S. GOVERNMENT PRINTING OFFICE" \
  --skip "FURTHER PROCESSING: Curing" "Corned Beef" "Dried Beef" "Canning"
$PGM "$SRC/pg-lamb.txt" $D/06-lamb-slaughtering.md \
  --title "Lamb Slaughtering, Cutting, and Cooking on the Farm (USDA Farmers' Bulletin 2264, 1977)" \
  --source-url "$PG/ebooks/62838" --start "SELECTION AND CARE OF ANIMAL BEFORE SLAUGHTER" \
  --after "Lamb Slaughtering, Cutting, Preserving and Cooking on the Farm" \
  --end "☆ U.S. GOVERNMENT PRINTING OFFICE: 1977 O-244-090"
$PGM "$SRC/pg-pork.txt" $D/07-pork-slaughtering.md \
  --title "Pork Slaughtering, Cutting, and Cooking on the Farm (USDA Farmers' Bulletin 2265, rev. 1981)" \
  --source-url "$PG/ebooks/62859" --start "SELECTION AND CARE OF ANIMAL BEFORE SLAUGHTER" \
  --after "Slightly revised April 1981" --end "OTHER PUBLICATIONS" \
  --skip "FURTHER PROCESSING: Curing Pork" "Dry Curing" "Sweet Pickle Cure" \
         "Pumping Hams and Shoulders" "Smoking" "Smokehouses:" "Smoking Process:" \
         "Storage of Smoked Meats:" "Canning" "Pickled Pigs’ Feet"

# =========================================================================
# 07c-farm-historical (historical): pre-1929 public-domain books.
# =========================================================================
D=content/07c-farm-historical; mkdir -p $D
XT="python3 tools/packs/extract_text.py"

# F. F. Rockwell, Home Vegetable Gardening (1911; the text dates its prices
# "1911 values"), PG #7123. Chapters VI-XI and XIV. Not used: I-V
# (introduction, planting-plan tables, implements), XII (varieties), XIII
# (insects and diseases: arsenicals, corrosive sublimate), XV-XX (fruit).
# Run-in vegetable heads ("_Beet:_--") also become section headings, and
# PG underscore italics are removed (structure only). Held back: the
# eggplant paragraph recommending Paris green / arsenate of lead.
RW="$PG/ebooks/7123"
rock() {  # rock <chapter> <out> <title>
  $XT "$SRC/pg-rockwell.txt" --chapter "$1" --title "$3 (F. F. Rockwell, Home Vegetable Gardening, 1911)" \
    --source-url "$RW" -o "$2"
  python3 - "$2" <<'PY2'
import re, sys
p = sys.argv[1]
out, sec = [], None
for l in open(p, encoding="utf-8").read().split("\n"):
    if l.startswith("## "):
        sec = l[3:]
    m = re.match(r"_([^_]+?):_\s*--", l)
    if m and sec:
        out += [f"## {sec.split(': ')[0]}: {m.group(1)}", ""]
    if l.startswith("Watch for potato-bugs on your egg-plants"):
        l = ("[Passage not included here: it recommends obsolete, hazardous "
             "insecticides (Paris green, arsenate of lead, hellebore); see the original]")
    if not l.startswith(("# ", "Source:")):
        l = re.sub(r"(?<![\w])_(\S(?:.*?\S)?)_(?![\w])", r"\1", l)
    out.append(l)
open(p, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", "\n".join(out)))
PY2
}
rock "MANURES AND FERTILIZERS" $D/01-manures-and-fertilizers.md "Manures and Fertilizers"
rock "THE SOIL AND ITS PREPARATION" $D/02-soil-preparation.md "The Soil and Its Preparation"
rock "STARTING THE PLANTS" $D/03-starting-the-plants.md "Starting the Plants"
rock "SOWING AND PLANTING" $D/04-sowing-and-planting.md "Sowing and Planting"
rock "THE CULTIVATION OF VEGETABLES" $D/05-cultivation.md "The Cultivation of Vegetables"
rock "THE VEGETABLES AND THEIR SPECIAL NEEDS" $D/06-vegetables-special-needs.md "The Vegetables and Their Special Needs"
rock "HARVESTING AND STORING" $D/07-harvesting-and-storing.md "Harvesting and Storing"

# J. N. DeLamater, A Revised and Illustrated Treatise on Grain Stacking
# (Norwalk, Ohio, 1884), PG #37034: stacking bound grain sheaves so they
# keep until threshing. The book has no CHAPTER lines; one is inserted
# before the body title for extract_text.py (title page, copyright line
# and preface are not extracted).
python3 - "$SRC/pg-stacking.txt" "$TMP/stacking.txt" <<'PY2'
import sys
s = open(sys.argv[1], encoding="utf-8").read().replace("\r\n", "\n")
j = s.index("\nTREATISE ON GRAIN STACKING.\n")
open(sys.argv[2], "w", encoding="utf-8").write(s[:j + 1] + "CHAPTER I.\n" + s[j + 1:])
PY2
$XT "$TMP/stacking.txt" --chapter "TREATISE ON GRAIN STACKING" \
  --title "A Treatise on Grain Stacking (J. N. DeLamater, 1884)" \
  --source-url "$PG/ebooks/37034" -o $D/08-grain-stacking.md
# PG underscore italics removed (markup, not text).
python3 - $D/08-grain-stacking.md <<'PY2'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(re.sub(r"(?<![\w])_(\S(?:.*?\S)?)_(?![\w])", r"\1", t))
PY2

# =========================================================================
# NOT INCLUDED (see report 2026-10-29)
# - Bot walls (HTTP 403, not circumvented): USDA APHIS (Biosecurity for
#   Birds / Defend the Flock), CDC Healthy Pets backyard poultry, usda.gov,
#   FSIS, Peace Corps library. NRCS and NIFA sites timed out.
# - EPA "Composting At Home" (epa.gov answers): EPA content is kept in
#   EPA-only packs (docs/decisions.md) — needs its own pack.
# - FEMA IS-111.A Livestock in Disasters: interactive web course only.
# - 1977 Yearbook of Agriculture "Gardening for Food and Fun": 3-column
#   PDF text layer interleaves columns; many chapters by non-federal authors.
# - FB 2182 Growing Summer Cover Crops (1965): seeding-rate table cells and
#   photo numbers fused into body sentences.
# - FB 2197 Farm Poultry Management (1977): commercial scale; feed formula
#   tables, arsenical feed additives, insecticide mixes throughout.
# - AFS Vegetable Harvest and Storage (1977): content is a chart (table).
# - Small Poultry Flocks (1977): adapted from a Clemson University circular.
# - FB 920 Milk Goats (1955): poor OCR; dusting/dip recipes (rotenone,
#   methoxychlor) and drenches.
# - FB 2204 beekeeping equipment and Leaflet 549 pollination: commercial
#   honey-house / crop-pollination focus.
# =========================================================================
echo "batch4_agriculture: done"
