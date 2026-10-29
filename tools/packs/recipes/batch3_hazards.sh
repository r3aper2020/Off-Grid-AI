#!/usr/bin/env bash
# Batch 3 (hazards area): more weather/geologic hazards, CBRN protective
# actions, cold weather, medicines (FDA), mental health (NIMH), community
# (CERT), vulnerable groups, bear safety, and a historical childbirth guide.
#
# Usage: tools/packs/recipes/batch3_hazards.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir> first
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-29. Run from the project root; then build each pack with
#   python3 tools/packs/build_pack.py content/<pack-dir>
#
# Everything here is a U.S. Government work (17 U.S.C. § 105) unless noted.
# Every page/PDF was scanned for "©", "copyright", "courtesy", "permission",
# "reprinted"; third-party portions are excluded as noted per source.
# Text is verbatim. Post-processing (post() below) only removes page chrome
# (site banners, "Return to top", accordion "+" glyphs, sidebar labels, video
# player text), turns FAQ question lines into "## " headings, normalizes
# typographic ligatures (ﬁ→fi) so search works, and cuts held-back tables,
# replacing each with a bracketed "not included" marker.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
PY=tools/.venv/bin/python
XP="$PY tools/packs/extract_pdf.py"
XH="python3 tools/packs/extract_html.py"
V=2026.10.29.5

RG=https://www.ready.gov
NWS=https://www.weather.gov/safety
FDA=https://www.fda.gov
NIMH=https://www.nimh.nih.gov/health/publications
ND_URL=https://remm.hhs.gov/PlanningGuidanceNuclearDetonation_2023.pdf
CW_URL=https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN46141-ATP_3-90.96-002-WEB-5.pdf
CERT_URL=https://em.uci.edu/training/_pdf/cert-participant-manual-english.pdf
CMS_URL=https://esrd.ipro.org/wp-content/uploads/2026/06/CMSPreparingforEmergencies_508-062026.pdf
NPS_URL=https://www.nps.gov/subjects/bears/safety.htm
PG_URL=https://www.gutenberg.org/cache/epub/26923/pg26923.txt

READY_PAGES="tornadoes thunderstorms-lightning landslides-debris-flow tsunamis
  volcanoes drought avalanche explosions hazmat radiation biohazard
  household-chemical-emergencies older-adults people-disabilities pets"
NWS_PAGES="tornado-during lightning-tips lightning-struck cold cold-during
  tsunami-during drought wind-dust-storm"
FDA_PAGES="
fda-safe-drug=drugs/emergency-preparedness-drugs/safe-drug-use-after-natural-disaster
fda-insulin=drugs/emergency-preparedness-drugs/information-regarding-insulin-storage-and-switching-between-products-emergency
fda-expiry-ext=emergency-preparedness-and-response/mcm-legal-regulatory-and-policy-framework/expiration-dating-extension
fda-expiry-qa=drugs/pharmaceutical-quality-resources/expiration-dates-questions-and-answers
fda-acetaminophen=drugs/safe-use-over-counter-pain-relievers-and-fever-reducers/acetaminophen
fda-kids-cold=consumers/consumer-updates/should-you-give-kids-medicine-coughs-and-colds
fda-disposal=drugs/safe-disposal-medicines/disposal-unused-medicines-what-you-should-know
fda-ki=drugs/bioterrorism-and-drug-preparedness/frequently-asked-questions-potassium-iodide-ki"

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC"
  dl() { curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/$1" "$2"; }
  for p in $READY_PAGES; do dl "ready-$p.html" "$RG/$p"; done
  for p in $NWS_PAGES; do dl "nws-$p.html" "$NWS/$p"; done
  for kv in $FDA_PAGES; do dl "${kv%%=*}.html" "$FDA/${kv#*=}"; done
  dl nimh-5steps.html "$NIMH/5-action-steps-for-helping-someone-in-emotional-pain"
  dl nimh-children.html "$NIMH/helping-children-and-adolescents-cope-with-disasters-and-other-traumatic-events"
  dl nps-bears.html "$NPS_URL"
  dl nuc-det-2023.pdf "$ND_URL"
  dl atp3-90-96.pdf "$CW_URL"
  dl cert-pm.pdf "$CERT_URL"
  dl cms-dialysis.pdf "$CMS_URL"
  dl childbirth.txt "$PG_URL"
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Wrap a slice of a page that has no <main> (NWS, NPS) in <main> so
# extract_html.py sees only the article: from START marker to END marker.
cat > "$TMP/slice.py" <<'PY'
import sys
src, start, end, out = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
i = s.index(start); j = s.index(end, i)
open(out, "w", encoding="utf-8").write("<html><body><main>" + s[i:j] + "</main></body></html>")
PY

# post FILE [ops...]: chrome removal and table cuts (see header).
#   drop=REGEX         delete lines matching REGEX
#   plus               strip accordion "+" from "## +Heading"
#   faq                "N. Question" lines become "## N. Question"
#   cut=START|END|NOTE delete from line matching START up to (not
#                      including) the line matching END; insert NOTE
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
lines = open(path, encoding="utf-8").read().split("\n")
LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}
for op in ops:
    kind, _, arg = op.partition("=")
    if kind == "drop":
        r = re.compile(arg); lines = [l for l in lines if not r.search(l)]
    elif kind == "plus":
        lines = [re.sub(r"^## \+", "## ", l) for l in lines]
    elif kind == "faq":
        lines = [("## " + l) if re.match(r"^\d{1,2}\. \S.*", l) else l for l in lines]
    elif kind == "cut":
        start, end, note = arg.split("|")
        i = next(k for k, l in enumerate(lines) if re.search(start, l))
        j = next(k for k in range(i + 1, len(lines)) if re.search(end, lines[k]))
        lines[i:j] = ([note, ""] if note else [])
    else:
        sys.exit(f"unknown op {op}")
