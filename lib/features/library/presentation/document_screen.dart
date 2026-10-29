import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../library_providers.dart';
import '../domain/pack_format.dart';
import 'passage_body.dart';
import 'review_badge.dart';

/// Reads one document. When opened from a citation or search result,
/// [passageId] is scrolled into view and highlighted.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.documentId, this.passageId});

  final int documentId;
  final int? passageId;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final _targetKey = GlobalKey();
  bool _scrolled = false;

  void _scrollToTarget() {
    if (_scrolled || widget.passageId == null) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _targetKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(documentProvider(widget.documentId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.value?.doc.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: data.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (d) {
          if (d == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'This reference is no longer installed.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          _scrollToTarget();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.pack != null &&
                    d.pack!.reviewStatus != ReviewStatus.verified) ...[
                  ReviewBadge(status: d.pack!.reviewStatus, detailed: true),
                  const SizedBox(height: 20),
                ],
                for (final p in d.passages)
                  Container(
                    key: p.id == widget.passageId ? _targetKey : null,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: p.id == widget.passageId
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    decoration: p.id == widget.passageId
                        ? BoxDecoration(
                            color: AppColors.accentMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.heading, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        PassageBody(
                          body: p.body,
                          images: SectionImage.listFromJson(p.images),
                        ),
                      ],
                    ),
                  ),
                if (d.doc.sourceUrl != null) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Source: ${d.doc.sourceUrl}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
