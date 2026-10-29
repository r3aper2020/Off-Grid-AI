#!/usr/bin/env bash
# CDC pages (cdc.gov blocks automated downloads; no workaround attempted).
# Each page was opened in the in-app browser, its <main> text extracted
# in-page, transferred, and verified by matching SHA-256 hashes before use.
# Extract from the saved copies:
#   python3 tools/packs/extract_html.py <saved>.txt --source-url <url> -o content/15-cdc-emergencies/<doc>.md
# Pages: radiation-emergencies/response/get-inside, radiation-emergencies/
# prevention/self-decontaminate, chemical-emergencies/response/shelter-in-place,
# chemical-emergencies/response/get-chemical-off-body, carbon-monoxide/about,
# niosh/outdoor-workers/about/venomous-snakes, .../venomous-spiders,
# ticks/after-a-tick-bite, rabies/about, diabetes/articles/diabetes-care-emergencies.
# HELD BACK: heat-health/.../heat-and-medications-guidance-for-clinicians
# (substance is a 27-row drug-class table). Not reachable: wound-care and
# mold-cleanup PDFs (403), which pages only wrap.
