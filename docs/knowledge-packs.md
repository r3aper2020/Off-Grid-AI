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
   Aliases: is my water safe to drink, how much bleach per gallon, boil water how long

   ## Section heading
   Text copied verbatim from the source.
   ```
   Keep sections focused (one procedure or topic, ≤ 4000 characters) —
   that is what a citation opens.
   - `Aliases:` (required for bundled packs) lists 8–25 plain-language
     phrasings a non-expert would type for what the document answers,
     covering its main sub-topics. They are indexed for keyword and
     meaning search and never shown, so the verbatim text stays verbatim
     while "bug out bag" still finds "Build A Kit".
   - `Chat: library-only` keeps a document readable and searchable in the
     Library but out of AI answers (regulation text, reference tables).
3. Build: `python3 tools/packs/build_pack.py content/<pack-id>`
   → writes `assets/packs/<pack-id>.json`.

Bundled packs in `assets/packs/` are installed on first launch and
reinstalled whenever their `version` changes; packs removed from the
bundle are uninstalled. After building, regenerate the meaning vectors
(`flutter test tools/embed/embed_packs_test.dart` writes
`assets/packs/vectors/<pack>.vec` and `<pack>.docs.vec`); a test fails if
they are stale.

## Cleaning

`build_pack.py` drops sections that are not readable prose (OCR noise and
diagram labels from scanned books, number-only table fragments, dotted
tables of contents) and merges sections under 200 characters of text into a
neighbour: a short intro ("Boil") joins its first sub-section, anything
else joins the previous section with its heading kept as a bold line. The
build prints every change; review it. Sections carrying an image are
always kept.

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
      "aliases": "plain phrase, plain phrase, ...",
      "libraryOnly": false,
      "sections": [ { "heading": "...", "body": "...",
                      "images": [ { "asset": "...", "caption": "...", "kind": "figure" } ] } ] }
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
