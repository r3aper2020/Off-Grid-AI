#!/usr/bin/env bash
# Batch 4 (medical area): two new packs.
#   content/01b-medical-emergencies  (id medical-emergencies) — NHLBI heart
#     attack, cardiac arrest, stroke and asthma pages; NIDDK low blood glucose.
#   content/02b-home-health          (id home-health) — NIDDK diarrhea /
#     stomach flu / food poisoning and dehydration; FDA hand sanitizer,
#     antibiotics, OTC Drug Facts label, masks and respirators; ASPR EPAP
#     (prescriptions after a disaster); IHS dental emergencies card.
#
# Usage: tools/packs/recipes/batch4_medical.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-29. Run from the project root; then build each pack with
#   python3 tools/packs/build_pack.py content/<pack-dir>
#
# LICENSE: every source is a U.S. Government work (17 U.S.C. § 105):
#   NHLBI, NIDDK (NIH), FDA, ASPR (HHS), Indian Health Service (HHS).
#   Every page/PDF was scanned for "©", "copyright", "courtesy",
#   "permission", "reprinted": the only hits are site-footer "Copyright"
#   policy links; no page credits third-party text. Images are not used.
#   IHS PDF metadata: Author "IHS Division of Oral Health".
#
# EXCLUDED (and why):
#   - FDA "Over-the-Counter Medicines: What's Right for You?" — states it was
#     prepared by "FDA and the Consumer Healthcare Products Association
#     (CHPA)" (co-authored with an industry body).
#   - NIAID "Guidelines for the Diagnosis and Management of Food Allergy:
#     Summary for Patients" (May 2011) pp. 27-30 (anaphylaxis) — federal, but
#     a 2011 publication (would be needs-review, cannot share a verified
#     pack); p. 31 action plan is "Adapted from J Allergy Clin Immunol"
#     (third-party) and must never be used.
#   - VA Epilepsy Centers of Excellence seizure first aid — no notice, but
#     the wording matches non-federal (epilepsy charity) first-aid text;
#     provenance unclear, so held back.
#   - NHLBI heart-attack/treatment and stroke/treatment (hospital care, not
#     layperson action), "Complications", device and hospital sections.
#   - Blocked (HTTP 403 to scripts; not circumvented): cdc.gov, ninds.nih.gov,
#     poisonhelp.hrsa.gov, niaid.nih.gov HTML pages.
#   - MedlinePlus A.D.A.M. encyclopedia (/ency/) — licensed; never used.
#     Veterans Health Library (StayWell-licensed) — not used.
#
# Text is verbatim. Pre-processing only: slicing the article body out of the
# page, unwrapping NHLBI glossary links and deleting their pop-up modal text,
# deleting NIDDK footnote-reference superscripts (<sup>7</sup> — they glued
# onto numbers: "1 gallon of water.7"), and renaming the class
# "entity-reference-revisions" (extract_html.py drops any class containing
# "reference", a MediaWiki marker, which removed whole NHLBI articles).
# Post-processing (post()) removes page chrome ("On this page" lists, "FACT
# SHEET"/"View the fact sheet" promo cards, "Click to learn more"),
# re-indents nested sub-lists that the extractor flattened, and normalizes
# ligatures.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
XH="python3 tools/packs/extract_html.py"
V=2026.10.29.6

NHLBI=https://www.nhlbi.nih.gov/health
NIDDK=https://www.niddk.nih.gov/health-information
FDA=https://www.fda.gov
EPAP_URL=https://www.aspr.gov/readiness-response/response-operations/epap/patients
IHS_URL=https://www.ihs.gov/doh/documents/centers/abq/DentalEmergMagnets_PORTAL.pdf

NHLBI_PAGES="heart-attack/symptoms cardiac-arrest/symptoms cardiac-arrest/treatment
  stroke/symptoms asthma/attacks asthma/symptoms asthma/treatment-action-plan"
NIDDK_PAGES="
hypo=diabetes/overview/preventing-problems/low-blood-glucose-hypoglycemia
diarrhea-sx=digestive-diseases/diarrhea/symptoms-causes
diarrhea-tx=digestive-diseases/diarrhea/treatment
gastro-sx=digestive-diseases/viral-gastroenteritis/symptoms-causes
gastro-tx=digestive-diseases/viral-gastroenteritis/treatment
foodpois-sx=digestive-diseases/food-poisoning/symptoms-causes
foodpois-tx=digestive-diseases/food-poisoning/treatment"
FDA_PAGES="
sanitizer=consumers/consumer-updates/safely-using-hand-sanitizer
antibiotics=consumers/consumer-updates/know-when-and-how-use-antibiotics-and-when-skip-them
otc-label=drugs/understanding-over-counter-medicines/over-counter-drug-facts-label
masks=medical-devices/personal-protective-equipment-infection-control/n95-respirators-surgical-masks-face-masks-and-barrier-face-coverings"

