import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'data/knowledge_search.dart';
import 'data/library_repository.dart';
import 'domain/pack_format.dart';

final packProvider = FutureProvider.family<KnowledgePack?, String>(
  (ref, id) => ref.watch(libraryRepositoryProvider).pack(id),
);

final packDocumentsProvider = FutureProvider.family<List<PackDocument>, String>(
  (ref, packId) => ref.watch(libraryRepositoryProvider).documents(packId),
);

/// A document with its sections and pack, for the reader.
final documentProvider =
    FutureProvider.family<
      ({PackDocument doc, KnowledgePack? pack, List<Passage> passages})?,
      int
    >((ref, id) async {
      final repo = ref.watch(libraryRepositoryProvider);
      final doc = await repo.document(id);
      if (doc == null) return null;
      return (
        doc: doc,
        pack: await repo.pack(doc.packId),
        passages: await repo.passages(id),
      );
    });

final librarySearchProvider = FutureProvider.family<List<PassageHit>, String>(
  (ref, query) => ref.watch(knowledgeSearchProvider).search(query),
);

/// Passages behind a message's citations, keyed by the stored JSON list.
/// Entries for passages since removed (pack uninstalled) are null.
final citationSourcesProvider =
    FutureProvider.family<List<PassageHit?>, String>((ref, json) async {
      final ids = (jsonDecode(json) as List).cast<int>();
      return ref.watch(knowledgeSearchProvider).byIds(ids);
    });

/// Figures and tables for the cited passages (their own, plus ones their
/// text refers to by number), keyed by comma-separated passage ids.
final citedFiguresProvider = FutureProvider.family<List<SectionImage>, String>((
  ref,
  key,
) async {
  final search = ref.watch(knowledgeSearchProvider);
  final ids = [for (final s in key.split(',')) int.parse(s)];
  final hits = (await search.byIds(ids)).whereType<PassageHit>().toList();
  return search.figuresFor(hits);
});
