import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/app.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/data/no_model_engine.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = testDatabase());
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
        ],
        child: const OffgridApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on chat and switches between all tabs', (tester) async {
    await pumpApp(tester);
    expect(find.text('How can I help\nyou today?'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('No references installed'), findsOneWidget);

    await tester.tap(find.text('Tools').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Elevation'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Not installed — tap to import'), findsOneWidget);
  });

  testWidgets('sending a message without a model explains why', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'How do I start a fire?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('How do I start a fire?'), findsWidgets);
    expect(find.text(NoModelEngine.reason), findsOneWidget);
  });
}
