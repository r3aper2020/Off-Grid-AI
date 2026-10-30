#!/usr/bin/env bash
# Batch 5 (medicines): two new packs.
#   content/02c-otc-medicines (id otc-medicines) — the Drug Facts panel of one
#     current OTC human label per medicine, from DailyMed (NLM) SPL XML.
#   content/03-herbal-remedies (id herbal-remedies) — NIH NCCIH "Herbs at a
#     Glance" pages, 30 herbs, with every safety paragraph kept.
#
# Usage: tools/packs/recipes/batch5_medicines.sh <source-dir> [--fetch]
#   --fetch downloads every source below into <source-dir>/{dailymed,nccih}
#   (curl -sL -A "Mozilla/5.0" --retry 3). All sources answered HTTP 200 on
#   2026-10-30. Run from the project root; then build each pack with
#   python3 tools/packs/build_pack.py content/<pack-dir>
#
# LICENSE
#   DailyMed: FDA-approved/OTC-monograph labeling (SPL) published by the
#   National Library of Medicine; the Drug Facts text is U.S. Government
#   (FDA) labeling and DailyMed's terms state its content is public domain
#   ("DailyMed ... information is in the public domain"; NLM Web Policies).
#   Only the Drug Facts panel (active ingredient, purpose, uses, warnings,
#   directions, other information) is taken. Inactive ingredients, package
#   label/principal display panel text, product-data tables, "Questions?"
#   phone lines, distributor addresses and ALL IMAGES are not used. Labeler
#   trade names appear only as the product's name on its own label.
#   NCCIH: every "Herbs at a Glance" page ends "This publication is not
#   copyrighted and is in the public domain. Duplication is encouraged."
#   Each page was scanned for "©", "copyright", "courtesy", "permission",
#   "reprinted", "adapted from": the only hits are the photo credits
#   "© Steven Foster" / "© Thinkstock" on the page images, which are NOT
#   used (text only), and the Bootstrap CSS licence comment.
#
# SELECTION (one label per medicine; setid, labeler, label effective date)
#   acetaminophen 500 mg caplets   Tylenol Extra Strength, Kenvue, 2026-07-22
#   acetaminophen 160 mg/5 mL      Children's Tylenol suspension, Kenvue, 2026-06-12
#   ibuprofen 200 mg tablets       Advil, Haleon, 2026-03-12 (Tablets panel; the
#                                  identical Caplets/Gel Caplets repeats are cut)
#   ibuprofen 100 mg/5 mL          Children's Motrin suspension, Kenvue, 2024-11-08
#   aspirin 325 mg tablets         Bayer Genuine Aspirin, Bayer, 2025-12-04
#   naproxen sodium 220 mg caplets Good Sense (Perrigo store-brand), 2026-05-11
#                                  (Bayer's own Aleve SPL 00ef5b30 has an EMPTY
#                                  warnings section; its 2025 "Blueshield" SPL
#                                  carries typos — "conidtion", "un the unborn")
#   diphenhydramine 25 mg tablets  Benadryl, Kenvue, 2026-07-28
#   loratadine 10 mg tablets       Claritin, Bayer, 2025-12-05
#   loperamide 2 mg caplets        Imodium A-D, Kenvue, 2025-09-23
#   bismuth subsalicylate liquid   Pepto-Bismol, Procter & Gamble, 2026-10-06
#   famotidine 20 mg tablets       Pepcid AC Maximum Strength, Kenvue, 2024-11-11
#                                  (Pepcid AC Original Strength is 10 mg)
#   meclizine 25 mg tablets        Dramamine Less Drowsy, Medtech, 2026-09-04
#   hydrocortisone 1% cream        Kroger store brand, 2026-08-19 (Cortizone-10
#                                  SPLs carry inline "■" bullets and are per-variant)
#   triple antibiotic ointment     Neosporin Original, Kenvue, 2024-11-13
#   povidone-iodine 10% solution   Major Pharmaceuticals, 2026-08-14 (the Betadine
#                                  brand SPL 1b1e224c has words run together in
#                                  its XML — "helpprevent", "timesdaily"; the
#                                  Betadine SPL c927c742 is the veterinary 5%)
#   pseudoephedrine 30 mg tablets  Sudogest, Major Pharmaceuticals, 2026-10-06
#                                  (no single-ingredient Sudafed SPL is current)
#
# EXCLUDED (and why):
#   - Oral rehydration salts: no OTC Drug Facts label exists on DailyMed.
#     "Suerolyte Oral Electrolyte Solution" (2015) is a dietary-supplement
#     label, not Drug Facts; Pedialyte and similar ORS are foods/medical
#     foods and are not listed at all. Skipped.
#   - NCCIH has no "Herbs at a Glance" page for comfrey, willow bark or honey
#     (HTTP 404), so none were made.
#   - NCCIH "For More Information" / Clearinghouse / PubMed / ODS footers and
#     the "Federal Regulation of Herbal Products" call-out box repeated on
#     every page (page chrome) are not included.
#   - Inactive ingredients and "Questions or comments?" lines are omitted
#     from every label (the assignment allows this).
#
# Text is verbatim. The SPL converter below only: normalises whitespace,
# writes each table row as one line with cells joined by " — " (checked by
# eye against the DailyMed HTML rendering for every dosing table), turns
# list items into "- " lines (dropping the labeler's own "•"/"■" glyphs), and
# groups the Drug Facts sections under four headings per product. The NCCIH
# post-processor only prefixes headings with the herb name, adds the page's
# "Last Updated" date to the title, and deletes the chrome listed above.
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--fetch]}"
XH="python3 tools/packs/extract_html.py"
V=2026.10.30.1
DM=https://dailymed.nlm.nih.gov/dailymed
NC=https://www.nccih.nih.gov/health