text = "\n".join(lines)
# An "## Overview" left empty by chrome removal is dropped (build rejects it).
text = re.sub(r"^## Overview\n\s*(?=## )", "", text, flags=re.M)
for a, b in LIG.items():
    text = text.replace(a, b)
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text))
PY
post() { python3 "$TMP/post.py" "$@"; }
BANNER='^If you are a disaster survivor, please visit FEMA.gov'
TOP='^(Return to top|Back to top)$'
NWS_SIDEBAR='^(Cold|Lightning|Tsunami|Tsunami Safety|Wind|Drought) Resources$|^Tornadoes, Wind, Hail$|^\*\*Get Tsunami Alerts\*\*$'

ready() {  # ready <page> <title> <out.md>
  $XH "$SRC/ready-$1.html" --source-url "$RG/$1" --title "$2" -o "$3"
  post "$3" "drop=$BANNER" "drop=$TOP"
}
nws() {    # nws <page> <title> <out.md>
  python3 "$TMP/slice.py" "$SRC/nws-$1.html" '<div class="cms-content">' '<div class="footer">' "$TMP/nws-$1.html"
  $XH "$TMP/nws-$1.html" --source-url "$NWS/$1" --title "$2" -o "$3"
  post "$3" plus "drop=$NWS_SIDEBAR"
}
fda() {    # fda <key> <title> <out.md> [extract args...]
  local key=$1 t=$2 o=$3; shift 3
  local path; path=$(printf '%s\n' $FDA_PAGES | grep "^$key=" | cut -d= -f2)
  $XH "$SRC/$key.html" --source-url "$FDA/$path" --title "$t" -o "$o" "$@"
}

# =========================================================================
# 14-weather-disasters-more (verified): Ready.gov + NWS. Geologic hazards
# (landslides, tsunamis, volcanoes) join here.
# NWS: weather.gov content is public domain unless noted; none of these
# pages credits third-party content. Excluded NWS pages: tornado and
# lightning landing pages (links only / story requests), lightning-safety
# (link list), dust-hazards (infographic links), wind-chill chart (table).
# Excluded: USGS FS 2004-3072 (4-page tri-column fact sheet: figure labels
# interleaved and paragraphs split mid-word — scrambled); USGS volcanic-ash
# households + during-ashfall pages (households text is from the IVHHN
# pamphlet; the site is co-authored with GNS Science, Massey and Canterbury
# universities — not a federal work).
# =========================================================================
D=content/14-weather-disasters-more; mkdir -p $D
ready tornadoes "Tornadoes (Ready.gov)" $D/01-tornadoes.md
nws tornado-during "What to Do During a Tornado (NWS)" $D/02-tornado-during.md
ready thunderstorms-lightning "Thunderstorms & Lightning (Ready.gov)" $D/03-thunderstorms-lightning.md
nws lightning-tips "Lightning: What You Need to Know (NWS)" $D/04-lightning-tips.md
nws lightning-struck "How People Are Struck by Lightning (NWS)" $D/05-lightning-struck.md
ready tsunamis "Tsunamis (Ready.gov)" $D/06-tsunamis.md
nws tsunami-during "What to Do During a Tsunami (NWS)" $D/07-tsunami-during.md
ready landslides-debris-flow "Landslides & Debris Flow (Ready.gov)" $D/08-landslides.md
ready volcanoes "Volcanoes (Ready.gov)" $D/09-volcanoes.md
ready avalanche "Avalanche (Ready.gov)" $D/10-avalanche.md
ready drought "Drought (Ready.gov)" $D/11-drought.md
nws drought "What Is Drought? (NWS)" $D/12-drought-types.md
nws wind-dust-storm "Dust Storms (NWS)" $D/13-dust-storms.md