nh_file() { echo "nhlbi-${1//\//-}.html"; }
lookup() { printf '%s\n' $2 | grep "^$1=" | cut -d= -f2; }

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for p in $NHLBI_PAGES; do dl "$(nh_file $p)" "$NHLBI/$p"; done
  for kv in $NIDDK_PAGES; do dl "niddk-${kv%%=*}.html" "$NIDDK/${kv#*=}"; done
  for kv in $FDA_PAGES; do dl "fda-${kv%%=*}.html" "$FDA/${kv#*=}"; done
  dl aspr-epap.html "$EPAP_URL"
  dl ihs-dental.pdf "$IHS_URL"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# prep MODE SRC OUT: wrap the article body in <main> for extract_html.py.
cat > "$TMP/prep.py" <<'PY'
import re, sys
mode, src, out = sys.argv[1:4]
s = open(src, encoding="utf-8").read()
if mode == "nhlbi":
    # Article body: from the language switcher (just after the page title)
    # to the site footer.
    i = s.index('<div role="navigation" class="block block-language')
    s = s[i:s.index('id="block-footerblock"', i)]
    # Glossary pop-ups: delete the modal (term heading + definition) ...
    s = re.sub(r'<span class="usa-modal" id="glossary-term-modal-(\d+)".*?'
               r'id="glossary-term-modal-\1-description">.*?</span>\s*</span>'
               r'\s*</span>\s*</span>\s*</span>', '', s, flags=re.S)
    # ... and unwrap the term link (its usa-button class would drop the word).
    s = re.sub(r'<a [^>]*class="glossary-term[^"]*"[^>]*>\s*(.*?)\s*<i [^>]*></i>\s*</a>',
               r'\1', s, flags=re.S)
    s = s.replace("entity-reference", "entity-ref")
    s = "<html><body><main>" + s + "</main></body></html>"
elif mode == "niddk":
    s = re.sub(r'<sup>\s*[\d,\s–-]+\s*</sup>', '', s)
open(out, "w", encoding="utf-8").write(s)
PY
prep() { python3 "$TMP/prep.py" "$@"; }

# post FILE [ops...]
#   drop=REGEX          delete lines matching REGEX
#   indent=REGEX        prefix "  " to "- " list lines matching REGEX
#   cutsec=REGEX        delete "## " sections whose heading matches REGEX
#   toc                 delete an "## Overview" that is only a contents link list
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
lines = open(path, encoding="utf-8").read().split("\n")
LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}
for op in ops:
    kind, _, arg = op.partition("=")
    if kind == "drop":
        r = re.compile(arg); lines = [l for l in lines if not r.search(l)]
    elif kind == "indent":
        r = re.compile(arg)
        lines = [("  " + l) if l.startswith("- ") and r.search(l) else l for l in lines]
    elif kind == "cutsec":
        r = re.compile(arg); out, skip = [], False
        for l in lines:
            if l.startswith("## "):
                skip = bool(r.search(l[3:]))
            if not skip:
                out.append(l)
        lines = out
    elif kind == "toc":
        # A page-contents link list left as the whole "## Overview" body.
        i = lines.index("## Overview") if "## Overview" in lines else -1
        if i >= 0:
            j = next((k for k in range(i + 1, len(lines)) if lines[k].startswith("## ")), len(lines))
            if all(l.startswith("- ") or not l.strip() for l in lines[i + 1:j]):
                del lines[i:j]
    else:
        sys.exit(f"unknown op {op}")
text = "\n".join(lines)
text = re.sub(r"^## Overview\n\s*(?=## )", "", text, flags=re.M)
text = re.sub(r" +([.,;:)])", r"\1", text)   # space left by unwrapped glossary links
for a, b in LIG.items():
    text = text.replace(a, b)
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n")
PY
post() { python3 "$TMP/post.py" "$@"; }

