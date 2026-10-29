import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../library_providers.dart';
import 'review_badge.dart';

class PackScreen extends ConsumerWidget {
  const PackScreen({super.key, required this.packId});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(packProvider(packId)).value;
    final docs = ref.watch(packDocumentsProvider(packId)).value ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(pack?.title ?? '')),
      body: pack == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (ReviewBadge.shortLabel(pack.reviewStatus) != null) ...[
                  ReviewBadge(status: pack.reviewStatus, detailed: true),
                  const SizedBox(height: 16),
                ],
                if (pack.description.isNotEmpty) ...[
                  Text(
                    pack.description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Column(
                    children: [
                      for (final d in docs)
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(d.title),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textTertiary,
                          ),
                          onTap: () => context.push('/doc/${d.id}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('SOURCE', style: _label),
                const SizedBox(height: 6),
                Text(
                  '${pack.publisher} • ${pack.license}',
                  style: theme.textTheme.bodySmall,
                ),
                if (pack.attribution.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(pack.attribution, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 6),
                Text(
                  'Version ${pack.version}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

const _label = TextStyle(
  fontSize: 11,
  letterSpacing: 0.8,
  fontWeight: FontWeight.w700,
  color: AppColors.textTertiary,
);
