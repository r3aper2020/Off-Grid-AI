import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../chat/chat_providers.dart';
import '../../chat/domain/inference_engine.dart';
import '../../library/data/library_repository.dart';
import '../../maps/map_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all conversations?'),
        content: const Text('This removes every chat from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(chatRepositoryProvider).deleteAll();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineStatusProvider).value;
    final packCount = ref.watch(packsProvider(null)).value?.length ?? 0;
    final chatCount = ref.watch(conversationsProvider).value?.length ?? 0;
    final regionCount = ref.watch(mapRegionsProvider).value?.length ?? 0;

    final modelSummary = switch (engine) {
      EngineReady(:final modelName) => modelName,
      EngineUnavailable() => 'Not installed — tap to import',
      null => '…',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: Text('Settings')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _Section(
                    title: 'On-device AI',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.memory_rounded),
                        title: const Text('Model'),
                        subtitle: Text(modelSummary),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () => context.go('/settings/models'),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Offline maps',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: const Text('Map regions'),
                        subtitle: Text(
                          regionCount == 0
                              ? 'None installed — tap to import'
                              : '$regionCount installed',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () => context.go('/settings/maps'),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Knowledge',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.library_books_outlined),
                        title: const Text('Installed packs'),
                        subtitle: Text('$packCount installed'),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Data',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.forum_outlined),
                        title: const Text('Delete all conversations'),
                        subtitle: Text('$chatCount stored on this device'),
                        enabled: chatCount > 0,
                        onTap: () => _confirmClear(context, ref),
                      ),
                    ],
                  ),
                  const _Section(
                    title: 'Privacy',
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock_outline_rounded),
                        title: Text('Everything stays on this phone'),
                        subtitle: Text(
                          'No account, no analytics, no cloud. Chats and '
                          'references are stored only in app-private storage.',
                        ),
                      ),
                    ],
                  ),
                  const _Section(
                    title: 'About',
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('OFFGRID AI'),
                        subtitle: Text('Version 1.0.0 (foundation build)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}