# name=setid
LABELS="
tylenol-es=103d109d-f520-409c-8da2-eb6b0fbec891
tylenol-child=3162733b-9382-39f1-e063-6294a90ac420
advil=1a665e64-9f30-be37-4a83-38789f1f1e89
motrin-child=152189e5-391c-42d3-a03b-c8364e2de6bf
bayer=44a08904-68b9-4d06-a28d-21aae3d6140c
goodsense-naproxen=8e150c00-8e5b-40b4-a964-cb70442c2752
benadryl=702f9786-7ce9-43e4-921d-e1db09612127
claritin=660ac9df-f1b1-4c89-94dd-9fae0a013f3c
imodium=01da76d0-1979-4c45-9d39-c72ae4e4ffe2
pepto=67006e82-870d-8d63-e053-2991aa0a02d1
pepcid-max=2854047f-c5c4-43c3-8ef2-5c0a84a307f2
dramamine-ld=fa6a0969-7427-4b87-bc04-a2792665c218
kroger-hc=f05edff2-2dc5-427c-b52c-518e0aaef4e0
neosporin=a3e6fe2e-1b74-4f22-9c7c-a00057439690
pvp-major=59041ca3-a195-5a20-e063-6394a90a2ac9
sudogest=d46577aa-7fd7-2130-6ed6-4b3f7562491f"
HERBS="aloe-vera chamomile cranberry echinacea elderberry ephedra garlic ginger
  asian-ginseng goldenseal green-tea kava lavender licorice-root milk-thistle
  peppermint-oil st-johns-wort tea-tree-oil turmeric valerian yohimbe feverfew
  sage dandelion cinnamon ginkgo hawthorn passionflower butterbur bitter-orange"
lookup() { printf '%s\n' $2 | grep "^$1=" | cut -d= -f2; }

