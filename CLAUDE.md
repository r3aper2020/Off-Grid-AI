# OFFGRID AI

Offline-first mobile AI assistant (iOS + Android, Flutter). Emergency
preparedness is the first specialty, but the core is a general assistant that
works with no internet, cellular service, or cloud.

Read before changing code: `docs/vision.md`, `docs/architecture.md`, `docs/decisions.md`,
`docs/roadmap.md`. Work one milestone at a time; don't build features from a
later milestone early.

## Non-negotiables

- **Offline after setup.** No network calls on startup or in any core flow.
  The only network code is `ModelDownload`
  (`lib/features/models/data/model_downloader.dart`) and `RegionDownload`
  (`lib/features/maps/data/region_download.dart`), run only when the user
  taps Download. Any new network use needs an entry in `docs/decisions.md`.
- **Never fake an answer.** If no model, no source, or no data exists, say so
  plainly. App-generated assistant text is stored as `MessageStatus.notice`
  and is never fed back to a model. The model answers as the instructor
  and cites library passages as evidence (see `Grounding`); doses and
  chemical amounts only ever come from a passage.
- **The app must stay usable without a model.** Library, tools, and
  emergency content cannot depend on AI.
- **UI depends on interfaces, not engines.** Chat talks to
  `InferenceEngine` (`lib/features/chat/domain/`), never to llama.cpp directly.

## Commands

```bash
flutter pub get
tools/fetch_models.sh              # once after cloning: bundled embedder (not in git)
dart run build_runner build        # after changing Drift tables
flutter analyze
flutter test
for d in content/*/; do python3 tools/packs/build_pack.py "$d"; done   # rebuild packs
flutter test tools/embed/embed_packs_test.dart                          # then rebuild vectors
flutter test tools/coverage/coverage_report_test.dart                   # retrieval audit
CHAT_MODEL=~/.cache/offgrid/Qwen3-4B-Instruct-2507-Q4_K_M.gguf EVAL_LABEL=x \
  flutter test tools/eval/chat_eval_test.dart                           # graded chat eval
tools/maps/extract_region.sh <name> <minLon> <minLat> <maxLon> <maxLat>  # offline map region
```

Don't run two `flutter test` processes in this checkout at once: they
share `build/native_assets` and the llama.cpp library gets clobbered.

## Conventions

- Feature-first layout: `lib/features/<feature>/{domain,data,presentation}`.
- State and DI: Riverpod (plain providers, no codegen). Tests override
  `databaseProvider` with `testDatabase()` from `test/support/`.
- Routing: GoRouter in `lib/app/router.dart`; tabs are a
  `StatefulShellRoute`. Full-screen routes use `parentNavigatorKey: _rootKey`.
- Colors only from `AppColors`; no inline hex values in widgets.
- Drift enums are stored by name — never rename enum values; add new ones.
- Library text is verbatim; the only authored text is each document's
  `Aliases:` line (retrieval-only, never shown). Every bundled document
  needs one.
- Bump `schemaVersion` and add a migration for any table change.
- In widget tests, call `tester.pump()` after `enterText` before tapping a
  button whose enabled state depends on the text. File and asset I/O never
  completes inside a `testWidgets` body (fake async): wrap it in
  `tester.runAsync` or override the provider that does it.
