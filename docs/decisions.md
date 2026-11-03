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

## 2026-10-30 — The model is the instructor; the library is its evidence
The chat read as a clerk reading scraps: 400-token replies, "about 2 to 6
sentences", a 3,500-character passage budget, an instruction to base the
answer on the excerpts and to open with "the offline guides don't cover
it" whenever they didn't fit — which, with weak retrieval, was most of the
time. The system prompt now casts the model as an experienced instructor
who answers completely (first action, ordered steps with the detail needed
to do them, what to watch for, when to get help; 150–350 words), and the
grounding instruction makes the passages evidence: cite them where they
back a sentence, prefer their specifics, defer to them on conflict, ignore
irrelevant ones silently, and fill gaps from the model's own knowledge.
Medicine doses and chemical amounts still must come from a passage. With
no sources the model answers from its own knowledge and adds one line at
the end that the reply wasn't checked against the library. Budgets: 800
reply tokens, 6,500 characters / 8 passages, context 6144, the last two
exchanges with earlier replies cut at 800 characters. The cost is prompt
size (~2,500 tokens) and so first-token latency on a phone CPU; measure on
device and offer a smaller model (roadmap).

## 2026-10-30 — Query rewriting by the chat model
"I'm lost, it's getting dark and cold" shares no useful word with "If You
Get Lost" and follow-ups ("what if I don't have one?") carry no topic.
Before searching, the controller asks the model (`InferenceEngine.complete`,
~64 tokens, no streaming) for 2–3 plain search queries with references to
earlier turns resolved (`Grounding.rewriteTurns`/`parseRewrites`). The
user's words are always searched too and weigh more; the rankings are
fused by reciprocal rank (`KnowledgeSearch.forQueries`). If no model can
run, the old previous-question heuristic (`forMessage`) is used. Engines
must never surface a `complete` result as an answer.

## 2026-10-30 — Document aliases (retrieval-only text) and library-only documents
The verbatim rule stays, but the library's wording ("isolated personnel",
"Build A Kit", "potable water") is rarely the user's. Each document now
carries `aliases`: 8–25 plain-language phrasings of what it answers
("bug out bag, go bag, 72 hour kit"), written for every bundled document,
stored in `pack_documents.aliases`, indexed in `passages_fts` with the
title, counted in the coverage gate, and embedded as a document vector —
never shown to the user or the model. They are indexing metadata, not
content, so no review status applies; the verbatim text is unchanged.
Documents may be `libraryOnly` (`Chat: library-only` in the source): the
47 CFR radio regulation texts are, so they stay readable and searchable
in the Library but never reach the model ("morse code for SOS" was
answered with §97.3 definitions).

## 2026-10-30 — Retrieval: document vectors, more candidates, expansion, dedupe
Keyword search alone picked a 1911 passage on storing cucumbers "in a cool,
dark cellar" for "lost, dark and cold". Changes: 80 BM25 candidates (20
kept after the coverage gate) and 20 semantic candidates instead of 6;
section similarity is lifted by the document's similarity (title +
aliases), and a strongly matching document (≥ 0.80) admits its sections
even below the section floor; "(part n)" sections bring the parts before
and after them; near-duplicate passages (word-set Jaccard > 0.5, the same
procedure in two manuals) are given once; a keyword match whose meaning
is far from the question (cosine < 0.55: "hide" in "Run, Hide, Fight" for
"tan a hide") is dropped. Calibrated on `tools/coverage/` with bge-base,
whose similarities run lower than bge-small's: on-topic questions' best
section scores median 0.74 (10th percentile 0.65), off-topic controls at
most 0.62, so `semanticMin` = 0.64; best document scores median 0.67
(10th percentile 0.57), controls at most 0.53, so a document lifts its
sections from 0.60 (`docMin`, × 0.3) and admits loosely related ones
(≥ 0.58) from 0.70 (`docStrong`). The semantic rank weight grows ×5 per
unit above `semanticMin` (was ×10). Trust multipliers are now 1 / 0.5 /
0.4 (verified / needs-review / historical): the Wikibooks CPR and choking
pages scored 0.81 against the question and outranked the current Army
chapter at 0.73 until the multiplier was this strong; unreviewed text
still surfaces when nothing verified covers the topic. Result on the 197
on-topic coverage questions: 5 find nothing (eye foreign body, ham radio
basics, dirty bomb, garbage disposal, bartering — library gaps), 3 of 10
off-topic controls find something (cookies → Army baking, stock → sheep
"foundation stock", Eiffel → scout tower), down from 6.

