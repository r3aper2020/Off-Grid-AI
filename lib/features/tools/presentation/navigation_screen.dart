import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/topo_background.dart';

/// Navigation shell. Map tiles (MapLibre), GPS and compass are wired in the
/// navigation milestone; until then readings show as unavailable.
class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: TopoBackground()),
          const Center(child: _PositionMarker()),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    const BackButton(),
                    const Expanded(
                      child: ScreenHeader(title: Text('Navigation')),
                    ),
                  ],
                ),
                const Spacer(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: _MapControls(),
                  ),
                ),
                const SizedBox(height: 16),
                const _ReadingsBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionMarker extends StatelessWidget {
  const _PositionMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls();

  @override
  Widget build(BuildContext context) {
    // Disabled until a map and location source exist.
    const controls = [
      (Icons.near_me_outlined, 'Follow heading'),
      (Icons.my_location_rounded, 'Center on me'),
      (Icons.add_rounded, 'Zoom in'),
      (Icons.remove_rounded, 'Zoom out'),
    ];
    return Column(
      children: [
        for (final (icon, label) in controls)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HeaderIconButton(
              icon: icon,
              tooltip: label,
              onPressed: null,
            ),
          ),
      ],
    );
  }
}

class _ReadingsBar extends StatelessWidget {
  const _ReadingsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _Reading(label: 'Elevation'),
              _Reading(label: 'Accuracy'),
              _Reading(label: 'Heading'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Location and offline maps are not set up yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('—', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
