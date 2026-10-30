import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/app.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
import 'package:offgrid_ai/features/chat/presentation/thinking_indicator.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/test_db.dart';

/// Engine whose events the test pushes by hand.
class ManualEngine implements InferenceEngine {
  final events = StreamController<GenerationEvent>();

  @override
  Future<EngineStatus> status() async => const EngineReady('manual');

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) => events.stream;

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
  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  test(
    'phases move from searching to loading, thinking, writing, done',
    () async {
      final engine = ManualEngine();
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          inferenceEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(c.dispose);
      final phases = <GenerationPhase?>[];
      c.listen(
        generationControllerProvider,
        (_, s) => phases.add(s[1]),
        fireImmediately: true,
      );

      final id = await c.read(chatRepositoryProvider).startConversation('hi');
      await c.read(generationControllerProvider.notifier).reply(id);
      engine.events
        ..add(const GenerationProgress(GenerationPhase.loadingModel))
        ..add(const GenerationProgress(GenerationPhase.thinking))
        ..add(const GenerationToken('Hello'))
        ..add(const GenerationDone());
      await pumpEventQueue();

      expect(phases.where((p) => p != null).toSet().toList(), [
        GenerationPhase.searching,
        GenerationPhase.loadingModel,
        GenerationPhase.thinking,
        GenerationPhase.writing,
      ]);
      expect(phases.last, isNull);
    },
  );

  test('stop during the library search cancels cleanly', () async {
    final engine = ManualEngine();
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        inferenceEngineProvider.overrideWithValue(engine),
      ],
    );
    addTearDown(c.dispose);
    final id = await c.read(chatRepositoryProvider).startConversation('hi');
    final controller = c.read(generationControllerProvider.notifier);

    final reply = controller.reply(id);
    await pumpEventQueue(times: 2);
    await controller.cancel(id);
    await reply;

    final last = (await db.select(db.messages).get()).last;
    expect(last.status, MessageStatus.cancelled);
    expect(engine.events.hasListener, isFalse);
    expect(c.read(generationControllerProvider), isEmpty);
  });

  testWidgets('a pending reply shows what it is doing', (tester) async {
    final engine = ManualEngine();
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          modelsDirectoryProvider.overrideWithValue(
            Directory('${Directory.systemTemp.path}/offgrid_test_models'),
          ),
          inferenceEngineProvider.overrideWithValue(engine),
        ],
        child: const OffgridApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'How do I boil water?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    engine.events.add(const GenerationProgress(GenerationPhase.loadingModel));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(ThinkingIndicator.label(GenerationPhase.loadingModel)),
      findsOneWidget,
    );
    expect(find.byTooltip('Stop'), findsOneWidget);

    engine.events
      ..add(const GenerationToken('Bring it to a boil.'))
      ..add(const GenerationDone());
    await tester.pumpAndSettle();
    expect(find.byType(ThinkingIndicator), findsNothing);
    expect(find.text('Bring it to a boil.'), findsOneWidget);
  });
}
