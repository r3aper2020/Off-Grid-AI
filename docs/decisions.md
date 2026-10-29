# Decisions

Record each decision with date, choice, and why. Newest at the bottom.

## 2026-10-29 — Foundation stack
Flutter + Dart, Riverpod (no codegen), GoRouter, Drift on SQLite.
Riverpod without codegen keeps the build simple; Drift codegen is needed
anyway for typed tables. Drift also gives FTS5 for Milestone 3.

## 2026-10-29 — Engine behind an interface
Chat depends on `InferenceEngine`, not on a llama.cpp package. The Flutter
llama.cpp bridges vary in platform support and licensing (some lack Android,
`flutter_llama` has a nonstandard license), so the bridge is chosen in
Milestone 2 after testing on real iOS and Android hardware, and can be
replaced later without touching UI.

## 2026-10-29 — No model means an honest notice, not a fake reply
`NoModelEngine` reports unavailability; the controller stores the reason as a
`notice` message, which is shown distinctly and excluded from model context.

## 2026-10-29 — No INTERNET permission in release
The Flutter template only grants `INTERNET` in debug/profile manifests (for
hot reload). Release has none, which enforces offline-by-default. Milestone 4
must add it deliberately and document why.

## 2026-10-29 — Dark-only theme
Matches the product mockups and suits low-light emergency use. A light theme
can be added later via the same `AppColors` tokens.

## 2026-10-29 — "100% Offline" badge is a design statement
It reflects that the app makes no network calls; it is not a connectivity
probe. Revisit wording if optional online features are added.

## 2026-10-29 — llama.cpp bridge: llamadart
Chosen over `llama_cpp_dart` (last release 9 months old), `fllama` (stale),
and `flutter_llama` (license unclear). `llamadart` is MIT, actively
maintained, supports Android and iOS, runs llama.cpp on its own isolate,
and cancels native generation when the Dart stream subscription is cancelled
(matches our `InferenceEngine` contract). Prebuilt native libraries are
fetched by its build hook **at build time only**; models load from a local
path, so there is no runtime network use. It requires iOS 16.4+.
Its `hf://` download feature is not used — downloads belong to Milestone 4.

## 2026-10-29 — Android runs on CPU
llamadart's Android Vulkan backend is experimental and some GPU drivers are
excluded. We force `ComputeDevice.cpu` on Android for predictable behavior;
revisit once GPU support stabilizes. Apple devices use Metal (`auto`).

## 2026-10-29 — Models are imported from a file (sideload)
Settings → AI model → Import copies a user-picked `.gguf` into app-private
storage. Copies go to `<name>.part` and are renamed only after the GGUF
header check and full copy succeed; leftover `.part` files are removed on
startup. This works fully offline and stays useful after downloads exist.
Free space is not pre-checked (no plugin yet); a full disk (ENOSPC) aborts
the import and removes the partial file.

## 2026-10-29 — Suggested starter model
Qwen3-4B-Instruct-2507 at Q4_K_M (~2.5 GB, Apache-2.0). Permissive license
suits a commercial app, non-thinking variant answers directly, and it fits
phones with 8 GB+ RAM. Not bundled; the user imports it.

## 2026-10-29 — Generation settings
Context 4096 tokens, max reply 1024 tokens, thinking disabled. History is
trimmed newest-first by a conservative character budget (~3 chars/token)
until token-accurate trimming is needed. On OS memory pressure an idle
model is unloaded and reloads on the next message.

## 2026-10-29 — Recommended model download pulled forward from Milestone 4
Requiring users to find and sideload a 2.5 GB file was a real barrier, so a
minimal download landed in Milestone 2: one catalog model
(`ModelCatalog.recommended`), started only by an explicit tap after a size
confirmation. Bytes stream through the same `ModelStore.import` path as
sideloading (`.part` file, GGUF header check) plus exact size and SHA-256
verification against Hugging Face LFS metadata. Cancel, network errors and
stalls (60 s without data) discard the partial file.
This supersedes "No INTERNET permission in release": the main Android
manifest now declares `INTERNET`, used only by `ModelDownload`.
Still for Milestone 4: pause/resume (server supports byte ranges),
background downloads, free-space pre-check, multi-model catalog.