PROMO='^(IN THIS ARTICLE|FACT SHEET|View the fact sheet|More about .*|Find asthma studies for you or your child|In this section:|On this page:)$'
NHLBI_SKIP='Participate in a study|Asthma medicine fact sheets|Bronchial thermoplasty|Learn What a Heart Attack Feels Like'
NIDDK_SKIP='Clinical Trials'

nhlbi() {  # nhlbi <page> <title> <out.md> [post ops...]
  local p=$1 t=$2 o=$3; shift 3
  prep nhlbi "$SRC/$(nh_file $p)" "$TMP/n.html"
  $XH "$TMP/n.html" --source-url "$NHLBI/$p" --title "$t" -o "$o"
  post "$o" "drop=$PROMO" "cutsec=$NHLBI_SKIP" "$@"
}
niddk() {  # niddk <key> <title> <out.md> [post ops...]
  local k=$1 t=$2 o=$3; shift 3
  prep niddk "$SRC/niddk-$k.html" "$TMP/d.html"
  $XH "$TMP/d.html" --source-url "$NIDDK/$(lookup $k "$NIDDK_PAGES")" --title "$t" -o "$o"
  post "$o" "drop=$PROMO" "cutsec=$NIDDK_SKIP" toc "$@"
}
fda() {    # fda <key> <title> <out.md> [post ops...]
  local k=$1 t=$2 o=$3; shift 3
  $XH "$SRC/fda-$k.html" --source-url "$FDA/$(lookup $k "$FDA_PAGES")" --title "$t" -o "$o"
  post "$o" "drop=$PROMO" "$@"
}

