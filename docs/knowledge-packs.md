# Knowledge packs

A knowledge pack is one JSON file (`offgrid-pack`, format version 1) holding
documents split into sections. Sections are the unit the app searches,
gives to the model, and cites.

## Authoring

1. Create `content/<pack-id>/pack.json`:
   ```json
   {
     "id": "water-safety",
     "title": "Water Safety",
     "category": "guide",
     "version": "2026.1",
     "publisher": "U.S. Centers for Disease Control and Prevention",
     "license": "Public domain (U.S. Government work, 17 U.S.C. § 105)",
     "attribution": "Adapted from CDC. Use does not imply endorsement.",
     "description": "Making water safe to drink in an emergency."
   }
   ```
   `category` is one of `guide`, `medical`, `map`, `note`.
2. Add one Markdown file per document (`01-boiling.md`, …):
   ```markdown
   # Document title
   Source: https://www.cdc.gov/...

   ## Section heading
   Text copied verbatim from the source.
   ```
   Keep sections focused (one procedure or topic, ≤ 4000 characters) —
   that is what a citation opens.
3. Build: `python3 tools/packs/build_pack.py content/<pack-id>`
   → writes `assets/packs/<pack-id>.json`.

Bundled packs in `assets/packs/` are installed on first launch and
reinstalled whenever their `version` changes; packs removed from the
bundle are uninstalled.

## Content rules

- **Verbatim source text only.** Don't paraphrase or "improve" guidance;
  reformatting and splitting into sections is fine. The AI's answers are
  labelled as AI output with citations to the verbatim text.
- Every pack states its publisher, license and attribution, and every
  document its source URL.
- Only sources whose license allows commercial redistribution (see
  `docs/decisions.md` for the approved list). No images, logos or seals.
- Bump `version` whenever content changes.

## JSON shape

```json
{
  "format": "offgrid-pack", "formatVersion": 1,
  "id": "...", "title": "...", "category": "guide", "version": "...",
  "publisher": "...", "license": "...",
  "attribution": "...", "description": "...",
  "documents": [
    { "title": "...", "sourceUrl": "...",
      "sections": [ { "heading": "...", "body": "..." } ] }
  ]
}
```

## Review status

`pack.json` must set `"review"`: `verified`, `needs-review` or
`historical` (missing = `needs-review`). See `docs/decisions.md`.

## Recipes

`tools/packs/recipes/*.sh` record, for every document, the official source
URL, release/copyright status and exact page selection, so the library can
be regenerated and audited:

```bash
python3 -m venv tools/.venv && tools/.venv/bin/pip install -r tools/packs/requirements.txt
tools/packs/recipes/batch1_pdfs.sh <dir-with-downloaded-sources>
tools/packs/recipes/batch1_books.sh <dir-with-downloaded-sources>
for d in content/*/; do python3 tools/packs/build_pack.py "$d"; done
```

PDF tools: `extract_pdf.py` (pdfminer.six). Watch its "words lost"
warnings — they caught dropped WARNING labels and garbled tables.
Never ship a document whose tables carry critical numbers (dosages,
processing times) until tables are preserved as images.
