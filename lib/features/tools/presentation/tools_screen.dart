import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: Text('Tools')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _ToolTile(
                    icon: Icons.explore_outlined,
                    title: 'Navigation',
                    subtitle: 'Offline map, position and heading',
                    onTap: () => context.go('/tools/navigation'),
                  ),
                  const _ToolTile(
                    icon: Icons.checklist_rounded,
                    title: 'Preparedness',
                    subtitle: 'Household plans, supplies, checklists',
                  ),
                  const _ToolTile(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Conversions',
                    subtitle: 'Units, water purification ratios',
                  ),
                  const _ToolTile(
                    icon: Icons.emergency_outlined,
                    title: 'Emergency Mode',
                    subtitle: 'Quick-access procedures, low-power UI',
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

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Null means the tool is not built yet.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: enabled,
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: enabled
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                )
              : const Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
        ),
      ),
    );
  }
}
