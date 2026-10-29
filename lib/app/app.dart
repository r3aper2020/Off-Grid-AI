import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/chat_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class OffgridApp extends ConsumerStatefulWidget {
  const OffgridApp({super.key});

  @override
  ConsumerState<OffgridApp> createState() => _OffgridAppState();
}

class _OffgridAppState extends ConsumerState<OffgridApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  /// The OS is short on memory: drop the model (if idle) rather than risk
  /// the app being killed. It reloads on the next message.
  @override
  void didHaveMemoryPressure() {
    ref.read(inferenceEngineProvider).release();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OFFGRID AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
