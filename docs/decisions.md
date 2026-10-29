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
