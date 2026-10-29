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
