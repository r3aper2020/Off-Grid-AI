import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/format.dart';
import '../../../core/keep_awake.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/topo_background.dart';
import '../data/map_store.dart';
import '../data/range_reader.dart';
import '../data/region_download.dart';
import '../domain/location_source.dart';
import '../domain/map_bounds.dart';
import '../map_providers.dart';
import 'map_view.dart';

/// Pan the map to an area, see exactly how big it is, download it. The
/// tiles come straight out of the Protomaps planet build by byte range,
/// so any place on Earth works and nothing is hosted for it.
class MapDownloadScreen extends ConsumerStatefulWidget {
  const MapDownloadScreen({super.key});

  @override
  ConsumerState<MapDownloadScreen> createState() => _MapDownloadScreenState();
}

/// Detail levels offered, by the deepest zoom fetched.
const detailLevels = [
  (zoom: 12, label: 'Towns & roads'),
  (zoom: 14, label: 'Trails & streets'),
  (zoom: 15, label: 'Everything'),
];

class _MapDownloadScreenState extends ConsumerState<MapDownloadScreen> {
  MapHandle? _map;
  int _maxZoom = 14;
  final _name = TextEditingController();
  bool _planning = false;
  RegionDownload? _download;
  RegionPlan? _plan;
  String? _error;
  ({int written, int total})? _progress;

  @override
  void dispose() {
    _download?.cancel();
    _download?.close();
    _name.dispose();
    super.dispose();
  }

  void _dropPlan() {
    _download?.close();
    _download = null;
    _plan = null;
  }

  Future<void> _check() async {
    final map = _map;
    if (map == null) return;
    final bounds = await map.visibleBounds();
    setState(() {
      _dropPlan();
      _planning = true;
      _error = null;
    });
    try {
      final reader = await ref.read(planetOpenerProvider)();
      final download = RegionDownload(ref.read(mapStoreProvider), reader);
      final plan = await download.plan(bounds: bounds, maxZoom: _maxZoom);
      if (!mounted) {
        download.close();
        return;
      }
      setState(() {
        _download = download;
        _plan = plan;
        if (_name.text.trim().isEmpty) _name.text = suggestedName(bounds);
      });
    } on RegionTooLargeException catch (e) {
      _fail(e.toString());
    } on MapImportException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Couldn\'t check that area: $e');
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _start() async {
    final download = _download;
    final plan = _plan;
    if (download == null || plan == null) return;
    final name = _name.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _progress = (written: 0, total: plan.totalBytes);
      _error = null;
    });
    var lastShown = 0;
    await keepAwake(true);
    try {
      final region = await download.run(
        plan,
        displayName: name,
        onProgress: (written) {
          if (written - lastShown < 256 << 10 || !mounted) return;
          lastShown = written;
          setState(
            () => _progress = (written: written, total: plan.totalBytes),
          );
        },
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Added ${region.displayName}')),
      );
      if (mounted) router.pop();
    } on RegionDownloadCancelled {
      // The user asked for it; nothing to say.
    } on MapImportException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Download failed: $e');
    } finally {
      await keepAwake(false);
      if (mounted) {
        setState(() {
          _progress = null;
          _download = null;
          _plan = null;
        });
      }
    }
  }

  void _cancel() => _download?.cancel();

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(mapStyleProvider).value;
    final regions = ref.watch(mapRegionsProvider).value ?? const [];
    final access = ref.watch(locationAccessProvider).value;
    final fix = ref.watch(positionProvider).value;
    final granted = access == LocationAccess.granted;
    final last = regions.lastOrNull;

    Widget map;
    if (style != null) {
      map = ref.watch(mapViewBuilderProvider)(
        MapViewSpec(
          style: style,
          centerLat:
              fix?.latitude ??
              (last == null ? 20 : (last.minLat + last.maxLat) / 2),
          centerLon:
              fix?.longitude ??
              (last == null ? 0 : (last.minLon + last.maxLon) / 2),
          zoom: fix != null ? 9 : (last != null ? 8 : 1),
          locationEnabled: granted,
          followHeading: false,
          onMapCreated: (m) => setState(() => _map = m),
          onHeading: (_) {},
          onFollowDismissed: () {},
          onCameraIdle: () {
            // The area changed: the size shown no longer applies.
            if (_plan != null && _progress == null && mounted) {
              setState(_dropPlan);
            }
          },
        ),
      );
    } else {
      map = const TopoBackground();
    }

    final plan = _plan;
    final progress = _progress;
    final busy = _planning || progress != null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const BackButton(),
                const Expanded(
                  child: ScreenHeader(title: Text('Download a map')),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: map),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        HeaderIconButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Center on me',
                          onPressed: _map != null && granted ? _center : null,
                        ),
                        const SizedBox(height: 10),
                        HeaderIconButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom in',
                          onPressed: _map == null ? null : () => _map?.zoomIn(),
                        ),
                        const SizedBox(height: 10),
                        HeaderIconButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom out',
                          onPressed: _map == null
                              ? null
                              : () => _map?.zoomOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pan and zoom until the area you want fills the map.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: [
                      for (final d in detailLevels)
                        ButtonSegment(value: d.zoom, label: Text(d.label)),
                    ],
                    selected: {_maxZoom},
                    showSelectedIcon: false,
                    onSelectionChanged: busy
                        ? null
                        : (s) => setState(() {
                            _maxZoom = s.first;
                            _dropPlan();
                          }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Smokies north',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (progress != null) ...[
                    LinearProgressIndicator(
                      value: progress.written / progress.total,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Downloading… ${formatBytes(progress.written)} of '
                            '${formatBytes(progress.total)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: _cancel,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ] else if (plan == null)
                    FilledButton.icon(
                      onPressed: _map == null || _planning ? null : _check,
                      icon: _planning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.straighten_rounded),
                      label: Text(_planning ? 'Finding tiles…' : 'Check size'),
                    )
                  else ...[
                    Text(
                      '${formatBytes(plan.totalBytes)} · ${plan.tileCount} '
                      'tiles · zoom ${plan.minZoom}–${plan.maxZoom}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _name.text.trim().isEmpty ? null : _start,
                      icon: const Icon(Icons.download_rounded),
                      label: Text('Download ${formatBytes(plan.totalBytes)}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _center() async {
    final m = _map;
    if (m == null) return;
    final fix = ref.read(positionProvider).value;
    final target = fix != null
        ? (fix.latitude, fix.longitude)
        : await m.myLocation();
    if (target == null) return;
    await m.moveTo(target.$1, target.$2, 9);
  }
}

/// "Map 35.6°N 83.5°W": a name to edit, from the area's center.
String suggestedName(MapBounds b) {
  final lat = b.centerLat, lon = b.centerLon;
  return 'Map ${lat.abs().toStringAsFixed(1)}°${lat >= 0 ? 'N' : 'S'} '
      '${lon.abs().toStringAsFixed(1)}°${lon >= 0 ? 'E' : 'W'}';
}