## 2026-10-30 — Embedder: bge-base-en-v1.5 (MIT, 118 MB) replaces bge-small
bge-small (33M parameters) ranked "Planing the First End Square" for
"close a deep cut without stitches". bge-base (110M, 768 dims, CompendiumLabs
GGUF q8_0, sha256 ad1afe72…1173c) is bundled in `assets/models/` at build time
but not committed: at 118 MB it exceeds GitHub's file limit, so
`tools/fetch_models.sh` downloads and verifies it (sha256 above) after a
clone. Query embedding takes ~0.1–0.3 s on a phone CPU. Vectors stay int8 (~770 B per
section, ~4.9 MB total). Schema v7 nulls every stored passage vector
(dimension changed) and reinstalls bundled packs. The bundle grows by
~80 MB; still well under store limits.

## 2026-10-30 — Corpus cleaning in the builder
Of 7,280 sections, 993 were under 200 characters and ~200 were OCR noise
("UJ cc", "TAPED ON,", diagram labels from the scanned NWSS appendices) or
number-only table fragments; they polluted both indexes and filled the
passage budget with junk. `build_pack.py` now drops unreadable sections
(all-caps labels, < 40 % letters, dot leaders, > 30 % short non-words) and
merges fragments into a neighbour, keeping their heading as a bold line.
Result: 6,308 sections, every one ≥ 8 words or carrying an image. The
build prints each change for review. Also removed: ATP 3-90.99 "Living and
Staying Healthy in the Desert", whose page range had extracted the
fratricide-reduction appendix instead.

## 2026-10-30 — Graded chat eval
`tools/eval/scenarios.tsv` holds 34 realistic conversations with the key
points an instructor must cover (call 911, direct pressure, drop/cover/
hold…); `chat_eval_test.dart` runs them through the real controller,
search and model and writes `tools/eval/results/<label>.md` with a
key-point score, length, time, sources and the full replies. Keyword
scoring measures coverage of essentials, not prose; read the replies.
Results for this change (Qwen3-4B Q4_K_M on an Intel i9 CPU, no GPU):

| | before | after |
|---|---|---|
| mean key-point score | 83 % | 93 % |
| mean reply length | 535 chars | 1,426 chars |
| mean time per turn | 117 s | 322 s |
| replies with a "not in your library" line | 6 / 34 | 1 / 34 (the off-topic control, at the end) |

Replies went from "call a doctor" (for "we have no doctor") to warning
signs, hydration and what not to give; "I'm lost" from a boating-weather
citation to stop, shelter, layers, three whistle blasts and a ranger
station. Known weaknesses seen in the run, left for follow-up: the 4B
model doesn't branch on unknowns (choking: it assumed an unresponsive
casualty instead of covering conscious back blows/abdominal thrusts
first); trivial questions still get a numbered list; one citation came
out as a paragraph number ("[4-31]"); and the per-turn time is ~2.75×
the old pipeline's on this CPU, which is the price of a real answer and
must be measured on a phone (roadmap).

## 2026-10-30 — First-word latency on a phone: prompt size is the knob
On the Pixel Fold the first reply with the 6,500-character passage budget
and ~2,400-token prompt showed no first word after two minutes. The
llamadart bridge keeps no prompt cache, so every reply re-reads the whole
prompt on four CPU cores (~15–25 tokens/s). Changes: passage budget
4,000 characters / 5 passages, system prompt and citation rules trimmed
to ~400 tokens together, context back to 4096, earlier replies cut at 600
characters (prompt now ~1,450 tokens), and the query-rewrite pass runs
only when the user's own words find fewer than 3 passages or the message
is a short follow-up, since the aliases and document vectors already
handle most paraphrases. The eval numbers above were measured with the
larger budget; re-run `tools/eval` after device testing settles the
budget. Prompt caching in the bridge (or a 1.7B model) is the real fix.

## 2026-10-30 — Model catalog: three choices, Q4_0 by default, switchable
One minute to the first word on the Pixel Fold with the trimmed prompt is
still the phone's CPU reading ~1,450 tokens. The catalog now offers three
GGUFs and the AI model screen lists, downloads and switches between any of
them (several can be installed; one is active):
- **Qwen3 4B Instruct (fast)** — Q4_0 (2.4 GB, sha256 e0ba675d…13be2),
  recommended. llama.cpp repacks Q4_0 weights into its ARM dot-product /
  i8mm kernels, so prompt processing is far faster on phones than Q4_K_M
  for a small loss in wording quality.