# =========================================================================
# 15-cbrn-protective-actions (verified)
# FEMA, Planning Guidance for Response to a Nuclear Detonation, 3rd ed.
# (2022; record of change 06/12/2023), HHS REMM mirror. PDF page = printed
# page + 10. Taken: Ch. 1 Nuclear Detonation Impacts (PDF 23-51) and Ch. 3
# Shelter & Evacuation (PDF 73-81).
# Excluded third-party: Figure 8 caption "courtesy of Kramer, 2014" (PDF 36,
# cut below); NCRP "reprinted with permission" text on PDF 55, 65-69, 191,
# 196 (all in skipped chapters: Ch. 2 zones/emergency worker safety, App.).
# Skipped as responder planning: Ch. 2 (its public-action lines interleave
# NCRP-reprinted bullets on PDF 55), Ch. 4-7, appendices.
# FDA Potassium Iodide FAQ: Question 5 is a dosing TABLE (dose by age group,
# tablet fractions, mL of solution) — HELD BACK (cut, marker inserted).
# =========================================================================
D=content/15-cbrn-protective-actions; mkdir -p $D
ready radiation "Radiation Emergencies (Ready.gov)" $D/01-radiation.md
$XP "$SRC/nuc-det-2023.pdf" --pages 73-81 --source-url "$ND_URL" \
  --title "Shelter and Evacuation After a Nuclear Detonation (FEMA Planning Guidance, Ch. 3)" -o $D/02-nuclear-shelter-evacuation.md
$XP "$SRC/nuc-det-2023.pdf" --pages 23-51 --source-url "$ND_URL" \
  --title "Nuclear Detonation Impacts: Blast, Heat, Radiation and Fallout (FEMA Planning Guidance, Ch. 1)" -o $D/03-nuclear-detonation-impacts.md
post $D/03-nuclear-detonation-impacts.md \
  'cut=^\[Figure 8: Outdoor initial radiation|^1\.4\.2\. RESIDUAL RADIATION|[Figure 8 — third-party figure and caption not included]'
fda fda-ki "Frequently Asked Questions on Potassium Iodide (KI) (FDA)" $D/04-potassium-iodide.md
post $D/04-potassium-iodide.md \
  'cut=^- What does potassium iodide \(KI\) do|^1\. What does|' \
  'cut=^5\. What dosages|^6\. When should|[Question 5, the KI dosing table, is not included: table layout not preserved. See the original FDA page for doses.]' \
  faq
ready hazmat "Hazardous Materials Incidents (Ready.gov)" $D/05-hazmat.md
ready household-chemical-emergencies "Household Chemical Emergencies (Ready.gov)" $D/06-household-chemicals.md
ready biohazard "Bioterrorism (Ready.gov)" $D/07-biohazard.md
ready explosions "Explosions (Ready.gov)" $D/08-explosions.md

