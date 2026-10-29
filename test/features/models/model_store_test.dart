import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/data/llama_engine.dart';
import 'package:offgrid_ai/features/chat/data/no_model_engine.dart';
import 'package:offgrid_ai/features/models/data/model_store.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/test_db.dart';

Stream<List<int>> bytesOf(List<int> data, {int chunk = 3}) async* {
  for (var i = 0; i < data.length; i += chunk) {
    yield data.sublist(i, (i + chunk).clamp(0, data.length));
  }
}

final fakeGguf = [...'GGUF'.codeUnits, 3, 0, 0, 0, 1, 2, 3, 4, 5];

void main() {
  late AppDatabase db;
  late Directory dir;
  late ModelStore store;

  setUp(() async {
    db = testDatabase();
    dir = await Directory.systemTemp.createTemp('models');
    store = ModelStore(db, dir);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  List<String> filesInDir() =>
      dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

  test('imports a GGUF file and makes the first one active', () async {
    final progress = <int>[];
    final model = await store.import(
      originalName: 'Qwen-3B.Q4_K_M.gguf',
      bytes: bytesOf(fakeGguf),
      onProgress: progress.add,
    );

    expect(model.displayName, 'Qwen-3B.Q4_K_M');
    expect(model.sizeBytes, fakeGguf.length);
    expect(model.isActive, isTrue);
    expect(await store.fileFor(model).readAsBytes(), fakeGguf);
    expect(progress.last, fakeGguf.length);
    expect(filesInDir(), ['Qwen-3B.Q4_K_M.gguf']);
  });

  test('second import is not active until chosen', () async {
    final a = await store.import(
      originalName: 'a.gguf',
      bytes: bytesOf(fakeGguf),
    );
    final b = await store.import(
      originalName: 'b.gguf',
      bytes: bytesOf(fakeGguf),
    );
    expect(b.isActive, isFalse);

    await store.setActive(b.id);

    expect((await store.watchActive().first)!.id, b.id);
    final models = await store.watchModels().first;
    expect(models.where((m) => m.isActive).single.id, isNot(a.id));
  });

  test('same file name twice gets a unique name', () async {
    await store.import(originalName: 'm.gguf', bytes: bytesOf(fakeGguf));
    final second = await store.import(
      originalName: 'm.gguf',
      bytes: bytesOf(fakeGguf),
    );
    expect(second.fileName, 'm-2.gguf');
  });

  test('rejects files without a .gguf extension', () async {
    await expectLater(
      store.import(originalName: 'model.bin', bytes: bytesOf(fakeGguf)),
      throwsA(isA<ModelImportException>()),
    );
    expect(filesInDir(), isEmpty);
  });

  test(
    'rejects a .gguf file with the wrong header and leaves nothing',
    () async {
      await expectLater(
        store.import(
          originalName: 'fake.gguf',
          bytes: bytesOf('<html>not a model</html>'.codeUnits),
        ),
        throwsA(isA<ModelImportException>()),
      );
      expect(filesInDir(), isEmpty);
      expect(await store.watchModels().first, isEmpty);
    },
  );

  test('an interrupted import leaves no file and no registry row', () async {
    Stream<List<int>> failing() async* {
      yield fakeGguf.sublist(0, 8);
      throw const FileSystemException('read failed');
    }

    await expectLater(
      store.import(originalName: 'cut.gguf', bytes: failing()),
      throwsA(isA<ModelImportException>()),
    );
    expect(filesInDir(), isEmpty);
    expect(await store.watchActive().first, isNull);
  });

  test('delete removes the file and row', () async {
    final m = await store.import(
      originalName: 'x.gguf',
      bytes: bytesOf(fakeGguf),
    );
    await store.delete(m);
    expect(filesInDir(), isEmpty);
    expect(await store.watchModels().first, isEmpty);
  });

  test('cleanUpPartials removes leftover .part files only', () async {
    await store.import(originalName: 'keep.gguf', bytes: bytesOf(fakeGguf));
    await File('${dir.path}/stale.gguf.part').writeAsBytes([1, 2, 3]);

    await store.cleanUpPartials();

    expect(filesInDir(), ['keep.gguf']);
  });

  test('engine provider follows the active model', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        modelsDirectoryProvider.overrideWithValue(dir),
      ],
    );
    addTearDown(c.dispose);

    // Like the app, keep the engine provider listened to.
    final sub = c.listen(inferenceEngineProvider, (_, _) {});
    await c.listen(activeModelProvider.future, (_, _) {}).read();
    expect(sub.read(), isA<NoModelEngine>());

    await store.import(originalName: 'm.gguf', bytes: bytesOf(fakeGguf));
    await pumpEventQueue();

    final engine = sub.read();
    expect(engine, isA<LlamaInferenceEngine>());
    expect((engine as LlamaInferenceEngine).modelName, 'm');
  });
}
