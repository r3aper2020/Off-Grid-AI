#!/usr/bin/env bash
# Batch 3 (food): poisonous plants and natural food toxins, agriculture and
# animals, food preservation and storage, cooking without power.
# Usage: tools/packs/recipes/batch3_food.sh <dir-with-downloaded-sources>
#
# Sources were re-verified 2026-10-29. Download into <dir> first with
# curl -sL -A "Mozilla/5.0" --retry 3 (file names below). Internet Archive
# items are USDA National Agricultural Library scans (collection
# usdanationalagriculturallibrary; rights field "The contributing
# institution believes that this item is not in copyright"); all are
# federal works printed by the GPO. PDF filenames come from
# https://archive.org/metadata/<identifier>. PDF page 1 of every NAL scan is
# the NAL "Historic, archived document" notice (not part of the original) and
# is never extracted.
#
# Every selection below was checked for OCR quality, numbers, layout
# scrambling, third-party credits and obsolete hazardous chemicals. Held-back
# sources are listed at the end with the reason.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir>}"
X="tools/.venv/bin/python tools/packs/extract_pdf.py"
IA=https://archive.org/download

# cut FILE START END: remove the lines from the first line starting with
# START up to (not including) the next line starting with END (END=EOF cuts
# to the end). Used only to HOLD BACK passages (scrambled table cells,
# obsolete toxic fumigants). Fails if either line is missing.
cut() {
  python3 - "$@" <<'EOF'
import re, sys
path, start, end = sys.argv[1:4]
lines = open(path, encoding="utf-8").read().split("\n")
key = lambda l: re.sub("[\uf06c\uf0b7\u2022] *", "", l).lstrip()  # ignore PDF bullet glyphs
i = next((n for n, l in enumerate(lines) if key(l).startswith(start)), None)
if i is None: sys.exit(f"cut: start not found in {path}: {start!r}")
j = len(lines) if end == "EOF" else next(
    (n for n in range(i + 1, len(lines)) if key(lines[n]).startswith(end)), None)
if j is None: sys.exit(f"cut: end not found in {path}: {end!r}")
open(path, "w", encoding="utf-8").write("\n".join(lines[:i] + lines[j:]))
print(f"cut {path}: dropped {j - i} lines after {start[:40]!r}")
EOF
}

# unprefix FILE PREFIX: structure only — remove a stray running-title prefix
# ("and FRUITS: ") that the extractor put in front of section headings.
unprefix() {
  python3 - "$@" <<'EOF'
import sys
path, prefix = sys.argv[1:3]
t = open(path, encoding="utf-8").read()
t = t.replace(f"## {prefix}: ", "## ").replace(f"**{prefix}: ", "**")
open(path, "w", encoding="utf-8").write(t)
EOF
}

# restructure FILE [--running HEAD...] [--plain HEAD...]: structure only, for
# the old scanned bulletins. (1) Headings made of figure OCR noise ("^BR ^i")
# are removed (that text is scan noise, not source text) and noise prefixes
# stripped; (2) headings listed after --plain (figure labels such as
# "Stake") and headings that are really wrapped body paragraphs (> 12 words,
# ending mid-word, or starting lower-case) are put back as body text, joined
# to the line they were split from; (3) standalone ALL-CAPS lines — the
# bulletins' own run-in titles ("BEANS AND PEAS.") — become "## " headings,
# except running page heads listed after --running; (4) body lines that are
# mostly figure OCR noise (carets, box glyphs) are dropped. No words of the
# source text are changed.
restructure() {
  python3 - "$@" <<'EOF'
import re, sys
path, args = sys.argv[1], sys.argv[2:]
running, plain, cur = set(), set(), None
for a in args:
    if a in ("--running", "--plain"):
        cur = a
        continue
    (running if cur == "--running" else plain).add(a.lower())
NOISE_CH = re.compile(r"[\^■♦|~«»¿]")
WORD = re.compile(r"^[A-Za-z][a-z]+$|^[A-Z]{2,}$|^[A-Za-z]+[.,:;)]?$")
def noise(h):
    toks = h.split()
    if not toks or NOISE_CH.search(h):
        return True
    good = sum(1 for t in toks if WORD.match(t) and re.search(r"[aeiouyAEIOUY]", t))
    return good < max(1, len(toks) * 0.6)
def wrapped(h):
    return (len(h.split()) > 12 or h.endswith("-") or h[:1].islower()
            or h.lower() in plain)
lines = open(path, encoding="utf-8").read().split("\n")
out, i = [], 0
while i < len(lines):
    l = lines[i]
    if l.startswith("## "):
        h = l[3:]
        parts = h.split(": ", 1)
        if len(parts) == 2 and noise(parts[0]):
            h = parts[1]
        if noise(h):
            i += 1
            continue
        if wrapped(h):
            body = lines[i + 1] if i + 1 < len(lines) else ""
            if body.startswith(("**", "## ", "[")) or not body.strip():
                out.append(h)
            else:
                out.append(h + " " + body)
                i += 1
            i += 1
            continue
        out.append("## " + h)
        i += 1
        continue
    s = l.strip()
    toks = s.split()
    good = sum(1 for t in toks if WORD.match(t) and re.search(r"[aeiouyAEIOUY]", t))
    if s and NOISE_CH.search(s) and good < len(toks) * 0.5:
        i += 1  # a line of figure OCR noise ("afefe¿8^^MjESl^^^^3")
        continue
    prev = lines[i - 1].strip() if i else ""
    nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
    if (s and not prev and not nxt and s.isupper() and not re.search(r"\d", s)
            and 1 <= len(s.split()) <= 10 and s.lower() not in running
            and not noise(s)):
        out.append("## " + s.rstrip(".,"))
        i += 1
        continue
    out.append(l)
    i += 1
# A heading with no text of its own is carried into the next section as a
# bold lead line (the extractor's own convention), never dropped.
final, carried = [], []
for n, l in enumerate(out):
    if l.startswith("## "):
        rest = [x for x in out[n + 1:] if x.strip()]
        if rest and rest[0].startswith("## "):
            carried.append(l[3:])
            continue
        final.append(l)
        final.extend(f"**{h}**\n" for h in carried)
        carried = []
        continue
    if carried and not l.strip():
        continue
    final.append(l)
open(path, "w", encoding="utf-8").write("\n".join(final))
EOF
}

