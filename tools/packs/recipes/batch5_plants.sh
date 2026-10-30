#!/usr/bin/env bash
# Batch 5 (plants): one new pack.
#   content/06b-edible-plants  (id edible-plants) — U.S. Army FM 21-76
#     Survival (5 June 1992): Chapter 9 "Survival Use of Plants" (edibility
#     warnings, plant identification figures, Universal Edibility Test only),
#     Appendix B "Edible and Medicinal Plants" (111 plants) and Appendix C
#     "Poisonous Plants" (17 plants).
#
# Usage: tools/packs/recipes/batch5_plants.sh <source-dir> [--fetch]
#   --fetch downloads the two PDFs below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). Both answered HTTP 200 on
#   2026-10-30. Run from the project root; then build with
#   python3 tools/packs/build_pack.py content/06b-edible-plants
#
# SOURCES (two copies of the same June 1992 edition):
#   TEXT: FM 21-76/MCRP 3-02F "Survival", the U.S. Marine Corps reprint of
#     FM 21-76 (PCN 144 000049 00), 571 pages, Internet Archive item
#     MCRP_3-02F_FM_21-76_Survival. Its text layer is clean (no U+FFFD;
#     nine U+FFFE soft-hyphen markers, removed). Page 3 is the Army
#     authentication page: "FM 21-76, 5 JUNE 1992 / By Order of the
#     Secretary of the Army: GORDON R. SULLIVAN ... PATRICIA P. HICKERSON,
#     Brigadier General, The Adjutant General". The USMC cover replaces the
#     Army title page, so the release line is confirmed on the second copy:
#   LICENCE EVIDENCE: FM 21-76 (1992) Army scan, 646 pages, from the BITS
#     "amd-us-archive" (Berlin Information-center for Transatlantic Security):
#     page 1 text layer reads "FIELD MANUAL No. 21-76 / HEADQUARTERS
#     DEPARTMENT OF THE ARMY / Washington, DC, 5 June 1992 / Approved for
#     public release; distribution is unlimited. / *This publication
#     supersedes FM 21-76, 26 March 1986." Its OCR is worse ("westen lndia",
#     hyphenation marks), so it is used only as evidence; spot checks (Abal,
#     Acacia, Agave, Chapter 9) show the two texts are identical.
#   Whole-document scan of both text layers for "©", "copyright",
#   "courtesy", "permission", "reprinted": no hits inside the manual (the
#   only "reprinted"/"permission" lines on the Internet are the chrome of a
#   civilian re-typeset copy, which is NOT used — see EXCLUDED).
#   FM 21-76 (1992) is a U.S. Government work (17 U.S.C. § 105). It was
#   superseded by FM 3-05.70 (2002) and is no longer on armypubs, hence
#   review = needs-review, and the attribution says it must never be read
#   as proof that a plant is safe to eat.
#
# EXCLUDED (and why):
#   - ALL plant photographs. The 1992 edition illustrates Appendixes B and C
#     with colour photographs, not Army line drawings; the manual states no
#     author for them and the same style of photograph in Appendix E (snakes)
#     carries individual photographer credits printed in the image
#     ("JOHN H. TASHJIAN/BÖRJE FLARDH", MCRP p. 481). Provenance doubtful →
#     not shipped. The one-line "Note: You will find illustrations of the
#     plants described in this chapter in Appendixes B and C." (Chapter 9
#     intro) is dropped because those illustrations are not included.
#   - Chapter 9 beyond the Universal Edibility Test (p. 132 on: plant lists,
#     seaweeds, preparation, medicinal uses, miscellaneous uses) — out of
#     the assignment's scope (plant appendices + the edibility test only).
#   - Appendixes D-H (insects, snakes, fish, clouds, contact plan) — not
#     plants.
#   - Internet Archive items USArmyFM2176 / Fm21-76SurvivalManual /
#     manuallib-id-2671395 (3,023,620-byte PDF): a civilian re-typeset
#     edition with running headers "Reprinted as permitted by U.S.
#     Department of the Army" and "Page N of 233"; no figures. Not used.
#   - globalsecurity.org/military/library/policy/army/fm/21-76/ — HTTP 404
#     (the HTML edition is gone). irp.fas.org — HTTP 202 placeholder.
#
# Text is verbatim. Post-processing (post()) only: removes the extractor's
# "APPENDIX B:"/"POISONOUS PLANTS:"/"SURVIVAL USE OF PLANTS:" heading
# prefixes and the bold "**APPENDIX B**"/"**CHAPTER 9**" label lines; moves
# each plant's Latin-name line (the line under the name in the manual) into
# the heading as "Name (Latin name)"; re-joins paragraphs the extractor
# split inside a sentence (previous line ends without punctuation and the
# next starts lower-case); normalizes the "·" bullet glyph to "- " and puts
# each bullet on its own line; fixes the text-layer spacing glitch
# "CAUTIO N" → "CAUTION"; deletes U+FFFE soft-hyphen markers. CAUTION and
# WARNING boxes stay (the extractor renders them "**CAUTION:** text").
# Figures 9-1 to 9-5 (Army line drawings; the Universal Edibility Test is a
# text box printed as a figure) are cropped from the MCRP PDF at the exact
# bounds of the embedded image objects (figs.py), because the captions are
# baked into the images and extract_figures.py cannot find them. The 13
# steps and CAUTION of Figure 9-5 are also typed out verbatim from the
# figure (checked by eye at 3x zoom) so the times are searchable.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
V=2026.10.30.1

