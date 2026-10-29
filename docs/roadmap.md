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