# =====================================================================
# 06 Poisonous Plants and Natural Food Toxins (verified)
# =====================================================================
D=content/06-poisonous-plants

# USDA ARS Agriculture Information Bulletin 415, "Plants Poisonous to
# Livestock in the Western States", revised April 2011 (current edition;
# server Last-Modified 2011-05-10). File: ars-poisonous.pdf
# Photo note (PDF p. 5): all photographs by USDA employees except
# "Spineless Horsebrush" (U.S. National Park Service, federal) and "Rayless
# Goldenrod" (Dr. Samantha Uhrig, private); the milkweed drawing (p. 72) is
# by Holly Broome-Hyer. No images are extracted; only USDA caption text
# remains.
# Pages 11-120 (text from "Poisonous Plants and Livestock" to "Noxious
# Weeds"). Skipped: front matter (pp. 1-10); the opening section
# "Poisonous Plants and Livestock" (PDF p. 11-12) because its 3-column
# bullet lists come out scrambled (list items split and interleaved).
ARS_URL=https://www.ars.usda.gov/is/np/PoisonousPlants/PoisonousPlants.pdf
$X "$SRC/ars-poisonous.pdf" --pages 11-120 --source-url "$ARS_URL" \
  --title "Plants Poisonous to Livestock in the Western States (USDA ARS AIB 415, 2011)" \
  -o $D/01-livestock-poisonous-plants.md
cut $D/01-livestock-poisonous-plants.md "## Poisonous Plants and Livestock" "## Economic Impact"

# FDA "Bad Bug Book", 2nd ed. (2012); fda.gov page "Bad Bug Book (Second
# Edition)" content current as of 02/07/2022 — still FDA's current edition.
# File: fda-badbug.pdf. Selected natural-toxin chapters plus botulism,
# Trichinella and Giardia. The only third-party credit found ("Photo by
# Jonathan Deeds, Ph.D., FDA", venomous fish) is federal and that chapter
# is not used.
BB_URL=https://www.fda.gov/media/83271/download
bb() { $X "$SRC/fda-badbug.pdf" --pages "$1" --source-url "$BB_URL" --bold-headings \
       --title "$2 (FDA Bad Bug Book, 2nd ed., 2012)" -o "$D/$3.md" "${@:4}"; }