## 2026-10-29 — Starter library sources (Milestone 3)
Approved: U.S. Government public-domain text only — CDC (emergency water,
food safety after emergencies, heat illness, hypothermia, frostbite) and
Ready.gov/FEMA (kit, plan, evacuation, shelter, food, power outages,
winter weather, heat, floods, hurricanes, wildfires, earthquakes). Each
pack carries publisher, license and a no-endorsement attribution; no
images, logos or seals. Rejected: Red Cross (non-commercial only),
MedlinePlus A.D.A.M. articles (licensed). Deferred pending verification:
EPA (its policy mentions non-commercial use), Army ATP 3-50.21
(distribution statement unconfirmed). Wikibooks *First Aid* (CC BY-SA)
approved by the owner to cover CPR/choking, as a separate pack with
attribution, flagged for safety review (volunteer-written). A lawyer
should review attribution wording and "do not alter content" conditions
before commercial release.

## 2026-10-29 — Verbatim extraction pipeline
Library text must be the source's exact words. `tools/packs/extract_html.py`
keeps every text run inside `<main>` (grouped by block element, so text in
div-based tables and callouts survives — an earlier tag-based version
silently dropped the volume labels from CDC's bleach tables) and reports
any words lost. CDC blocks automated downloads (no workaround attempted);
its pages were read in a browser, extracted in-page, and each transfer
verified by matching SHA-256 hashes. `<h3>` sub-headings become their own
sections ("Boil: Steps for boiling water") so citations are precise.

## 2026-10-29 — Retrieval: whole passages only
Passages given to the model are never truncated (a cut passage could drop
a dosage or warning). `Grounding.select` keeps whole passages in rank
order within a 5,000-character budget, always including the best match.
Search uses FTS5 BM25 over an any-term query, requiring partial matches
to share 2+ terms with the question; a short intro section pulls in its
sub-sections. `test/features/library/bundled_packs_test.dart` asserts that
realistic questions reach the safety-critical lines.

## 2026-10-29 — Pack review status (Survival Coverage Matrix, pack level)
Every pack declares `review`: `verified` (authoritative, current),
`needs-review` (volunteer-written or superseded), or `historical` (pre-1929).
A missing status means `needs-review` — content is never assumed verified.
Flagged packs show a warning on the library tile, pack page, reader and
citation chips, and their passages reach the model labelled UNREVIEWED or
HISTORICAL with an instruction to tell the user to verify critical steps.

## 2026-10-29 — Library expansion (batch 1)
Added, from official sources (see `tools/packs/recipes/`):
ATP 3-50.21 Survival (verified), TC 4-02.3 Field Hygiene ch. 1–3
(verified), FEMA Are You Ready? (verified), FM 3-25.26 (2001) land
navigation (needs-review: superseded; later editions are not public
release), Nuclear War Survival Skills 1979 ORNL original (needs-review;
the 1987 edition has copyrighted additions), Wikibooks First Aid
(needs-review; its CPR rate/depth follow pre-2015 guidelines), Beard 1914
and Harding 1907 via Project Gutenberg (historical; PG license text
stripped). Excluded: FM 3-05.70 and post-2001 navigation manuals
(restricted distribution), ST 31-91B (no release statement), TM 31-210
(improvised munitions — never), copyrighted works (Hesperian, foreign
government guides, LDS manual, TruePrepper's own material).

## 2026-10-29 — Tables are held back until preserved exactly
Text extraction cannot keep table rows and columns together. The USDA
Complete Guide to Home Canning and TC 4-02.3 App. A (water dosing) are NOT
shipped: their processing-time/dosage tables came out as fragments that
could pair a wrong time with a jar size or altitude (botulism risk).
Remaining table captions in shipped text are marked "table layout not
preserved; verify values against the original document". Next step: store
tables and diagrams as images of the original page regions.

## 2026-10-29 — PDF extraction safeguards
pdfminer.six (not pypdf, which split words like "car e"). Headers/footers
are only dropped from the top/bottom 8% of a page — repeated text in the
body (table cells) is content. WARNING/CAUTION/NOTE labels start a callout
whose text is never treated as a heading (bold warning bodies had become
section titles, losing the label). Headings with no text are carried into
the next section, never dropped. Every run reports words lost.

## 2026-10-29 — Retrieval at library scale
The FTS index includes each document's title (sections often never repeat
their subject). Relevance uses BM25-style IDF coverage: a passage must
cover ≥55% of the question's word weight, so rare topic words carry a
question and words the library has never seen make off-topic questions
find nothing. Up to 6 candidates; whole passages within the 5,000-char
budget.

## 2026-10-29 — Figures and tables as images (format addition)
`tools/packs/extract_figures.py` renders each captioned figure/table region
of the original PDF page (pypdfium2) and `extract_pdf.py --figures auto`
drops the text inside those regions (scrambled table cells, diagram
labels) in favour of the image. Sections carry `images` [{asset, caption,
kind}] with `{{img:N}}` placeholders in the body; images ship flat in
`assets/packs/images/` (schema v5 adds `passages.images`). The model sees
"[Table image: … — exact values … not available as text]" and is told
never to state or guess values it cannot see. Region rules learned the hard
way (each caught by contact-sheet review): stop at the neighbouring caption
(stacked tables had merged), use the page text column not the caption
width (row labels were clipped), stay out of header/footer bands, unique
names for "(continued)" pages (they had overwritten each other). Scanned
books (NWSS 1979) are excluded — detection is unreliable on page images.
Every table image was reviewed by eye; review contact sheets with
`tools/packs/contact_sheet.py`.

## 2026-10-29 — USDA canning guide still held back
Table images work (Guide 3 reviewed: every table separate and exact), but
Guides 1–2 and 4–7 use a font that maps the space glyph to U+FFFD, so their
text is not verbatim and captions don't match (Guide 2: 71 of 110 tables).
`build_pack.py` now refuses any section containing U+FFFD.

## 2026-10-29 — Library expansion (batch 3, via parallel import agents)
20 new packs from federal/Army sources with the same safeguards, recipes in
`tools/packs/recipes/batch3_*.sh`. Notable holdbacks: every table carrying
critical numbers (span/mortar/rigging/pipe tables, KI dosing table, NIFOG
channel tables, CERT bleach and extinguisher tables, dialysis diet), OCR
scans with garbled quantities (most Farmers' Bulletins, 1917 mushrooms,
1943 Pacific plants), and pages with third-party or co-authored content.
EPA: pages used only where no third-party notice appears; EPA's "commercial
use may be protected" note applies only to documents that adopt it (none
of those used). EPA content is isolated in EPA-only packs (wood-burning,
water-systems) so it can be dropped in one step if counsel disagrees.
CMS dialysis guide kept as verified (CMS publication, no notice; contractor
contributors noted). OSHA PDFs could not be downloaded (bot wall) — pending.

