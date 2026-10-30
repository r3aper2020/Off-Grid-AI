#!/usr/bin/env bash
# Batch 5 (family): additions to two existing packs.
#   content/17b-household-historical (id household-historical, historical):
#     + 09 USDA Farmers' Bulletin 1334, Home Tanning of Leather and Small
#         Fur Skins (Frey, Clarke & Veitch, 1923) — NAL scan on archive.org.
#     + 10 USDA Farmers' Bulletin 1438, Making Fermented Pickles
#         (LeFevre, 1924) — Project Gutenberg #48722 transcription.
#   content/18-vulnerable-groups (id vulnerable-groups): NOTHING ADDED —
#     every assigned source was unreachable from a script (see BLOCKED).
#
# Usage: tools/packs/recipes/batch5_family.sh <source-dir> [--fetch]
#   --fetch downloads the sources into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3; all answered HTTP 200 on
#   2026-10-30). Run from the project root; then
#   python3 tools/packs/build_pack.py content/17b-household-historical
#
# LICENSE (checked 2026-10-30):
# - FB 1334 (1923) and FB 1438 (1924): U.S. Department of Agriculture
#   publications — U.S. Government works (17 U.S.C. § 105), and in any case
#   published in the U.S. before 1929. archive.org item CAT87202829 is the
#   National Agricultural Library's own scan ("contributor: U.S. Department
#   of Agriculture, National Agricultural Library"; "The contributing
#   institution believes that this item is not in copyright"). The NALDC
#   catalog (https://naldc.nal.usda.gov/catalog/CAT87202829) now renders
#   through a JavaScript (Primo) viewer that returns no document to curl,
#   so the NAL scan was taken from archive.org instead. The PG #48722 text
#   was "produced from materials made available at The Internet Archive";
#   the PG header/footer (license, trademark) are stripped. Both bulletins
#   were scanned for "©", "copyright", "courtesy", "permission",
#   "reprinted": no hits except the PG license. The 1334 combination
#   tannage cites "M. C. Lamb" as the source of a formula (a published
#   formula, not quoted text); its footnote reference is dropped.
#
# OCR CHECK (FB 1334). The archive.org PDF text layer is the NAL OCR. Every
# page was scanned for non-ASCII characters and digit/letter mixes, and
# every hit was checked by eye against the page image (pypdfium2 render at
# 4-5x). The text is clean except the fractions and a few words, all fixed
# below in FIX (each one verified against the printed page):
#   p16 "3J pounds" -> 3½ pounds   p17 "If pounds" -> 1¾ pounds
#   p17 "1£ gallons" -> 1½ gallons  p17 "4| gallons" -> 4½ gallons
#   p14 "1^ pints" -> 1¼ pints      p18 "1J pints" -> 1¼ pints
#   p4 "(E) ... IJ inches thick" -> 1½ inches; p13 "1^ inches thick at the
#   head" -> 1½ inches; "hurdwood" -> hardwood;
#   p4 "(F) ... about è inch thick" -> ½ inch; "SL dull" -> a dull
#   p10 "AH flesh" -> All flesh; p11 "much oí the lime" -> much of;
#   p11 "UDbaired" -> Unhaired; p8 "PIG. 3.—Eeady" -> FIG. 3.—Ready;
#   p6 "split Into", "folded Over" -> into, over; p21 "©f" -> of;
#   p25 "Terra Japónica" -> Terra Japonica; p26 "correctly • speaking"
#   (ink speck) -> correctly speaking; p16 "(^crystallized" ->
#   (crystallized; p18 "Thin leather.^—" -> Thin leather.—; p3 "legSf" ->
#   legs,; Fig. 9 labels "HINK FOX OTTER" dropped (figure labels); and the
#   stray marks/misreads 'clean "half barrel', "bucketf uls", "dampen^",
#   "Kubbing", "#many", "chlond", "while^pushing", "polling", "less, need",
#   "liesin", "gone m,", "entirely, covered", "(Fig, 5)", "Is drying" (Fig. 8
#   caption), running heads misread as "* Hoirie Tanning. 15" and "Home
#   Tunning." — all checked against the page images.
#   Paragraphs broken by page breaks and figures are re-joined (a paragraph
#   not ending in sentence punctuation continues in the next text
#   paragraph; "sul-/phuric", "occa-/sionally", "beat-/ing", "follow-/ing"
#   lose the break hyphen); the chrome-leather DELIMING heading, which the
#   layout put after the first line of its paragraph, is moved in front.
#   Footnote 3 (the Lamb citation: "Leather Trades Review, Aug. 20, 1913,
#   p. 596") is dropped with the other footnotes.
#   The dressing-formulas table (p15) came out scrambled ("PetrolatUBj
#   __i__^___ 8 ...") and is written out below one line per row, copied
#   from the page image. An ERRATA SLIP bound in after p4 replaces the
#   caption of tool (D), whose fractions did not print ("5 inches square,
#   to inch thick"): the errata wording "1/32 to 1/16 inch thick" is used
#   and the slip itself dropped.
#   p5 (Slaking lime) has a torn corner: "[co]vered with boards or sacks",
#   "[I]f available, ... may be used in-[stead] of the burnt or caustic
#   lime. In this case use from 8 to 10 [pou]nds in 4 or 5 gallons". The
#   missing letters are restored from the identical sentences in the 1929
#   and 1930 reprints (archive.org CAT31295343 / CAT31295344 OCR: "covered
#   with boards or sacks until ready to use it. / If available, fresh
#   hydrated lime, not air-slaked, may be used in- / stead of the burnt or
#   caustic lime. In this case use from 8 to 10 / pounds in 4 or 5 gallons
#   of water.").
#   p8 Fig. 3 caption: "Wien the hair can be rubbefl off" -> When ... rubbed
#   off (second caption sentence, read before the "FIG. 3" line).
#   Line-break hyphens that pdfminer kept inside words are rejoined (list
#   DEHYPH); real compounds (bark-tanned, neat's-foot) are untouched.
#   Footnotes about ordering free USDA publications and their markers
#   ("Marketing,1", "Lamb.3") are dropped; running heads and page numbers
#   are dropped; "FIG. n.—" captions are kept as text and marked
#   "— figure not included"; the Fig. 1 tool descriptions (A)-(F) are kept.
#   NAL's "Historic, archived document" banner, the cover, the contents and
#   the back-matter publication lists are not included.
#
# FB 1438 (pickles): Project Gutenberg text, verbatim via gtext (copied
#   from batch4_selfsufficiency.sh). Its four ASCII tables (salt/salinometer
#   /ounces per 6 quarts, brine freezing points, sugar sirup density,
#   cucumbers per gallon) are written out one row per line in pgtable.py,
#   copied cell by cell from the transcription and re-checked against it. Illustrations marked not
#   included. "Coloring and hardening agents" (warns copper greening is
#   poisonous) is kept. Gutenberg transcription typos ("several clays",
#   "p referred", "60° F,;") left as is; its one garbled number, "2| per
#   cent" of salt for sauerkraut, is restored to "2½ per cent" from the
#   printed page (archive.org CAT10305679, the NAL scan of the same 1924
#   edition, p. 13, checked by eye).
#
# BLOCKED — fetch by browser (HTTP 403 "Access Denied" (Akamai) to curl with
# a browser User-Agent; one attempt each, not circumvented):
#   USDA APHIS (www.aphis.usda.gov — the whole host, including /):
#     https://www.aphis.usda.gov/search?keys=pets+in+disasters
#     https://www.aphis.usda.gov/search?keys=livestock+emergency
#     https://www.aphis.usda.gov/search?keys=Protect+your+pets+in+an+emergency
#     (page paths unverified because the search itself is blocked)
#   www.usda.gov (also 403): https://www.usda.gov/topics/disaster-resource-center
#   CDC (www.cdc.gov):
#     https://www.cdc.gov/nutrition/emergencies-infant-feeding/index.html
#       (Infant and Young Child Feeding in Emergencies / Feeding your baby
#       during an emergency)
#     https://www.cdc.gov/nutrition/emergencies-infant-feeding/ — the
#       "Safely prepare infant formula with emergency water" page under
#       this section (exact file name unverified)
#   FEMA (www.fema.gov):
#     https://www.fema.gov/emergency-managers/national-preparedness/children
#
# EXCLUDED (and why):
#   - ASPR HHS Maternal-Child Health Emergency Planning Toolkit (May 2021,
#     80 pp.) and Child and Adolescent Health Emergency Planning Toolkit
#     (2023): reachable (aspr.gov), but written for health-care, public
#     health and social-services providers (planning steps, Title V, case
#     studies), "developed ... in collaboration with the federal
#     interagency and other partners" (non-federal co-authorship not
#     excluded), and the only family-level content is a one-box list.
#     ASPR's "Hurricane Response – Resources for Children with Special
#     Health Care Needs" page is a link list (AAP, NCTSN, ACEP — all
#     third-party). No ASPR page on children's needs in shelters found.
#   - USDA "Soap-making at home" (1933), "Candle making" (1940), "Care and
#     use of rope on the farm" (1943): post-1929 (would be needs-review,
#     and the pack is historical). No pre-1929 USDA soap/candle/rope
#     bulletin found on archive.org (title searches 2026-10-30).
#   - The assignment named "Farmers' Bulletin 1693 Making Fermented
#     Pickles"; the bulletin with that title is FB 1438 (1924, superseding
#     FB 1159). The 1920/1922 "Fermented pickles" editions on archive.org
#     are OCR scans and were not needed.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
V=2026.10.30.2

