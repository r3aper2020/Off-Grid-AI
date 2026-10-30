#!/usr/bin/env bash
# Batch 5 (FCC radio): content/16b-ham-radio (id ham-radio-basics).
# fcc.gov returns HTTP 403 to scripts; pages were fetched same-origin in the app's built-in browser on 2026-10-30,
# <main> converted to Markdown in-page (headings, lists, table rows) and sha256(innerText) recorded.
# Post-processing: FAQ "Q:/A:" pairs became "## <question>" sections; dates, Print/Share, Bureau/Tags chrome removed; nothing reworded.
# LICENSE: U.S. Government works (FCC). No ©/courtesy/permission/reprinted hits. The regulation texts themselves (47 CFR 95/97) are in the
# communications pack as library-only documents; these are the FCC's plain-language pages.
# NOT FOUND: an FCC page on emergency communications for the general public (none beyond the FAQ answers kept here).
set -euo pipefail
D=content/16b-ham-radio
# file | url | sha256(main.innerText)
# 01-amateur-radio-service.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/amateur-radio-service | 91016a0d83ce2933714637e195b2cb061ee430679647430d23a0bfaacbf9309a
# 02-communications-faq.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/amateur-radio-service/amateur-communications-operations | 72d2def75d3e857ebf74992c95e9a24b129fa1292e8841f21d2f4238eab5589c
# 03-examinations.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/amateur-radio-service/examinations | 40e5d18177edd867b3388f4ab28566227ade48608895b158920dab55a3f1d1b8
# 04-operator-class.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/amateur-radio-service/operator-class | 84ca57a5e9a8fe036ec2bdbdfb36f52a5fbef68e9ce9d598e902253f4809a3f1
# 05-call-signs.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/amateur-radio-service/amateur-call-sign-systems | 5162d4faaaf42875b3d185c9483e80e6ee5b68fc66334f9645476372c1b6793f
# 06-personal-radio-services.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/personal-radio-services | f41121fe9223958c87276735bc7e7f0dc1b2b75a15d459b6d45687bdf9d76048
# 07-gmrs.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/general-mobile-radio-service-gmrs | 71ac65ab519054dd758c8f7ca2c68289e956b7d4e44ed2a48749c82a625a00ea
# 08-frs.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/family-radio-service-frs | 4e9065d134206b9a1eefb87197dd39eb25cb3b35bf364c584fda95fc84e8dd64
# 09-cb.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/citizens-band-radio-service-cbrs | 4ce3dfbd5fdb16b1829ca26c961d021f30546c7bb5146a77a2bac1bb5ac304a6
# 10-murs.md | https://www.fcc.gov/wireless/bureau-divisions/mobility-division/multi-use-radio-service-murs | 94dd557b8e761f57a3d3d893485f05ee374252df1d7ced3b24c1469f3f7e9ffc
for f in 01-amateur-radio-service.md 02-communications-faq.md 03-examinations.md 04-operator-class.md 05-call-signs.md 06-personal-radio-services.md 07-gmrs.md 08-frs.md 09-cb.md 10-murs.md; do [ -f "$D/$f" ] || { echo "missing $f"; exit 1; }; done
echo "ham-radio-basics: $(ls $D/*.md | wc -l) documents present"
