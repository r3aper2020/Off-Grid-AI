import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/topo_background.dart';
import '../../maps/domain/location_source.dart';
import '../../maps/domain/map_style.dart';
import '../../maps/map_providers.dart';
import '../../maps/presentation/map_view.dart';

/// Offline map of the bundled world overview and the installed regions,
/// with the phone's position and heading. Without a region the screen
/// still shows the world and GPS readings, and says where to get a map.
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  MapHandle? _map;
  bool _follow = false;
  double? _compass;
  bool _jumpedToFix = false;

  @override
  Widget build(BuildContext context) {
    // The map opens on the world; the first fix brings it to the phone.
    ref.listen(positionProvider, (_, next) {
      final fix = next.value;
      final m = _map;
      if (fix == null || m == null || _jumpedToFix) return;
      _jumpedToFix = true;
      m.moveTo(fix.latitude, fix.longitude, 11);
    });
    final regions = ref.watch(mapRegionsProvider).value ?? const [];
    final style = ref.watch(mapStyleProvider).value;
    final access = ref.watch(locationAccessProvider).value;
    final fix = ref.watch(positionProvider).value;
    final granted = access == LocationAccess.granted;
    final heading = _compass ?? fix?.heading;

    Widget map;
    if (style != null) {
      final first = regions.firstOrNull;
      map = ref.watch(mapViewBuilderProvider)(
        MapViewSpec(
          style: style,
          centerLat:
              fix?.latitude ??
              (first == null ? 20 : (first.minLat + first.maxLat) / 2),
          centerLon:
              fix?.longitude ??
              (first == null ? 0 : (first.minLon + first.maxLon) / 2),
          zoom: fix != null ? 13 : (first != null ? 9 : 1),
          locationEnabled: granted,
          followHeading: _follow,
          onMapCreated: (m) {
            setState(() => _map = m);
            final f = ref.read(positionProvider).value;
            if (f != null && !_jumpedToFix) {
              _jumpedToFix = true;
              m.moveTo(f.latitude, f.longitude, 11);
            }
          },
          onHeading: (h) {
            if (h != _compass && mounted) setState(() => _compass = h);
          },
          onFollowDismissed: () {
            if (_follow && mounted) setState(() => _follow = false);
          },
        ),
      );
    } else {
      _map = null;
      map = const TopoBackground();
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: map),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    const BackButton(),
                    const Expanded(
                      child: ScreenHeader(title: Text('Navigation')),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: HeaderIconButton(
                        icon: Icons.layers_outlined,
                        tooltip: 'Map layers',
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => const MapLayersSheet(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (regions.isEmpty)
                  _NoRegionBanner(
                    onDownload: () => context.push('/settings/maps/download'),
                  ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _MapControls(
                      enabled: _map != null,
                      following: _follow,
                      canCenter: granted,
                      onFollow: _toggleFollow,
                      onCenter: () => _center(fix),
                      onZoomIn: () => _map?.zoomIn(),
                      onZoomOut: () => _map?.zoomOut(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (style != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mapAttribution,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                _ReadingsBar(fix: fix, access: access, heading: heading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    final m = _map;
    if (m == null) return;
    setState(() => _follow = !_follow);
    await m.setFollowHeading(_follow);
  }

  Future<void> _center(Fix? fix) async {
    final m = _map;
    if (m == null) return;
    final target = fix != null
        ? (fix.latitude, fix.longitude)
        : await m.myLocation();
    if (target == null) return;
    await m.moveTo(target.$1, target.$2, 14);
  }
}

/// Streets, topo or satellite, plus hillshade: whichever layers the
/// installed regions have. The rest point at Offline maps.
class MapLayersSheet extends ConsumerWidget {
  const MapLayersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(mapRegionsProvider).value ?? const [];
    final available = availableLayerKinds(regions);
    final choice = ref.watch(mapLayerChoiceProvider);
    final controller = ref.read(mapLayerChoiceProvider.notifier);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map layers', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<MapLayerKind>(
              segments: [
                const ButtonSegment(
                  value: MapLayerKind.streets,
                  label: Text('Streets'),
                ),
                ButtonSegment(
                  value: MapLayerKind.topo,
                  label: const Text('Topo'),
                  enabled: available.contains(MapLayerKind.topo),
                ),
                ButtonSegment(
                  value: MapLayerKind.imagery,
                  label: const Text('Satellite'),
                  enabled: available.contains(MapLayerKind.imagery),
                ),
              ],
              selected: {choice.basemap},
              showSelectedIcon: false,
              onSelectionChanged: (s) => controller.setBasemap(s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hillshade'),
              subtitle: Text(
                available.contains(MapLayerKind.terrain)
                    ? 'Shaded relief from elevation data'
                    : 'Add elevation to a region to turn this on',
                style: theme.textTheme.bodySmall,
              ),
              value: choice.hillshade,
              onChanged: available.contains(MapLayerKind.terrain)
                  ? controller.setHillshade
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/settings/maps');
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Offline maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown over the world overview until a region is installed.
class _NoRegionBanner extends StatelessWidget {
  const _NoRegionBanner({required this.onDownload});
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Only the world overview is installed',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Download a region for roads, trails and towns.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onDownload, child: const Text('Download')),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.enabled,
    required this.following,
    required this.canCenter,
    required this.onFollow,
    required this.onCenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final bool enabled;
  final bool following;
  final bool canCenter;
  final VoidCallback onFollow;
  final VoidCallback onCenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final controls = [
      (
        following ? Icons.near_me_rounded : Icons.near_me_outlined,
        'Follow heading',
        enabled && canCenter ? onFollow : null,
      ),
      (
        Icons.my_location_rounded,
        'Center on me',
        enabled && canCenter ? onCenter : null,
      ),
      (Icons.add_rounded, 'Zoom in', enabled ? onZoomIn : null),
      (Icons.remove_rounded, 'Zoom out', enabled ? onZoomOut : null),
    ];
    return Column(
      children: [
        for (final (icon, label, onPressed) in controls)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HeaderIconButton(
              icon: icon,
              tooltip: label,
              onPressed: onPressed,
            ),
          ),
      ],
    );
  }
}

class _ReadingsBar extends StatelessWidget {
  const _ReadingsBar({
    required this.fix,
    required this.access,
    required this.heading,
  });

  final Fix? fix;
  final LocationAccess? access;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    final f = fix;
    final status = switch (access) {
      null => 'Checking location access…',
      LocationAccess.servicesOff => 'Location services are off',
      LocationAccess.denied => 'Location permission denied',
      LocationAccess.deniedForever =>
        'Location permission denied — allow it in system settings',
      LocationAccess.granted when f == null => 'Waiting for a GPS fix…',
      LocationAccess.granted => formatCoordinates(f!.latitude, f.longitude),
    };
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
          Row(
            children: [
              _Reading(
                label: 'Elevation',
                value: f?.altitude == null ? null : '${f!.altitude!.round()} m',
              ),
              _Reading(
                label: 'Accuracy',
                value: f?.accuracy == null
                    ? null
                    : '±${f!.accuracy!.round()} m',
              ),
              _Reading(
                label: 'Heading',
                value: heading == null ? null : '${heading!.round() % 360}°',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// "35.60000° N, 83.47500° W": what you'd read out over a radio.
String formatCoordinates(double lat, double lon) {
  final ns = lat >= 0 ? 'N' : 'S';
  final ew = lon >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(5)}° $ns, '
      '${lon.abs().toStringAsFixed(5)}° $ew';
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value ?? '—', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
