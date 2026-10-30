import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/providers.dart';
import '../chat_providers.dart';
import 'chat_input.dart';
import 'photo_picker.dart';

class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    String text,
    String? imagePath,
  ) async {
    final id = await ref
        .read(chatRepositoryProvider)
        .startConversation(text, imagePath: imagePath);
    if (!context.mounted) return;
    context.go('/chat/c/$id');
    ref.read(generationControllerProvider.notifier).reply(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recent = ref.watch(conversationsProvider).value ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: const _Wordmark(),
              action: HeaderIconButton(
                icon: Icons.history_rounded,
                tooltip: 'Conversations',
                onPressed: () => context.go('/chat/history'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Text(
                    'How can I help\nyou today?',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Private. Offline. Always.',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _QuickAction(
                    icon: Icons.warning_amber_rounded,
                    title: 'Emergency Guidance',
                    subtitle: 'Get step-by-step instructions',
                    onTap: () => context.go('/library?category=guide'),
                  ),
                  _QuickAction(
                    icon: Icons.eco_rounded,
                    title: 'Survival Tips',
                    subtitle: 'Practical knowledge offline',
                    onTap: () => context.go('/library?category=guide'),
                  ),
                  _QuickAction(
                    icon: Icons.add_rounded,
                    title: 'Health & First Aid',
                    subtitle: 'Critical information when needed',
                    onTap: () => context.go('/library?category=medical'),
                  ),
                  _QuickAction(
                    icon: Icons.near_me_rounded,
                    title: 'Navigation & Location',
                    subtitle: 'Find your way offline',
                    onTap: () => context.go('/tools/navigation'),
                  ),
                  _QuickAction(
                    icon: Icons.handyman_rounded,
                    title: 'Tools & Utilities',
                    subtitle: 'Calculations, conversions, more',
                    onTap: () => context.go('/tools'),
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Recent', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final c in recent.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        title: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => context.go('/chat/c/${c.id}'),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ChatInput(
                onSend: (t, image) => _start(context, ref, t, image),
                onAttach: () =>
                    PhotoPicker(ref.read(photosDirectoryProvider))
                        .pick(context),
                photosDirectory: ref.read(photosDirectoryProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'offgrid'),
          TextSpan(
            text: ':AI',
            style: TextStyle(color: AppColors.accent),
          ),
        ],
      ),
      semanticsLabel: 'Offgrid AI',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
