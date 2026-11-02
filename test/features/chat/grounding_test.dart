import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/domain/grounding.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

import '../../support/test_db.dart';

PassageHit hit(
  int id,
  String heading,
  String body, {
  ReviewStatus review = ReviewStatus.verified,
}) => PassageHit(
  reviewStatus: review,
  passageId: id,
  documentId: 1,
  heading: heading,
  body: body,
  documentTitle: 'Doc',
  packTitle: 'Pack',
  snippet: '',
);

class RecordingEngine implements InferenceEngine {
  RecordingEngine(this.reply, {this.rewrite});
  final String reply;
  final String? rewrite;
  List<ChatTurn>? history;
  List<ChatTurn>? rewriteRequest;

  @override
  Future<EngineStatus> status() async => const EngineReady('fake');

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) {
    this.history = history;
    return Stream.fromIterable([
      GenerationToken(reply),
      const GenerationDone(),
    ]);
  }

  @override
  Future<String?> complete(List<ChatTurn> turns, {int maxTokens = 64}) async {
    rewriteRequest = turns;
    return rewrite;
  }

  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('Grounding.apply', () {
    const history = [
      ChatTurn(ChatSpeaker.user, 'old question'),
      ChatTurn(ChatSpeaker.assistant, 'old answer'),
      ChatTurn(ChatSpeaker.user, 'How do I boil water?'),
    ];

    test('puts numbered passages in the system turn, not the message', () {
      final turns = Grounding.apply(history, [
        hit(10, 'Boiling', 'Boil it.'),
        hit(11, 'Storing', 'Store it.'),
      ]);

      expect(turns.first.speaker, ChatSpeaker.system);
      final rules = turns.first.text;
      expect(rules, startsWith(Grounding.citeInstruction));
      expect(rules, contains('[1] Doc — Boiling\nBoil it.'));
      expect(rules, contains('[2] Doc — Storing\nStore it.'));
      expect(turns[1].text, 'old question');
      // The user's own words reach the model untouched, last.
      expect(turns.last.speaker, ChatSpeaker.user);
      expect(turns.last.text, 'How do I boil water?');
    });

    test('without passages, instructs the model to say so', () {
      final turns = Grounding.apply(history, const []);
      expect(turns.first.text, Grounding.noSourceInstruction);
      expect(turns.last.text, 'How do I boil water?');
    });

    test('unreviewed and historical passages are labelled for the model', () {
      final turns = Grounding.apply(history, [
        hit(1, 'CPR', 'Push hard.', review: ReviewStatus.needsReview),
        hit(2, 'Snares', 'Tie a loop.', review: ReviewStatus.historical),
        hit(3, 'Boil', 'Boil it.'),
      ]);
      final text = turns.first.text;
      expect(text, contains('[1] Doc — CPR (UNREVIEWED SOURCE'));
      expect(text, contains('[2] Doc — Snares (HISTORICAL SOURCE'));
      expect(text, contains('[3] Doc — Boil\nBoil it.'));
      expect(turns.first.text, contains('UNREVIEWED or HISTORICAL'));
    });

    test('figures and table images become labelled text for the model', () {
      final h = PassageHit(
        passageId: 1,
        documentId: 1,
        heading: 'Canning',
        body: 'Use this table: {{img:0}} Then see {{img:1}}.',
        documentTitle: 'Doc',
        packTitle: 'Pack',
        snippet: '',
        images: const [
          SectionImage(
            asset: 'a.webp',
            caption: 'Process times',
            isTable: true,
          ),
          SectionImage(asset: 'b.webp', caption: 'Fire lays', isTable: false),
        ],
      );
      final text = Grounding.apply(history, [h]).first.text;
      expect(text, contains('[Table image: Process times'));
      expect(text, contains('not available as text'));
      expect(text, contains('[Figure: Fire lays]'));
      expect(text, isNot(contains('{{img:')));
    });

    test('passages are never truncated', () {
      final body = '${'x' * 2500} final dosage line';
      final turns = Grounding.apply(history, [hit(1, 'Long', body)]);
      expect(turns.first.text, contains('final dosage line'));
    });

    test('select keeps whole passages within budget, best first', () {
      const half = Grounding.passageBudgetChars ~/ 2;
      final big = hit(1, 'Big', 'b' * (half + 200));
      final alsoBig = hit(2, 'Also big', 'c' * (half + 200));
      final small = hit(3, 'Small', 's' * 500);
      final chosen = Grounding.select([big, alsoBig, small]);
      expect(chosen.map((h) => h.passageId), [1, 3]);
    });

    test('select always keeps the best match even if oversized', () {
      final huge = hit(1, 'Huge', 'h' * 6000);
      expect(Grounding.select([huge, hit(2, 'Next', 'n')]).first, huge);
    });

    test('parseRewrites keeps clean, distinct queries', () {
      final q = Grounding.parseRewrites(
        '1. "lost in the woods what to do first"\n'
            '- staying warm overnight without a tent\n'
            'Queries:\n'
            "I'm lost in the woods\n"
            'a\n'
            'emergency shelter overnight\n'
            'a fourth query here',
        "I'm lost in the woods",
      );
      expect(q, [
        'lost in the woods what to do first',
        'staying warm overnight without a tent',
        'emergency shelter overnight',
      ]);
      expect(Grounding.parseRewrites(null, 'x'), isEmpty);
    });

    test('rewriteTurns sends the rewrite rules and the latest exchange', () {
      final turns = Grounding.rewriteTurns(const [
        ChatTurn(ChatSpeaker.system, 'cite rules'),
        ChatTurn(ChatSpeaker.user, 'old'),
        ChatTurn(ChatSpeaker.assistant, 'old answer'),
        ChatTurn(ChatSpeaker.user, 'bleeding leg'),
        ChatTurn(ChatSpeaker.assistant, 'use a tourniquet'),
        ChatTurn(ChatSpeaker.user, "what if I don't have one?"),
      ]);
      expect(turns.first.text, Grounding.rewriteInstruction);
      expect(turns.map((t) => t.text), isNot(contains('old')));
      expect(turns[1].text, 'bleeding leg');
      expect(turns.last.text, contains("what if I don't have one?"));
    });

    test('isSmallTalk: greetings yes, answers to the assistant no', () {
      expect(Grounding.isSmallTalk('Hi there!'), isTrue);
      expect(Grounding.isSmallTalk('how do I boil water'), isFalse);
      const q = 'how much bleach per gallon';
      const asked = 'Add 8 drops. What strength is your bleach?';
      expect(
        Grounding.isSmallTalk("I think it's 1%", previous: q, lastReply: asked),
        isFalse,
      );
      expect(Grounding.isSmallTalk('yes', previous: q, lastReply: asked), isFalse);
      expect(
        Grounding.isSmallTalk('ok thanks!', previous: q, lastReply: asked),
        isTrue,
      );
      expect(
        Grounding.isSmallTalk('yes', previous: q, lastReply: 'Add 8 drops.'),
        isTrue,
      );
    });

    test('citedNumbers finds bracketed numbers in order of first use', () {
      expect(Grounding.citedNumbers('Do A [2]. Then B [1][2]. Not [x].'), [
        2,
        1,
      ]);
      expect(Grounding.citedNumbers('No citations here.'), isEmpty);
    });
  });

  group('GenerationController with the library', () {
    late AppDatabase db;
    setUp(() async {
      db = testDatabase();
      await PackInstaller(db).install(
        File('test/fixtures/test_pack.json').readAsStringSync(),
        source: 'test',
      );
    });
    tearDown(() => db.close());

    Future<(ProviderContainer, RecordingEngine)> run(
      String question, {
      String? rewrite,
    }) async {
      final engine = RecordingEngine('Boil it first [1].', rewrite: rewrite);
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          inferenceEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(c.dispose);
      final id = await c
          .read(chatRepositoryProvider)
          .startConversation(question);
      await c.read(generationControllerProvider.notifier).reply(id);
      await pumpEventQueue();
      return (c, engine);
    }

    test('stores the passages it gave the model as citations', () async {
      final (c, engine) = await run('How long should I boil water?');

      final reply = (await db.select(db.messages).get()).last;
      final ids = (jsonDecode(reply.citations!) as List).cast<int>();
      expect(ids, isNotEmpty);
      final cited = await KnowledgeSearch(db).byIds(ids);
      expect(cited.first!.heading, 'Boiling water');
      expect(engine.history!.first.text, contains('[1] Fixture Water Guide'));
      expect(reply.status, MessageStatus.complete);
    });

    test('unrelated questions record an empty citation list', () async {
      final (_, engine) = await run('What is the capital of France?');

      final reply = (await db.select(db.messages).get()).last;
      expect(reply.citations, '[]');
      expect(engine.history!.first.text, Grounding.noSourceInstruction);
    });

    test('the model\'s rewrites widen the search', () async {
      // The user's words match nothing; the rewrite names the topic.
      final (_, engine) = await run(
        'is it ok to drink it straight?',
        rewrite: 'boiling water before drinking\nstoring water',
      );
      final reply = (await db.select(db.messages).get()).last;
      final ids = (jsonDecode(reply.citations!) as List).cast<int>();
      final cited = await KnowledgeSearch(db).byIds(ids);
      expect(cited.map((h) => h!.heading), contains('Boiling water'));
      expect(engine.rewriteRequest!.first.text, Grounding.rewriteInstruction);
    });

    test('an answer to the assistant\'s question is still grounded', () async {
      final engine = RecordingEngine(
        'Boil it [1]. Is the water cloudy?',
        rewrite: 'boiling cloudy water',
      );
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          inferenceEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(c.dispose);
      final repo = c.read(chatRepositoryProvider);
      final controller = c.read(generationControllerProvider.notifier);
      final id = await repo.startConversation('How long should I boil water?');
      await controller.reply(id);
      await pumpEventQueue();

      await repo.addUserMessage(id, 'yes');
      await controller.reply(id);
      await pumpEventQueue();

      final reply = (await db.select(db.messages).get()).last;
      expect(reply.citations, isNotNull);
      expect(engine.history!.first.speaker, ChatSpeaker.system);
      expect(engine.history!.first.text, contains('[1] Fixture Water Guide'));
    });

    test('greetings and thanks get a plain reply, no library lookup', () async {
      final (_, engine) = await run('Thanks!');

      final reply = (await db.select(db.messages).get()).last;
      expect(reply.citations, isNull);
      expect(
        engine.history!.where((t) => t.speaker == ChatSpeaker.system),
        isEmpty,
      );
    });
  });
}