IA_1334=https://archive.org/download/CAT87202829/farmbul1334.pdf
IA_1334_PAGE=https://archive.org/details/CAT87202829
PG_1438=https://www.gutenberg.org/ebooks/48722

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  dl farmbul1334.pdf "$IA_1334"
  dl pg48722.txt "$PG_1438.txt.utf-8"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
D=content/17b-household-historical; mkdir -p $D

# =========================================================================
# 09 Home Tanning of Leather and Small Fur Skins (FB 1334, 1923)
# =========================================================================
$XP "$SRC/farmbul1334.pdf" --source-url "$IA_1334_PAGE" --caps-headings \
  --title "Home Tanning of Leather and Small Fur Skins (USDA Farmers' Bulletin 1334, 1923)" \
  -o "$TMP/tanning-raw.md"

cat > "$TMP/tanfix.py" <<'PY'
"""Post-process extract_pdf output of FB 1334 (see recipe header)."""
import re, sys
src, out = sys.argv[1:3]
lines = open(src, encoding="utf-8").read().split("\n")
head = lines[:2]                                    # "# title" / "Source:"
body = lines[2:]

# Slice: from the cover summary to the back-matter publication list.
i = next(k for k, l in enumerate(body) if l.startswith("ORDINARILY hides"))
j = next(k for k, l in enumerate(body) if "PUBLICATIONS OF THE UNITED STATES DEPARTMENT" in l)
body = body[i:j]
# Cut the title/authors/contents block (from the "## HOME TANNING" heading
# the extractor made to the first paragraph of the text).
a = next(k for k, l in enumerate(body) if l.startswith("## HOME TANNING"))
b = next(k for k, l in enumerate(body) if l.startswith("THE TANNING of a few"))
del body[a:b]

