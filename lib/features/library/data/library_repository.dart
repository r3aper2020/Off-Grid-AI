import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';

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
}

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(databaseProvider)),
);

final packsProvider = StreamProvider.family<List<KnowledgePack>, PackCategory?>(
  (ref, category) =>
      ref.watch(libraryRepositoryProvider).watchPacks(category: category),
);
