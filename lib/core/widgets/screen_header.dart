import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Title block used at the top of each tab: title, offline badge, action.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.action});

  final Widget title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.titleLarge,
                  child: title,
                ),
                const SizedBox(height: 4),
                const OfflineBadge(),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// The app makes no network calls, so this is a statement of design,
/// not a connectivity probe.
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '100% Offline',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Round icon button matching the header style in the mockups.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.textTertiary,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