MCRP_URL="https://archive.org/download/MCRP_3-02F_FM_21-76_Survival/MCRP_3-02F_FM_21-76_Survival.pdf"
BITS_URL="https://www.bits.de/NRANEU/others/amd-us-archive/FM21-76(92).pdf"
PDF="$SRC/mcrp_3-02f.pdf"

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  curl -sL -A "Mozilla/5.0" --retry 3 -o "$PDF" "$MCRP_URL"
  curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/fm21-76_bits.pdf" "$BITS_URL"
fi

# Licence evidence check on the Army scan, if present.
if [[ -f "$SRC/fm21-76_bits.pdf" ]]; then
  $PY -I -c '
import sys, pypdfium2 as pdfium
t = pdfium.PdfDocument(sys.argv[1])[0].get_textpage().get_text_range()
assert "Approved for public release; distribution is unlimited." in t, "release line not found"
assert "5 June 1992" in t
print("licence evidence OK: FM 21-76, 5 June 1992, approved for public release")
' "$SRC/fm21-76_bits.pdf"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
D=content/06b-edible-plants; mkdir -p $D; rm -rf $D/*.md $D/images

# post MD ALIASES PREFIX: see the header comment.
cat > "$TMP/post.py" <<'PY'
import re, sys
path, aliases, prefix = sys.argv[1:4]
text = open(path, encoding="utf-8").read().replace("￾", "")
text = text.replace("CAUTIO N", "CAUTION")
# Three plant-name lines the extractor dropped as page furniture (they sit
# at the top of pp. 401 and 407 and before "Cordyline terminalis"); the
# names are copied from the manual: "Thistle / Cirsium species",
# "Ti / Cordyline terminalis", "Water lily / Nymphaea odorata".
text = text.replace("\nDescription: This plant may grow as high as 1.5 meters. Its leaves are long-pointed",
                    "\n## Thistle\nCirsium species\n\nDescription: This plant may grow as high as 1.5 meters. Its leaves are long-pointed")
text = text.replace("\nCordyline terminalis\n", "\n## Ti\nCordyline terminalis\n")
text = text.replace("\nDescription: These plants have large, triangular leaves that float on the water's surface",
                    "\n## Water lily\nNymphaea odorata\n\nDescription: These plants have large, triangular leaves that float on the water's surface")
# Appendix C prints name / Latin name / family on three bold lines; the
# extractor merged two of them in places.
text = text.replace("## POISONOUS PLANTS: Poison ivy and poison oak Toxicodendron radicans and Toxicodendron diversibba",
                    "## POISONOUS PLANTS: Poison ivy and poison oak\nToxicodendron radicans and Toxicodendron diversibba")
FAMILY = re.compile(r"^(.*?) ((?:[A-Z][a-z]+ (?:[a-z]+ )?)?\([A-Z][a-z]+\) Family|[A-Z][a-z]+ Family)$")
FIELDS = ("Description:", "Habitat and Distribution:", "Edible Parts:", "Other Uses:", "Note:")
lines = text.split("\n")
out = []
i = 0
while i < len(lines):
    l = lines[i]
    if l.startswith("Source: "):
        out += [l, f"Aliases: {aliases}"]
    elif l.startswith("## "):
        h = l[3:]
        h = h[len(prefix) + 2:] if h.startswith(prefix + ": ") else h
        h = {"EDIBLE AND MEDICINAL PLANTS": "Edible and Medicinal Plants: introduction",
             "POISONOUS PLANTS": "Poisonous Plants: introduction",
             "SURVIVAL USE OF PLANTS": "Survival Use of Plants: introduction",
             "EDIBILITY OF PLANTS": "Edibility of Plants"}.get(h, h)
        if h in ("CAUTION", "WARNING"):
            # A box label the extractor promoted to a heading: back to a label.
            out.append(f"**{h}:** ")
            i += 1
            continue
        # The manual prints the Latin name on the line under the plant name.
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        latin = lines[j].strip() if j < len(lines) else ""
        family = ""
        m = FAMILY.match(latin)
        if m:
            latin, family = m.group(1), m.group(2)
        if (prefix != "SURVIVAL USE OF PLANTS" and not h.endswith(": introduction")
                and ":" not in latin and not latin.startswith("**") and len(latin.split()) <= 8):
            out.append(f"## {h} ({latin})")
            if family:
                out += ["", family]
            i = j
        else:
            out.append(f"## {h}")
    elif l in ("**APPENDIX B**", "**APPENDIX C**", "**CHAPTER 9**"):
        pass
    elif l.startswith("Note: You will find illustrations of the plants described in this chapter"):
        pass
    elif l.startswith(("**CAUTION:** ", "**WARNING:** ")) and l.split("** ", 1)[1].startswith(FIELDS):
        # The label got attached to the field paragraph printed below the
        # box; the box text is the paragraph above it.
        label, rest = l.split("** ", 1)
        k = len(out) - 1
        while k >= 0 and not out[k].strip():
            k -= 1
        out[k] = f"{label}** {out[k]}"
        out.append(rest)
    else:
        out.append(l)
    i += 1
text = "\n".join(out)
text = re.sub(r"\*\*(CAUTION|WARNING):\*\* \n+", r"**\1:** ", text)
# Bullets: "·" glyph -> "- ", each on its own line.
text = re.sub(r"(?<=[.!?\"]) · ", "\n\n- ", text)
text = re.sub(r"^· ", "- ", text, flags=re.M)
# Paragraph split inside a sentence: previous line ends in a letter or comma,
# next paragraph starts lower-case.
text = re.sub(r"([A-Za-z,])\n\n(?=[a-z])", r"\1 ", text)
assert "�" not in text
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n")
PY
post() { python3 "$TMP/post.py" "$@"; }

# figs.py PDF OUTDIR: crop Figures 9-1 .. 9-5 (the only image object on each
# page region) at 150 dpi, grayscale, like extract_figures.py.
cat > "$TMP/figs.py" <<'PY'
import json, os, sys, pypdfium2 as pdfium
pdf, out = sys.argv[1:3]
os.makedirs(out, exist_ok=True)
pdf = pdfium.PdfDocument(pdf)
FIGS = [  # name, caption, 1-based page, image-object index on that page (top first)
    ("fig-9-1", "Figure 9-1. Leaf margins", 128, 0),
    ("fig-9-2", "Figure 9-2. Leaf shapes", 129, 0),
    ("fig-9-3", "Figure 9-3. Leaf arrangements", 129, 1),
    ("fig-9-4", "Figure 9-4. Root structures", 130, 0),
    ("fig-9-5", "Figure 9-5. Universal Edibility Test", 131, 0),
]
index = []
for name, caption, pno, k in FIGS:
    page = pdf[pno - 1]
    w, h = page.get_size()
    imgs = [o for o in page.get_objects() if o.type == 3]
    imgs.sort(key=lambda o: -o.get_bounds()[3])
    l, b, r, t = imgs[k].get_bounds()
    l, b, r, t = l - 3, b - 3, r + 3, t + 3
    bm = page.render(scale=150 / 72, crop=(l, b, w - r, h - t), grayscale=True)
    bm.to_pil().save(os.path.join(out, name + ".webp"), "WEBP", quality=70)
    index.append({"file": name + ".webp", "caption": caption, "kind": "figure", "page": pno,
                  "bbox": [round(l, 1), round(b, 1), round(r, 1), round(t, 1)]})
json.dump(index, open(os.path.join(out, "index.json"), "w"), indent=1)
print(f"{len(index)} figures -> {out}")
PY

# =========================================================================
# 01 Chapter 9 (pp. 126-131 of the MCRP PDF): edibility, identification, UET
# =========================================================================
$XP "$PDF" --pages 126-131 --bold-headings --source-url "$MCRP_URL" \
  --title "Survival Use of Plants: Edibility and the Universal Edibility Test (FM 21-76, 1992)" \
  -o $D/01-edibility-test.md
post $D/01-edibility-test.md "universal edibility test, test if a plant is edible, is this plant safe to eat, can I eat unknown plants, wild plant edibility test steps, tell if a plant is poisonous, plant identification survival, leaf shapes and arrangements, which wild plants to avoid, milky sap plant poisonous, eating wild plants safely, do not eat mushrooms survival, poison hemlock looks like wild carrot, roadside plants pesticides, bitter acorns tannin, oxalic acid plants, how long to test a plant, foraging safety rules" \
  "SURVIVAL USE OF PLANTS"
$PY -I "$TMP/figs.py" "$PDF" $D/images/01-edibility-test
python3 - $D/01-edibility-test.md <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
def put(after, marker):
    global t
    assert t.count(after) == 1, after
    t = t.replace(after, after + "\n\n" + marker)
put("The basic leaf margins (Figure 9-1) are toothed, lobed, and toothless or smooth.",
    "![Figure 9-1. Leaf margins](img:01-edibility-test/fig-9-1.webp)")
put("triangular, long-pointed, or top-shaped (Figure 9-2).",
    "![Figure 9-2. Leaf shapes](img:01-edibility-test/fig-9-2.webp)")
put("are opposite, alternate, compound, simple, and basal rosette.",
    "![Figure 9-3. Leaf arrangements](img:01-edibility-test/fig-9-3.webp)")
put("looks much like a mophead under the soil's surface.",
    "![Figure 9-4. Root structures](img:01-edibility-test/fig-9-4.webp)")
put("apply the Universal Edibility Test (Figure 9-5) before eating any portion of it.",
    "![Figure 9-5. Universal Edibility Test](img:01-edibility-test/fig-9-5.webp)")
open(p, "w", encoding="utf-8").write(t)
PY
# Figure 9-5 is a text box printed as an image; its words, typed verbatim.
cat >> $D/01-edibility-test.md <<'MD'

## Universal Edibility Test: the steps (Figure 9-5)
1. Test only one part of a potential food plant at a time.
2. Separate the plant into its basic components - leaves, stems, roots, buds, and flowers.
3. Smell the food for strong or acid odors. Remember, smell alone does not indicate a plant is edible or inedible.
4. Do not eat for 8 hours before starting the test.
5. During the 8 hours you abstain from eating, test for contact poisoning by placing a piece of the plant part you are testing on the inside of your elbow or wrist. Usually 15 minutes is enough time to allow for a reaction.
6. During the test period, take nothing by mouth except purified water and the plant part you are testing.
7. Select a small portion of a single part and prepare it the way you plan to eat it.
8. Before placing the prepared plant part in your mouth, touch a small portion (a pinch) to the outer surface of your lip to test for burning or itching.
9. If after 3 minutes there is no reaction on your lip, place the plant part on your tongue, holding it there for 15 minutes.
10. If there is no reaction, thoroughly chew a pinch and hold it in your mouth for 15 minutes. Do not swallow.
11. If no burning, itching, numbing, stinging, or other irritation occurs during the 15 minutes, swallow the food.
12. Wait 8 hours. If any ill effects occur during this period, induce vomiting and drink a lot of water.
13. If no ill effects occur, eat 0.25 cup of the same plant part prepared the same way. Wait another 8 hours. If no ill effects occur, the plant part as prepared is safe for eating.

**CAUTION:** Test all parts of the plant for edibility, as some plants have both edible and inedible parts. Do not assume that a part that proved edible when cooked is also edible when raw. Test the part raw to ensure edibility before eating raw. The same part or plant may produce varying reactions in different individuals.
MD

# =========================================================================
# 02 Appendix B (pp. 315-422): Edible and Medicinal Plants
# =========================================================================
$XP "$PDF" --pages 315-422 --bold-headings --source-url "$MCRP_URL" \
  --title "Edible and Medicinal Plants, A to Z (FM 21-76 Appendix B, 1992)" \
  -o $D/02-edible-plants.md
post $D/02-edible-plants.md "wild edible plants, what wild plants can I eat, edible plants list, can I eat cattails, dandelion edible, acorns how to eat, is this berry edible, edible wild berries, wild onion and garlic, edible roots and tubers, pine needle tea, wild rose hips, edible cactus prickly pear, agave edible parts, burdock root, chicory coffee substitute, plantain leaves medicinal, reindeer moss edible, coconut survival food, edible palm hearts, is pokeweed poisonous, plants to eat in the desert, plants to eat in the jungle, plants that treat diarrhea, medicinal wild plants" \
  "EDIBLE AND MEDICINAL PLANTS"

# =========================================================================
# 03 Appendix C (pp. 423-438): Poisonous Plants
# =========================================================================
$XP "$PDF" --pages 423-438 --bold-headings --source-url "$MCRP_URL" \
  --title "Poisonous Plants to Avoid (FM 21-76 Appendix C, 1992)" \
  -o $D/03-poisonous-plants.md
post $D/03-poisonous-plants.md "poisonous plants to avoid, poison ivy identification, poison oak, poison sumac, how to identify poison ivy, water hemlock vs wild parsnip, poison hemlock identification, deadly plants, plants that cause rash, castor bean poisonous, oleander poisonous, death camas, rosary pea, manchineel tree, plants that kill if eaten, toxic berries, lantana poisonous, chinaberry poisonous, contact dermatitis plants, strychnine tree, physic nut, trumpet vine rash, cowhage itching, poisonous seeds in pods, plant poisoning survival" \
  "POISONOUS PLANTS"

cat > $D/pack.json <<JSON
{
 "id": "edible-plants",
 "title": "Edible and Poisonous Plants of the World (FM 21-76 Survival, 1992)",
 "category": "guide",
 "version": "$V",
 "review": "needs-review",
 "publisher": "U.S. Army, Headquarters, Department of the Army",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105); FM 21-76 (5 June 1992) is marked \"Approved for public release; distribution is unlimited.\"",
 "attribution": "Text from U.S. Army Field Manual FM 21-76, Survival (5 June 1992): Chapter 9 (edibility and the Universal Edibility Test), Appendix B (Edible and Medicinal Plants) and Appendix C (Poisonous Plants), from the U.S. Marine Corps reprint FM 21-76/MCRP 3-02F. Reformatted into one section per plant without changing substance; the manual's photographs are not included (only its line-drawn figures). This manual was superseded in 2002 and is reproduced as historical military guidance for soldiers, not as a field guide: nothing here is proof that a plant is safe to eat, descriptions alone cannot identify a plant, and look-alikes can be deadly. Use does not imply endorsement by the U.S. Army, the Department of Defense, or the U.S. Government.",
 "description": "The U.S. Army's 1992 survival manual on wild plants: the Universal Edibility Test and leaf, root and arrangement identification figures; descriptions, habitat, edible parts and other uses of 111 edible and medicinal plants worldwide; and 17 poisonous plants to recognize and avoid. Superseded manual, text only: never eat a wild plant on the strength of this app."
}
JSON
echo "done: $D"
