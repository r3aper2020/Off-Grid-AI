import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';

/// Warns when content is not from a verified, current authority.
/// Renders nothing for [ReviewStatus.verified].
class ReviewBadge extends StatelessWidget {
  const ReviewBadge({super.key, required this.status, this.detailed = false});

  final ReviewStatus status;

  /// Full explanation (reader banner) instead of a short label.
  final bool detailed;

  static String? shortLabel(ReviewStatus s) => switch (s) {
    ReviewStatus.verified => null,
    ReviewStatus.needsReview => 'Needs expert review',
    ReviewStatus.historical => 'Historical source',
  };

  static String? explanation(ReviewStatus s) => switch (s) {
    ReviewStatus.verified => null,
    ReviewStatus.needsReview =>
      'This reference is not from an official authority and may be '
          'outdated. Verify critical steps against current training or '
          'official guidance when you can.',
    ReviewStatus.historical =>
      'This is a historical text (before 1929), kept for traditional skills. '
          'Some practices — especially medical ones — are outdated or unsafe '
          'by modern standards.',
  };

  @override
  Widget build(BuildContext context) {
    final label = shortLabel(status);
    if (label == null) return const SizedBox.shrink();

    if (!detailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          // Flexible so large system font sizes wrap instead of overflow.
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation(status)!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
