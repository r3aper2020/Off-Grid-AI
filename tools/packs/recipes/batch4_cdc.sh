#!/usr/bin/env bash
# CDC pages, batch 4 (cdc.gov blocks automated downloads; no workaround
# attempted). Each page was opened in the in-app browser, its <main> text
# (h1–h4, p, li; text after "This page was last updated" dropped) extracted
# in-page, transferred, and verified by matching SHA-256 hashes before use.
#   seizures.txt        99b5ae18d8fb46b5b0e4970d45bdcca592899548f8e49f6d2191418bea32750c
#     https://www.cdc.gov/epilepsy/first-aid-for-seizures/index.html
#   caring-sick.txt     cce02605b2f18841c47310d43e4afe1094e2a4782ed64215e0047a9faa96f425
#     https://www.cdc.gov/flu/takingcare/caring-for-someone.html
#   hygiene.txt         00a2ed1865be58d862f7c330010db4b7528ad4e45a8a69130e7e64ad5d4f981b
#     https://www.cdc.gov/water-emergency/safety/guidelines-for-personal-hygiene-during-an-emergency.html
#   after-disaster.txt  e76768325623c8b861fd73fd68f247e3687239eade362191efe9d9234b49a3f1
#     https://www.cdc.gov/natural-disasters/response/index.html
# Post-processing removes only chrome: a footnote marker ("lifetime.1"),
# the reference list, "Related pages", "Other questions about flu" and
# "Learn more:" link lists, an empty accordion heading, a trailing
# "Resources" heading. Not reachable: the emergency wound care factsheet
# (the page only wraps a PDF, which returns 403).
set -euo pipefail
SRC="${1:?usage: $0 <dir-with-saved-pages>}"
D=content/01c-cdc-health
X="python3 tools/packs/extract_html.py"
$X "$SRC/seizures.txt" --source-url https://www.cdc.gov/epilepsy/first-aid-for-seizures/index.html -o $D/01-seizure-first-aid.md
$X "$SRC/caring-sick.txt" --source-url https://www.cdc.gov/flu/takingcare/caring-for-someone.html -o $D/02-caring-for-someone-sick.md
$X "$SRC/hygiene.txt" --source-url https://www.cdc.gov/water-emergency/safety/guidelines-for-personal-hygiene-during-an-emergency.html -o $D/03-personal-hygiene-emergency.md
$X "$SRC/after-disaster.txt" --source-url https://www.cdc.gov/natural-disasters/response/index.html -o $D/04-after-a-disaster.md
python3 - <<'PY'
import re
D='content/01c-cdc-health'
def fix(p, fn):
    s=open(p).read(); open(p,'w').write(fn(s))
fix(f'{D}/01-seizure-first-aid.md', lambda s: re.sub(r'\n## RELATED PAGES[\s\S]*$','\n', re.sub(r'\n- Hauser WA[^\n]*','', s.replace('in their lifetime.1 This','in their lifetime. This'))))
fix(f'{D}/02-caring-for-someone-sick.md', lambda s: re.sub(r'\n## [^\n]*Other questions about flu[^\n]*\n(- [^\n]*\n|\n)*','\n',s))
fix(f'{D}/03-personal-hygiene-emergency.md', lambda s: re.sub(r'\n## Resources\s*$','\n', re.sub(r'\n## [^\n]*If soap and water are not available\.\.\.\n','\n',s)))
fix(f'{D}/04-after-a-disaster.md', lambda s: re.sub(r'\nLearn more:\n\n?(- [^\n]*\n)+','\n',s))
PY
python3 tools/packs/build_pack.py $D
