# Architecture

## Layers

```
Flutter UI (Chat · Library · Tools · Settings)
        │  Riverpod providers
        ▼
Feature domain interfaces
  InferenceEngine        (chat)          — LlamaInferenceEngine (llamadart)
  ModelStore             (models)        — imported GGUF files + registry
  KnowledgeSearch        (library)       — SQLite FTS5 search + retrieval
  PackInstaller          (library)       — installs knowledge packs
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
    library/                 packs, FTS5 search, Library/pack/reader/search UI
    tools/                   Tools list + Navigation shell
    models/                  ModelStore (import/activate/delete), AI model screen
    settings/                status overview, data controls
```

## Data model (schema v7)

| Table | Purpose |
|---|---|
| `conversations` | Chat threads; title from first user message |
| `messages` | `role` (user/assistant/system), `status` (complete/streaming/cancelled/failed/notice); cascades on conversation delete |
| `installed_models` (v2) | Imported GGUF files: file name in `models/`, size, `isActive` (at most one); v8 `projectorFileName` for vision models |
| `knowledge_packs` (v3) | Installed packs: metadata, publisher, license, attribution, source |
| `pack_documents` (v3) | Documents in a pack, with source URL; v7 adds retrieval-only `aliases`, `libraryOnly` (never given to the model) and a document `embedding` |
| `passages` (v3) | Sections: the unit searched, given to the model and cited; v5 `images`, v6 `embedding` (int8 vector) |
| `passages_fts` (v3) | FTS5 index over passages (porter stemming) and their document's title + aliases, synced by triggers |
| `messages.citations` (v3) | JSON passage ids given to the model for a reply; `[]` = searched, nothing matched |
| `messages.imagePath` (v8) | Photo attached to a user message: file name in the app's `photos/` directory |

## Chat generation flow

1. Screen calls `GenerationController.reply(conversationId)`.
2. Controller asks `InferenceEngine.status()`. If unavailable, it stores the
   reason as a `notice` message and stops.
3. Otherwise it builds history from `complete` messages only. The model
   first rewrites the latest message into 2–3 search queries
   (`InferenceEngine.complete` with `Grounding.rewriteTurns`; follow-ups
   are resolved against the previous exchange). The user's words plus the
   rewrites go through `KnowledgeSearch.forQueries` (keyword BM25 gated by
   IDF coverage, fused with section- and document-level meaning vectors;
   library-only documents excluded; split parts and sub-sections pulled
   in; near-duplicates dropped). `Grounding.select` keeps whole passages
   within ~6,500 characters (at most 8) and `Grounding.apply` attaches
   them, numbered, with the citation rules (or the "answer from your own
   knowledge" rule when nothing matched). It inserts an empty `streaming`
   assistant message recording those passage ids, and subscribes to
   `generate()`.
4. Tokens accumulate in memory and flush to SQLite every ~120 ms; the UI
   watches the messages stream.
5. Done → `complete`; failure → `failed`; Stop → subscription cancelled,
   partial text kept as `cancelled`. On next launch any leftover
   `streaming` rows become `cancelled` (app was killed mid-reply).

The reply bubble shows a chip for each `[n]` the model actually cited
(opening the passage in the reader), or "Not from the offline library"
when it cited nothing.

Cancelling the subscription is the engine's signal to stop computing; the
Milestone 2 engine must honor that promptly.
