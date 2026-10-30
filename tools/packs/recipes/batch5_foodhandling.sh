#!/usr/bin/env bash
# Batch 5 (food handling): one new pack.
#   content/08c-food-handling (id food-handling) — USDA Food Safety and
#   Inspection Service (FSIS) consumer fact sheets: safe minimum internal
#   temperatures, the Danger Zone, leftovers, cleanliness, washing food,
#   freezing, jerky, smoking, shelf-stable food, molds, hiking/camping/
#   boating, food in an emergency, shell eggs, egg products.
#
# Usage: tools/packs/recipes/batch5_foodhandling.sh <dir-with-saved-pages>
#   then: python3 tools/packs/build_pack.py content/08c-food-handling
#
# HOW THE PAGES WERE OBTAINED. fsis.usda.gov answers HTTP 403 to scripts
# (curl -A "Mozilla/5.0"; also foodsafety.gov, usda.gov; no workaround
# attempted). As for batch 3/4 CDC pages, each page was opened in the
# in-app browser on 2026-10-30 and the article (the page's h1 plus every
# <section>/<div> of .l-sidebar__main except the "Featured Factsheets"
# cards, scripts, styles and images, with all attributes but href/colspan/
# rowspan removed and whitespace runs collapsed) was serialised in-page by
# extract.js below, SHA-256 hashed in the browser, transferred, and saved
# as <dir>/<name>.html. verify() below checks the saved files against the
# in-browser hashes before anything is built. Text is never changed.
#
# LICENSE: every page is a U.S. Government work (17 U.S.C. § 105): FSIS is
# an agency of USDA. Every saved page was scanned for "©", "copyright",
# "courtesy", "permission", "reprinted", "adapted from": no hits. The jerky
# page summarises two Journal of Food Protection studies in FSIS's own
# words (two short quotations) — kept. The shell-egg page's "History of the
# Egg" section is a long quotation from Harold McGee's copyrighted book
# "On Food and Cooking" — EXCLUDED. Images (none used) and the
# "Featured Factsheets" cards are not part of the text.
#
# SOURCES (fsis.usda.gov/food-safety/safe-food-handling-and-preparation/…,
# "Last Updated" date as printed on the page, SHA-256 of the saved file):
#   temp-chart        food-safety-basics/safe-temperature-chart            Apr 14, 2025
#   danger-zone       food-safety-basics/danger-zone-40f-140f              Jun 28, 2023
#   leftovers         food-safety-basics/leftovers-and-food-safety         Jul 31, 2020
#   cleanliness       food-safety-basics/cleanliness-helps-prevent         Mar 11, 2025
#   washing           food-safety-basics/washing-food-does-it-promote-food Feb 07, 2024
#   freezing          food-safety-basics/freezing-and-food-safety          Aug 09, 2024
#   jerky             meat-fish/jerky                                      Nov 03, 2016
#   smoking           food-safety-basics/smoking-meat-and-poultry          Aug 13, 2024
#   shelf-stable      food-safety-basics/shelf-stable-food                 Oct 24, 2024
#   molds             food-safety-basics/molds-food-are-they-dangerous     Aug 22, 2013
#   hiking            food-safety-basics/food-safety-while-hiking-camping  Jun 04, 2024
#   emergency         food-safety-basics/keeping-food-safe-during          Jul 30, 2013
#   shell-eggs        eggs/shell-eggs-farm-table                           Nov 20, 2024
#   egg-products      eggs/egg-products-and-food-safety                    Nov 15, 2023
#
# EXCLUDED (and why):
#   - Hunting / wild game / field dressing: FSIS has no such page any more
#     ("Game from Farm to Table" is gone; site search and URL guesses give
#     Page Not Found). The jerky page's "wild game jerky" section and the
#     freezer chart's "Wild game, uncooked — 8 to 12" row are the only
#     game-specific FSIS text.
#   - Home drying of fruits and vegetables: no current USDA-owned source
#     exists (USDA defers to the University of Georgia's NCHFP, which is
#     not used). The only USDA text found is Farmers' Bulletin "Drying
#     fruits and vegetables in the home: with recipes for cooking" (1917,
#     NAL scan archive.org/details/CAT87202742) — pre-1929, public domain,
#     but would be "historical", so it cannot join this verified pack.
#   - "Keep Your Food Safe During Emergencies: Power Outages, Floods &
#     Fires" (emergencies/keep-your-food-safe-during-emergencies, 2013,
#     saved as emergencies-keep.html) — same content as "Keeping Food Safe
#     During an Emergency" in bullet form; redundant.
#   - "The Big Thaw — Safe Defrosting Methods" (2013, saved as
#     big-thaw.html) — not assigned; the Freezing page covers thawing.
#   - "Water in Meat & Poultry" — labelling topic, not useful off-grid.
#   - Shell Eggs sections: History of the Egg (McGee quotation), Who Is
#     Working on Eliminating Salmonella, What Government Agencies Are
#     Responsible, What Is Candling, Is Grading Mandatory, Are Fertilized
#     Eggs More Nutritious (+ "Per Capita Consumption"), U.S. Egg
#     Consumption; Egg Products sections: Who Inspects, Why Useful,
#     Nutrition, Labels — regulatory/industry text, not handling guidance.
#   - ask.usda.gov (USDA knowledge base): its TLS certificate has expired
#     (openssl: "certificate has expired"); not used.
#
# Pre-processing (prep.py, structure only): tables become one line per row
# ("cell — cell", or "cell — Header: cell; Header: cell" for 3 columns,
# header row kept as the first line, caption as a heading); <br> runs
# inside a paragraph become paragraph breaks (otherwise "Cooking<br>Raw
# meat" is glued into "Cooking Raw meat"); in-page "Top of Page" links and
# #_anchor contents lists are removed; the source's own mojibake in the
# emergency freezer table ("40 ¬∞F", "Casseroles‚Äîpasta") is decoded to
# "40 °F", "Casseroles—pasta". Post-processing (post.py) only cuts whole
# sections listed above, renames a merged heading, deletes a heading
# repeated as its own first body line (shell eggs), splits the two long
# save/throw-out tables into sections by their own ALL-CAPS food groups,
# and inserts the Aliases line. Every table line was checked by eye
# against the page.
set -euo pipefail
SRC="${1:?usage: $0 <dir-with-saved-pages>}"
XH="tools/.venv/bin/python tools/packs/extract_html.py"
V=2026.10.30.1
BASE=https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation
D=content/08c-food-handling