# Running heads / page numbers, print signature, figure labels, the errata
# slip (applied below), footnotes about ordering free publications and the
# Lamb citation footnote, and headings the extractor made out of them.
DROP = [r"^(\d+ )?Farmers[9'] Bulletin \S{1,6}$", r"^\*? ?Ho\w+ T\w+ning\.( \d+)?$",
        r"^Home Tanning\. W~\\$", r"^47763°—23 2$", r"^W~\\$", r"^(HINK|MINK|FOX|OTTER)$", r"^## ",
        r"^ERRATA SLIP, FARMERS' BULLETIN 1334, PAGE 4\.$",
        r"^\(D\) Metal slicker - a dull steel blade about 5$",
        r"^inches square, l/3â tç 1/16 inch thick, mounted in a wooden handle\.$",
        r"^1 A copy of Farmers' Bulletin 1055 may be had free upon request",
        r"^2 A copy of this separate may be obtained upon request",
        r"^& Leather Trades Review, Aug\. 20, 1913, p\. 596\.$"]
body = [l for l in body if not any(re.search(p, l.strip()) for p in DROP)]
# Second line of footnote 1 (only this exact line, which follows it).
body = [l for l in body if l != "Publications, United States Department of Agriculture, Washington, D. C."]
text = "\n".join(body)
text = re.sub(r"\n{3,}", "\n\n", text)

def rep(old, new):
    global text
    assert old in text, f"target missing: {old!r}"
    text = text.replace(old, new)

