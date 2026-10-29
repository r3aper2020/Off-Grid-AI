# OFFGRID AI

Offline-first mobile AI assistant (iOS + Android, Flutter). Emergency
preparedness is the first specialty, but the core is a general assistant that
works with no internet, cellular service, or cloud.

Read before changing code: `docs/architecture.md`, `docs/decisions.md`,
`docs/roadmap.md`. Work one milestone at a time; don't build features from a
later milestone early.

## Non-negotiables

- **Offline after setup.** No network calls on startup or in any core flow.
  The release Android manifest has no `INTERNET` permission; adding it is a
  decision that goes in `docs/decisions.md` (only for the optional download
  manager, Milestone 4).
- **Never fake an answer.** If no model, no source, or no data exists, say so
  plainly. App-generated assistant text is stored as `MessageStatus.notice`
  and is never fed back to a model.
- **The app must stay usable without a model.** Library, tools, and
  emergency content cannot depend on AI.
- **UI depends on interfaces, not engines.** Chat talks to
  `InferenceEngine` (`lib/features/chat/domain/`), never to llama.cpp directly.

## Commands

```bash
flutter pub get
dart run build_runner build        # after changing Drift tables
flutter analyze
flutter test
```

## Conventions

- Feature-first layout: `lib/features/<feature>/{domain,data,presentation}`.
- State and DI: Riverpod (plain providers, no codegen). Tests override
  `databaseProvider` with `testDatabase()` from `test/support/`.
- Routing: GoRouter in `lib/app/router.dart`; tabs are a
  `StatefulShellRoute`. Full-screen routes use `parentNavigatorKey: _rootKey`.
- Colors only from `AppColors`; no inline hex values in widgets.
- Drift enums are stored by name — never rename enum values; add new ones.
- Bump `schemaVersion` and add a migration for any table change.
- In widget tests, call `tester.pump()` after `enterText` before tapping a
  button whose enabled state depends on the text.