# name=path=sha256 of the saved page
PAGES="
temp-chart=food-safety-basics/safe-temperature-chart=a056bb8568e69c91533443d492ad69baa6050e5401bb64d28d264db154eea58a
danger-zone=food-safety-basics/danger-zone-40f-140f=b504bf6c8fcac77f6cf6074d586299504f5d649ba23c5fd910f3ca8cfdb3f7f4
leftovers=food-safety-basics/leftovers-and-food-safety=a5c29ac4e6df2abf7d9aa2fa200c3ce95861bab7193053eb9d3cbd2a758e29ab
cleanliness=food-safety-basics/cleanliness-helps-prevent=2be63902fbdefb588383ac2c8ec805d762571fabebc942c40dfdd71beb73b575
washing=food-safety-basics/washing-food-does-it-promote-food=50faa241880a460ad5789858bf843afed4f5f9eac83ec2303ed8f61a9d2e6968
freezing=food-safety-basics/freezing-and-food-safety=5d67ef603c93e0462675147f3df6d632ab0f2b76ce76f43b4b163945227dc225
jerky=meat-fish/jerky=d313e99dfc4ead54e955055a0d99acb1aa7adb5983c38d07e2bd3459d60b3584
smoking=food-safety-basics/smoking-meat-and-poultry=521446268fece7f005810002931b1f348e008e39fa7dbaf7ccdbc7b7823eba05
shelf-stable=food-safety-basics/shelf-stable-food=ed45dc37778ed7af5b974d0c9dbc1c886cdb3965a44f5852f175be02d70c1952
molds=food-safety-basics/molds-food-are-they-dangerous=0c29451cb95d8b93273d4ae08ec29fcbc974d985f1aef4b132db64f5957dc9af
hiking=food-safety-basics/food-safety-while-hiking-camping=fcd740ee96ed3d2ddcb99a45038409702a23d1b22b7b6593f824b6b0ea30db2b
emergency=food-safety-basics/keeping-food-safe-during=a21ad7659f691cb1caf95fc4bcf953f69c4bb11873698638bdc75e0c751894ea
shell-eggs=eggs/shell-eggs-farm-table=6c0553f31af203e00aae66f18028792d80593d1cb5e8de23afb52c6d16d3e7d2
egg-products=eggs/egg-products-and-food-safety=f5ddec14b0511c85eaf9317a3decdba0c9bd737ad19558baaf59dda71667253f"
field() { printf '%s\n' $PAGES | grep "^$1=" | cut -d= -f$2; }

