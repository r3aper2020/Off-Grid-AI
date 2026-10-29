import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'features/chat/chat_providers.dart';
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
    ],
  );
  await container.read(chatRepositoryProvider).recoverInterrupted();
  await container.read(modelStoreProvider).cleanUpPartials();
  // Resolve the active model before the first frame so an early message
  // isn't answered with "no model installed". Riverpod pauses providers
  // with no listeners, so listen (for the app's lifetime) rather than read.
  container.listen(inferenceEngineProvider, (_, _) {});
  await container.listen(activeModelProvider.future, (_, _) {}).read();

  runApp(
    UncontrolledProviderScope(container: container, child: const OffgridApp()),
  );
}