# Errata slip applied to the tool (D) caption (fractions did not print).
rep("(D) Metal slicker—SL dull steel blade about 5 inches square, to inch thick,\n\nmounted in a wooden handle.",
    "(D) Metal slicker—a dull steel blade about 5 inches square, 1/32 to 1/16 inch thick, mounted in a wooden handle.")
# Torn corner, p. 5 (letters restored from the 1929/1930 reprints).
rep("^vered with boards or sacks", "covered with boards or sacks")
rep("Tf available, fresh hydrated lime, not air-slaked, may be used in-of the burnt or caustic lime. In this case use from 8 to 10\n\nads in 4 or 5 gallons",
    "If available, fresh hydrated lime, not air-slaked, may be used instead of the burnt or caustic lime. In this case use from 8 to 10 pounds in 4 or 5 gallons")
# The chrome-leather DELIMING heading was read after the first line of its
# first paragraph (page layout); put it back in front.
rep("After the sides have been put through the unhairing and fleshing\n\nDELIMING.\n\noperations (p. 9) rinse them off with clean water.",
    "DELIMING.\n\nAfter the sides have been put through the unhairing and fleshing operations (p. 9) rinse them off with clean water.")
# Scrambled dressing-formulas table (p. 15), rows copied from the page.
m = re.search(r"Formulai: Ounces\.\n.*?Tallow 12 Cod oil — 4", text, re.S)
assert m, "formulas block not found"
text = text[:m.start()] + """Formula 1 (ounces): Neutral wool grease 8; Dark petrolatum 4; Paraffin wax 4.

Formula 2 (ounces): Petrolatum 16; Beeswax 2.

Formula 3 (ounces): Petrolatum 8; Paraffin wax 4; Wool grease 4; Crude turpentine gum (gum thus) 2.

Formula 4 (ounces): Tallow 12; Cod oil 4.""" + text[m.end():]

# OCR corrections, each checked against the page image (see recipe header).
FIX = [("3J pounds", "3½ pounds"), ("If pounds of soda", "1¾ pounds of soda"), ("1£ gallons", "1½ gallons"),
       ("4| gallons", "4½ gallons"), ("1^ pints", "1¼ pints"), ("1J pints", "1¼ pints"),
       ("IJ inches thick at", "1½ inches thick at"), ("1^ inches thick at the head", "1½ inches thick at the head"),
       ("hurdwood", "hardwood"), ("about è inch thick", "about ½ inch thick"),
       ("AH flesh, fat", "All flesh, fat"), ("much oí the lime", "much of the lime"), ("UDbaired", "Unhaired"),
       ("folded\n\nOver a stick", "folded over a stick"), ("split Into two sides", "split into two sides"),
       ("©f neat's-f oot", "of neat's-foot"), ("Terra Japónica", "Terra Japonica"),
       ("correctly • speaking", "correctly speaking"), ("(^crystallized", "(crystallized"), ("Thin leather.^—", "Thin leather.—"),
       ("legSf and head", "legs, and head"), ("Marketing,1 should", "Marketing, should"), ("M. C. Lamb.3 A pasty", "M. C. Lamb. A pasty"),
       ("Trapping on the Farm.2", "Trapping on the Farm."), ("in-wet sacking", "in wet sacking"),
       ('in a clean "half barrel', "in a clean half barrel"), ("bucketf uls", "bucketfuls"), ("dampen^ again", "dampen again"),
       ("Kubbing over with sawdust", "Rubbing over with sawdust"), ("as #many months", "as many months"),
       ("(sodium chlond)", "(sodium chlorid)"), ("while^pushing", "while pushing"), ("polling them up", "pulling them up"),
       ("less, need for such", "less need for such"), ("soft skin liesin this", "soft skin lies in this"),
       ("has gone m, apply", "has gone in, apply"), ("tirely, covered", "tirely covered"), ("(Fig, 5)", "(Fig. 5)"),
       ("Stretching boards (for fur skins.", "Stretching boards for fur skins."),
       ("should be used for lace leather\n", "should be used for lace leather.\n")]   # full stop lost by OCR (p. 5)
for a, b in FIX:
    rep(a, b)
