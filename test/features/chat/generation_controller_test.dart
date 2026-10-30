import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/data/no_model_engine.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';

import '../../support/test_db.dart';

class FakeEngine implements InferenceEngine {
  FakeEngine(this.controller, {this.canSeeImages = false});
  final StreamController<GenerationEvent> controller;
  final bool canSeeImages;
  List<ChatTurn>? lastHistory;

  @override
  Future<EngineStatus> status() async =>
      EngineReady('fake', canSeeImages: canSeeImages);

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) {
    lastHistory = history;
    return controller.stream;
  }

  @override
  Future<String?> complete(List<ChatTurn> turns, {int maxTokens = 64}) async =>
      null;

  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  late AppDatabase db;

  ProviderContainer containerWith(InferenceEngine engine) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        inferenceEngineProvider.overrideWithValue(engine),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  Future<List<Message>> messagesOf(ProviderContainer c, int id) =>
      c.read(chatRepositoryProvider).messages(id);

  test('without a model, a notice is stored instead of an answer', () async {
    final c = containerWith(const NoModelEngine());
    final id = await c.read(chatRepositoryProvider).startConversation('hi');

    await c.read(generationControllerProvider.notifier).reply(id);

    final reply = (await messagesOf(c, id)).last;
    expect(reply.role, MessageRole.assistant);
    expect(reply.status, MessageStatus.notice);
    expect(reply.content, NoModelEngine.reason);
  });

  test('streams tokens into a completed message', () async {
    final stream = StreamController<GenerationEvent>();
    final engine = FakeEngine(stream);
    final c = containerWith(engine);
    final id = await c.read(chatRepositoryProvider).startConversation('hi');

    await c.read(generationControllerProvider.notifier).reply(id);
    expect(c.read(generationControllerProvider), contains(id));

    stream
      ..add(const GenerationToken('Boil '))
      ..add(const GenerationToken('for one minute.'))
      ..add(const GenerationDone());
    await stream.close();
    await pumpEventQueue();

    final reply = (await messagesOf(c, id)).last;
    expect(reply.content, 'Boil for one minute.');
    expect(reply.status, MessageStatus.complete);
    expect(c.read(generationControllerProvider), isNot(contains(id)));
  });

  test('notices are never sent back to the model', () async {
    final stream = StreamController<GenerationEvent>();
    final engine = FakeEngine(stream);
    final c = containerWith(engine);
    final repo = c.read(chatRepositoryProvider);
    final id = await repo.startConversation('first');
    await repo.addAssistantMessage(id, 'no model', MessageStatus.notice);
    await repo.addUserMessage(id, 'second');

    await c.read(generationControllerProvider.notifier).reply(id);

    expect(
      engine.lastHistory!
          .where((t) => t.speaker != ChatSpeaker.system)
          .map((t) => t.text),
      ['first', 'second'],
    );
    await stream.close();
  });

  test('cancel keeps partial text and marks it cancelled', () async {
    final stream = StreamController<GenerationEvent>();
    final c = containerWith(FakeEngine(stream));
    final id = await c.read(chatRepositoryProvider).startConversation('hi');
    final controller = c.read(generationControllerProvider.notifier);

    await controller.reply(id);
    stream.add(const GenerationToken('Partial'));
    await pumpEventQueue();
    await controller.cancel(id);

    final reply = (await messagesOf(c, id)).last;
    expect(reply.content, 'Partial');
    expect(reply.status, MessageStatus.cancelled);
    expect(stream.hasListener, isFalse);
  });

  test('engine failure is recorded as failed', () async {
    final stream = StreamController<GenerationEvent>();
    final c = containerWith(FakeEngine(stream));
    final id = await c.read(chatRepositoryProvider).startConversation('hi');

    await c.read(generationControllerProvider.notifier).reply(id);
    stream.add(const GenerationFailed('Out of memory'));
    await stream.close();
    await pumpEventQueue();

    final reply = (await messagesOf(c, id)).last;
    expect(reply.status, MessageStatus.failed);
    expect(reply.content, 'Out of memory');
  });

  test('a photo sent to a text-only model gets an honest notice', () async {
    final stream = StreamController<GenerationEvent>();
    final engine = FakeEngine(stream);
    final c = containerWith(engine);
    final id = await c
        .read(chatRepositoryProvider)
        .startConversation('what is this', imagePath: 'leaf.jpg');

    await c.read(generationControllerProvider.notifier).reply(id);

    final reply = (await messagesOf(c, id)).last;
    expect(reply.status, MessageStatus.notice);
    expect(reply.content, GenerationController.noVisionReason);
    expect(engine.lastHistory, isNull);
    // Never listened to, so close without waiting for it to drain.
    unawaited(stream.close());
  });

  test('a vision model receives the photo on the latest turn', () async {
    final stream = StreamController<GenerationEvent>();
    final engine = FakeEngine(stream, canSeeImages: true);
    final c = containerWith(engine);
    final id = await c
        .read(chatRepositoryProvider)
        .startConversation('what is this', imagePath: 'leaf.jpg');

    await c.read(generationControllerProvider.notifier).reply(id);
    stream.add(const GenerationDone());
    await stream.close();
    await pumpEventQueue();

    final user = engine.lastHistory!.lastWhere(
      (t) => t.speaker == ChatSpeaker.user,
    );
    expect(user.imagePath, endsWith('/leaf.jpg'));
  });
}