verify() {
  for kv in $PAGES; do
    n=${kv%%=*}; want=${kv##*=}
    got=$(shasum -a 256 "$SRC/$n.html" | cut -d' ' -f1)
    [[ "$got" == "$want" ]] || { echo "hash mismatch: $n.html"; exit 1; }
  done
}
verify

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# extract.js — run in the browser on each page (audit record; not executed here).
cat > "$TMP/extract.js" <<'JS'
(async()=>{const m=document.querySelector('.l-sidebar__main')||document.querySelector('main');const h1=m.querySelector('h1');const secs=[...m.querySelectorAll(':scope > section, :scope > div')].filter(s=>!s.classList.contains('section-cards')&&!s.classList.contains('introduction')&&!s.classList.contains('modified'));const clean=(el)=>{const c=el.cloneNode(true);c.querySelectorAll('script,style,img,picture,svg,iframe,noscript').forEach(x=>x.remove());c.querySelectorAll('button').forEach(b=>b.replaceWith(document.createTextNode(b.textContent.trim())));c.querySelectorAll('*').forEach(x=>{for(const a of [...x.attributes]) if(!['href','colspan','rowspan'].includes(a.name)) x.removeAttribute(a.name);});const w=document.createTreeWalker(c,NodeFilter.SHOW_TEXT);const ts=[];while(w.nextNode())ts.push(w.currentNode);for(const t of ts){t.nodeValue=t.nodeValue.replace(/\s+/g,' ');}for(let i=0;i<3;i++)c.querySelectorAll('div,figcaption,figure,span,p').forEach(x=>{if(!x.textContent.trim()&&!x.querySelector('table'))x.remove();});return c.outerHTML.replace(/>\s+</g,'><').replace(/<\/(p|li|h[1-6]|tr|table|ul|ol|div|section)>/g,'</$1>\n');};const mod=m.querySelector('.modified');const html='<html><head><title>'+document.title+'</title><link rel="canonical" href="'+location.href+'"></head><body><main>\n<h1>'+(h1?h1.textContent.trim():'')+'</h1>\n'+secs.map(clean).join('\n')+'\n<p>'+(mod?mod.textContent.trim():'')+'</p>\n</main></body></html>\n';const buf=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(html));const hex=[...new Uint8Array(buf)].map(b=>b.toString(16).padStart(2,'0')).join('');return 'SHA256 '+hex+' LEN '+html.length+'\n'+html;})()
JS

cat > "$TMP/prep.py" <<'PY'
import re, sys, html as H
src, out = sys.argv[1:3]
s = open(src, encoding="utf-8").read()
s = s.replace("¬∞", "°").replace("‚Äî", "—")          # source mojibake (emergency page)
def cell_text(c):
    return H.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", c))).strip()