DEHYPH = "en-tirely urther-more tem-perature through-out re-turned re-ceipts pro-tection pro-motes mistreat-ment hap-pens enor-mous ap-proximately accord-ing".split()
for w in DEHYPH:
    rep(w, w.replace("-", ""))

# Figure captions (title + explanatory lines, which the layout scattered
# around the "FIG. n" line) become one marked paragraph each.
FIGS = [
 ("FIG. 1.—Tools for tanning.\n\n(A) Tanner's fleshing knife, having a blade 15 to 17 inches long: (a) Dull edge for\n\nscraping off the hair after liming; (b) very sharp edge for shaving off the flesh.\n\n"
  "(B) Eight-inch-blade drawing knife which may be used instead of A, especially if both handles are bent straight. The back edge may be used for unhairing and the cutting edge for shaving off the flesh.\n\n"
  "(C) Twelve-inch-blade butcher knife which may be used instead of A or B, when the\n\npoint has been driven into a wooden handle or wrapped with leather.\n\n"
  "(D) Metal slicker—a dull steel blade about 5 inches square, 1/32 to 1/16 inch thick, mounted in a wooden handle.\n\n"
  "(E) Wooden slicker, made of hardwood, about 6 inches square, 1½ inches thick at\n\nhead, shaved down in the shape of a wedge to a thin edge.\n\n"
  "(F) Stake for breaking up and softening skins and leather. A board about 3 feet long, 6 inches wide, and 1 inch thick is braced in an upright position to a heavy base or to the floor. The top of the board is rounded and thinned in the shape of a wedge to an edge about ½ inch thick.",
  "[Fig. 1.—Tools for tanning. — figure not included]\n(A) Tanner's fleshing knife, having a blade 15 to 17 inches long: (a) Dull edge for scraping off the hair after liming; (b) very sharp edge for shaving off the flesh.\n"
  "(B) Eight-inch-blade drawing knife which may be used instead of A, especially if both handles are bent straight. The back edge may be used for unhairing and the cutting edge for shaving off the flesh.\n"
  "(C) Twelve-inch-blade butcher knife which may be used instead of A or B, when the point has been driven into a wooden handle or wrapped with leather.\n"
  "(D) Metal slicker—a dull steel blade about 5 inches square, 1/32 to 1/16 inch thick, mounted in a wooden handle.\n"
  "(E) Wooden slicker, made of hardwood, about 6 inches square, 1½ inches thick at head, shaved down in the shape of a wedge to a thin edge.\n"
  "(F) Stake for breaking up and softening skins and leather. A board about 3 feet long, 6 inches wide, and 1 inch thick is braced in an upright position to a heavy base or to the floor. The top of the board is rounded and thinned in the shape of a wedge to an edge about ½ inch thick."),
 ("FIG. 2.—Putting a side into limewater.\n\nThe hide has been split into two sides, and soaked and cleaned. Each side is folded over a stick.",
  "[Fig. 2.—Putting a side into limewater. The hide has been split into two sides, and soaked and cleaned. Each side is folded over a stick. — figure not included]"),
 ("Wien the hair can be rubbefl off easily with the hand the hide is ready to be\n\nunhaired.\n\nPIG. 3.—Eeady to unhair after liming.",
  "[Fig. 3.—Ready to unhair after liming. When the hair can be rubbed off easily with the hand the hide is ready to be unhaired. — figure not included]"),
 ("After thorough liming, the hair is pushed or scraped off with a dull metal edge. At the same time some of the lime, grease, and dirt are worked out of the hide. Here the workman is using the dull edge of the fleshing knife and a tanner's beam.\n\nFIG. 4.—Unhairing.",
  "[Fig. 4.—Unhairing. After thorough liming, the hair is pushed or scraped off with a dull metal edge. At the same time some of the lime, grease, and dirt are worked out of the hide. Here the workman is using the dull edge of the fleshing knife and a tanner's beam. — figure not included]"),
 ("FIG. 5.—Fleshing.\n\nAll flesh, fat, and tissue must be shaved off down to the real hide or skin.",
  "[Fig. 5.—Fleshing. All flesh, fat, and tissue must be shaved off down to the real hide or skin. — figure not included]"),
 ("FIG. 6.—Unhaired, fleshed hide ready to be delimed.\n\nAll hair, flesh, and fat must be removed, as well as much of the lime and grease.",
  "[Fig. 6.—Unhaired, fleshed hide ready to be delimed. All hair, flesh, and fat must be removed, as well as much of the lime and grease. — figure not included]"),
 ("FIG. 7.—Slicking out.\n\nAfter tanning and after greasing, the leather should be worked out on both sides with\n\na slicker.",
  "[Fig. 7.—Slicking out. After tanning and after greasing, the leather should be worked out on both sides with a slicker. — figure not included]"),
 ("To soften leather and tanned skins, they must be worked repeatedly back and forth\n\nIn all directions over a dull edge. This must be done when the leather Is drying.\n\nStaking.",
  "[Fig. 8.—Staking. To soften leather and tanned skins, they must be worked repeatedly back and forth in all directions over a dull edge. This must be done when the leather is drying. — figure not included]"),
 ("FIG. 9.—Stretching boards for fur skins.\n\nCased fur skins are dried on boards of different sizes\n\nand shapes, depending upon the kind of skin.",
  "[Fig. 9.—Stretching boards for fur skins. Cased fur skins are dried on boards of different sizes and shapes, depending upon the kind of skin. — figure not included]"),
]
for a, b in FIGS:
    rep(a, b)
