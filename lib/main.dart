import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/chat/chat_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nothing here may touch the network: the app must cold-start offline.
  final container = ProviderContainer();
  await container.read(chatRepositoryProvider).recoverInterrupted();

  runApp(
    UncontrolledProviderScope(container: container, child: const OffgridApp()),
  );
}
