# Roadmap

Each milestone ends with a working, tested build. Milestone 3 is the first
real MVP: model + reference library on device, airplane mode on, answers cite
local passages.

## 1. Flutter foundation — ✅ done
App shell and four tabs (Chat, Library, Tools, Settings), dark theme from the
mockups, Drift database (conversations, messages, pack registry), Riverpod DI,
`InferenceEngine` contract with streaming, cancel, and an honest no-model
path. Conversation persistence, history and delete. Navigation screen shell.
Unit and widget tests.

**Not yet verified:** running on a physical iPhone/Android phone (Xcode was
incomplete and no emulator existed on the dev machine at build time).

## 2. On-device AI — ✅ working on Android
Done:
- `llamadart` chosen (see decisions), `LlamaInferenceEngine` streams tokens,
  stops on cancel, loads lazily, unloads on memory pressure.
- Settings → AI model: import `.gguf` (atomic, header-validated), switch
  active model, delete.
- Clear errors for missing/corrupt/unloadable model files.
- One-tap download of the recommended model (size + SHA-256 verified,
  cancellable); see decisions.
- Tests for import safety, download verification/cancel, engine selection.

Verified on device (2026-10-29, Pixel Fold, Android 17): recommended model
downloads (with automatic resume after dropped connections), loads, and
answers in chat — including in airplane mode.

Remaining:
- Measure load time, tokens/sec, RAM, and battery over a long chat.
- Show a "loading model…" state on the first message (load takes seconds).
- iOS run once Xcode is installed (deployment target already 16.4).

## 3. Offline knowledge engine — 🚧 in progress
Done:
- Pack format + Python builder and verbatim HTML extractor (`tools/packs/`).
- SQLite FTS5 search; Library, pack, reader and search screens.
- Grounded answers: numbered passages, `[n]` citations as chips that open
  the exact passage; "Not from the offline library" label otherwise.
- Starter library: 5 packs, 19 documents, 150 sections (CDC, Ready.gov).
- Retrieval tests on the real library for safety-critical details.

Library now: 30 packs, ~5,800 sections, 477 figure/table images, from CDC,
FEMA/Ready.gov, NWS, USDA, FDA, NIMH, EPA, CMS, NPS, CISA, FCC and Army
manuals, plus flagged Wikibooks and historical texts. Review status shown
throughout; background install with progress.

Remaining:
- Verify on Pixel Fold: background install time, images in the reader,
  table-image citations.
- Figures for the batch-3 Army manuals (carpentry, rigging, plumbing,
  welding, antennas) — their recipes don't use `--figures auto` yet.
- USDA canning guide: decode the U+FFFD space glyph, then require
  table-image count == caption count.
- OSHA tool/electrical/generator PDFs (blocked to scripts; fetch by browser).
- Per-section safety review of hazardous improvised advice (Coverage Matrix).
- In-app source/attribution notice (About screen).
- ✅ Semantic search (bundled bge-small embedder + per-section vectors),
  fused with keyword search; conversational chat voice; Markdown replies.
- ✅ Batch 4 coverage audit (`tools/coverage/`) and new packs: power,
  medical emergencies, home health, CDC health, signaling, sea survival,
  wilderness/wildlife, storm shelter, SODIS, preparedness, household
  skills (historical), self-sufficiency, gardening, livestock.
- Gaps still open (no permitted/reachable source yet): fever care,
  choking/anaphylaxis/drowning first aid (current federal), jump-starting
  and tire changes, ham radio basics (fcc.gov blocks scripts — try the
  in-app browser), CPSC generator/electrical safety (same), EMP household
  guidance, bartering, current beekeeping/livestock health.
- Tooling: `extract_html.py` drops any class containing "reference"
  (hits Drupal/NHLBI/DOE pages) and all `<button>` text (accordion
  titles) — fix to whole-token match; move the agents' recipe-local
  converters (gtext, pg2md, djvu2md, capfig) into `tools/packs/`.
- Offer a smaller, faster model option in the catalog for slower phones.

## Beyond the original plan (see docs/vision.md)
Folded into later milestones as the library grows: the 18-pack taxonomy,
Survival Coverage Matrix and Knowledge Management System (tooling),
Emergency Scenario Explorer (with Milestone 6), regional plant/mushroom
species database with images, and the three-layer medicine model.

## 4. Model & knowledge downloads
Download manager (pause/resume, checksums, atomic install, versioning),
storage checks, catalog. First feature allowed to use the network.

## 5. Preparedness
Household profile, supply inventory, checklists, personalized plans.

## 6. Emergency Mode
Quick-access procedures, guided workflows, low-battery UI, deterministic
(non-AI) fallbacks.

## 7. Offline navigation & utilities
MapLibre with downloadable regions, GPS, compass, conversions.

## 8. Production readiness
Device matrix testing, performance, security review, accessibility, store
packaging, and the acceptance tests in the build plan (airplane mode, cold
start offline, restart persistence, corrupt model, interrupted download, low
storage/memory, missing source, citation accuracy, platform parity).
