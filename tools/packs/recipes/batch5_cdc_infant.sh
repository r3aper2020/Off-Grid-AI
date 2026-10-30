#!/usr/bin/env bash
# Batch 5 (CDC infant feeding): content/22-infant-feeding (id infant-feeding).
# cdc.gov returns HTTP 403 to scripts, so these pages were read in the app's
# built-in browser on 2026-10-30: each page was fetched same-origin
# from a cdc.gov tab, its <main> element converted to Markdown in-page
# (headings → ##, lists → -, table rows → " | "), and the SHA-256 of the
# element's innerText recorded below. Page chrome removed afterwards: dates,
# "For Public Health", "Download handout…", "Sources Print Share", "Content
# Source: NCCDPHP". h3/h4 headings became "Parent: Child". Nothing reworded.
#
# LICENSE: U.S. Government works (CDC/NCCDPHP, 17 U.S.C. § 105). Every page
# scanned for ©/courtesy/permission/reprinted/adapted: none in the shipped
# pages. Images and PDF handouts not used.
#
# EXCLUDED:
#   - php/cup-feeding.html — states "Adapted from Baby-friendly Hospital
#     Initiative training course … WHO and UNICEF, 2020" (third-party text).
#   - php/safe-spaces.html, php/index.html, php/preparedness-response.html —
#     shelter planning/meta pages with no household procedure.
#   - infant-toddler-nutrition/emergencies-and-illness/index.html and
#     breastfeeding/.../breastfeeding-during-a-disaster.html — HTTP 404.
#
# To regenerate: open each URL in a browser, extract <main> verbatim, and
# compare sha256(innerText) with the value here. This script only checks
# that the files exist (no network).
set -euo pipefail
D=content/22-infant-feeding
# file | url | sha256(main.innerText)
# 01-facts.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/facts.html | 97ace92005bfd174ffc30501bbdf2aa49c8420c644ceb2993dbeec34b50d87d1
# 02-feeding-safely-during-disaster.md | https://www.cdc.gov/breastfeeding/php/guidelines-recommendations/feeding-your-child-safely-during-a-disaster.html | dd5371367603d420734e9e770b559fcdd66ab4e150332f4d63ff9c026d5850fd
# 03-emergency-list-families.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/checklist.html | 34f899c7042f285453a498ebbf1b7458e876cc1ab3dafd6d5b42d6f0faa87ba5
# 04-powdered-formula-emergency.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/powdered-infant-formula.html | 38bde89e97b39c7f11a517b0a2ebb90b685e4616fad67533e9e106c77246fb17
# 05-special-considerations.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/special-considerations.html | 12805111f211b83ce88fcd6ab7622598032e3f753aee7a2459c18b6cfa05492d
# 06-clean-feeding-items-emergencies.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/how-to-clean-infant-feeding-items-during-emergencies.html | 6c841d403038346cf1b1fcb7a17de064e06902f788d8ae72357de97c1b2d4bd7
# 07-clean-sanitize-store-everyday.md | https://www.cdc.gov/hygiene/about/clean-sanitize-store-infant-feeding-items.html | 49792bf6aaa09146ab32cf1616ee5c1ebab232b30ed45720eb14571140fd7213
# 08-hand-expression.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/hand-expression.html | d14d8256bcd85342864a1eeac81015d9847253b1f9b4b6b8e74c983772385b3b
# 09-radiation-emergency-infant-feeding.md | https://www.cdc.gov/radiation-emergencies/caring/infant-feeding.html | 7d790e5b0afc1e86afa0ed13cdf186c712ba192ef495e37dc1638af1e29bf03e
# 10-shelter-support.md | https://www.cdc.gov/infant-feeding-emergencies-toolkit/php/shelter-support.html | b4b561e3449b55df6f226292813b9ebe7b3cb71cd7c5ca292993837fd2df03a5
# 11-formula-preparation-storage.md | https://www.cdc.gov/infant-toddler-nutrition/formula-feeding/preparation-and-storage.html | 9ee0b5cf25436bf7cc100a45a3d2cbc78cdfe22ffc4f83a70b8519ddd6836be8
for f in 01-facts.md 02-feeding-safely-during-disaster.md 03-emergency-list-families.md 04-powdered-formula-emergency.md 05-special-considerations.md 06-clean-feeding-items-emergencies.md 07-clean-sanitize-store-everyday.md 08-hand-expression.md 09-radiation-emergency-infant-feeding.md 10-shelter-support.md 11-formula-preparation-storage.md; do [ -f "$D/$f" ] || { echo "missing $D/$f"; exit 1; }; done
echo "infant-feeding: $(ls $D/*.md | wc -l) documents present"