def render_table(m):
    cap = re.search(r"<caption>(.*?)</caption>", m.group(0), re.S)
    rows = re.findall(r"<tr>(.*?)</tr>", m.group(0), re.S)
    out, header = [], None
    for r in rows:
        cells = [cell_text(c) for c in re.findall(r"<t[hd][^>]*>(.*?)</t[hd]>", r, re.S)]
        if not any(cells):
            continue
        if header is None:
            header = cells
            out.append(" — ".join(cells) if len(cells) > 1 else cells[0])
        elif len(cells) == 1:
            out.append(cells[0])
        elif len(cells) == 2:
            out.append(f"{cells[0]} — {cells[1]}")
        else:
            parts = [f"{header[i] if i < len(header) else ''}: {cells[i]}".strip(": ") for i in range(1, len(cells))]
            out.append(f"{cells[0]} — " + "; ".join(parts))
    body = "".join(f"<p>{H.escape(l, quote=False)}</p>\n" for l in out)
    return (f"<h3>{cap.group(1).strip()}</h3>\n" if cap else "") + body
s = re.sub(r"<table>.*?</table>", render_table, s, flags=re.S)
s = re.sub(r"<p><a href=\"#_Top\">Top of Page</a></p>\n?", "", s)
s = re.sub(r"<br>\s*<a href=\"#_Top\">Top of Page</a>(<br>)?", "", s)
s = re.sub(r"<ul>(?:<li>(?:<a></a>)?<a href=\"#_[^\"]*\">[^<]*</a></li>\n?)+</ul>\n?", "", s)
s = re.sub(r"<p>(.*?)</p>", lambda m: "<p>" + re.sub(r"(?:\s*<br>\s*)+", "</p>\n<p>", m.group(1)) + "</p>", s, flags=re.S)
s = re.sub(r"<p>\s*</p>\n?", "", s)
open(out, "w", encoding="utf-8").write(s)
PY

# post FILE [ops...]
#   aliases=TEXT        insert "Aliases: TEXT" after the Source line
#   cutsec=REGEX        delete "## " sections whose heading matches REGEX
#   rename=OLD=>NEW     rename the "## OLD" heading to "## NEW"
#   echo                delete a body line identical to its section heading
#   headbefore=LINE=>H  insert "## H" before the body line LINE
#   chunk=REGEX         split sections whose heading matches REGEX into
#                       sections of <= 3500 chars at the table's own
#                       ALL-CAPS food-group rows; each part repeats the
#                       table header line and names its groups
cat > "$TMP/post.py" <<'PY'
import re, sys
path, ops = sys.argv[1], sys.argv[2:]
text = open(path, encoding="utf-8").read()
CAT = re.compile(r"^([A-Z][A-Z ,/]+?[A-Z])(?= [A-Z][a-z]| — |$)")
def sections(t):
    head, *rest = re.split(r"\n(?=## )", t)
    return head, rest
for op in ops:
    kind, _, arg = op.partition("=")
    if kind == "aliases":
        text = re.sub(r"^(Source: .*\n)", r"\1Aliases: " + arg.replace("\\", r"\\") + "\n", text, count=1, flags=re.M)
    elif kind == "cutsec":
        r = re.compile(arg); head, rest = sections(text)
        text = "\n".join([head] + [s for s in rest if not r.search(s.split("\n", 1)[0][3:])])
    elif kind == "rename":
        old, new = arg.split("=>")
        assert f"\n## {old}\n" in text, old
        text = text.replace(f"\n## {old}\n", f"\n## {new}\n")
    elif kind == "echo":
        text = re.sub(r"^(## (.+))\n\2\n", r"\1\n", text, flags=re.M)
    elif kind == "headbefore":
        line, h = arg.split("=>")
        assert f"\n{line}\n" in text, line
        text = text.replace(f"\n{line}\n", f"\n## {h}\n{line}\n", 1)
    elif kind == "chunk":
        r = re.compile(arg); head, rest = sections(text); out = [head]
        for s in rest:
            h, body = s.split("\n", 1)
            if not r.search(h[3:]):
                out.append(s); continue
            lines = [l for l in body.split("\n") if l.strip()]
            header, rows = lines[0], lines[1:]
            groups, cur, name = [], [], None
            for l in rows:
                m = CAT.match(l)
                if m and cur:
                    groups.append((name, cur)); cur = []
                if m: name = m.group(1)
                cur.append(l)
            groups.append((name, cur))
            parts, part, names = [], [], []
            for name, g in groups:
                add = "\n\n".join(g)
                if part and len("\n\n".join(part)) + len(add) > 3500:
                    parts.append((names, part)); part, names = [], []
                part.append(add); names.append(name)
            parts.append((names, part))
            for names, part in parts:
                out.append(f"{h}: {'; '.join(n for n in names if n)}\n{header}\n\n" + "\n\n".join(part) + "\n")
        text = "\n".join(out)
    else:
        sys.exit(f"unknown op {op}")