# Mushrooms pp. 218-230. Table 1 (symptom onset) and Table 2 (poisonous
# mushrooms vs. edible look-alikes) come out as unlabelled lists that could
# pair a deadly species with an edible one: their cells are cut (the
# "[Table …]" markers stay). Lost with them: the bullet notes on look-alikes
# that follow Table 2 on the same page (they sit under the table heading).
# (The extractor's --skip only acts on top-level headings, so cut is used.)
bb 218-230 "Mushroom Toxins" 10-mushroom-toxins
cut $D/10-mushroom-toxins.md "## Prognosis" "## Protoplasmic Poisons"
cut $D/10-mushroom-toxins.md "## Appearance" "## 5. Diagnosis"
bb 108-112 "Clostridium botulinum (Botulism)" 11-botulism
bb 254-256 "Phytohaemagglutinin (Kidney Bean Lectin)" 12-kidney-bean-lectin
bb 249-253 "Grayanotoxins (Honey Intoxication)" 13-grayanotoxins
bb 242-244 "Pyrrolizidine Alkaloids" 14-pyrrolizidine-alkaloids
bb 231-236 "Aflatoxins" 15-aflatoxins
bb 200-206 "Shellfish Toxins (PSP, DSP, NSP, ASP, AZP)" 16-shellfish-toxins
# Ciguatera pp. 194-196 only: pp. 197-199 are the ciguatoxic-fish table.
bb 194-196 "Ciguatoxin (Ciguatera Fish Poisoning)" 17-ciguatera
# Tetrodotoxin: the "puffer species considered safe in Japan / edible
# parts" table is cut (scrambled Yes/No columns), with its footnote.
bb 211-217 "Tetrodotoxin (Pufferfish Poisoning)" 18-tetrodotoxin
cut $D/18-tetrodotoxin.md "## 13. Examples of puffer species" "## State bans harvesting"
bb 139-143 "Trichinella Species (Trichinosis)" 19-trichinella
bb 123-126 "Giardia lamblia (Giardiasis)" 20-giardia

# =====================================================================
# 07 Agriculture (Historical)
# =====================================================================
D=content/07-agriculture-historical

# Farmers' Bulletin 884, Saving Vegetable Seeds for the Home and Market
# Garden (W. W. Tracy, 1917). IA CAT87202632, file farmbul0884.pdf.
# Pages 3-14. Skipped pp. 15-17 ("Labeling, fumigating, and storing"):
# carbon disulphide fumigation (explosive, no longer registered) is
# interleaved with the labeling/storage text.
$X "$SRC/farmbul0884.pdf" --pages 3-14 --caps-headings \
  --source-url "$IA/CAT87202632/farmbul0884.pdf" \
  --title "Saving Vegetable Seeds for the Home and Market Garden (USDA Farmers' Bulletin 884, 1917)" \
  -o $D/01-saving-vegetable-seeds.md
restructure $D/01-saving-vegetable-seeds.md --running "SAVING VEGETABLE SEEDS."

# Farmers' Bulletin 447, Bees (E. F. Phillips, 1911). IA CAT88909012, file
# farmbul0447.pdf. Pages 6-44 (introduction through "Diseases and
# enemies"). Skipped: front matter; pp. 45-49 (queen breeders, dealers,
# laws, publication lists; p. 45 recommends corrosive sublimate).
$X "$SRC/farmbul0447.pdf" --pages 6-44 --caps-headings \
  --source-url "$IA/CAT88909012/farmbul0447.pdf" \
  --title "Bees (USDA Farmers' Bulletin 447, 1911)" \
  -o $D/02-bees.md
restructure $D/02-bees.md --running "BEES."

# =====================================================================
# 08 Food Storage, Meat and Fireless Cooking (Historical)
# =====================================================================
D=content/08-food-preservation-historical

# Farmers' Bulletin 1939, Home Storage of Vegetables and Fruits (L. P.
# McColloch, revised June 1960). IA CAT87205380, file
# farmbul1939rev1960.pdf. Pages 4-10 and 12-22. Skipped: cover/contents,
# p. 11 (Table 1 storage conditions — scrambled; its side column of prose
# is lost with it), p. 23 (blank). The
# carbon tetrachloride fumigation text (Dry Beans and Peas, item 3, and the
# following "After 48 hours ... aerated" paragraph, which would otherwise
# read as part of the oven treatment) is cut: carbon tetrachloride is banned
# for consumer use.
F=$D/01-home-storage-vegetables-fruits.md
$X "$SRC/farmbul1939rev1960.pdf" --pages 4-10,12-22 --bold-headings \
  --source-url "$IA/CAT87205380/farmbul1939rev1960.pdf" \
  --title "Home Storage of Vegetables and Fruits (USDA Farmers' Bulletin 1939, rev. 1960)" -o $F
cut $F "(3) Fumigation with carbon" "## and FRUITS: Late Cabbage"
unprefix $F "and FRUITS"
# Figure 1 (cellar plan) label noise and its garbled caption.
cut $F "## LONGITUDINAL SECTION" "[FIGURE 2."
# The Beltsville ventilation example continues on skipped p. 11; the
# broken sentence ("it was found that … the day and dipped to 10°") is cut.
cut $F "The only danger from overventi" "Certain commodities such as"
restructure $F --plain "Clean" "NEG. 40276" "Stake" "HOET. 50241" \
  "A frame building can be built of"