if [[ "${2:-}" == "--fetch" ]]; then
  mkdir -p "$SRC/dailymed" "$SRC/nccih"
  for kv in $LABELS; do
    curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/dailymed/${kv%%=*}.xml" "$DM/services/v2/spls/${kv#*=}.xml"
  done
  for h in $HERBS; do
    curl -sL -A "Mozilla/5.0" --retry 3 -o "$SRC/nccih/$h.html" "$NC/$h"
  done
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# spl2md XML OUT TITLE PRODUCT ALIASES [DROP_SUB_REGEX]
#   Drug Facts panel of an SPL -> one markdown document with four sections.
cat > "$TMP/spl2md.py" <<'PY'
import re, sys, xml.etree.ElementTree as ET
NS = {'v': 'urn:hl7-org:v3'}
def q(t): return '{urn:hl7-org:v3}' + t
# package label / principal display panel / product data / patient info / questions
SKIP_CODES = {'34069-5', '51945-4', '48780-1', '34076-0', '60561-8', '53413-1'}
DROP_TITLES = re.compile(r'^(inactive ingredients?|package label|principal display|questions)', re.I)
def norm(s): return re.sub(r'\s+', ' ', s or '').strip()
def tag(e): return e.tag.replace('{urn:hl7-org:v3}', '')

def inline(el):
    out = [el.text or '']
    for ch in el:
        t = tag(ch)
        if t == 'br': out.append(' ')
        elif t == 'sup': out.append(ch.text or '')
        elif t == 'list': out.append(' ' + '; '.join(l.lstrip(' -') for l in block(ch)))
        elif t == 'renderMultiMedia': pass
        else: out.append(inline(ch))
        out.append(ch.tail or '')
    return ''.join(out)

def items(lst, depth):
    out = []
    for it in lst.findall('v:item', NS):
        sub, head = [], [it.text or '']
        for g in it:
            gt = tag(g)
            if gt == 'list': sub.extend(items(g, depth + 1))
            elif gt == 'table': sub.extend(table(g))
            elif gt == 'br': head.append(' ')
            else: head.append(inline(g))
            head.append(g.tail or '')
        h = norm(''.join(head))
        if h: out.append('  ' * depth + '- ' + h)
        out.extend(sub)
    return out

def table(tb):
    rows = []
    for tr in tb.iter(q('tr')):
        cells = [norm(inline(td)) for td in tr if td.tag in (q('td'), q('th'))]
        cells = [c for c in cells if c]
        if cells: rows.append('- ' + ' — '.join(cells))
    return rows

def block(el):
    lines = []
    def add(t):
        t = norm(t)
        if t: lines.append(t)
    if el.tag != q('text'): add(el.text)
    for ch in el:
        t = tag(ch)
        if t == 'list': lines.extend(items(ch, 0))
        elif t == 'table': lines.extend(table(ch))
        elif t in ('renderMultiMedia', 'br'): pass
        else: add(inline(ch))
        if ch.tail and norm(ch.tail): lines.append(norm(ch.tail))
    return lines

def walk(sec, depth, out):
    code = sec.find('v:code', NS)
    c = code.get('code') if code is not None else ''
    if c in SKIP_CODES: return
    t = sec.find('v:title', NS)
    title = norm(inline(t)) if t is not None else ''
    if title and DROP_TITLES.search(title): return
    text = sec.find('v:text', NS)
    out.append((depth, c, title, block(text) if text is not None else []))
    for comp in sec.findall('v:component', NS):
        for s in comp.findall('v:section', NS):
            walk(s, depth + 1, out)

def clean(line):
    # the labeler's own bullet glyphs; "■ a ■ b" run-ons become list items
    line = re.sub(r'^(\s*- )\s*[•■]\s*', r'\1', line)
    line = re.sub(r';\s*•\s*', '; ', line).replace(' •', ' ').replace('•', '')
    if '■' in line:
        parts = [p.strip() for p in line.split('■')]
        head, rest = parts[0], [p for p in parts[1:] if p]
        out = []
        for l in ([head] if head else []) + ['- ' + p for p in rest]: out.extend(clean(l))
        return out
    if re.match(r'^-\S', line): return ['  - ' + line[1:]]
    m = re.match(r'^(- .*: )-(\S.*)$', line)   # "due to: -the common cold"
    if m: return [m.group(1).rstrip(), '  - ' + m.group(2)]
    return [line]

def main():
    xml, out, title, product, aliases = sys.argv[1:6]
    drop_sub = re.compile(sys.argv[6]) if len(sys.argv) > 6 else None
    root = ET.parse(xml).getroot()
    setid = root.find('v:setId', NS).get('root')
    flat = []
    for comp in root.find('v:component/v:structuredBody', NS).findall('v:component', NS):
        for s in comp.findall('v:section', NS):
            walk(s, 0, flat)
    groups = {'A': [], 'B': [], 'C': [], 'D': []}
    g = None
    for depth, c, t, body in flat:
        if c in ('55106-9', '55105-1', '34067-9', '50745-9'): g = 'A'
        elif c == '34071-1': g = 'B'
        elif c == '34068-7': g = 'C'
        elif c == '44425-7' or re.match(r'^(other|additional) information', t, re.I): g = 'D'
        elif depth == 0 and c == '42229-5' and not t: continue  # "Drug Facts" marker
        if g is None: continue
        if drop_sub and t and drop_sub.search(t): continue
        if body and re.match(r'^(Dist\.?\s*by|Distributed by|DIST\. BY)', body[0], re.I): continue
        if t.lower() == 'adverse reaction': continue
        lines = []
        for l in body: lines.extend(clean(l))
        lines = [l for l in lines if l.strip() and l.strip() != 'Drug Facts']
        if t and lines and lines[0].lower() == t.lower(): lines = lines[1:]
        if t and lines and lines[0].lower().startswith(t.lower()):
            pass  # the body already carries the label ("Liver warning: ...")
        elif t and not lines and t.lower() in ('warnings', 'directions', 'other information'):
            pass  # bare group title, already the section heading
        elif t:
            # bold label; merge "Title" + first line when the label is a lead-in
            if lines and re.search(r'(if|are|is|have|has|taking|give|,)$', t, re.I) and not lines[0].startswith('- '):
                lines[0] = f'**{t}** {lines[0]}'
            else:
                lines.insert(0, f'**{t}**')
        if lines: groups[g].append('\n'.join(lines))
    heads = {'A': 'active ingredient, purpose and uses', 'B': 'warnings',
             'C': 'directions (dosing)', 'D': 'other information'}
    doc = [f'# {title}', f'Source: https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid={setid}',
           f'Aliases: {aliases}', '']
    for k in 'ABCD':
        if not groups[k]: continue
        doc.append(f'## {product}: {heads[k]}')
        doc.append('\n\n'.join(groups[k]))
        doc.append('')
    text = '\n'.join(doc).rstrip() + '\n'
    assert '�' not in text
    open(out, 'w', encoding='utf-8').write(text)
main()
PY
spl2md() { python3 "$TMP/spl2md.py" "$@"; }

# herb MD HTML NAME ALIASES: title with "Last Updated", heading prefixes,
# aliases line, delete the "Federal Regulation" call-out box.
cat > "$TMP/herb.py" <<'PY'
import re, sys
md, html, name, aliases = sys.argv[1:5]
h = open(html, encoding='utf-8').read()
m = re.search(r'Last Updated:\s*</b>\s*([A-Za-z]+ \d{4})', h)
date = m.group(1) if m else 'undated'
lines = open(md, encoding='utf-8').read().split('\n')
BOX = ('- Federal Regulation of Herbal Products', '- Depending on what’s in them, how they’re intended to be used',
       '- Unlike drugs, dietary supplements are not approved by the U.S. Food and Drug Administration')
out = []
for l in lines:
    if l.startswith('# '): l = f'# {name} (NIH NCCIH Herbs at a Glance, {date})'
    elif l.startswith('## '): l = f'## {name}: {l[3:]}'
    elif l.startswith(BOX): continue
    out.append(l)
    if l.startswith('Source: '): out.append(f'Aliases: {aliases}')
text = '\n'.join(out)
assert '�' not in text
open(md, 'w', encoding='utf-8').write(re.sub(r'\n{3,}', '\n\n', text).rstrip() + '\n')
PY
herb() {  # herb <slug> <Name> <aliases>
  local s=$1 n=$2 a=$3 o=$D/$(printf '%02d' $N)-$1.md
  $XH "$SRC/nccih/$s.html" --container main --source-url "$NC/$s" --title "$n" \
    --drop-after "For More Information" -o "$o" >/dev/null
  python3 "$TMP/herb.py" "$o" "$SRC/nccih/$s.html" "$n" "$a"
  N=$((N + 1))
}
label() {  # label <name> <out.md> <title> <product> <aliases> [drop-sub regex]
  local k=$1; shift
  spl2md "$SRC/dailymed/$k.xml" "$@"
}

# =========================================================================
# 02c-otc-medicines (verified)
# =========================================================================
D=content/02c-otc-medicines; mkdir -p $D; rm -f $D/*.md
label tylenol-es $D/01-acetaminophen-500mg.md \
  "Acetaminophen 500 mg caplets (Drug Facts, Tylenol Extra Strength, Kenvue)" "Tylenol Extra Strength (acetaminophen 500 mg)" \
  "tylenol dosage adults, how much tylenol can I take, acetaminophen 500 mg dose, extra strength tylenol how many caplets, tylenol every how many hours, max tylenol per day, acetaminophen overdose warning, tylenol liver damage alcohol, tylenol with warfarin, tylenol for fever adult, tylenol for headache backache, can I take tylenol pregnant, tylenol with other cold medicine, 4000 mg acetaminophen limit, tylenol skin rash reaction, tylenol for children under 12, tylenol and liver disease, paracetamol dose adult"
label tylenol-child $D/02-acetaminophen-childrens-liquid.md \
  "Acetaminophen 160 mg/5 mL children's oral suspension (Drug Facts, Children's Tylenol, Kenvue)" "Children's Tylenol (acetaminophen 160 mg per 5 mL)" \
  "how much tylenol can I give my kid, childrens tylenol dosing chart, tylenol dose by weight, acetaminophen 160 mg per 5 ml, tylenol for toddler fever, how often can I give tylenol to a child, childrens tylenol every 4 hours, how many doses of childrens tylenol per day, tylenol for 2 year old, tylenol for baby under 2, child acetaminophen overdose, kids fever reducer dose, childrens tylenol sore throat, measuring childrens tylenol ml, child liver warning acetaminophen, how many ml of tylenol for a 40 pound child"
label advil $D/03-ibuprofen-200mg.md \
  "Ibuprofen 200 mg tablets (Drug Facts, Advil, Haleon)" "Advil (ibuprofen 200 mg)" \
  "ibuprofen dosage adults, how much advil can I take, ibuprofen 200 mg how many, advil every how many hours, max ibuprofen per day, ibuprofen stomach bleeding warning, advil heart attack stroke risk, ibuprofen with aspirin, ibuprofen pregnancy 20 weeks, advil on empty stomach, nsaid allergy symptoms, ibuprofen for fever adult, advil for back pain, ibuprofen kidney disease, can I take advil with blood thinner, ibuprofen for children under 12, advil before surgery, motrin dose adult" \
  "Caplets"
label motrin-child $D/04-ibuprofen-childrens-liquid.md \
  "Ibuprofen 100 mg/5 mL children's oral suspension (Drug Facts, Children's Motrin, Kenvue)" "Children's Motrin (ibuprofen 100 mg per 5 mL)" \
  "childrens ibuprofen dosing chart, how much motrin can I give my child, ibuprofen dose by weight kids, childrens advil dose, ibuprofen 100 mg per 5 ml, motrin for toddler fever, how often can I give motrin, ibuprofen every 6 to 8 hours child, motrin for 2 year old, child ibuprofen dehydrated vomiting, kids fever reducer ibuprofen, childrens motrin 4 times a day, ibuprofen child stomach bleeding, motrin sore throat child, child nsaid allergy, ibuprofen for baby under 2"
label bayer $D/05-aspirin-325mg.md \
  "Aspirin 325 mg tablets (Drug Facts, Bayer Genuine Aspirin, Bayer)" "Bayer Genuine Aspirin (aspirin 325 mg)" \
  "aspirin dosage adults, how many aspirin can I take, aspirin 325 mg every 4 hours, max aspirin per day, aspirin for headache dose, aspirin reye syndrome children, can kids take aspirin, aspirin chicken pox flu warning, aspirin stomach bleeding, aspirin allergy symptoms, aspirin pregnancy last 3 months, aspirin ringing in ears, aspirin with blood thinner, aspirin for fever adult, aspirin for toothache, aspirin with gout diabetes medicine, aspirin asthma warning, aspirin for arthritis pain"
label goodsense-naproxen $D/06-naproxen-sodium-220mg.md \
  "Naproxen sodium 220 mg caplets (Drug Facts, Good Sense, Perrigo)" "Naproxen sodium 220 mg caplets (Good Sense)" \
  "aleve dosage, how much naproxen can I take, naproxen sodium 220 mg how many, aleve every 8 to 12 hours, max aleve per day, naproxen stomach bleeding, aleve heart attack stroke warning, naproxen pregnancy 20 weeks, aleve with aspirin, naproxen for back pain, aleve for arthritis, naproxen for menstrual cramps, aleve for children under 12, naproxen pill stuck in throat, aleve with blood thinner, nsaid allergic reaction, aleve for fever, naproxen kidney disease"
label benadryl $D/07-diphenhydramine-25mg.md \
  "Diphenhydramine HCl 25 mg tablets (Drug Facts, Benadryl, Kenvue)" "Benadryl (diphenhydramine 25 mg)" \
  "benadryl dosage adults, how much benadryl can I take, diphenhydramine 25 mg how many, benadryl every 4 to 6 hours, benadryl for kids dose, benadryl children under 6, benadryl for hay fever runny nose, benadryl drowsiness driving, benadryl with alcohol, benadryl to make child sleepy, antihistamine for sneezing itchy eyes, benadryl glaucoma prostate warning, benadryl with sedatives, benadryl for cold symptoms, benadryl max per day, diphenhydramine overdose, benadryl excitability in children, benadryl with skin cream diphenhydramine"
label claritin $D/08-loratadine-10mg.md \
  "Loratadine 10 mg tablets (Drug Facts, Claritin, Bayer)" "Claritin (loratadine 10 mg)" \
  "claritin dosage, loratadine 10 mg how often, claritin once a day, claritin for kids 6 and over, non drowsy allergy medicine, claritin for hay fever, loratadine for runny nose sneezing, claritin itchy watery eyes, claritin liver kidney disease, claritin children under 6, claritin pregnancy, loratadine drowsiness if too much, claritin allergic reaction, claritin max per day, antihistamine without drowsiness"
label imodium $D/09-loperamide-2mg.md \
  "Loperamide HCl 2 mg caplets (Drug Facts, Imodium A-D, Kenvue)" "Imodium A-D (loperamide 2 mg)" \
  "imodium dosage, how much imodium can I take, loperamide 2 mg how many, imodium after each loose stool, imodium for kids dose, imodium children under 2, imodium for travelers diarrhea, loperamide max per day, imodium heart warning overdose, imodium bloody black stool, imodium with fever mucus, how long can I take imodium, diarrhea medicine dose, imodium weight dosing children, loperamide drowsiness dizziness, loperamide with prescription drugs, stop diarrhea fast, imodium dehydration fluids"
label pepto $D/10-bismuth-subsalicylate-liquid.md \
  "Bismuth subsalicylate 525 mg/30 mL oral suspension (Drug Facts, Pepto-Bismol, Procter & Gamble)" "Pepto-Bismol liquid (bismuth subsalicylate 525 mg per 30 mL)" \
  "pepto bismol dosage, how much pepto can I take, bismuth subsalicylate 525 mg dose, pepto every half hour, pepto bismol max doses per day, pepto for kids, pepto bismol children under 12, pepto reye syndrome, pepto for upset stomach nausea, pepto for diarrhea, pepto for heartburn indigestion, pepto black stool tongue, pepto aspirin allergy, pepto with blood thinner, pepto bismol ulcer bleeding, pepto bismol how many days, pepto ringing in ears, pepto for travelers diarrhea"
label pepcid-max $D/11-famotidine-20mg.md \
  "Famotidine 20 mg tablets (Drug Facts, Pepcid AC Maximum Strength, Kenvue)" "Pepcid AC Maximum Strength (famotidine 20 mg)" \
  "pepcid dosage, famotidine 20 mg how often, pepcid ac max per day, pepcid before eating to prevent heartburn, famotidine for heartburn, acid reducer dose, pepcid for kids under 12, pepcid for more than 14 days, heartburn with chest pain warning, famotidine kidney disease, pepcid with other acid reducers, famotidine prescription drug interaction, pepcid pregnancy, sour stomach acid indigestion relief, pepcid allergic reaction, heartburn trouble swallowing warning"
label dramamine-ld $D/12-meclizine-25mg.md \
  "Meclizine HCl 25 mg tablets (Drug Facts, Dramamine Less Drowsy, Medtech)" "Dramamine Less Drowsy (meclizine 25 mg)" \
  "meclizine dosage, meclizine 25 mg how many, dramamine less drowsy dose, motion sickness pill dose, meclizine for sea sickness, take motion sickness pill how long before travel, meclizine for dizziness vertigo nausea, meclizine for kids under 12, meclizine drowsiness driving, meclizine with alcohol, meclizine glaucoma prostate warning, bonine dose, meclizine once daily, car sick medicine adult, meclizine pregnancy, meclizine with sedatives"
label kroger-hc $D/13-hydrocortisone-1pct-cream.md \
  "Hydrocortisone 1% cream (Drug Facts, Kroger)" "Hydrocortisone 1% cream (Kroger)" \
  "hydrocortisone cream how often, hydrocortisone 1 percent uses, cortisone cream for poison ivy, hydrocortisone for bug bites, hydrocortisone for eczema rash, hydrocortisone for kids under 2, hydrocortisone cream diaper rash, cortisone cream 3 to 4 times daily, hydrocortisone for anal itching, hydrocortisone cream more than 7 days, hydrocortisone near eyes, itch cream for psoriasis, anti itch cream directions, hydrocortisone for genital itching, cortisone cream swallowed, hydrocortisone cream for insect bites"
label neosporin $D/14-triple-antibiotic-ointment.md \
  "Bacitracin zinc, neomycin sulfate, polymyxin B sulfate ointment (Drug Facts, Neosporin Original, Kenvue)" "Neosporin Original ointment (triple antibiotic)" \
  "neosporin directions, how often to apply neosporin, triple antibiotic ointment uses, neosporin for cuts scrapes burns, neosporin on deep puncture wound, neosporin animal bite, neosporin more than 1 week, antibiotic ointment allergic reaction rash, neosporin in eyes, neosporin over large area, bacitracin neomycin polymyxin ointment, first aid antibiotic ointment, neosporin under bandage, neosporin swallowed child, wound infection prevention ointment, how much neosporin to use"
label pvp-major $D/15-povidone-iodine-10pct.md \
  "Povidone-iodine 10% topical solution (Drug Facts, Major Pharmaceuticals)" "Povidone-iodine 10% solution (Major)" \
  "betadine directions, povidone iodine 10 percent uses, iodine for cuts scrapes burns, how to use betadine on wound, povidone iodine how often, iodine antiseptic bandage, betadine deep puncture wound, betadine animal bite, iodine allergy antiseptic, povidone iodine in eyes, betadine more than 1 week, iodine on large areas of body, betadine swallowed, first aid antiseptic solution, povidone iodine irritation redness, iodine wound cleaning"
label sudogest $D/16-pseudoephedrine-30mg.md \
  "Pseudoephedrine HCl 30 mg tablets (Drug Facts, Sudogest, Major Pharmaceuticals)" "Sudogest (pseudoephedrine 30 mg)" \
  "sudafed dosage, pseudoephedrine 30 mg how many, sudafed every 4 to 6 hours, sudafed max per day, pseudoephedrine for kids 6 to 11, sudafed children under 6, decongestant for stuffy nose, sudafed for sinus pressure, pseudoephedrine high blood pressure warning, sudafed with maoi, sudafed heart disease thyroid diabetes, pseudoephedrine nervousness sleeplessness, sudafed more than 7 days, sudafed pregnancy, nasal decongestant dose adult, sudafed prostate urination, sudafed for hay fever congestion"

cat > $D/pack.json <<JSON
{
 "id": "otc-medicines",
 "title": "Over-the-Counter Medicines: Drug Facts Labels (FDA/DailyMed)",
 "category": "medical",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. National Library of Medicine DailyMed (FDA-regulated OTC labeling)",
 "license": "Public domain — FDA drug labeling published by NLM DailyMed (U.S. Government work, 17 U.S.C. § 105)",
 "attribution": "Drug Facts panels of over-the-counter labels retrieved from DailyMed (U.S. National Library of Medicine) in October 2026, one current label per medicine; reformatted into sections without changing substance; inactive ingredients, package art and distributor lines not included. Product names are those printed on each label. Use does not imply endorsement by NLM, FDA, HHS, the U.S. Government, or any manufacturer.",
 "description": "The FDA Drug Facts label (uses, warnings, adult and child dosing tables) for 16 common over-the-counter medicines: acetaminophen and ibuprofen (adult and children's), aspirin, naproxen, diphenhydramine, loratadine, loperamide, bismuth subsalicylate, famotidine, meclizine, hydrocortisone cream, triple-antibiotic ointment, povidone-iodine and pseudoephedrine."
}
JSON

# =========================================================================
# 03-herbal-remedies (verified)
# =========================================================================
D=content/03-herbal-remedies; mkdir -p $D; rm -f $D/*.md; N=1
herb aloe-vera "Aloe Vera" "aloe vera for burns, aloe for sunburn, aloe vera gel on skin, aloe vera juice safe to drink, aloe latex laxative, aloe vera side effects, is aloe safe, aloe vera for wounds, aloe for constipation, aloe vera diabetes blood sugar, aloe vera plant uses, aloe for psoriasis, aloe vera pregnancy"
herb chamomile "Chamomile" "chamomile tea for sleep, chamomile for anxiety, chamomile for upset stomach, chamomile side effects, chamomile allergy ragweed, chamomile for babies colic, chamomile with blood thinners warfarin, is chamomile safe, chamomile for skin, chamomile mouth sores, chamomile pregnancy"
herb cranberry "Cranberry" "cranberry for uti, cranberry juice bladder infection, cranberry prevent urinary tract infection, cranberry side effects, cranberry with warfarin, cranberry supplement safe, does cranberry cure uti, cranberry for children uti, cranberry stomach upset"
herb echinacea "Echinacea" "echinacea for colds, does echinacea work, echinacea to prevent a cold, echinacea side effects, echinacea allergy, echinacea for kids, is echinacea safe, echinacea immune system, echinacea for flu, echinacea rash children, echinacea pregnancy"
herb elderberry "Elderberry" "elderberry for colds flu, elderberry syrup, does elderberry work, elderberry for covid, raw elderberry poisonous, elderberry side effects nausea, uncooked elderberries toxic, elderberry safe for kids, elderberry immune, elderberry bark leaves unripe berries, elderberry pregnancy"
herb ephedra "Ephedra (Ma Huang)" "ephedra ma huang dangers, ephedra banned, ephedra weight loss, ephedra side effects heart, ephedra for asthma colds, ephedra stroke seizure death, ma huang tea, ephedrine supplement risk, ephedra energy pills, is ephedra safe"
herb garlic "Garlic" "garlic for cholesterol, garlic for blood pressure, garlic supplement side effects, garlic with blood thinners, garlic before surgery bleeding, is garlic safe, garlic for colds, raw garlic on skin burn, garlic breath odor, garlic pregnancy, garlic for heart disease"
herb ginger "Ginger" "ginger for nausea, ginger for morning sickness, ginger for motion sickness, ginger for upset stomach, ginger safe in pregnancy, ginger side effects heartburn, ginger for menstrual cramps, ginger for arthritis, ginger tea nausea vomiting, ginger with medicines, ginger root remedy, ginger for chemo nausea"
herb asian-ginseng "Asian Ginseng" "ginseng benefits, ginseng for energy, ginseng side effects, is ginseng safe, ginseng diabetes blood sugar, panax ginseng, korean ginseng, ginseng for colds flu, ginseng insomnia headache, ginseng pregnancy, ginseng with medications"
herb goldenseal "Goldenseal" "goldenseal for colds, goldenseal for infection, goldenseal berberine, goldenseal side effects, is goldenseal safe, goldenseal drug interactions, goldenseal pregnancy breastfeeding, goldenseal newborn jaundice, goldenseal echinacea, goldenseal for diarrhea, goldenseal for eye infection"
herb green-tea "Green Tea" "green tea health benefits, green tea for weight loss, green tea extract liver damage, green tea caffeine, green tea side effects, green tea safe pregnancy, green tea for cancer, green tea cholesterol, green tea supplement danger, how much green tea is safe, green tea with medicines"
herb kava "Kava" "kava liver damage, is kava safe, kava for anxiety, kava side effects, kava with alcohol, kava drink dangers, kava for sleep, kava hepatitis liver failure, kava driving drowsy, kava root tea"
herb lavender "Lavender" "lavender for anxiety, lavender for sleep, lavender oil uses, lavender essential oil safe, lavender oil on skin, lavender aromatherapy, lavender oil swallowed poisonous, lavender side effects, lavender breast growth boys, lavender tea, lavender pregnancy"
herb licorice-root "Licorice Root" "licorice root benefits, licorice for cough sore throat, licorice for stomach ulcers, licorice root side effects, licorice high blood pressure, too much licorice dangerous, licorice irregular heartbeat, licorice pregnancy, licorice with corticosteroids, licorice heart kidney conditions, glycyrrhizin safety, deglycyrrhizinated licorice"
herb milk-thistle "Milk Thistle" "milk thistle for liver, milk thistle hepatitis, milk thistle side effects, is milk thistle safe, milk thistle diabetes, silymarin, milk thistle allergy ragweed, milk thistle with medications, milk thistle for cirrhosis, milk thistle pregnancy"
herb peppermint-oil "Peppermint Oil" "peppermint oil for ibs, peppermint for upset stomach, peppermint oil for headache, peppermint tea for nausea, peppermint oil capsules, peppermint oil side effects heartburn, peppermint oil on skin, peppermint oil for babies dangerous, is peppermint oil safe, peppermint for indigestion, menthol on face infants"
herb st-johns-wort "St. John's Wort" "st johns wort for depression, st johns wort side effects, st johns wort drug interactions, st johns wort birth control, st johns wort sun sensitivity, st johns wort with antidepressants, st johns wort serotonin syndrome, is st johns wort safe, st johns wort for anxiety, st johns wort hiv transplant drugs, hypericum"
herb tea-tree-oil "Tea Tree Oil" "tea tree oil for acne, tea tree oil for athletes foot, tea tree oil for nail fungus, tea tree oil for lice, tea tree oil antiseptic, tea tree oil swallowed poisonous, tea tree oil on skin rash, is tea tree oil safe, tea tree oil for wounds, tea tree oil side effects, tea tree oil boys breast growth, melaleuca oil"
herb turmeric "Turmeric" "turmeric for arthritis, turmeric for inflammation, curcumin benefits, turmeric side effects, is turmeric safe, turmeric liver damage, turmeric pregnancy, turmeric for pain, turmeric supplement dose, curcumin absorption piperine, turmeric for stomach, turmeric with medications"
herb valerian "Valerian" "valerian for sleep, valerian for anxiety, valerian root side effects, is valerian safe, valerian with alcohol, valerian drowsiness, does valerian work for insomnia, valerian long term use, valerian for kids, valerian headache stomach upset, natural sleep aid herb, valerian pregnancy"
herb yohimbe "Yohimbe" "yohimbe dangers, yohimbe side effects, yohimbe for erectile dysfunction, yohimbe heart attack seizure, yohimbine supplement risks, is yohimbe safe, yohimbe high blood pressure, yohimbe weight loss bodybuilding, yohimbe with antidepressants, yohimbe poison control"
herb feverfew "Feverfew" "feverfew for migraines, feverfew to prevent headaches, feverfew side effects, is feverfew safe, feverfew mouth sores, feverfew pregnancy, feverfew with blood thinners, feverfew for arthritis, feverfew ragweed allergy, feverfew tea"
herb sage "Sage" "sage for sore throat, sage tea, sage for memory, sage for hot flashes, sage side effects, is sage safe, sage thujone seizures, sage essential oil toxic, sage for mouth throat, sage pregnancy, sage blood sugar, sage for cholesterol"
herb dandelion "Dandelion" "dandelion benefits, dandelion tea, dandelion for liver, dandelion water pill interaction, dandelion side effects, dandelion safe to eat, dandelion allergy ragweed, dandelion greens root, dandelion with medications, dandelion for digestion, dandelion eczema reaction"
herb cinnamon "Cinnamon" "cinnamon for diabetes, cinnamon blood sugar, cinnamon side effects, cassia cinnamon coumarin liver, how much cinnamon is safe, cinnamon supplement, cinnamon pregnancy, cinnamon for cholesterol, cinnamon allergy mouth sores, ceylon vs cassia cinnamon, cinnamon with medications"
herb ginkgo "Ginkgo" "ginkgo for memory, ginkgo biloba dementia, ginkgo side effects, ginkgo bleeding risk, ginkgo with blood thinners, ginkgo before surgery, ginkgo seeds poisonous, ginkgo for tinnitus, is ginkgo safe, ginkgo headache dizziness, ginkgo for circulation, ginkgo pregnancy"
herb hawthorn "Hawthorn" "hawthorn for heart failure, hawthorn for blood pressure, hawthorn berry benefits, hawthorn side effects, is hawthorn safe, hawthorn with heart medications, tejocote root yellow oleander warning, hawthorn dizziness nausea, hawthorn for chest pain, hawthorn tea, hawthorn pregnancy"
herb passionflower "Passionflower" "passionflower for anxiety, passionflower for sleep, passionflower tea, passionflower side effects, is passionflower safe, passionflower drowsiness, passionflower pregnancy, passionflower with sedatives, passionflower for stress, natural calming herb"
herb butterbur "Butterbur" "butterbur for migraines, butterbur for hay fever, butterbur liver damage, butterbur pyrrolizidine alkaloids, butterbur side effects, is butterbur safe, pa free butterbur, butterbur for allergies, butterbur pregnancy, butterbur burping"
herb bitter-orange "Bitter Orange" "bitter orange weight loss, bitter orange synephrine, bitter orange side effects, bitter orange heart risk, is bitter orange safe, bitter orange with caffeine, bitter orange supplement dangers, bitter orange for heartburn nausea, bitter orange skin fungal infection, bitter orange high blood pressure, bitter orange pregnancy"

cat > $D/pack.json <<JSON
{
 "id": "herbal-remedies",
 "title": "Herbs and Natural Remedies: What the Science Says (NIH NCCIH)",
 "category": "medical",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. National Institutes of Health, National Center for Complementary and Integrative Health (NCCIH)",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105); each page states \"This publication is not copyrighted and is in the public domain.\"",
 "attribution": "Text from NIH National Center for Complementary and Integrative Health (NCCIH) \"Herbs at a Glance\" web pages, retrieved October 2026; reformatted into sections without changing substance; images, photo credits and the \"For More Information\" footers not included. Use does not imply endorsement by NCCIH, NIH, HHS, or the U.S. Government.",
 "description": "What research shows, and what is known about safety, for 30 herbs and plant products people reach for when there is no pharmacy: aloe, chamomile, cranberry, echinacea, elderberry, garlic, ginger, ginseng, goldenseal, green tea, lavender, licorice, milk thistle, peppermint oil, St. John's wort, tea tree oil, turmeric, valerian and others, plus warnings on ephedra, kava, yohimbe, butterbur and bitter orange."
}
JSON
echo "done: content/02c-otc-medicines content/03-herbal-remedies"