assert "FIG." not in text and "�" not in text

# Re-join paragraphs the page breaks and figures split: a paragraph that
# does not end in sentence punctuation continues in the next text
# paragraph (a hyphen at the break is removed); figure paragraphs in
# between are moved after the re-joined paragraph.
paras = [p for p in text.split("\n\n") if p.strip()]
HEAD = r"[A-Z][A-Z ,'-]{4,}\."
joined, k = [], 0
while k < len(paras):
    p = paras[k]; k += 1
    figs = []
    while not re.search(r"""[.:;!?"'\)\]]$""", p.rstrip()) and not re.fullmatch(HEAD, p) and k < len(paras):
        while k < len(paras) and paras[k].startswith("[Fig."):
            figs.append(paras[k]); k += 1
        if k >= len(paras) or re.fullmatch(HEAD, paras[k]):
            break
        nxt = paras[k]; k += 1
        p = (p[:-1] + nxt) if p.endswith("-") else (p + " " + nxt)
    joined.append(p); joined.extend(figs)
text = "\n\n".join(joined)

# Headings: ALL-CAPS lines ending in a period.
PARENTS = {"PRELIMINARY OPERATIONS", "BARK-TANNED SOLE AND HARNESS LEATHER", "CHROME-TANNED LEATHER",
           "ALUM-TANNED LACE LEATHER", "TANNING FUR SKINS"}
TOP = PARENTS | {"HAVING HIDES TANNED", "BUYING LEATHER BY THE SIDE", "HOME TANNING", "TANNING HIDES AND SKINS FOR LEATHER"}
SMALL = {"and", "of", "for", "by", "the", "from"}
def title(h):
    ws = [w.lower() for w in h.split()]
    return " ".join(("-".join(p.capitalize() for p in w.split("-")) if (k == 0 or w not in SMALL) else w) for k, w in enumerate(ws))
olines, parent = ["## Home Tanning of Leather and Small Fur Skins (Introduction)"], None
for l in text.split("\n"):
    if re.fullmatch(r"[A-Z][A-Z ,'-]{4,}\.", l):
        h = l[:-1]
        if h in TOP:
            parent = h if h in PARENTS else None
            olines.append("## " + title(h))
        else:
            olines.append("## " + (title(parent) + ": " if parent else "") + title(h))
    else:
        olines.append(l)
text = "\n".join(olines)
text = re.sub(r"\n{3,}", "\n\n", text)
# A parent heading with no text of its own (its first sub-heading follows
# at once) is dropped; the sub-headings carry its name as a prefix.
text = re.sub(r"^## [^\n]+\n+(?=## )", "", text, flags=re.M)

# Sections over 4000 characters are split at a paragraph break.
secs = re.split(r"(?m)^(?=## )", text)
final = []
for s in secs:
    if not s.strip(): continue
    h, _, bodyt = s.partition("\n")
    paras = [p for p in bodyt.split("\n\n") if p.strip()]
    chunk, n = [], 1
    for p in paras:
        if chunk and len("\n\n".join(chunk + [p])) > 3900:
            final.append((h if n == 1 else f"{h} (continued)", "\n\n".join(chunk))); chunk, n = [], n + 1
        chunk.append(p)
    final.append((h if n == 1 else f"{h} (continued)", "\n\n".join(chunk)))
