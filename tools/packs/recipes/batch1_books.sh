#!/usr/bin/env bash
# Historical (pre-1929, public domain) books from Project Gutenberg.
# Usage: tools/packs/recipes/batch1_books.sh <dir-with-downloaded-sources>
# Sources (HTML editions; PG license header/footer are stripped on extract,
# as Project Gutenberg's trademark terms require for redistribution):
#   https://www.gutenberg.org/cache/epub/28255/pg28255-images.html  (Beard)
#   https://www.gutenberg.org/cache/epub/34110/pg34110-images.html  (Harding)
set -euo pipefail
SRC="${1:?usage: $0 <source-dir>}"
D=content/historical-woodcraft; mkdir -p $D
python3 tools/packs/extract_html.py "$SRC/beard.html" --container body \
  --drop-before FOREWORD --skip contents \
  --title "Shelters, Shacks and Shanties (D. C. Beard, 1914)" \
  --source-url "https://www.gutenberg.org/ebooks/28255" \
  -o $D/01-shelters-shacks-shanties.md
# Drop the publisher's advertisements that follow "The End".
python3 - "$D/01-shelters-shacks-shanties.md" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s[: s.index("The End\n") + len("The End\n")])
PY
python3 tools/packs/extract_html.py "$SRC/harding.html" --container body \
  --drop-before INTRODUCTION \
  --title "Deadfalls and Snares (A. R. Harding, 1907)" \
  --source-url "https://www.gutenberg.org/ebooks/34110" \
  -o $D/02-deadfalls-and-snares.md

# Boy Scouts Handbook, 1911 first edition (PG #29558, plain text):
#   https://www.gutenberg.org/cache/epub/29558/pg29558.txt
# Only woodcraft, campcraft and signaling. The 1911 first-aid chapter is
# deliberately excluded: century-old first aid can be harmful, and current
# Army first aid (ATP 4-02.11) covers the subject.
U="https://www.gutenberg.org/ebooks/29558"
python3 tools/packs/extract_text.py "$SRC/scouts.txt" --chapter WOODCRAFT \
  --title "Woodcraft (Boy Scouts Handbook, 1911)" --source-url $U -o $D/03-scouts-woodcraft.md
python3 tools/packs/extract_text.py "$SRC/scouts.txt" --chapter CAMPCRAFT \
  --title "Campcraft (Boy Scouts Handbook, 1911)" --source-url $U -o $D/04-scouts-campcraft.md
python3 tools/packs/extract_text.py "$SRC/scouts.txt" --chapter TRACKS \
  --title "Tracks, Trailing and Signaling (Boy Scouts Handbook, 1911)" --source-url $U -o $D/05-scouts-signaling.md
# Seton, The Book of Woodcraft (1912): only scan OCR exists (errors like
# "Life Mistories"), which would corrupt verbatim text — not included.
