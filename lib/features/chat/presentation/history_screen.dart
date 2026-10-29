import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../chat_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: conversations.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  'No conversations yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(indent: 16),
                itemBuilder: (context, i) {
                  final c = list[i];
                  return Dismissible(
                    key: ValueKey(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppColors.danger,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_outline_rounded),
                    ),
                    onDismissed: (_) => ref
                        .read(chatRepositoryProvider)
                        .deleteConversation(c.id),
                    child: ListTile(
                      title: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        localizations.formatShortDate(c.updatedAt),
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                      onTap: () => context.go('/chat/c/${c.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