open(path, "w", encoding="utf-8").write(re.sub(r"\n{3,}", "\n\n", text).rstrip() + "\n")
PY

doc() {  # doc <name> <NN-file> <title> <aliases> [post ops...]
  local n=$1 f=$2 t=$3 a=$4; shift 4
  python3 "$TMP/prep.py" "$SRC/$n.html" "$TMP/$n.html"
  $XH "$TMP/$n.html" --source-url "$BASE/$(field $n 2)" --title "$t" -o "$D/$f"
  python3 "$TMP/post.py" "$D/$f" "aliases=$a" "$@"
}

mkdir -p $D; rm -f $D/*.md

doc temp-chart 01-safe-temperature-chart.md "Safe Minimum Internal Temperature Chart (USDA FSIS, 2025)" \
  "meat temperature chart, safe minimum internal temperature, what temperature to cook chicken, what temperature to cook pork, ground beef safe temperature, reheat leftovers to what temperature, fish cooking temperature, egg dish cooking temperature, ham reheating temperature, steak safe temperature and rest time, casserole internal temperature, food thermometer target temperatures, how hot does meat need to be" \
  "rename=Overview=>Safe minimum internal temperatures by food"

doc danger-zone 02-danger-zone.md "Danger Zone (40°F - 140°F) (USDA FSIS, 2023)" \
  "danger zone 40 to 140, how long can food sit out, bacteria growth temperature range, keep hot food hot, keep cold food cold, food left out overnight, two hour rule for food, one hour rule above 90 degrees, reheating temperature 165, cooling leftovers shallow containers, minimum oven temperature for roasting, food left out at a party" \
  "rename=Overview=>Keep food out of the Danger Zone"

doc leftovers 03-leftovers.md "Leftovers and Food Safety (USDA FSIS, 2020)" \
  "leftovers and food safety, how long are leftovers good, how long can leftovers sit out, cooling leftovers quickly, reheating leftovers temperature, refreezing leftovers, thawing frozen leftovers, how many days leftovers in fridge, leftovers danger zone, reheating in microwave safely, freezing leftovers how long, wrapping leftovers, reheat frozen leftovers without thawing, buffet food safety" \
  "rename=Overview=>Handling leftovers safely"

doc cleanliness 04-cleanliness.md "Cleanliness Helps Prevent Foodborne Illness (USDA FSIS, 2025)" \
  "cleanliness prevents foodborne illness, wash hands before cooking, clean separate cook chill, sanitize cutting board with bleach, bleach solution for cutting boards, wash dishcloths kitchen bacteria, raw meat cross contamination, clean food thermometer probe, kitchen hygiene steps, gloves for cut on hand cooking, picnic clean utensils, wash hands 20 seconds, same plate for raw and cooked meat" \
  "rename=Overview=>Four steps to prevent foodborne illness"

doc washing 05-washing-food.md "Washing Food: Does It Promote Food Safety? (USDA FSIS, 2024)" \
  "washing food does it promote safety, should I wash raw chicken, washing meat before cooking, washing produce before eating, washing eggs at home, soaking meat in salt water, cross contamination raw meat, how to sanitize kitchen surfaces, homemade disinfectant bleach solution, sanitizing solution for utensils, clean then sanitize, handwashing steps 20 seconds, pre washed salad wash again, produce wash with soap, reusable grocery bags washing, bleach per gallon sanitizer, bleach per gallon disinfectant, how long germs live on counters"

doc freezing 06-freezing.md "Freezing and Food Safety (USDA FSIS, 2024)" \
  "is my frozen meat still good, freezing and food safety, how long can meat stay frozen, freezer burn safe to eat, refreezing thawed meat, safe ways to thaw food, freezer power outage food safe, frozen cans swollen, can you freeze eggs, freezer storage chart months, does freezing kill bacteria, does freezing kill parasites trichina, blanching vegetables before freezing, freezer temperature zero degrees, food thawed in power outage, cooking frozen meat without thawing, how long to freeze wild game, frozen food safe indefinitely, meat turned brown in freezer, how long a full freezer stays cold" \
  "rename=Overview=>Foods in the freezer: are they safe?" \
  "rename=Frozen Eggs: Freezer Storage Chart (0 °F)=>Freezer Storage Chart (0 °F)"

doc jerky 07-jerky.md "Jerky and Food Safety (USDA FSIS, 2016)" \
  "how to make jerky, jerky food safety, safe jerky temperature, cook meat before dehydrating, dehydrator temperature for jerky, venison jerky safety, wild game jerky, how long does jerky last, drying meat to preserve it, is sun drying meat safe, ground beef jerky safety, marinating jerky meat, homemade jerky storage time, dehydrating meat at home, making pemmican dried meat, oven jerky temperature, why precook meat for jerky, bacteria survive drying" \
  "rename=Overview=>Drying meat at home to make jerky"

doc smoking 08-smoking.md "Smoking Meat and Poultry (USDA FSIS, 2024)" \
  "smoking meat and poultry, how to smoke meat safely, smoking meat without a smoker, smoke meat in a covered grill, smoker temperature range, how long to smoke meat, thaw meat before smoking, marinade safety smoking, wood chips for smoking, smoked meat internal temperature, galvanized can smoker danger, how long does smoked meat keep, partially cooking before smoking, drip pan of water smoking, two thermometers for smoking" \
  "rename=Overview=>What smoking is"

doc shelf-stable 09-shelf-stable-food.md "Shelf-Stable Food Safety (USDA FSIS, 2024)" \
  "shelf stable food safety, how long do canned foods last, dented can safe to eat, rusted cans safe, bulging can botulism, can hisses when opened, frozen canned food safe, botulism symptoms from canned food, home canned food boil before eating, how long does jerky keep, dry cured ham shelf stable, dry sausage no refrigeration, dried egg mix storage, freeze dried food shelf life, MRE shelf life by temperature, retort pouch food, aseptic drink boxes safe, can codes and expiration dates, storing canned goods temperature, shelf stable storage chart, canned food past the date, how canning preserves food, salt curing food preservation"

doc molds 10-molds.md "Molds on Food: Are They Dangerous? (USDA FSIS, 2013)" \
  "molds on food are they dangerous, can I cut mold off cheese, moldy bread safe to eat, mold on jam or jelly, mold on country ham, mycotoxins and aflatoxin, mold in refrigerator cleaning, how to handle moldy food, mold on fruits and vegetables, moldy leftovers, is mold poisonous, which moldy foods to throw out, white mold on salami, prevent mold on food, moldy peanut butter or nuts, mold on hard cheese cut off inch" \
  "rename=Overview=>Is it safe to cut off the moldy part?" \
  "headbefore=FOOD — HANDLING — REASON=>Moldy food: use or discard, by food (FOOD — HANDLING — REASON)"

doc hiking 11-hiking-camping-boating.md "Food Safety While Hiking, Camping and Boating (USDA FSIS, 2024)" \
  "food safety while hiking camping boating, keeping food cold while camping, cooler ice safety, what food to bring backpacking, camping food without refrigeration, cooking meat over campfire safely, food thermometer camping, leftovers in cooler safe, drinking water while hiking, shelf stable foods for backpacking, danger zone two hours outdoors, hand washing without running water, keeping food safe on a boat, packing a cooler with raw meat, block ice versus cubes, frozen sandwiches for a day trip, hamburger safe temperature outdoors"

doc emergency 12-food-safety-emergency.md "Keeping Food Safe During an Emergency (USDA FSIS, 2013)" \
  "keeping food safe during an emergency, power outage food safety, how long does food last without power, refrigerator without power four hours, full freezer 48 hours, dry ice in freezer, put food in snow during outage, flooded food what to throw out, salvaging canned food after flood, cleaning dishes after a flood, disinfect water with bleach drops, boil water after flood, food after a house fire, refreeze thawed food safe, when to throw out refrigerator food, which foods are safe without refrigeration, emergency food supply planning, appliance thermometer freezer, what to keep and what to toss, mayonnaise after power outage" \
  "rename=Overview=>Food safety when the power is out, in a flood or after a fire" \
  "rename=Q. Flood waters covered our food stored on shelves and in cabinets. What can I keep and what should I throw out?: Steps to Salvage All-Metal Cans and Retort Pouches=>Steps to Salvage All-Metal Cans and Retort Pouches after a flood" \
  "chunk=^When to Save and When to Throw It Out: "

doc shell-eggs 13-shell-eggs.md "Shell Eggs from Farm to Table (USDA FSIS, 2024)" \
  "shell eggs food safety, how long do eggs last in fridge, eggs left out overnight, are cracked eggs safe, do eggs need to be refrigerated, washing eggs from backyard chickens, egg float test meaning, raw eggs salmonella risk, how to cook eggs safely, egg storage chart, can you freeze eggs, hard boiled eggs how long, pickled eggs how long, egg carton dates meaning, egg grades and sizes, blood spot in egg safe, green ring on egg yolk, homemade eggnog raw eggs, pasteurized eggs raw recipes, easter eggs safe to eat, spoiled egg smell" \
  echo \
  "cutsec=^What Is the History of the Egg|^Who Is Working on Eliminating|^What Government Agencies|^What Is Candling|^Is Grading of Eggs Mandatory|^Are Fertilized Eggs More Nutritious|^U\.S\. Egg Consumption" \
  "rename=Overview=>Eggs are perishable, like raw meat"

doc egg-products 14-egg-products.md "Egg Products and Food Safety (USDA FSIS, 2023)" \
  "egg products and food safety, powdered eggs storage, dried egg mix how to use, reconstitute dried egg mix, liquid egg products storage, frozen egg products thawing, pasteurized egg products in raw recipes, dried egg whites shelf life, USDA dried egg mix, egg substitute storage, how long do liquid eggs keep, egg products for people at risk" \
  "cutsec=^Who Inspects Egg Products|^Why Are Egg Products Useful|^Nutrition of Egg Products|^Labels on Egg Products" \
  "rename=Overview=>What egg products are used for"

cat > $D/pack.json <<JSON
{
 "id": "food-handling",
 "title": "Drying, Smoking, Freezing and Wild Game (USDA Food Safety)",
 "category": "guide",
 "version": "$V",
 "review": "verified",
 "publisher": "U.S. Department of Agriculture, Food Safety and Inspection Service",
 "license": "Public domain — U.S. Government work (17 U.S.C. § 105)",
 "attribution": "Text from USDA Food Safety and Inspection Service (FSIS) consumer fact sheets at fsis.usda.gov, retrieved October 2026; reformatted into sections without changing substance; tables rendered one line per row; images, in-page links and regulatory/agency sections not included. Use does not imply endorsement by USDA, FSIS, or the U.S. Government.",
 "description": "USDA food-safety fact sheets: safe cooking temperatures, the Danger Zone and leftovers, cleaning and sanitizing, washing food, freezing and thawing, making jerky, smoking meat, canned and shelf-stable food, moldy food, food on the trail and on the water, keeping food safe in a power outage, flood or fire, and handling eggs and egg products."
}
JSON
echo "done: $D"
