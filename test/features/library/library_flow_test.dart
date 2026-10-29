import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/app.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/test_db.dart';

class CitingEngine implements InferenceEngine {
  @override
  Future<EngineStatus> status() async => const EngineReady('fake');

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) =>
      Stream.fromIterable(const [
        GenerationToken('Bring it to a rolling boil [1].'),
        GenerationDone(),
      ]);

  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = testDatabase();
    await PackInstaller(db).install(
      File('test/fixtures/test_pack.json').readAsStringSync(),
      source: 'test',
    );
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
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
          inferenceEngineProvider.overrideWithValue(CitingEngine()),
        ],
        child: const OffgridApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('browse a pack and read a document', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test Fixture Pack'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture Water Guide'), findsOneWidget);
    expect(find.textContaining('Test data'), findsOneWidget);

    await tester.tap(find.text('Fixture Water Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Boiling water'), findsOneWidget);
    expect(find.text('Storing water'), findsOneWidget);
  });

  testWidgets('search finds a passage and opens it', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search library'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kindling');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Building a campfire'), findsOneWidget);

    await tester.tap(find.text('Building a campfire'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture Fire Guide'), findsOneWidget);
  });

  testWidgets('a citation chip opens the cited passage', (tester) async {
    await pumpApp(tester);
    await tester.enterText(
      find.byType(TextField),
      'How long should I boil water?',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Bring it to a rolling boil [1].'), findsOneWidget);
    final chip = find.widgetWithText(ActionChip, 'Boiling water');
    expect(chip, findsOneWidget);

    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Fixture Water Guide'), findsOneWidget);
    expect(find.textContaining('rolling boil before drinking'), findsOneWidget);
  });
}
