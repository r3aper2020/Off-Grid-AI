import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer c;

  setUp(() {
    db = testDatabase();
    c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        modelsDirectoryProvider.overrideWithValue(
          Directory('${Directory.systemTemp.path}/offgrid_test_models'),
        ),
      ],
    );
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<int> install(String name, {bool active = false, String? projector}) =>
      db
          .into(db.installedModels)
          .insert(
            InstalledModelsCompanion.insert(
              displayName: name,
              fileName: '$name.gguf',
              sizeBytes: 1,
              installedAt: DateTime(2026),
              isActive: Value(active),
              projectorFileName: Value(projector),
            ),
          );

  /// Like the app, keep the engine providers listened to, and wait for
  /// the model streams to deliver.
  Future<void> settle() async {
    c.listen(inferenceEngineProvider, (_, _) {});
    c.listen(visionEngineProvider, (_, _) {});
    await c.listen(installedModelsProvider.future, (_, _) {}).read();
    await c.listen(activeModelProvider.future, (_, _) {}).read();
    await pumpEventQueue();
  }

  test('a vision model beside an active text model is offered', () async {
    await install('text', active: true);
    await install('vision', projector: 'mmproj.gguf');
    await settle();

    final engine = c.read(visionEngineProvider);
    expect(engine, isNotNull);
    // Its file is missing in tests, which reports the model's name is not
    // what matters; only that it is a different, vision-capable engine.
    expect(engine, isNot(same(c.read(inferenceEngineProvider))));
    expect(await engine!.status(), isA<EngineUnavailable>());
  });

  test(
    'nothing is offered when the active model already sees photos',
    () async {
      await install('vision', active: true, projector: 'mmproj.gguf');
      await settle();
      expect(c.read(visionEngineProvider), isNull);
    },
  );

  test('nothing is offered without a vision model', () async {
    await install('text', active: true);
    await settle();
    expect(c.read(visionEngineProvider), isNull);
  });
}