# =========================================================================
# 01b-medical-emergencies (verified)
# =========================================================================
D=content/01b-medical-emergencies; mkdir -p $D; rm -f $D/*.md
nhlbi heart-attack/symptoms "Heart Attack Symptoms and When to Call 9-1-1 (NHLBI)" $D/01-heart-attack-symptoms.md
nhlbi cardiac-arrest/symptoms "Cardiac Arrest: Symptoms and Warning Signs (NHLBI)" $D/02-cardiac-arrest-symptoms.md
nhlbi cardiac-arrest/treatment "Cardiac Arrest: Emergency Treatment, CPR and AEDs (NHLBI)" $D/03-cardiac-arrest-treatment.md \
  "cutsec=^Hospital treatment|^Cardioverter devices"
nhlbi stroke/symptoms "Stroke Signs and the FAST Test (NHLBI)" $D/04-stroke-symptoms.md "cutsec=^Complications"
nhlbi asthma/attacks "Asthma Attacks: What to Do and When to Call 9-1-1 (NHLBI)" $D/05-asthma-attacks.md
nhlbi asthma/symptoms "Asthma Symptoms and Signs It Is Getting Worse (NHLBI)" $D/06-asthma-symptoms.md
nhlbi asthma/treatment-action-plan "Asthma Medicines and Action Plans (NHLBI)" $D/07-asthma-treatment.md
niddk hypo "Low Blood Glucose (Hypoglycemia) (NIDDK)" $D/08-low-blood-glucose.md \
  "indent=^- (four glucose tablets|1/2 cup|1/2 can|1 tablespoon of sugar)"

cat > $D/pack.json <<JSON
{
 "id": "medical-emergencies",
 "title": "Medical Emergencies: Heart, Stroke, Asthma, Low Blood Sugar",
 "category": "medical",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. National Institutes of Health (NHLBI and NIDDK)",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105)",
 "attribution": "Text from National Heart, Lung, and Blood Institute (NHLBI) and National Institute of Diabetes and Digestive and Kidney Diseases (NIDDK) web pages, retrieved October 2026; reformatted into sections without changing substance; glossary pop-ups, footnote numbers and hospital-treatment sections not included. Use does not imply endorsement by NIH, HHS, or the U.S. Government.",
 "description": "Recognizing a heart attack, cardiac arrest (CPR and AEDs), stroke (FAST test), asthma attacks and low blood glucose, and when to call 9-1-1."
}
JSON

# =========================================================================
# 02b-home-health (verified)
# =========================================================================
D=content/02b-home-health; mkdir -p $D; rm -f $D/*.md
niddk diarrhea-sx "Diarrhea: Symptoms, Dehydration and When to See a Doctor (NIDDK)" $D/01-diarrhea-symptoms.md
niddk diarrhea-tx "Treating Diarrhea at Home, Including Children (NIDDK)" $D/02-diarrhea-treatment.md
niddk gastro-sx "Viral Gastroenteritis (Stomach Flu): Symptoms and Dehydration (NIDDK)" $D/03-stomach-flu-symptoms.md
niddk gastro-tx "Treating Viral Gastroenteritis (Stomach Flu) (NIDDK)" $D/04-stomach-flu-treatment.md
niddk foodpois-sx "Food Poisoning: Symptoms and When to Seek Care (NIDDK)" $D/05-food-poisoning-symptoms.md
niddk foodpois-tx "Treating Food Poisoning (NIDDK)" $D/06-food-poisoning-treatment.md
fda sanitizer "Safely Using Hand Sanitizer (FDA)" $D/07-hand-sanitizer.md
fda antibiotics "When and How to Use Antibiotics (FDA)" $D/08-antibiotics.md
fda otc-label "Reading the Over-the-Counter Drug Facts Label (FDA)" $D/09-otc-drug-facts-label.md \
  "drop=^(Click to learn more:|Below is an example of what the OTC medicine label looks like\.|Disclaimer: This label is for illustrative purposes only\.)$" \
  "cutsec=^What It Means$"
fda masks "Face Masks, Surgical Masks and N95 Respirators (FDA)" $D/10-masks-respirators.md \
  "drop=^Companies interested in developing NIOSH-approved respirators" \
  "cutsec=^COVID-19 Resources|^On this page:"
$XH "$SRC/aspr-epap.html" --source-url "$EPAP_URL" \
  --title "Free Prescriptions and Medical Supplies After a Disaster: EPAP (ASPR)" -o $D/11-emergency-prescriptions.md
post $D/11-emergency-prescriptions.md "cutsec=^Important for Pharmacists$"

# IHS "Dental Emergencies - In Your Home" card (1-page, six columns). The
# text layer reads two columns interleaved, so the words are written out
# column by column, in the order printed (verified against pdfminer x/y
# positions: BROKEN TOOTH column x≈148-157, TONGUE OR LIP CUT x≈212-221).
# Only line breaks and bullet glyphs (U+F0B7 -> "- ") change; the card's
# title and its one footer line form the first section.
cat > $D/12-dental-emergencies.md <<'MD'
# Dental Emergencies in Your Home (Indian Health Service)
Source: https://www.ihs.gov/doh/documents/centers/abq/DentalEmergMagnets_PORTAL.pdf

## Dental emergencies in your home
DENTAL EMERGENCIES - In Your Home

IF YOU NEED MORE HELP, CALL 911

## Toothache
- Rinse with warm water
- Use floss or toothpick to remove anything caught between teeth
- Do NOT put medicine on tooth!
- See dentist

## Knocked-out tooth
- Find tooth
- Hold tooth by part that was not in the gums
- Gently rinse tooth with water
- Put tooth back in tooth socket, if not able, store tooth in milk
- See dentist ASAP

## Broken tooth
- Rinse with warm water
- Use cold compress/ ice pack on face outside near tooth area
- See dentist ASAP

## Tongue or lip cut
- Put easy direct pressure to area
- Use cold compress/ ice pack on area
- If bleeding doesn’t stop, go to hospital or dentist ASAP

## Object stuck between teeth
- Gently use floss or toothpick to remove
- Do NOT put anything sharp in mouth
- If object cannot be removed, see dentist

## Possible broken jaw
- Use cold compress/ ice pack on area
- Go to hospital ASAP
MD

cat > $D/pack.json <<JSON
{
 "id": "home-health",
 "title": "Home Health: Diarrhea, Hygiene, Medicines & Dental",
 "category": "medical",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. NIH (NIDDK), Food and Drug Administration, HHS ASPR, and Indian Health Service",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105)",
 "attribution": "Text from National Institute of Diabetes and Digestive and Kidney Diseases (NIDDK), U.S. Food and Drug Administration (FDA), Administration for Strategic Preparedness and Response (ASPR) web pages and an Indian Health Service Division of Oral Health card, retrieved October 2026; reformatted into sections without changing substance; footnote numbers and images not included. Use does not imply endorsement by NIH, FDA, ASPR, IHS, HHS, or the U.S. Government.",
 "description": "Caring for diarrhea, stomach flu and food poisoning at home and spotting dehydration in adults and children; hand sanitizer, antibiotics, reading OTC medicine labels, masks and N95 respirators; free prescriptions after a disaster (EPAP); and dental emergencies when no dentist is available."
}
JSON
echo "done: content/01b-medical-emergencies content/02b-home-health"