md = "\n".join(head) + "\n" + "\n\n".join(f"{h}\n{b}" for h, b in final) + "\n"
open(out, "w", encoding="utf-8").write(md)
print(f"wrote {out}: {len(final)} sections, {len(md)} chars")
PY
$PY "$TMP/tanfix.py" "$TMP/tanning-raw.md" $D/09-home-tanning.md

# =========================================================================
# 10 Making Fermented Pickles (FB 1438, 1924) — PG #48722
# =========================================================================
# gtext: copied verbatim from tools/packs/recipes/batch4_selfsufficiency.sh.
awk '/^cat > "\$TMP\/gtext.py" <<'"'"'PY'"'"'$/{f=1;next} f&&/^PY$/{exit} f' tools/packs/recipes/batch4_selfsufficiency.sh > "$TMP/gtext.py"
test -s "$TMP/gtext.py"
$PY "$TMP/gtext.py" "$SRC/pg48722.txt" $D/10-fermented-pickles.md --source-url $PG_1438 \
  --title "Making Fermented Pickles: Brining Cucumbers, Sauerkraut and Other Vegetables (USDA Farmers' Bulletin 1438, 1924)" \
  --after "^CONTENTS$" --start "^ALTHOUGH excellent pickles" --end "^ +ORGANIZATION OF THE$"

# pgtable: replace gtext's four "[Table not included ...]" markers, in
# order, with the tables written out one row per line. Rows were copied by
# hand from the PG text's "|" tables (cells unchanged; the column units
# "per cent / degrees / ounces" and, in Table 3, "lbs." / "ozs." are the
# tables' own unit labels written beside each value).
cat > "$TMP/pgtable.py" <<'PY'
import sys
md_path = sys.argv[1]
T1 = """Salt in solution (per cent) | Salinometer reading (degrees) | Salt in 6 quarts of finished brine (ounces)
1.06 | 4 | 2
2.12 | 8 | 4¼
3.18 | 12 | 6½
4.24 | 16 | 8½
5.3 | 20 | 11
7.42 | 28 | 14½
8.48 | 32 | 18
9.54 | 36 | 20
10.6 | 40 | 22½
15.9 | 60 | 35
21.2 | 80 | 48
26.5 | 100 | 64"""
T2 = """Salt (per cent) | Salinometer reading (degrees) | Freezing temperature (°F)
5 | 20 | 25.2
10 | 40 | 18.7
15 | 60 | 12.2
20 | 80 | 6.1
25 | 100 | 0.5"""
T3 = """Density (degrees Brix or Balling) | Quantity of sugar for each gallon of water (see note [4])
5 | 7 ozs.
10 | 14.8 ozs.
15 | 1 lb. 7.5 ozs.
20 | 1 lb. 14.75 ozs.
25 | 2 lbs. 12.5 ozs.
30 | 3 lbs. 9 ozs.
40 | 5 lbs. 8.75 ozs.
45 | 6 lbs. 13 ozs.
50 | 8 lbs. 5.25 ozs.
55 | 10 lbs. 4 ozs.
60 | 12 lbs. 8 ozs."""
T4 = """Size | Variety | Number to a gallon
1 to 2 inches long | Gherkins (see note [5]) | 250 to 650
2 to 3 inches long | Small pickles | 130 to 250
3 to 4 inches long | Medium pickles | 40 to 130
4 inches and longer | Large pickles | 12 to 40"""
md = open(md_path, encoding="utf-8").read()
# The transcription's one garbled figure: "2| per cent" (sauerkraut salt) is
# "2½ per cent" on the printed page (NAL 1924 scan, archive.org CAT10305679,
# p. 13, checked by eye).
assert md.count("2| per cent by weight of the cabbage") == 1
md = md.replace("2| per cent by weight of the cabbage", "2½ per cent by weight of the cabbage")
NOTE = "[Table not included: layout not preserved; see the original]"
assert md.count(NOTE) == 4, md.count(NOTE)
for t in (T1, T2, T3, T4):
    md = md.replace(NOTE, t, 1)
open(md_path, "w", encoding="utf-8").write(md)
print("tables rendered: 4")
PY
$PY "$TMP/pgtable.py" $D/10-fermented-pickles.md