## 2026-10-29 — Bundled library installs in the background
With ~5,800 sections, installing before the first frame would blank the
screen. `librarySyncProvider` installs packs after launch with progress in
the Library; search covers whatever is installed so far.

## 2026-10-29 — Known content caveat: "verified" ≠ "safe in every context"
Some verified official text contains improvised military survival
treatments (e.g. ATP 3-50.21 Table 2-1: drinking kerosene for worms).
It is authentic and current Army doctrine, shown verbatim with citation.
A per-section safety review (Survival Coverage Matrix) is needed before
release to flag such passages — see roadmap.

## 2026-10-29 — Chat answers: figures by reference, short prompts
Figures are attached to whichever section their PDF page fell in ("Fire
lays" sits under "Star Fire"), so chat thumbnails also include figures a
cited passage refers to by number ("Figure 5-5"), matched within the same
document only (`KnowledgeSearch.figuresFor`).
On-device speed is dominated by reading the prompt on the CPU, and a 4B
model blends earlier questions into new answers. So: passages capped at
3,500 chars, only the previous exchange is sent (earlier reply cut to 600
chars), replies capped at 600 tokens with a "brief, numbered steps,
latest question only" instruction, and 4 llama.cpp threads on Android
(the big cores; the default also schedules the slow ones).
Situation words ("middle of nowhere", "my friend", "his") are stopwords:
rare words outweighed the topic in the coverage check, so "start a fire
in the middle of nowhere" found nothing. Keyword search still misses
paraphrases (a "shelter" question ranks fallout shelters above wilderness
ones); semantic (embedding) search is the proper fix — see roadmap.
A question word found in a section's heading or document title counts
1.5× in the coverage check: "I'm in contact with a bear" scored 54.6%
against the NPS "Bear Encounters" sections ("contact" is common in
welding/chemical text) and found nothing.

## 2026-10-29 — collapsesurvivalsite.com list triaged (~400 PDFs)
A mirror with no provenance; we use it only as a reading list and fetch
originals from the publisher. Title/copyright pages of ~95 plausible
candidates were checked. Worth adding (original sources to fetch):
Aids to Survival (WA Police Academy, "not subject to copyright"), FEMA
P-320 safe rooms (current edition), U.S. Antarctic Program Field Manual
(NSF: snow shelters, cold injuries), SODIS Safe Water School Manual
(copy/adapt permitted with attribution), Army GTA 05-02-013 navigation
cards (Distribution A), FM 21-76 (1992) edible/poisonous plant appendices
(Distribution A; superseded → needs-review; plant ID needs extra care).
Excluded: copyrighted books and articles (Foxfire, Hesperian, Ragnar,
Agromisa, VITA reprints, magazines, Woodson flu guide, university
extension bulletins without a reuse grant), foreign government works
without a reuse grant (Canada, Yukon), "free if kept intact" works
(Survival and Austere Medicine — we excerpt), untraceable compilations,
weapons/combat manuals, cookbooks, and older editions of manuals we
already ship in current form (FM 21-11/4-25.11 → ATP 4-02.11,
FM 3-97.61 → TC 3-97.61, FM 21-10 → TC 4-02.3, FM 21-76 survival text →
ATP 3-50.21, FEMA Are You Ready?, NWSS). Image-only scans (wood gas
generator FEMA RR-28, Farm Blacksmithing) wait for an OCR path.

## 2026-10-29 — Conversational assistant behaviour
The system prompt now asks for a calm, experienced friend's voice: most
important action first, short (≈150 words), one clarifying question when
the answer depends on unknowns (after giving safe first steps), an
occasional offer of the next useful step, and building on the
conversation. The last two exchanges are sent (earlier replies cut to 500
chars). Greetings/thanks (no topic words) skip library lookup and get no
library instruction or "not from the library" label (citations stay
null). Short follow-ups ("what about for a baby?") are searched together
with the previous question, but every passage must still match a word of
the new message, so a change of topic never returns the old topic
(`KnowledgeSearch.forMessage`). Replies render light Markdown (lists,
bold, highlighted [n]) instead of raw symbols.

## 2026-10-29 — Semantic search (bundled embedding model)
Keyword search missed paraphrases ("emergency kit" vs "Build A Kit",
"find water in the wild" vs ATP 3-50.21 Ch. 3). bge-small-en-v1.5 Q8_0
(MIT; ggml-org GGUF, 36,685,152 bytes, sha256 f046db1d…66b5608) ships in
`assets/models/` — no download, works offline from first launch; copied
out of the bundle once because llama.cpp needs a path, loaded on the
first question, ~35 ms per query. Passage vectors are precomputed with
the same model and runtime (`tools/embed/embed_packs_test.dart`) and
shipped as `assets/packs/vectors/<pack>.vec` (int8, 384 dims, ~385 B per
section, each with a hash of its section text so stale vectors are
ignored, never misattached). Schema v6 adds `passages.embedding`; the
migration removes bundled packs so they reinstall with vectors. Ranking
fuses keyword (still gated by IDF coverage) and semantic (cosine ≥
`semanticMin`) lists by reciprocal rank. Any embedder failure falls back
to keywords. The embedder always runs on CPU: llama.cpp's default device
on macOS (Metal) returned vectors that varied between calls (cosine 0.72
for identical text).

## 2026-10-29 — Batch 4 library expansion (coverage audit)
`tools/coverage/questions.tsv` (≈200 scenario questions across the 18
packs + off-topic controls) and `coverage_report_test.dart` measure what
the model would be given. Gaps it found were filled by recipes
`batch4_*.sh` (each lists sources, licence evidence, cuts and holdbacks):
power (USFA, FAA, FDA, EIA, DOE), medical emergencies and home health
(NHLBI, NIDDK, FDA, ASPR, IHS dental card), CDC seizures/sick care/
hygiene/after-disaster (browser-fetched, SHA-256 verified), signaling
(FAA AIM 6-2 with figures, USCG, NOAA SARSAT), sea survival (USCG, NWS,
NOAA, NPS), lost-in-the-woods and wildlife (NPS, USFS), tornado shelter
(NOAA SPC, NWS), SODIS (Eawag open-source grant; needs-review),
preparedness (Ready.gov, USFA, CFPB, CISA), household skills (pre-1929
Gutenberg texts; historical) and farm sanitation/rodents (USDA FB;
needs-review). Not fillable with permitted sources: CPSC/OSHA/NHTSA/
fema.gov/FCC/many cdc.gov PDFs (bot walls), choking/anaphylaxis/drowning
first aid from a current federal source, USAP Field Manual (contractor
work), Aids to Survival (no official copy online), EFFAK (copyrighted),
TM 9-243 and GTA 05-02-013 (CAC-only), bartering.