- **Qwen3 4B Instruct (standard)** — the Q4_K_M build shipped before.
- **Qwen3 1.7B (small)** — Q4_0 (1.1 GB, sha256 c876f159…e81c5, Apache-2.0)
  for 6 GB phones: roughly half the wait, thinner answers; `enableThinking`
  stays off so the hybrid model answers directly.
Installs from the old single-entry catalog ("Qwen3 4B Instruct") are
recognised as the standard build so they aren't offered again.

## 2026-10-30 — Show the sources while the model is still reading
Retrieval takes a second or two; the model then reads for up to a minute.
The reply bubble now shows the passages it was given as tappable chips as
soon as they are known ("Reading from your library — tap to open"), or
says nothing matched, so the wait is useful and honest. When the reply
completes, the chips narrow to the passages the model actually cited, as
before.

## 2026-10-30 — Earlier replies keep their ending
A reply that ends with a clarifying question ("Do you have a whistle?")
was cut to its first 600 characters before being sent back as context, so
the question was exactly what the model lost, and "yes" made it answer the
original question all over again. `LlamaInferenceEngine.trimReply` now
keeps the opening and the last third of the budget (the ending) with the
middle elided, and the system prompt says to continue from an answered
question rather than repeat the steps.

## 2026-10-30 — Retrieval precision: relative similarity floor, confidence-gated rewrite
On the phone, "it's getting dark, I'm lost in the woods, what do I do first.
I have no cell service either" was answered with advice about cleaning
scrapes. The passages given were "Call 911 if you have cell phone
service", "Minor injuries like scrapes", "If someone in your group gets
injured": "cell", "service" and "first" are rare words in the library, so
the keyword coverage gate admitted them, they ranked above the STOP and
keep-warm passages, and the model covered what it was handed. Three
changes:
- Every hit now carries its cosine similarity to the question, and
  passages more than 0.12 below the best match are dropped
  (`KnowledgeSearch.relativeFloor`): incidental keyword hits ride along
  only when they are also close in meaning.
- The query rewrite also runs when the best direct match is below 0.72
  (`confidentSimilarity`), not only when fewer than 3 passages are found —
  a scenario phrased in the user's words rarely matches the library's.
- At most 3 passages / 3,500 characters go to the model: a 4B model given
  four passages covers all four.
