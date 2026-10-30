import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';
import 'package:offgrid_ai/features/library/domain/passage_vectors.dart';
import 'package:offgrid_ai/features/library/domain/text_embedder.dart';

import '../../support/test_db.dart';

final fixture = File('test/fixtures/test_pack.json').readAsStringSync();

/// Unit vector along axis [i].
List<double> axis(int i) => [
  for (var k = 0; k < PassageVectors.dim; k++) k == i ? 1.0 : 0.0,
];

/// Maps "kit" questions to axis 1 (the "Storing water" section's meaning).
class FakeEmbedder implements TextEmbedder {
  @override
  Future<List<double>?> embedQuery(String text) async =>
      text.contains('kit') ? axis(1) : axis(9);
}

void main() {
  late AppDatabase db;
  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  /// Vectors for the fixture's sections: section k gets axis k.
  List<int> hashes() => [
    for (final d in PackData.fromJson(jsonDecode(fixture)).documents)
      for (final s in d.sections) PassageVectors.sectionHash(s.heading, s.body),
  ];

  test('vectors round-trip through the file format', () {
    final v = [for (var k = 0; k < PassageVectors.dim; k++) sin(k.toDouble())];
    final norm = sqrt(v.fold(0.0, (a, x) => a + x * x));
    final unit = [for (final x in v) x / norm];
    final bytes = PassageVectors.encode([(42, unit)]);
    final decoded = PassageVectors.decode(bytes)!;
    expect(decoded.single.$1, 42);
    // int8 storage: a unit vector's self-similarity stays close to 1.
    expect(
      PassageVectors.similarity(decoded.single.$2, decoded.single.$2),
      closeTo(1, 0.05),
    );
    expect(PassageVectors.decode(bytes.sublist(0, 20)), isNull);
  });

  test('a question in different words finds the passage by meaning', () async {
    final h = hashes();
    await PackInstaller(db).install(
      fixture,
      source: 'test',
      vectors: PassageVectors.encode([
        for (final (k, hash) in h.indexed) (hash, axis(k)),
      ]),
    );
    final search = KnowledgeSearch(db, embedder: FakeEmbedder());
    // No keyword in common with "Keep stored water in clean sealed
    // containers…", but its vector matches.
    final hits = await search.forQuestion('what belongs in a disaster kit');
    expect(hits.first.heading, 'Storing water');
    // Without an embedder, keywords alone find nothing.
    expect(
      await KnowledgeSearch(db).forQuestion('what belongs in a disaster kit'),
      isEmpty,
    );
  });

  test('vectors for changed sections are ignored, not misattached', () async {
    await PackInstaller(db).install(
      fixture,
      source: 'test',
      vectors: PassageVectors.encode([
        for (var k = 0; k < hashes().length; k++) (k + 1, axis(k)),
      ]),
    );
    final rows = await db.select(db.passages).get();
    expect(rows.every((p) => p.embedding == null), isTrue);
  });

  test('weak semantic matches are not used as sources', () async {
    final h = hashes();
    await PackInstaller(db).install(
      fixture,
      source: 'test',
      vectors: PassageVectors.encode([
        for (final (k, hash) in h.indexed) (hash, axis(k)),
      ]),
    );
    final search = KnowledgeSearch(db, embedder: FakeEmbedder());
    // Axis 9 matches no section (similarity 0).
    expect(await search.forQuestion('quantum computing basics'), isEmpty);
  });
}