# Aliases (retrieval only, never shown).
python3 - $D/09-home-tanning.md "how to tan a hide, deer hide tanning at home, rabbit skin tanning, tanning leather at home, make leather from cowhide, bark tanning, chrome tanning at home, alum tanning, tan a fur pelt with the hair on, tanning squirrel or raccoon skins, salt and alum tanning, liming and unhairing a hide, fleshing a hide, soften a dried hide, homemade shoe sole leather, waterproofing leather boots, dye leather black, oil and finish leather, stretching boards for pelts, tawing skins, hide to leather" <<'PY'
import sys; p, al = sys.argv[1:3]
s = open(p, encoding="utf-8").read().split("\n")
assert s[1].startswith("Source:"); s.insert(2, "Aliases: " + al)
open(p, "w", encoding="utf-8").write("\n".join(s))
PY
python3 - $D/10-fermented-pickles.md "making fermented pickles, brine pickles in a crock, salt brine for pickles, how much salt per gallon brine, 10 percent brine, sauerkraut in a barrel, dill pickles old fashioned, salt stock cucumbers, curing cucumbers in salt, pickles went soft or slimy, hollow pickles, scum on pickle brine, fermenting green beans, salting vegetables without fermentation, brine freezing point, egg floats in brine test, sour pickles from salt stock, sweet pickles sirup, copper greened pickles poisonous, pickle barrel and cover weight" <<'PY'
import sys; p, al = sys.argv[1:3]
s = open(p, encoding="utf-8").read().split("\n")
assert s[1].startswith("Source:"); s.insert(2, "Aliases: " + al)
open(p, "w", encoding="utf-8").write("\n".join(s))
PY

cat > $D/pack.json <<JSON
{
 "id": "household-historical",
 "title": "Blacksmithing, Woodworking, Sewing, Soap, Candles & Tanning (Historical)",
 "category": "guide",
 "version": "$V",
 "review": "historical",
 "publisher": "Project Gutenberg editions of Ilgen (1912), Griffith (1908), Watson (1907), Beecher (1873) and U.S. Department of Agriculture Farmers' Bulletins 896 (1917), 1334 (1923), 1408 (1926) and 1438 (1924)",
 "license": "Public domain (published in the U.S. before 1929; USDA bulletins are U.S. Government works)",
 "attribution": "Texts from Project Gutenberg editions of Forge Work (William L. Ilgen, 1912; #53854; ch. I–V), Essentials of Woodworking (Ira S. Griffith, 1908; #71855; ch. I–V), Textiles and Clothing (Kate H. Watson, 1907; #21534; sewing, mending and care of clothing), Miss Beecher's Housekeeper and Healthkeeper (Catharine E. Beecher, 1873; #55734; washing and soap making, fires and lights), USDA Farmers' Bulletins 1408, The House Fly and How to Suppress It (1926; #18050), 896, House Rats and Mice (1917; #35542) and 1438, Making Fermented Pickles (1924; #48722), and from the National Agricultural Library scan of USDA Farmers' Bulletin 1334, Home Tanning of Leather and Small Fur Skins (R. W. Frey, I. D. Clarke and F. P. Veitch, 1923; OCR fractions corrected against the page images). Selected chapters; poison and fumigation sections left out. Project Gutenberg license and trademark text removed. Illustrations not included. Use does not imply endorsement by USDA or the U.S. Government.",
 "description": "Forge and anvil work, welding iron, hardening and tempering tool steel; hand woodworking tools, saw filing and sharpening chisels and plane irons; hand sewing, patching and darning; washing clothes by hand, making lye and soap; lamps and candle making; controlling flies, rats and mice; tanning hides into sole, harness and lace leather and tanning small fur skins (liming, unhairing, bark, chrome and alum tannage); brining cucumbers, sauerkraut and other vegetables. 100–150 years old: lye, kerosene, cyanide (casehardening), benzine, gasoline and chloroform (cleaning cloth and furs), chrome alum and sulphuric acid (tanning) are handled in ways now considered unsafe — use modern safety precautions and never follow old chemical advice blindly."
}
JSON
echo "done: $D (09-home-tanning, 10-fermented-pickles); 18-vulnerable-groups unchanged (sources blocked)"