Also: the builder no longer glues an intro ending in ":" ("For
children:") onto the unrelated section before it; it joins what follows.

## 2026-10-30 — Library batch 5: the 24-category audit and what filled the gaps
An audit against a 24-category survival taxonomy found 11 categories
strong, 9 partial, 3 thin (medicines, edible plants, long-term
homesteading) and 1 missing (general science). Seven new packs and one
extension fill the biggest holes, from sources we can ship; recipes in
`tools/packs/recipes/batch5_*.sh` hold every URL, licence line and
exclusion. The library is now 55 packs / ~7,220 sections.
- **otc-medicines** (16 docs, verified): Drug Facts panels for common
  over-the-counter medicines from DailyMed (NLM), one current label each,
  dosing tables rendered one row per line and checked against the label.
  Answers "how much ibuprofen" with a cited dose for the first time.
- **herbal-remedies** (30 docs, verified): NIH NCCIH "Herbs at a Glance",
  each page's safety section intact; each states it is public domain.
- **edible-plants** (3 docs, 135 sections, needs-review): FM 21-76 (1992)
  Chapter 9 edibility test and Appendices B/C, text only (the 1992
  edition's plant photographs carry individual photographer credits in
  the same book, so none shipped). Superseded manual; attribution says it
  is never proof a plant is safe to eat.
- **food-handling** (14 docs, verified): USDA FSIS jerky, smoking,
  freezing, shelf-stable storage, molds, leftovers, camping, emergencies,
  eggs. fsis.usda.gov blocks scripts; pages were read in the app's
  browser and hashed (batch3/4 CDC precedent). FSIS no longer publishes
  a wild-game handling page; nothing on hunting was found.
- **infant-feeding** (11 docs, verified): CDC's Infant and Young Child
  Feeding in Emergencies toolkit plus formula and bottle-cleaning pages,
  fetched in the browser. Cup-feeding page excluded (adapted from
  WHO/UNICEF).
- **ham-radio-basics** (10 docs, verified): the FCC's plain-language
  Amateur Radio Service pages (licensing, FAQ, exams, classes, call
  signs) and the Personal Radio Services pages (FRS, GMRS, CB, MURS),
  fetched in the browser. The CFR texts stay library-only.
- **practical-science** (13 docs, 165 sections, verified): OpenStax
  College Physics 2e and Chemistry 2e chapters on temperature, heat
  transfer, fluids, current and circuits, electrical safety, simple
  machines, solutions and dilution, reactions, gases, acids and bases,
  batteries. New `tools/packs/extract_openstax.py`.
- **household-historical** +2 docs: USDA FB 1334 Home Tanning (1923) and
  FB 1438 Making Fermented Pickles (1924), OCR checked word by word with
  every fix listed in the recipe.
- **home-energy** (18 docs, verified): DOE Energy Saver pages on
  insulation and where to put it, air sealing, caulking, weatherstripping,
  passive solar design, heating systems, wood and pellet stoves, space
  heaters, planning a solar electric system, grid-tied vs off-grid,
  balance-of-system equipment, solar water heaters, small wind and
  microhydro. Photo credits dropped (no images shipped).
- **vehicle-operation** +1 doc: TC 21-305-20 Ch. 12 jump starting with
  jumper cables (the cable order and the explosion warnings).
- **communications** +2 docs: TC 3-21.75 Section II radiotelephone
  procedure (rules, nets, message format, common messages, the prowords
  table as a figure) — only that section of the manual is used, since the
  rest is a combat-skills manual we exclude — and FAA AIM 4-2 radio
  technique with the ICAO phonetic alphabet, one line per letter.
  (ATP 6-02.53 turned out to hold no proword list; its antenna and
  adverse-conditions appendices were extracted and not shipped.)
Also: "field dress a deer / gutting / skinning and butchering" aliases
on the Army food chapter, which already covers preparing game. No
current federal page on fever care or choking first aid exists beyond
what is shipped (CDC "Caring for Someone Sick", Army airway chapter).
Blocked or not found: aphis.usda.gov and usda.gov (403; the APHIS
emergency pages are agency response material anyway — Ready.gov's pets
page already covers households), a current federal wild-game page, a
USDA-owned home-drying guide (USDA defers to a university site).

## 2026-10-30 — Licence calls made for batch 5 (owner's decision: ship)
- **DailyMed Drug Facts.** Labeling text is written by each manufacturer
  under FDA's OTC monograph and published by NLM, which states DailyMed
  content carries no copyright restriction. It is not a §105 government
  work in the strict sense and the pack names trade names (nominatively).
  Shipped as verified; a lawyer should confirm before commercial release,
  and the recipe can be re-pointed at store-brand labels.
- **OpenStax.** The live books were relicensed in 2026 to CC BY-NC-SA
  with a clause forbidding ingestion into generative AI systems. The pack
  uses the 2023 content versions OpenStax still serves from its archive,
  whose metadata and the 2022 PDF copyright page state CC BY 4.0, which
  is irrevocable for those versions. Attribution follows OpenStax's
  required form. Shipped on the owner's instruction; the publisher's
  stated intent cuts against AI use, so this is the pack to drop first
  if counsel objects.
- **FM 21-76 (1992).** Distribution A (text). Photographs excluded.

## 2026-10-30 — Photos in chat: a vision model, the same pipeline
Users can attach one photo per message (camera or gallery). Design:
- **Model.** The catalog offers Qwen3 VL 4B Instruct (Apache-2.0): the
  Q4_0 text weights (2.4 GB) plus the F16 multimodal projector (836 MB),
  downloaded one after the other with the same resume, size and SHA-256
  checks; `installed_models.projector_file_name` (schema v8) records the
  projector and `ModelStore.delete` removes both files. llamadart loads
  the pair as `LlamaModel(source, projector:)` and `EngineReady.canSeeImages`
  reports it. A text-only model stays usable for text.
- **Honesty.** A photo sent while a text-only model is active gets a
  `notice` saying the model can't see it and how to install one that can.
  The app never describes a photo it didn't look at.
- **Cost control.** Photos are resized to 768 px on the long side
  (image_picker) before storage; a vision model reads a photo as hundreds
  of tokens and each pass re-encodes it, so only the latest message's
  photo is sent as an image and earlier ones become "[Photo attached]"
  text. The query rewrite always runs when a photo is attached (the words
  rarely say what the photo shows), so a photo costs two vision passes:
  one to write the search queries, one to answer. Measure on device.
- **Storage.** Photos live in the app's `photos/` directory and messages
  store the file name (`messages.image_path`), as models do, so the
  container can move. Deleting a conversation does not yet delete its
  photos (roadmap).
- **iOS** needs camera and photo-library usage strings (added);
  image_picker needs no Android permission.

## 2026-11-02 — Passages are a check on the model's answer, not its source
Even after the instructor prompt, replies on the phone still led with the
library: whatever the search returned was paraphrased first and the
model's own knowledge filled in around it, so the answer was only as good
as the retrieval. Two causes. The passages were spliced into the user's
message ahead of the question ("Reference passages… My message: …"), and
a 4B model given notes before a question answers the notes. And the
instruction said to take specifics from the passages, which read as "base
the answer on them". Now `Grounding.apply` leaves the user's message
untouched and puts the numbered passages in the system turn, after a
rule that says: decide what you would tell this person from your own
expertise, then compare with the passages, and only where a passage gives
a different specific (amount, time, order, warning) use the passage's and
cite it. Doses and chemical amounts still come only from a passage, and
off-topic passages are still ignored silently. Citation chips are
unchanged ([n] in the reply). Checked against the graded eval before
shipping (`tools/eval/results/`).


## 2026-11-02 — A short answer to the assistant's question is not small talk
"I think it's 1%" after "what strength is your bleach?" had no topic word
of its own, so it took the small-talk path (no library lookup, no
grounding instruction) and the model gave the 5% dose from memory. Now
`Grounding.isSmallTalk` treats a term-less message as small talk only
when it has no digits and is either a pleasantry ("ok thanks") or does
not follow a reply that ended with a question. Anything else is a
follow-up: searched with the previous question, rewritten by the model,
and grounded — so the dose comes from the passage.

## 2026-11-02 — Keyword matches need a related document, not just a word
"Start a fire" pulled "Observation and Fields of Fire" from a terrain
chapter and "Prepping the Fire" from a woodstove page; "signal mirror"
pulled "Turning Left" from the driving manual (mirror checks). Each
section was close enough in meaning to pass the 0.55 section floor, but
its document scored 0.41–0.47 against the question where the right
chapter scored 0.58. `KnowledgeSearch._rank` now drops a keyword match
whose section is below `semanticMin` and whose document is below
`lexicalDocFloor` (0.50). Coverage audit: 14 of 256 questions changed,
all for the better or neutral; three off-topic questions ("best stock to
buy", "chocolate chip cookies", "Eiffel tower") now find nothing instead
of sheep, smokers and a scout tower.

## 2026-11-02 — The app picks the vision model for photos
Sending a photo while a text model was active produced a notice telling
the user to go and switch models. The owner's view: the app should know
which model to use. Now the user's chosen model is for everyday text, and
`visionEngineProvider` offers an engine for an installed vision model
whenever the active one can't see photos. `GenerationController.engineFor`
routes a conversation that contains a photo to it and keeps it there
(the vision model answers text as well, and every switch reloads a
model); new text conversations go back to the active model. The engine
not in use is released, so one model is in memory at a time. The notice
remains only when no vision model is installed at all.

## 2026-11-02 — Text goes to a text model, photos to a vision model, always
The phone still had the vision model set as the model for everything
(chosen before photo routing existed), and its text replies were worse:
a desert trench for a cold night in the woods, 911 tails. The owner's
rule: "if it needs only text use the text model, if there is an image
use the vision model; the user shouldn't need to switch." So the active
flag is now a preference within its kind, not a switch: `textModelOf`
answers text with the active model if it is text-only, otherwise the
largest installed text-only model; `visionModelOf` answers photos with
the active model if it can see, otherwise the largest installed vision
model. A lone vision model still answers everything. The models screen
says what each model does ("Answers text", "Answers photos", "Tap to use
for text"). Tapping sets the preference, and the other kind falls back
to its default.


## 2026-11-02 — Show the pictures: figures under every reply
The product promise is to show someone what they're looking at and how
to do the task, and the library already holds 704 figures and tables
(shelters, knots, splints, fire lays, navigation, canning). They were
shown only under passages the reply cited with [n], and since the model
now cites only specifics that differ from its own answer, that was
almost never. Now `_Sources` shows every passage the reply was checked
against (cited ones numbered, first) and `_CitedImages` their figures
and tables, with "Checked against your library" when nothing was cited
and "Not from the offline library" only when no passage was given.
Figure and table captions are indexed with the document title in
`passages_fts` (schema v9) and count toward keyword coverage, so a
question can find a section by what its picture shows. The grounding
rule tells the model the user sees those figures, so it can point to one
by caption. Section vectors still embed body text only; re-embedding
with captions is a later, measured change.

## 2026-11-02 — Offline maps: MapLibre drawing Protomaps regions from the phone
The owner moved the navigation milestone ahead of downloads, preparedness
and emergency mode. First cut, with no network code at all:
- **Renderer:** `maplibre_gl` 0.27 (MapLibre Native 13.5 on Android, 6.28
  on iOS), which reads a PMTiles archive on the phone directly as
  `pmtiles://file://<path>`. Bundled assets can't be used for tiles (the
  asset reader has no byte ranges), so regions live in the app's `maps/`
  directory like models do.
- **Tiles:** Protomaps basemap builds (OpenStreetMap data, ODbL Produced
  Work; attribution "© OpenStreetMap contributors · Protomaps" is drawn on
  the map and in the regions screen). A region is cut from the daily
  planet build on a computer with `tools/maps/extract_region.sh` (the
  `pmtiles` CLI) and imported from a file, exactly like a GGUF model.
  Downloading regions in the app waits for the download manager
  (milestone 4), which will reuse `MapStore.import`.
- **Style:** the Protomaps basemap layers (BSD-3, dark flavor, English
  labels) generated once by `tools/maps/build_style.mjs` into
  `assets/maps/layers-dark.json`; `buildMapStyle` repeats them per
  installed region. Fonts (Noto, OFL; Latin glyph ranges only for now)
  and sprites (BSD-3) are bundled and copied beside the regions on first
  use, because the renderer loads them as `file://` paths.
- **Position:** `geolocator` for permission and fixes (asked only when
  the Navigation tool opens, never at startup; the permission text says
  the location never leaves the phone), MapLibre's own puck for the dot
  and compass heading. The screen talks to a `LocationSource` interface
  so it is tested with a fake.
- **Not yet:** contour lines and hillshade (the basemap has none),
  magnetic declination (headings are what the platform reports), UTM/MGRS
  grids, routes and waypoints, and in-app downloads.

## 2026-11-03 — Map regions download straight from the Protomaps planet build
The owner asked why a region had to be made on a computer when models
download in the app. Now Settings → Offline maps → Download a region
(`MapDownloadScreen`) does it on the phone:
- The phone does what `pmtiles extract` does (`RegionDownload`): reads
  the planet's 127-byte header, root directory and the leaf directories
  that cover the area (a few hundred KB), then fetches only the tile byte
  ranges, joining neighbours closer than 128 KB into one request, and
  writes a fresh clustered archive through `MapStore.import`. The size
  shown before downloading is exact. A dropped connection resumes from
  the last byte (`HttpRangeReader`), like the model downloader.
- Source: the newest `https://build.protomaps.com/YYYYMMDD.pmtiles` of
  the last week (one HEAD per day back). This is the second and last
  network use after `ModelDownload`; it runs only when the user taps Check
  size or Download. Nothing is hosted for the app: pre-cut regions would
  mean multi-GB files to keep fresh, and the build server is what
  Protomaps' own CLI reads from. User agent `offgrid-ai`.
- Picking an area: pan the map until the area fills it, choose a detail
  level (deepest zoom 12, 14 or 15), Check size, Download. Over 300,000
  tiles the app asks to zoom in rather than start a multi-GB job.
- `assets/maps/world.pmtiles` (planet zoom 0–5, 15 MB) is bundled and
  copied with the fonts, so the map always shows coastlines, countries
  and big cities, the picker has something to frame on, and the
  navigation screen never sits empty. Refresh it with
  `pmtiles extract https://build.protomaps.com/<build>.pmtiles
  assets/maps/world.pmtiles --maxzoom=5` and bump `mapAssetsVersion`.
- The PMTiles reader/writer (`lib/features/maps/domain/pmtiles.dart`) is
  checked against an archive the Protomaps CLI made
  (`test/fixtures/smokies_z10-12.pmtiles`): same Hilbert tile ids, same
  directory encoding, and `pmtiles verify` accepts what the app writes.
- Screens talk to the map through `MapHandle`, not the MapLibre
  controller, so the download and navigation screens are widget-tested
  with a fake map.