# Farmers' Bulletin 1186, Pork on the Farm: Killing, Curing, and Canning
# (1921). IA farmbul1186rev1921, file farmbul1186rev1921.pdf. Pages 3-16
# (selection, slaughter, dressing, cutting, lard rendering, curing agents).
# HELD BACK pp. 17-28 (cure, sausage and smoking formulas: OCR garbled the
# quantities, e.g. "2i pounds molasses", "2$ pounds sugar", "4¿ gallons
# water"; p. 27 "yellow wash" uses chrome yellow) and pp. 29-45 (home
# canning: obsolete processing times — never use).
$X "$SRC/farmbul1186rev1921.pdf" --pages 3-16 --caps-headings \
  --source-url "$IA/farmbul1186rev1921/farmbul1186rev1921.pdf" \
  --title "Pork on the Farm: Killing, Dressing and Cutting (USDA Farmers' Bulletin 1186, 1921)" \
  -o $D/02-pork-on-the-farm.md
restructure $D/02-pork-on-the-farm.md --running "PORK ON THE FARM."

# Farmers' Bulletin 1415, Beef on the Farm (1924). IA CAT87203466, file
# farmbul1415.pdf. Pages 3-22 (selection, slaughter, examining the carcass,
# cooling, cutting). HELD BACK pp. 22-36 from "Curing beef" on (corning
# and sausage quantities OCR-garbled, e.g. "6£ ounces", "^ pound of salt";
# yellow wash with chrome yellow; canning). The extract therefore ends at
# the first lines of "Curing beef"; those lines are cut (to end of file).
F=$D/03-beef-on-the-farm.md
$X "$SRC/farmbul1415.pdf" --pages 3-22 --caps-headings \
  --source-url "$IA/CAT87203466/farmbul1415.pdf" \
  --title "Beef on the Farm: Slaughtering and Cutting (USDA Farmers' Bulletin 1415, 1924)" -o $F
cut $F "CURING BEEF." EOF
restructure $F

# Farmers' Bulletin 771, Homemade Fireless Cookers and Their Use (1916,
# issued Feb. 1917). IA CAT87202338, file farmbul0771.pdf. Pages 3-12
# (principle, construction, use, temperature test). The recipes that start
# on p. 12 are cut, and pp. 13-17 skipped: OCR garbled ingredient fractions
# ("1^ teaspoons", "i pound", "11 quarts").
$X "$SRC/farmbul0771.pdf" --pages 3-12 --caps-headings \
  --source-url "$IA/CAT87202338/farmbul0771.pdf" \
  --title "Homemade Fireless Cookers and Their Use (USDA Farmers' Bulletin 771, 1916)" \
  -o $D/04-fireless-cookers.md
cut $D/04-fireless-cookers.md "RECIPES FOR USE WITH THE FIRELESS COOKER." EOF
restructure $D/04-fireless-cookers.md --running "HOMEMADE FIRELESS COOKERS AND THEIR USE." \
  "HOMEMADE FIEELESS COOKERS AND THEIR USE."

# =====================================================================
# HELD BACK (not shipped) — see report 2026-10-29
# - TM 10-420 Emergency Food Plants and Poisonous Plants of the Pacific
#   (1943; IA emergencyfoodpla00merr; GPO sale copy, no copyright notice):
#   two-column OCR interleaves sentences between plant entries — an
#   edibility statement can attach to the wrong plant.
# - FB 796 Some Common Edible and Poisonous Mushrooms (1917; CAT87202726):
#   OCR garbles species names and the (EDIBLE)/(POISONOUS) labels; includes
#   mushroom canning; outdated edibility (e.g. Tricholoma equestre).
# - Victory Gardens, Misc. Pub. 483 (1942): two-column scrambling; the
#   spacing/seed/planting-date tables carry the substance.
# - FB 1743 Hotbeds and Coldframes (1935): temperatures OCR-garbled
#   ("between (0 and 7;)°").
# - Backyard Conservation, NRCS PA-1621 (1998): co-published with NACD and
#   Wildlife Habitat Council (partner content); magazine layout scrambled.
# - FB 984 Farm and Home Drying (1919): lye and sulphuring quantities
#   garbled ("dissolving! pound of concentrated lye", "li to 2 hours").
# - FB 1438 Making Fermented Pickles (both NAL scans, 1924/1925):
#   sauerkraut salt "2J"/"2^ per cent" (2½ %) and brine tables garbled.
# - Leaflet 553 Controlling Insects in Farm-Stored Grain (1971): sanitation
#   text is interleaved with pesticide/fumigant mixes on every page.
# - FB 889 Back-Yard Poultry Keeping (1917): bill of materials and seed
#   rates garbled; lice treatment with sodium fluoride / mercury ointment.
# - AIB 358 Selecting and Raising Rabbits (1972): word order scrambled
#   within sentences; a percentage dropped from an eye-treatment line.
# - FB 920 Milk Goats (1918): ration and drench amounts garbled throughout.
# - Special Reports on Diseases of Cattle (1904) / of the Horse (1907):
#   treatment and drug dosing interleaved in every chapter (~1,200 mentions).
