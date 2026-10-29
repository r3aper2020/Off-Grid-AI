import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';

import '../../support/test_db.dart';

final fixture = File('test/fixtures/test_pack.json').readAsStringSync();

void main() {
  late AppDatabase db;
  late PackInstaller installer;
  late KnowledgeSearch search;

  setUp(() async {
    db = testDatabase();
    installer = PackInstaller(db);
    search = KnowledgeSearch(db);
    await installer.install(fixture, source: 'test');
  });
  tearDown(() => db.close());

  group('install', () {
    test('stores pack, documents and passages', () async {
      final pack = await db.select(db.knowledgePacks).getSingle();
      expect(pack.title, 'Test Fixture Pack');
      expect(await db.select(db.packDocuments).get(), hasLength(2));
      expect(await db.select(db.passages).get(), hasLength(4));
    });

    test('reinstalling replaces instead of duplicating', () async {
      await installer.install(fixture, source: 'test');
      expect(await db.select(db.passages).get(), hasLength(4));
      expect(await search.search('boil'), hasLength(1));
    });

    test('uninstall removes passages from the search index', () async {
      await installer.uninstall('test-fixture');
      expect(await db.select(db.passages).get(), isEmpty);
      expect(await search.search('boil'), isEmpty);
    });

    test('rejects malformed packs without touching the library', () async {
      final bad = jsonDecode(fixture) as Map<String, Object?>;
      bad['documents'] = <Object>[];
      await expectLater(
        installer.install(jsonEncode(bad), source: 'test'),
        throwsA(isA<PackFormatException>()),
      );
      await expectLater(
        installer.install('not json', source: 'test'),
        throwsA(isA<PackFormatException>()),
      );
      expect(await db.select(db.passages).get(), hasLength(4));
    });

    test('a pack without a review status is treated as needs-review', () {
      final pack = PackData.fromJson(jsonDecode(fixture));
      expect(pack.reviewStatus, ReviewStatus.needsReview);
    });

    test('rejects an unknown review status', () {
      final bad = jsonDecode(fixture) as Map<String, Object?>;
      bad['review'] = 'trust-me';
      expect(() => PackData.fromJson(bad), throwsA(isA<PackFormatException>()));
    });

    test('rejects packs from a newer format', () {
      final future = jsonDecode(fixture) as Map<String, Object?>;
      future['formatVersion'] = 99;
      expect(
        () => PackData.fromJson(future),
        throwsA(isA<PackFormatException>()),
      );
    });
  });

  group('search', () {
    test('stemming matches word forms', () async {
      final hits = await search.search('boiled');
      expect(hits.single.heading, 'Boiling water');
      expect(hits.single.documentTitle, 'Fixture Water Guide');
      expect(hits.single.snippet, contains('['));
    });

    test('heading matches rank first', () async {
      final hits = await search.search('fire');
      expect(hits.first.heading, contains('fire'));
    });

    test('user input cannot break the FTS query', () async {
      for (final q in ['"', 'water AND', 'NEAR(', '*', 'boil OR "']) {
        await search.search(q);
        await search.forQuestion(q);
      }
    });

    test('stopword-only questions find nothing', () async {
      expect(await search.forQuestion('how do I do it?'), isEmpty);
    });
  });

  group('forQuestion', () {
    test('finds the passage that answers the question', () async {
      final hits = await search.forQuestion('How long should I boil water?');
      expect(hits.first.heading, 'Boiling water');
    });

    test('a single shared common word is not enough', () async {
      // Shares only "water" with the library.
      final hits = await search.forQuestion(
        'Is sparkling water bad for teeth?',
      );
      expect(hits, isEmpty);
    });

    test('unrelated questions find nothing', () async {
      expect(
        await search.forQuestion('What is the capital of France?'),
        isEmpty,
      );
    });

    test('describing the situation does not hide the topic', () async {
      final hits = await search.forQuestion(
        "How do I boil water? I'm stuck in the middle of nowhere",
      );
      expect(hits.first.heading, 'Boiling water');
    });

    test('a word in the heading outweighs a passing mention', () async {
      await installer.install(
        jsonEncode({
          'format': 'offgrid-pack',
          'formatVersion': 1,
          'id': 'bears',
          'title': 'Wildlife',
          'description': 'TEST FIXTURE',
          'category': 'guide',
          'version': '1',
          'publisher': 'tests',
          'license': 'Test data',
          'documents': [
            {
              'title': 'Animals',
              'sections': [
                {'heading': 'Bear encounters', 'body': 'Back away slowly.'},
                {'heading': 'Splints', 'body': 'Do not bear weight on it.'},
                {'heading': 'Skin', 'body': 'Wash after skin contact.'},
              ],
            },
          ],
        }),
        source: 'test',
      );
      // "contact" is the rarer word, but only "bear" names a section.
      final hits = await search.forQuestion("I'm in contact with a bear");
      expect(hits.map((h) => h.heading), contains('Bear encounters'));
    });

    test('a short follow-up is read with the question before it', () async {
      final hits = await search.forMessage(
        'with water?',
        previous: 'How do I put out a fire?',
      );
      expect(hits.first.heading, 'Putting out a fire');
    });

    test('a change of topic does not bring back the old topic', () async {
      final hits = await search.forMessage(
        'storing water',
        previous: 'How do I build a campfire?',
      );
      expect(hits.first.heading, 'Storing water');
      expect(
        hits.map((h) => h.heading),
        isNot(contains('Building a campfire')),
      );
    });

    test('byIds keeps citation order', () async {
      final all = await search.search('water fire');
      final ids = all.map((h) => h.passageId).toList().reversed.toList();
      final hits = await search.byIds(ids);
      expect(hits.map((h) => h!.passageId), ids);
    });

    test('byIds keeps positions when a cited passage is gone', () async {
      final first = (await search.search('boil')).single.passageId;
      final hits = await search.byIds([999999, first]);
      expect(hits[0], isNull);
      expect(hits[1]!.passageId, first);
    });
  });

  group('figuresFor', () {
    Map<String, Object> image(String n, String caption) => {
      'asset': 'assets/packs/images/$n.webp',
      'caption': caption,
      'kind': 'figure',
    };

    setUp(() async {
      await installer.install(
        jsonEncode({
          'format': 'offgrid-pack',
          'formatVersion': 1,
          'id': 'figures',
          'title': 'Figures',
          'description': 'TEST FIXTURE',
          'category': 'guide',
          'version': '1',
          'publisher': 'tests',
          'license': 'Test data',
          'documents': [
            {
              'title': 'Manual A',
              'sections': [
                {
                  'heading': 'Fire lays',
                  'body': 'Build a tepee fire lay (Figure 5-5).',
                },
                {
                  'heading': 'Star fire',
                  'body': 'Push logs inward. {{img:0}}',
                  'images': [image('a-5-5', 'Figure 5-5. Fire lays')],
                },
              ],
            },
            {
              'title': 'Manual B',
              'sections': [
                {
                  'heading': 'Other',
                  'body': 'Unrelated. {{img:0}}',
                  'images': [image('b-5-5', 'Figure 5-5. Something else')],
                },
              ],
            },
          ],
        }),
        source: 'test',
      );
    });

    test(
      'includes figures the text refers to, from the same document only',
      () async {
        final hit = (await search.search('tepee')).single;
        final figures = await search.figuresFor([hit]);
        expect(figures.map((f) => f.asset), ['assets/packs/images/a-5-5.webp']);
      },
    );

    test('lists each figure once', () async {
      final lays = (await search.search('tepee')).single;
      final star = (await search.search('inward')).single;
      final figures = await search.figuresFor([star, lays]);
      expect(figures, hasLength(1));
    });
  });
}
