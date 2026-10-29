import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/screen_header.dart';
import '../data/library_repository.dart';
import 'review_badge.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, this.category});

  /// Active filter, driven by the `category` query parameter.
  final PackCategory? category;

  static const _filters = <(String, PackCategory?)>[
    ('All', null),
    ('Guides', PackCategory.guide),
    ('Medical', PackCategory.medical),
    ('Maps', PackCategory.map),
    ('Notes', PackCategory.note),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(packsProvider(category));
    final sync = ref.watch(librarySyncProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: const Text('Library'),
              action: HeaderIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search library',
                onPressed: () => context.go('/library/search'),
              ),
            ),
            if (sync != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installing references… ${sync.done} of ${sync.total}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: sync.total == 0 ? null : sync.done / sync.total,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  for (final (label, value) in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: category == value,
                        labelStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: category == value
                                  ? AppColors.onAccent
                                  : AppColors.textPrimary,
                            ),
                        onSelected: (_) => context.go(
                          value == null
                              ? '/library'
                              : '/library?category=${value.name}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: packs.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Center(child: Text('Could not load: $e')),
                data: (list) => list.isEmpty
                    ? _EmptyLibrary(filtered: category != null)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PackTile(pack: list[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData packIcon(PackCategory c) => switch (c) {
  PackCategory.guide => Icons.menu_book_rounded,
  PackCategory.medical => Icons.medical_services_outlined,
  PackCategory.map => Icons.map_outlined,
  PackCategory.note => Icons.sticky_note_2_outlined,
};

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack});
  final KnowledgePack pack;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.go('/library/pack/${pack.id}'),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(packIcon(pack.category), size: 20),
        ),
        title: Text(pack.title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pack.publisher, style: Theme.of(context).textTheme.bodySmall),
            if (ReviewBadge.shortLabel(pack.reviewStatus) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ReviewBadge(status: pack.reviewStatus),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'Nothing in this category yet'
                  : 'No references installed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Reference guides appear here and stay available without a '
              'connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
