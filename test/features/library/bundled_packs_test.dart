import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/chat/domain/grounding.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';
import 'package:offgrid_ai/features/library/domain/passage_vectors.dart';

import '../../support/test_db.dart';

/// Retrieval checks against the real bundled library: realistic questions
/// must surface the right passage, and what reaches the model must still
/// contain the safety-critical details.
void main() {
  late AppDatabase db;
  late KnowledgeSearch search;

  final packs = Directory('assets/packs')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  setUpAll(() {
    expect(packs, isNotEmpty, reason: 'no bundled packs found');
  });

  setUp(() async {
    db = testDatabase();
    search = KnowledgeSearch(db);
    final installer = PackInstaller(db);
    for (final f in packs) {
      await installer.install(f.readAsStringSync(), source: 'test');
    }
  });
  tearDown(() => db.close());

  /// The passages the model would actually receive.
  Future<List<PassageHit>> given(String q) async =>
      Grounding.select(await search.forQuestion(q));

  Future<void> expectAnswerHas(
    String question,
    List<String> mustContain,
  ) async {
    final hits = await given(question);
    expect(hits, isNotEmpty, reason: 'nothing found for "$question"');
    final text = hits.map((h) => '${h.heading}\n${h.body}').join('\n');
    for (final s in mustContain) {
      expect(text, contains(s), reason: '"$question" lacks "$s"');
    }
  }

  test('every bundled pack installs and every section is searchable', () async {
    final passages = await db.select(db.passages).get();
    expect(passages.length, greaterThan(1500));
    for (final p in passages) {
      expect(p.body.trim(), isNotEmpty, reason: p.heading);
      expect(p.body.length, lessThanOrEqualTo(4000), reason: p.heading);
    }
  });

  test('bleach dosing keeps volumes with amounts', () async {
    await expectAnswerHas(
      'How much bleach do I add to a gallon of water to make it safe to drink?',
      [
        '1 gallon of water',
        'Add 8 drops of bleach',
        'Let the water stand for at least 30 minutes',
      ],
    );
  });

  test('boiling time includes the altitude rule', () async {
    await expectAnswerHas('How long should I boil water to make it safe?', [
      'rolling boil for 1 minute',
      '6,500 feet',
    ]);
  });

  test('contaminated water warning is reachable', () async {
    await expectAnswerHas(
      'Can I boil water that has fuel or chemicals in it?',
      ['cannot make water containing fuel'],
    );
  });

  test('fridge and freezer limits during a power outage', () async {
    await expectAnswerHas(
      'How long will food stay safe in the fridge when the power is out?',
      ['4 hours in a refrigerator', '48 hours in a full freezer'],
    );
  });

  /// Case-insensitive check across all passages the model receives, so
  /// tests assert the safety instruction, not one source's wording.
  Future<String> givenText(String q) async =>
      (await given(q))
          .map((h) => '${h.heading}\n${h.body}')
          .join('\n')
          .toLowerCase();

  test('hypothermia first aid covers wet clothing and warming', () async {
    final text = await givenText(
      'What should I do for someone with hypothermia?',
    );
    expect(text, contains('wet'));
    expect(text, contains('warm'));
  });

  test('heat stroke first aid', () async {
    await expectAnswerHas('How do I treat heat stroke?', ['Call 911']);
  });

  test('frostbite: do not rub', () async {
    final text = await givenText('How do I treat frostbite on fingers?');
    expect(text, contains('do not rub'));
  });

  test('emergency water quantity per person', () async {
    await expectAnswerHas(
      'How much water should I store per person for an emergency?',
      ['1 gallon of water per person, per day'],
    );
  });

  test('earthquake: drop, cover, hold on', () async {
    final hits = await given('What should I do during an earthquake?');
    expect(hits.first.documentTitle, 'Earthquakes');
  });

  test('off-topic questions find nothing', () async {
    expect(await given('Who won the 1998 World Cup?'), isEmpty);
    expect(await given('Write me a poem about cats'), isEmpty);
  });

  test('government packs are verified; Wikibooks is flagged', () async {
    final packs = {
      for (final p in await db.select(db.knowledgePacks).get())
        p.id: p.reviewStatus,
    };
    expect(packs['water-sanitation'], ReviewStatus.verified);
    expect(packs['first-aid'], ReviewStatus.verified);
    expect(packs['first-aid-wikibooks'], ReviewStatus.needsReview);
  });

  test('choking question reaches the obstructed airway chapter', () async {
    final hits = await given(
      'Someone is choking and cannot breathe, what do I do?',
    );
    expect(hits.map((h) => h.documentTitle), contains('Obstructed Airway'));
  });

  test(
    'CPR comes from a current verified source with the current rate',
    () async {
      final hits = await given('How do I do CPR chest compressions?');
      expect(hits.first.reviewStatus, ReviewStatus.verified);
      expect(
        hits.first.body.toLowerCase(),
        contains('100 to 120 compressions per minute'),
      );
    },
  );

  test('bleeding control is covered', () async {
    final hits = await given('How do I stop severe bleeding from a wound?');
    expect(hits, isNotEmpty);
    expect(
      hits.map((h) => '${h.heading} ${h.body}').join(' ').toLowerCase(),
      contains('pressure'),
    );
  });

  group('expanded library', () {
    Future<String> topDocs(String q) async =>
        (await given(q)).map((h) => h.documentTitle).join(' | ');

    test('building a debris hut shelter', () async {
      expect(
        await topDocs('How do I build a debris hut shelter?'),
        contains('Shelter'),
      );
    });

    test('starting a fire with a bow drill', () async {
      expect(
        await topDocs('How do I start a fire with a bow and drill?'),
        contains('Fire'),
      );
    });

    test('setting a snare for small game', () async {
      expect(
        await topDocs('How do I make a simple loop snare to catch small game?'),
        anyOf(contains('Food'), contains('Snares')),
      );
    });

    test('tying a bowline knot', () async {
      expect(await topDocs('How do I tie a bowline knot?'), contains('Knots'));
    });

    test('finding direction without a compass', () async {
      expect(
        await topDocs('How can I find north without a compass using the sun?'),
        anyOf(contains('Navigation'), contains('Direction')),
      );
    });

    test('building an expedient fallout shelter', () async {
      expect(
        await topDocs('How do I build an expedient fallout shelter?'),
        contains('Shelter'),
      );
    });

    test('latrine and waste disposal in the field', () async {
      expect(
        await topDocs('How should I dig a latrine and dispose of human waste?'),
        anyOf(
          contains('Hygiene'),
          contains('Sanitation'),
          contains('Medicine'),
        ),
      );
    });

    test('flagged historical source is labelled', () async {
      final hits = await given('How do I build a deadfall trap?');
      expect(
        hits.any(
          (h) =>
              h.reviewStatus == ReviewStatus.historical ||
              h.documentTitle.contains('ATP'),
        ),
        isTrue,
      );
    });
  });

  test('every image a passage references exists and is placed', () async {
    var images = 0;
    for (final p in await db.select(db.passages).get()) {
      final list = SectionImage.listFromJson(p.images);
      images += list.length;
      for (final img in list) {
        expect(File(img.asset).existsSync(), isTrue, reason: img.asset);
      }
      for (final m in SectionImage.placeholder.allMatches(p.body)) {
        expect(
          int.parse(m.group(1)!),
          lessThan(list.length),
          reason: p.heading,
        );
      }
    }
    expect(images, greaterThan(300));
  });

  test('no shipped text contains undecodable characters', () async {
    for (final p in await db.select(db.passages).get()) {
      expect(p.body.contains('\ufffd'), isFalse, reason: p.heading);
    }
  });

  test('every bundled pack ships up-to-date meaning vectors', () {
    // Regenerate with: flutter test tools/embed/embed_packs_test.dart
    for (final f in packs) {
      final pack = PackData.fromJson(jsonDecode(f.readAsStringSync()));
      final vec = File(
        f.path
            .replaceFirst('assets/packs/', 'assets/packs/vectors/')
            .replaceFirst(RegExp(r'\.json$'), '.vec'),
      );
      expect(vec.existsSync(), isTrue, reason: '${pack.id}: no vectors');
      final entries = PassageVectors.decode(vec.readAsBytesSync());
      expect(entries, isNotNull, reason: '${pack.id}: unreadable vectors');
      final hashes = [
        for (final d in pack.documents)
          for (final s in d.sections)
            PassageVectors.sectionHash(s.heading, s.body),
      ];
      expect(
        [for (final (h, _) in entries!) h],
        hashes,
        reason: '${pack.id}: vectors are stale',
      );
    }
  });
}