# =========================================================================
# 16-cold-weather (verified)
# ATP 3-90.96 / MCTP 12-10E Arctic and Extreme Cold Weather Operations
# (24 Feb 2025, incl. Change 2). Title page and every page footer:
# "DISTRIBUTION RESTRICTION: Approved for public release; distribution is
# unlimited." PDF page = printed page + 20. Taken: Ch. 1 Sec. II The Physical
# Environment and Sec. III Environmental Hazards (PDF 25-65).
# Excluded third-party (Acknowledgements, p. xi): Figure 2-3 (Nordregio,
# Ch. 2), Figure 4-3 Fesler/Fredston avalanche checklist (Ch. 4, p. 119),
# Ted Stevens Center "Arctic Security Operations Course" material — its
# location is not marked in the text, so Ch. 1 Sec. I and Ch. 2 (arctic
# significance/security, where it most plausibly sits) are skipped.
# Skipped as military: Ch. 2-10, App. A, E, G. HELD BACK (critical numbers
# in tables): Table 1-4 windchill chart and Table 1-5 cheek-frostbite times
# (cut below); App. C ice load capacity tables; App. D Table D-1 cold injury
# signs/prevention/treatment (table rows); App. B frost-depth/vehicle tables;
# App. F clothing/planning tables.
# NWS cold pages: cold-during quotes CDC frostbite signs/first aid
# ("From CDC") — Source: CDC.
# =========================================================================
D=content/16-cold-weather; mkdir -p $D
cw() { $XP "$SRC/atp3-90-96.pdf" --pages "$1" --source-url "$CW_URL" --title "$2" -o "$D/$3.md" --bold-headings; }
nws cold "Extreme Cold (NWS)" $D/01-extreme-cold.md
nws cold-during "What to Do During Extreme Cold: Frostbite and Hypothermia (NWS)" $D/02-cold-during.md
cw 25-46 "Arctic Climates, Snow, Ice and Terrain (ATP 3-90.96 Ch. 1)" 03-climate-terrain
cw 47-57 "Arctic Weather: Temperature, Wind, Light and Precipitation (ATP 3-90.96 Ch. 1)" 04-weather
post $D/04-weather.md \
  'cut=^\[Table 1-4\. Windchill chart|^## Ground Blizzard|[Table 1-4. Windchill chart and Table 1-5. Time to occurrence of cheek frostbite in minutes — not included: table layout not preserved; see the original document]'
cw 58-65 "Seasons, Wildlife and Environmental Hazards (ATP 3-90.96 Ch. 1)" 05-seasons-hazards

# =========================================================================
# 02-medicines (verified, FDA; FDA web content is public domain per FDA's
# website policies). Excluded: "Drug Interactions: What You Should Know"
# (states it is "brought to you by the Council on Family Health in
# cooperation with the National Consumers League and the U.S. FDA" — joint
# non-federal work; also table-based). Expiration Dating Extension: only the
# overview and "Approaches" sections; the per-product lot/date tables
# (from "MCM Expiration Dating Extensions" on) are dropped.
# =========================================================================
D=content/02-medicines; mkdir -p $D
fda fda-safe-drug "Safe Drug Use After a Natural Disaster (FDA)" $D/01-safe-drug-use-after-disaster.md
post $D/01-safe-drug-use-after-disaster.md 'drop=^Back to Natural Disaster Response$'
fda fda-insulin "Insulin Storage and Switching Between Products in an Emergency (FDA)" $D/02-insulin-emergency.md
fda fda-expiry-qa "Expiration Dates: Questions and Answers (FDA)" $D/03-expiration-dates.md
post $D/03-expiration-dates.md faq
fda fda-expiry-ext "Expiration Dating Extension (FDA)" $D/04-expiration-extension.md \
  --drop-after "MCM Expiration Dating Extensions"
fda fda-acetaminophen "Acetaminophen (FDA)" $D/05-acetaminophen.md
fda fda-kids-cold "Should You Give Kids Medicine for Coughs and Colds? (FDA)" $D/06-kids-cough-cold.md
fda fda-disposal "Disposal of Unused Medicines (FDA)" $D/07-disposal.md

# =========================================================================
# 02-mental-health (verified, NIMH). Each page: "The information in this
# publication is in the public domain and may be reused or copied without
# permission. However, you may not reuse or copy images." (images not used).
# The children page lists the old lifeline 1-800-273-TALK (8255); text is
# kept verbatim and the pack description gives 988.
# =========================================================================
D=content/02-mental-health; mkdir -p $D
NIMH_SKIP=(--skip "Share the Infographic on Social Media" "Reprints" "Where can I find more resources?")
$XH "$SRC/nimh-5steps.html" --source-url "$NIMH/5-action-steps-for-helping-someone-in-emotional-pain" \
  --title "5 Action Steps to Help Someone Having Thoughts of Suicide (NIMH)" -o $D/01-5-action-steps.md "${NIMH_SKIP[@]}"
$XH "$SRC/nimh-children.html" --source-url "$NIMH/helping-children-and-adolescents-cope-with-disasters-and-other-traumatic-events" \
  --title "Helping Children and Adolescents Cope With Disasters and Other Traumatic Events (NIMH)" -o $D/02-children-trauma.md "${NIMH_SKIP[@]}"
