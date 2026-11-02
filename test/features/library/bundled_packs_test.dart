import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/chat/domain/grounding.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/llama_embedder.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';
import 'package:offgrid_ai/features/library/domain/passage_vectors.dart';

import '../../support/test_db.dart';

/// Retrieval checks against the real bundled library with the real
/// embedding model, as the app runs it: realistic questions must surface
/// the right passage, and what reaches the model must still contain the
/// safety-critical details.
void main() {
  late AppDatabase db;
  late KnowledgeSearch search;
  final embedder = LlamaTextEmbedder.fromFile(File(LlamaTextEmbedder.asset));
  tearDownAll(embedder.dispose);

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
    search = KnowledgeSearch(db, embedder: embedder);
    final installer = PackInstaller(db);
    for (final f in packs) {
      final stem = f.path
          .replaceFirst('assets/packs/', 'assets/packs/vectors/')
          .replaceFirst(RegExp(r'\.json$'), '');
      Uint8List? read(String name) =>
          File(name).existsSync() ? File(name).readAsBytesSync() : null;
      await installer.install(
        f.readAsStringSync(),
        source: 'test',
        vectors: read('$stem.vec'),
        docVectors: read('$stem.docs.vec'),
      );
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

  test('choking question reaches airway obstruction first aid', () async {
    final hits = await given(
      'Someone is choking and cannot breathe, what do I do?',
    );
    expect(hits.first.documentTitle, contains('Airway'));
    expect(hits.map((h) => h.body.toLowerCase()).join(' '), contains('thrust'));
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
      // The reply shows the figures of the passages it was given.
      final figures = await search.figuresFor(
        await given('How do I tie a bowline knot?'),
      );
      expect(figures.map((f) => f.caption), contains(contains('Bowline knot')));
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
          contains('Latrines'),
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
      final stem = f.path
          .replaceFirst('assets/packs/', 'assets/packs/vectors/')
          .replaceFirst(RegExp(r'\.json$'), '');
      void check(String name, List<int> hashes) {
        final vec = File(name);
        expect(vec.existsSync(), isTrue, reason: '${pack.id}: no $name');
        final entries = PassageVectors.decode(vec.readAsBytesSync());
        expect(entries, isNotNull, reason: '$name: unreadable vectors');
        expect(
          [for (final (h, _) in entries!) h],
          hashes,
          reason: '$name: vectors are stale',
        );
      }

      check('$stem.vec', [
        for (final d in pack.documents)
          for (final s in d.sections)
            PassageVectors.sectionHash(s.heading, s.body),
      ]);
      check('$stem.docs.vec', [
        for (final d in pack.documents)
          PassageVectors.docHash(d.title, d.aliases),
      ]);
    }
  });

  test('every bundled document carries plain-language aliases', () {
    for (final f in packs) {
      final pack = PackData.fromJson(jsonDecode(f.readAsStringSync()));
      for (final d in pack.documents) {
        expect(d.aliases, isNotEmpty, reason: '${pack.id}: ${d.title}');
      }
    }
  });

  test('no fragment or garbage sections remain', () async {
    for (final p in await db.select(db.passages).get()) {
      final text = p.body.replaceAll(SectionImage.placeholder, '').trim();
      final words = RegExp(r'[A-Za-z]+').allMatches(text).length;
      expect(
        words >= 8 || p.body.contains('{{img:'),
        isTrue,
        reason:
            '${p.heading}: "${text.substring(0, text.length.clamp(0, 60))}"',
      );
    }
  });

  test('regulation text is library-only', () async {
    final docs = await db.select(db.packDocuments).get();
    final cfr = docs.where((d) => d.title.contains('47 CFR'));
    expect(cfr, isNotEmpty);
    expect(cfr.every((d) => d.libraryOnly), isTrue);
    expect(await search.search('amateur station'), isNotEmpty);
    final hits = await given('rules for an amateur station');
    expect(hits.map((h) => h.documentTitle), isNot(contains('47 CFR')));
  });

  group('plain-language questions reach the right document', () {
    Future<String> topDocs(String q) async =>
        (await given(q)).take(4).map((h) => h.documentTitle).join(' | ');

    test('bug out bag → the disaster supplies kit', () async {
      expect(
        await topDocs('what should I pack in a bug out bag'),
        contains('Kit'),
      );
    });

    test('lost and cold → lost-hiker guidance, not cucumbers', () async {
      final docs = await topDocs(
        "I'm lost in the woods, it's getting dark and cold, what do I do first",
      );
      expect(docs, anyOf(contains('Lost'), contains('Get Lost')));
      expect(docs, isNot(contains('Gardening')));
    });

    test('choking → airway, not chemical agents', () async {
      final docs = await topDocs("someone is choking and can't breathe");
      expect(docs, contains('Airway'));
      expect(docs, isNot(contains('Chemical')));
    });

    test('edible plants → the survival food chapter, plants first', () async {
      final hits = await given('which plants can I eat in the woods');
      expect(hits.first.documentTitle, contains('Food'));
      expect(hits.first.heading.toLowerCase(), contains('plant'));
    });

    test('the edibility test is found by name', () async {
      final hits = await given('universal edibility test');
      expect(
        hits.map((h) => h.heading.toUpperCase()).join(' '),
        contains('EDIBILITY'),
      );
    });
  });
}
