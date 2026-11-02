import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'features/chat/chat_providers.dart';
import 'features/library/data/library_repository.dart';
import 'features/library/data/llama_embedder.dart';
import 'core/providers.dart';
import 'features/models/model_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nothing here may touch the network: the app must cold-start offline.
  final support = await getApplicationSupportDirectory();
  final container = ProviderContainer(
    overrides: [
      modelsDirectoryProvider.overrideWithValue(
        Directory(p.join(support.path, 'models')),
      ),
      photosDirectoryProvider.overrideWithValue(
        Directory(p.join(support.path, 'photos')),
      ),
      // Bundled embedding model for semantic search; loads on first use.
      textEmbedderProvider.overrideWithValue(
        LlamaTextEmbedder(
          directory: Directory(p.join(support.path, 'embedder')),
        ),
      ),
    ],
  );
  await container.read(chatRepositoryProvider).recoverInterrupted();
  await container.read(modelStoreProvider).cleanUpPartials();
  // Install or update the reference packs bundled with the app (offline).
  // Install or update bundled references in the background so the app
  // opens immediately; the Library shows progress meanwhile.
  container.listen(librarySyncProvider, (_, _) {});
  unawaited(container.read(librarySyncProvider.notifier).run(rootBundle));
  // Resolve the installed models before the first frame so an early
  // message isn't answered with "no model installed". Riverpod pauses
  // providers with no listeners, so listen (for the app's lifetime)
  // rather than read.
  container.listen(inferenceEngineProvider, (_, _) {});
  await container.listen(installedModelsProvider.future, (_, _) {}).read();

  runApp(
    UncontrolledProviderScope(container: container, child: const OffgridApp()),
  );
}
