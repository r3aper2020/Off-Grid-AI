import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../chat_providers.dart';
import 'chat_input.dart';

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final int conversationId;

  Future<void> _send(WidgetRef ref, String text) async {
    await ref.read(chatRepositoryProvider).addUserMessage(conversationId, text);
    ref.read(generationControllerProvider.notifier).reply(conversationId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    final messages = ref.watch(messagesProvider(conversationId));
    final generating = ref
        .watch(generationControllerProvider)
        .contains(conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversation.value?.title ?? 'Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Center(child: Text('Could not load: $e')),
                data: (list) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _MessageBubble(message: list[list.length - 1 - i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ChatInput(
                generating: generating,
                onSend: (t) => _send(ref, t),
                onStop: () => ref
                    .read(generationControllerProvider.notifier)
                    .cancel(conversationId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isNotice = message.status == MessageStatus.notice;
    final isProblem = message.status == MessageStatus.failed;

    final background = isUser
        ? AppColors.accentMuted
        : isNotice
        ? AppColors.surfaceRaised
        : AppColors.surface;

    final text =
        message.content.isEmpty && message.status == MessageStatus.streaming
        ? '…'
        : message.content;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isProblem ? AppColors.danger : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNotice)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'OFFGRID AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              SelectableText(text),
              if (message.status == MessageStatus.cancelled)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Stopped',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
