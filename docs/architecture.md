# Architecture

## Layers

```
Flutter UI (Chat · Library · Tools · Settings)
        │  Riverpod providers
        ▼
Feature domain interfaces
  InferenceEngine        (chat)          — LlamaInferenceEngine (llamadart)
  ModelStore             (models)        — imported GGUF files + registry
  LibraryRepository      (library)       — Milestone 3: FTS5 retrieval
  (preparedness, emergency, navigation)  — later milestones
        │
        ▼
Local storage (app-private)
  SQLite via Drift · GGUF model files · knowledge packs · map data
        ┊
Optional internet (Milestone 4+): model/pack downloads only.
Never required after setup.
```

## Source layout

```
lib/
  main.dart                  boot: open DB, recover interrupted replies, run app
  app/                       MaterialApp, GoRouter, tab shell, theme tokens
  core/
    database/                Drift schema (AppDatabase) + generated code
    providers.dart           databaseProvider (overridden in tests)
    widgets/                 ScreenHeader, OfflineBadge, TopoBackground
  features/
    chat/
      domain/                InferenceEngine contract, GenerationEvent stream
      data/                  ChatRepository, NoModelEngine
      presentation/          home, conversation, history, composer
      chat_providers.dart    providers + GenerationController
    library/                 pack registry + Library screen
    tools/                   Tools list + Navigation shell
    models/                  ModelStore (import/activate/delete), AI model screen
    settings/                status overview, data controls
```

## Data model (schema v2)

| Table | Purpose |
|---|---|
| `conversations` | Chat threads; title from first user message |
| `messages` | `role` (user/assistant/system), `status` (complete/streaming/cancelled/failed/notice); cascades on conversation delete |
| `installed_models` (v2) | Imported GGUF files: file name in `models/`, size, `isActive` (at most one) |
| `knowledge_packs` | Installed-pack registry (id, category, format, version, size, path). Passages/FTS tables arrive in Milestone 3 |

## Chat generation flow

1. Screen calls `GenerationController.reply(conversationId)`.
2. Controller asks `InferenceEngine.status()`. If unavailable, it stores the
   reason as a `notice` message and stops.
3. Otherwise it builds history from `complete` messages only, inserts an
   empty `streaming` assistant message, and subscribes to `generate()`.
4. Tokens accumulate in memory and flush to SQLite every ~120 ms; the UI
   watches the messages stream.
5. Done → `complete`; failure → `failed`; Stop → subscription cancelled,
   partial text kept as `cancelled`. On next launch any leftover
   `streaming` rows become `cancelled` (app was killed mid-reply).

Cancelling the subscription is the engine's signal to stop computing; the
Milestone 2 engine must honor that promptly.