for f in $D/01-5-action-steps.md $D/02-children-trauma.md; do post $f 'drop=^- (Download PDF|En español)$'; done

# =========================================================================
# 18-vulnerable-groups (verified): Ready.gov + CMS dialysis guide.
# CMS "Preparing for Emergencies: A Guide for People on Dialysis" v2.3
# (June 2026), hosted by the ESRD Network contractor IPRO. No copyright
# notice; contributors include ESRD Network/contractor staff (flagged in
# report). Taken PDF 5-8 (intro, get ready, alternative arrangements, go-kit
# checklist), 15-16 (medical ID, emergency diet introduction), 28-34
# (facility closed, sheltering, evacuating, getting off the machine, access
# care, more information). HELD BACK: 3-Day Emergency Diet shopping list and
# menus (PDF 17-26, food/fluid quantity tables) and How to Disinfect Water
# (PDF 27, bleach-by-volume table). Skipped: fill-in forms (PDF 10-14),
# version history, ESRD Network contact list (PDF 35-38).
# =========================================================================
D=content/18-vulnerable-groups; mkdir -p $D
ready older-adults "Older Adults (Ready.gov)" $D/01-older-adults.md
ready people-disabilities "People with Disabilities (Ready.gov)" $D/02-people-disabilities.md
ready pets "Pets and Animals (Ready.gov)" $D/03-pets.md
cms() { $XP "$SRC/cms-dialysis.pdf" --pages "$1" --source-url "$CMS_URL" --title "$2" -o "$D/$3.md"; }
cms 5-8   "Getting Ready: A Guide for People on Dialysis (CMS)" 04-dialysis-get-ready
cms 15-16 "Medical ID and the Emergency Diet Plan: A Guide for People on Dialysis (CMS)" 05-dialysis-medical-id-diet
cms 28-34 "When You Can't Get Dialysis, Sheltering and Evacuating: A Guide for People on Dialysis (CMS)" 06-dialysis-during-emergency

# =========================================================================
# 16-wildlife-safety (verified): NPS "Staying Safe Around Bears" (federal;
# the page's only credit is the banner photo "NPS Photo", not used).
# Kept as its own small pack rather than editing wilderness-survival.
# =========================================================================
D=content/16-wildlife-safety; mkdir -p $D
python3 "$TMP/slice.py" "$SRC/nps-bears.html" '<div id="main" role="main"' '<div id="related_content_position"' "$TMP/nps-bears.html"
$XH "$TMP/nps-bears.html" --source-url "$NPS_URL" --title "Staying Safe Around Bears (National Park Service)" \
  -o $D/01-bear-safety.md --skip "Bear Safety Articles"
post $D/01-bear-safety.md 'drop=^<iframe' 'drop=^Visit our keyboard shortcuts docs' 'drop=^Duration:$' 'drop=^1 minute, 3 seconds$'

# =========================================================================
# 18-community-cert (needs-review): FEMA CERT Basic Training Participant
# Manual (Aug 2019 update), copy hosted by UC Irvine Emergency Management —
# not fetched from fema.gov, so provenance is unverified. Federal work; the
# only third-party mentions are referrals to Red Cross/AHA courses.
# Units (PDF pages, cover/TOC and fill-in forms skipped): 1 Disaster
# Preparedness 14-40, 2 CERT Organization 57-81, 3 Medical Ops I 99-117,
# 4 Medical Ops II 124-136, 5 Psychology 143-155, 6 Fire Safety & Utilities
# 162-184, 7 Light Search & Rescue 192-220, 8 Terrorism & CERT 227-244.
# Unit 9 (course review/exam) skipped. HELD BACK (cut, markers inserted):
# Table 3.3 bleach-to-water ratios (U1), Table 3.1 stages of severe bleeding
# and Table 3.2 burn classification (U3), Table 2.3 rescue by degree of
# damage (U2; the same rules are in the prose above it), Table 6.2 fire
# types/extinguishing agents (U6), Table 7.2 earthquake damage by
# construction type (U7). Unit 4's prose water-purification ratios are kept.
# =========================================================================
D=content/18-community-cert; mkdir -p $D
cert() { local p=$1 t=$2 o=$3; shift 3
  $XP "$SRC/cert-pm.pdf" --pages "$p" --source-url "$CERT_URL" --title "$t" -o "$D/$o.md" --skip "Homework Assignment" "$@"; }
