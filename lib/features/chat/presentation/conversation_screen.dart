import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../library/data/knowledge_search.dart';
import '../../library/library_providers.dart';
import '../../library/domain/pack_format.dart';
import '../../library/presentation/passage_body.dart';
import '../../library/presentation/review_badge.dart';
import '../chat_providers.dart';
import '../domain/grounding.dart';
import '../domain/inference_engine.dart';
import 'chat_input.dart';
import 'message_text.dart';
import 'photo_picker.dart';
import 'thinking_indicator.dart';

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final int conversationId;

  Future<void> _send(WidgetRef ref, String text, String? imagePath) async {
    await ref
        .read(chatRepositoryProvider)
        .addUserMessage(conversationId, text, imagePath: imagePath);
    ref.read(generationControllerProvider.notifier).reply(conversationId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    final messages = ref.watch(messagesProvider(conversationId));
    final phase = ref.watch(generationControllerProvider)[conversationId];
    final generating = phase != null;

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
                  itemBuilder: (context, i) => _MessageBubble(
                    message: list[list.length - 1 - i],
                    phase: phase,
                    photosDirectory: ref.read(photosDirectoryProvider),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ChatInput(
                generating: generating,
                onSend: (t, image) => _send(ref, t, image),
                onAttach: () =>
                    PhotoPicker(ref.read(photosDirectoryProvider))
                        .pick(context),
                photosDirectory: ref.read(photosDirectoryProvider),
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
  const _MessageBubble({
    required this.message,
    this.phase,
    required this.photosDirectory,
  });

  final Message message;
  final Directory photosDirectory;

  /// Progress of the reply in this conversation, if one is running.
  final GenerationPhase? phase;

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

    final waiting =
        message.content.isEmpty && message.status == MessageStatus.streaming;
    final text = message.content;

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
              if (message.imagePath != null)
                Padding(
                  padding: EdgeInsets.only(bottom: text.isEmpty ? 0 : 8),
                  child: _Photo(
                    file: File('${photosDirectory.path}/${message.imagePath}'),
                  ),
                ),
              if (waiting)
                ThinkingIndicator(phase: phase)
              else if (isUser || isNotice)
                (text.isEmpty ? const SizedBox.shrink() : SelectableText(text))
              else
                MessageText(text),
              // While the model is still reading or writing, show what it
              // was given: the passages are known within a second or two,
              // and the user can read them long before the reply arrives.
              if (message.role == MessageRole.assistant &&
                  message.status == MessageStatus.streaming &&
                  message.citations != null)
                _ReadingSources(citationsJson: message.citations!),
              if (message.role == MessageRole.assistant &&
                  message.status == MessageStatus.complete &&
                  message.citations != null)
                _Sources(
                  citationsJson: message.citations!,
                  cited: Grounding.citedNumbers(message.content),
                ),
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

/// A photo attached to a message; tap to view it full screen.
class _Photo extends StatelessWidget {
  const _Photo({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SafeArea(
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          file,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Photo no longer available',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The passages given to the model for a reply still in progress, as
/// tappable chips, so the wait for the first word is useful: the user can
/// open the Forest Service page while the model is still reading it.
class _ReadingSources extends ConsumerWidget {
  const _ReadingSources({required this.citationsJson});

  final String citationsJson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(citationSourcesProvider(citationsJson)).value;
    if (sources == null) return const SizedBox.shrink();
    final hits = sources.whereType<PassageHit>().toList();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hits.isEmpty
                ? 'Nothing in the offline library matched; answering from '
                      'general knowledge'
                : 'Reading from your library — tap to open:',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          if (hits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final hit in hits)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      hit.heading,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    tooltip: '${hit.documentTitle} — ${hit.heading}',
                    onPressed: () => context.push(
                      '/doc/${hit.documentId}?passage=${hit.passageId}',
                    ),
                    side: hit.reviewStatus == ReviewStatus.verified
                        ? null
                        : const BorderSide(color: AppColors.warning),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable sources under an assistant reply: one chip per citation the
/// model actually used. Replies citing nothing are labelled as such so
/// users can tell library-backed answers from general knowledge.
class _Sources extends ConsumerWidget {
  const _Sources({required this.citationsJson, required this.cited});

  final String citationsJson;
  final List<int> cited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(citationSourcesProvider(citationsJson)).value;
    if (sources == null) return const SizedBox.shrink();

    final used = [
      for (final n in cited)
        if (n >= 1 && n <= sources.length && sources[n - 1] != null)
          (n, sources[n - 1]!),
    ];

    if (used.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                'Not from the offline library',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      );
    }

    final flagged = used
        .map((u) => u.$2.reviewStatus)
        .where((s) => s != ReviewStatus.verified)
        .toSet();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (n, hit) in used)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  label: Text(
                    hit.heading,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  tooltip: '${hit.documentTitle} — ${hit.heading}',
                  onPressed: () => context.push(
                    '/doc/${hit.documentId}?passage=${hit.passageId}',
                  ),
                  side: hit.reviewStatus == ReviewStatus.verified
                      ? null
                      : const BorderSide(color: AppColors.warning),
                ),
            ],
          ),
          for (final status in flagged)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ReviewBadge(status: status),
            ),
          // Diagrams and tables from the cited passages, so a "how do I"
          // answer shows the picture, and table values stay exact.
          _CitedImages(
            passageIds: [for (final (_, hit) in used) hit.passageId],
          ),
        ],
      ),
    );
  }
}

class _CitedImages extends ConsumerWidget {
  const _CitedImages({required this.passageIds});

  final List<int> passageIds;

  /// Enough to cover a procedure's figures without an endless strip.
  static const _max = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images =
        (ref.watch(citedFiguresProvider(passageIds.join(','))).value ??
                const <SectionImage>[])
            .take(_max)
            .toList();
    if (images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final img = images[i];
            return Semantics(
              image: true,
              button: true,
              label: img.caption,
              child: GestureDetector(
                onTap: () => openImageViewer(context, img),
                child: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColoredBox(
                            color: Colors.white,
                            child: Image.asset(
                              img.asset,
                              width: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        img.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
