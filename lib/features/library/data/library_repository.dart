import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../domain/text_embedder.dart';
import 'knowledge_search.dart';
import 'pack_installer.dart';

class LibraryRepository {
  LibraryRepository(this._db);
  final AppDatabase _db;

  /// Installed packs, optionally limited to one [category].
  Stream<List<KnowledgePack>> watchPacks({PackCategory? category}) {
    final query = _db.select(_db.knowledgePacks)
      ..orderBy([(p) => OrderingTerm.asc(p.title)]);
    if (category != null) {
      query.where((p) => p.category.equalsValue(category));
    }
    return query.watch();
  }

  Future<KnowledgePack?> pack(String id) => (_db.select(
    _db.knowledgePacks,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<PackDocument>> documents(String packId) =>
      (_db.select(_db.packDocuments)
            ..where((d) => d.packId.equals(packId))
            ..orderBy([(d) => OrderingTerm.asc(d.position)]))
          .get();

  Future<PackDocument?> document(int id) => (_db.select(
    _db.packDocuments,
  )..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<List<Passage>> passages(int documentId) =>
      (_db.select(_db.passages)
            ..where((p) => p.documentId.equals(documentId))
            ..orderBy([(p) => OrderingTerm.asc(p.position)]))
          .get();
}

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(databaseProvider)),
);

final knowledgeSearchProvider = Provider<KnowledgeSearch>(
  (ref) => KnowledgeSearch(
    ref.watch(databaseProvider),
    embedder: ref.watch(textEmbedderProvider),
  ),
);

/// Semantic search model. Keyword-only unless overridden at startup
/// (main.dart supplies the bundled model); tests keep the default.
final textEmbedderProvider = Provider<TextEmbedder>(
  (ref) => const NoTextEmbedder(),
);

final packInstallerProvider = Provider<PackInstaller>(
  (ref) => PackInstaller(ref.watch(databaseProvider)),
);

/// Progress of installing the bundled references after an app update:
/// null when idle/done, otherwise (done, total) packs.
final librarySyncProvider =
    NotifierProvider<LibrarySync, ({int done, int total})?>(LibrarySync.new);

class LibrarySync extends Notifier<({int done, int total})?> {
  @override
  ({int done, int total})? build() => null;

  /// Installs/updates bundled packs in the background. The app is usable
  /// meanwhile; search simply covers the packs installed so far.
  Future<void> run(AssetBundle bundle) async {
    try {
      await ref
          .read(packInstallerProvider)
          .syncBundled(
            bundle,
            onProgress: (done, total) {
              state = done < total ? (done: done, total: total) : null;
            },
          );
    } finally {
      state = null;
    }
  }
}

final packsProvider = StreamProvider.family<List<KnowledgePack>, PackCategory?>(
  (ref, category) =>
      ref.watch(libraryRepositoryProvider).watchPacks(category: category),
);