NA='not included: table layout not preserved; see the original manual]'
cert 14-40   "Disaster Preparedness (CERT Basic Training, Unit 1)" 01-disaster-preparedness
post $D/01-disaster-preparedness.md "cut=^\[Table 3\.3: Ratios for Purifying Water|^Food and Kitchen Items|[Table 3.3: Ratios for Purifying Water with Bleach — $NA"
cert 57-81   "CERT Organization and Size-up (CERT Basic Training, Unit 2)" 02-cert-organization
post $D/02-cert-organization.md "cut=^\[Table 2\.3: CERT Rescue Efforts|^Image 2\.3|[Table 2.3: CERT Rescue Efforts Based on Degree of Damage — $NA"
cert 99-117  "Disaster Medical Operations Part 1: Life-Threatening Conditions (CERT Basic Training, Unit 3)" 03-medical-operations-1
post $D/03-medical-operations-1.md \
  "cut=^\[Table 3\.1: Stages of Severe Bleeding|^Types of bleeding are characterized|[Table 3.1: Stages of Severe Bleeding — $NA" \
  "cut=^\[Table 3\.2: Burn Classification Chart|^Guidelines for Treating Heat Burns|[Table 3.2: Burn Classification Chart — $NA"
cert 124-136 "Disaster Medical Operations Part 2: Mass Casualties, Assessment and Public Health (CERT Basic Training, Unit 4)" 04-medical-operations-2
cert 143-155 "Disaster Psychology (CERT Basic Training, Unit 5)" 05-disaster-psychology
cert 162-184 "Fire Safety and Utility Controls (CERT Basic Training, Unit 6)" 06-fire-safety-utilities
post $D/06-fire-safety-utilities.md "cut=^\[Table 6\.2: Fire Types|^## Extinguisher Rating|[Table 6.2: Fire Types, Extinguishing Agents, and Methods — $NA"
cert 192-220 "Light Search and Rescue Operations (CERT Basic Training, Unit 7)" 07-light-search-rescue
post $D/07-light-search-rescue.md "cut=^\[Table 7\.2: Probable Severity|^## Step 3: Consider Probabilities|[Table 7.2: Probable Severity and Type of Earthquake Damage Based on Construction Type — $NA"
cert 227-244 "Terrorism, Active Shooter and CBRNE (CERT Basic Training, Unit 8)" 08-terrorism

# =========================================================================
# 01-childbirth-historical (historical): Emergency Childbirth, Medical
# Self-Help Training Course Lesson 11, U.S. DoD Office of Civil Defense and
# U.S. PHS (reprinted December 1970), Project Gutenberg #26923 (plain text;
# PG header/footer stripped by extract_text.py). The AMA acknowledgment
# (review assistance) is not a copyright claim. The book has no CHAPTER
# lines, so one is inserted before the body heading for extract_text.py;
# the cover, acknowledgment and imprint before it are not extracted.
# =========================================================================
D=content/01-childbirth-historical; mkdir -p $D
python3 - "$SRC/childbirth.txt" "$TMP/childbirth.txt" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read().replace("\r\n", "\n")
j = s.index("\nEMERGENCY CHILDBIRTH\n", s.index("Reprinted December 1970"))
open(sys.argv[2], "w", encoding="utf-8").write(s[:j + 1] + "CHAPTER I.\n" + s[j + 1:])
PY
python3 tools/packs/extract_text.py "$TMP/childbirth.txt" --chapter "EMERGENCY CHILDBIRTH" \
  --title "Emergency Childbirth (Office of Civil Defense and Public Health Service, 1970 reprint)" \
  --source-url https://www.gutenberg.org/ebooks/26923 -o $D/01-emergency-childbirth.md

# =========================================================================
# NOT INCLUDED (decisions needed / held back):
# - EPA "A Brief Guide to Mold, Moisture, and Your Home", EPA mold-cleanup
#   and flooded-homes pages: EPA's disclaimer says its documents "may be
#   freely distributed and used for non-commercial, scientific and
#   educational purposes. Commercial use ... may be protected" — EPA is
#   deferred in docs/decisions.md. (flooded-homes is also only a link hub.)
# - Ready.gov animals (same text as pets), kids, kids/prepare-your-family,
#   home page (navigation hubs, no guidance text).
# =========================================================================
echo "batch3_hazards: done"
