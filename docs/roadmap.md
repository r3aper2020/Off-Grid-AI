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

## 2. On-device AI
- Pick and vet a llama.cpp bridge that runs on both iOS and Android with a
  compatible license; record the choice in `decisions.md`.
- `LlamaEngine implements InferenceEngine`: load GGUF from app storage,
  stream tokens, stop on subscription cancel, run off the UI isolate.
- Chat template per model, context window trimming.
- Memory guardrails: refuse or unload on low memory; clear errors for
  corrupt/unsupported files.
- Sideload a GGUF for testing (download manager comes in M4).
- Measure tokens/sec, RAM, and battery on real devices.

## 3. Offline knowledge engine
Knowledge-pack format, import into SQLite FTS5, Library search, retrieval
into prompts, citations that open the exact local passage, "no source found"
behavior. Bundled starter guides that work with no model installed.

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
