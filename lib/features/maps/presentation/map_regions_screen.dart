import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format.dart';
import '../../../core/widgets/screen_header.dart';
import '../data/map_store.dart';
import '../domain/map_style.dart';
import '../domain/raster_sources.dart';
import '../map_providers.dart';

/// Installed offline map regions: download one, import a .pmtiles file,
/// delete one.
class MapRegionsScreen extends ConsumerStatefulWidget {
  const MapRegionsScreen({super.key});

  @override
  ConsumerState<MapRegionsScreen> createState() => _MapRegionsScreenState();
}

class _MapRegionsScreenState extends ConsumerState<MapRegionsScreen> {
  ({int written, int? total})? _progress;

  Future<void> _import() async {
    final store = ref.read(mapStoreProvider);
    final messenger = ScaffoldMessenger.of(context);

    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn\'t open file: $e')),
      );
      return;
    }
    if (picked == null) return;

    final total = picked.lengthSync() ?? await picked.length();
    setState(() => _progress = (written: 0, total: total));
    var lastShown = 0;
    try {
      final region = await store.import(
        originalName: picked.name,
        bytes: picked.readAsByteStream(),
        onProgress: (written) {
          if (written - lastShown < 4 << 20 || !mounted) return;
          lastShown = written;
          setState(() => _progress = (written: written, total: total));
        },
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Added ${region.displayName}')),
      );
    } on MapImportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      await FilePicker.clearTemporaryFiles().catchError((_) {});
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _addLayer(MapRegion parent, MapLayerKind kind) async {
    final controller = ref.read(layerDownloadProvider.notifier);
    final source = ref.read(rasterSourcesProvider)[kind]!;
    final plan = await controller.estimate(parent, kind);
    if (plan == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${source.label} to ${parent.displayName}?'),
        content: Text(
          'About ${formatBytes(plan.estimatedBytes)} (${plan.tileCount} '
          'tiles, zoom ${plan.minZoom}–${plan.maxZoom}) from '
          '${source.attribution}. Use Wi-Fi if you can; the screen stays on '
          'until it finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (ok == true) controller.start(plan);
  }

  Future<void> _delete(MapRegion region) async {
    final children = (ref.read(mapRegionsProvider).value ?? const [])
        .where((r) => r.parentId == region.id)
        .toList();
    final total =
        region.sizeBytes + children.fold<int>(0, (n, r) => n + r.sizeBytes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${region.displayName}?'),
        content: Text(
          children.isEmpty
              ? 'Frees ${formatBytes(total)}. You can download it again later.'
              : 'Also removes its ${children.length} extra '
                    '${children.length == 1 ? 'layer' : 'layers'}. Frees '
                    '${formatBytes(total)}. You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(mapStoreProvider).delete(region);
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(mapRegionsProvider).value ?? const [];
    final regions = rows.where((r) => r.kind == MapLayerKind.streets).toList();
    final layersOf = <int, Map<MapLayerKind, MapRegion>>{};
    for (final r in rows) {
      final parent = r.parentId;
      if (parent != null) (layersOf[parent] ??= {})[r.kind] = r;
    }
    final layerDownload = ref.watch(layerDownloadProvider);
    ref.listen(layerDownloadProvider.select((d) => d.message), (_, message) {
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final progress = _progress;
    final busy = progress != null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                const BackButton(),
                const Expanded(
                  child: ScreenHeader(title: Text('Offline maps')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The world overview (coastlines, countries, big cities) is '
              'built in. For roads, trails and towns, download the area you '
              'need while you have a connection, or import a .pmtiles file '
              'made on a computer (tools/maps/extract_region.sh in the '
              'project). After that the map needs no connection at all.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (busy)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress.total == null
                        ? null
                        : progress.written / progress.total!,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Importing… ${formatBytes(progress.written)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else ...[
              FilledButton.icon(
                onPressed: () => context.push('/settings/maps/download'),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download a region'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import a .pmtiles file'),
              ),
            ],
            const SizedBox(height: 24),
            if (regions.isNotEmpty) ...[
              const Text(
                'INSTALLED',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in regions)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.map_outlined,
                          color: AppColors.accent,
                        ),
                        title: Text(r.displayName),
                        subtitle: Text(
                          '${formatBytes(r.sizeBytes)} • zoom ${r.minZoom}–'
                          '${r.maxZoom} • ${_bounds(r)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.textTertiary,
                          onPressed: busy || layerDownload.active
                              ? null
                              : () => _delete(r),
                        ),
                      ),
                      for (final kind in const [
                        MapLayerKind.topo,
                        MapLayerKind.imagery,
                        MapLayerKind.terrain,
                      ])
                        _LayerRow(
                          parent: r,
                          kind: kind,
                          installed: layersOf[r.id]?[kind],
                          download: layerDownload,
                          onAdd: busy || layerDownload.active
                              ? null
                              : () => _addLayer(r, kind),
                          onCancel: ref
                              .read(layerDownloadProvider.notifier)
                              .cancel,
                          onDelete: (layer) =>
                              ref.read(mapStoreProvider).delete(layer),
                        ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Map data: $mapAttribution (ODbL). Topo and satellite: USGS '
                'The National Map (public domain). Hillshade: $_terrainCredit. '
                'Fonts: Noto (OFL).',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String get _terrainCredit =>
      rasterSources[MapLayerKind.terrain]!.attribution;

  static String _bounds(MapRegion r) =>
      '${r.minLat.toStringAsFixed(2)}, ${r.minLon.toStringAsFixed(2)} to '
      '${r.maxLat.toStringAsFixed(2)}, ${r.maxLon.toStringAsFixed(2)}';
}

/// One extra layer of a region: installed (with delete), downloading
/// (progress and cancel), or an Add button.
class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.parent,
    required this.kind,
    required this.installed,
    required this.download,
    required this.onAdd,
    required this.onCancel,
    required this.onDelete,
  });

  final MapRegion parent;
  final MapLayerKind kind;
  final MapRegion? installed;
  final LayerDownloadState download;
  final VoidCallback? onAdd;
  final VoidCallback onCancel;
  final void Function(MapRegion layer) onDelete;

  @override
  Widget build(BuildContext context) {
    final source = rasterSources[kind]!;
    final theme = Theme.of(context);
    final layer = installed;
    final icon = switch (kind) {
      MapLayerKind.topo => Icons.terrain_rounded,
      MapLayerKind.imagery => Icons.satellite_alt_rounded,
      _ => Icons.landscape_rounded,
    };
    Widget body;
    if (download.isFor(parent, kind)) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            download.estimating
                ? '${source.label}: checking size…'
                : '${source.label}: ${download.tiles} of '
                      '${download.tilesTotal} tiles · '
                      '${formatBytes(download.bytes)}',
            style: theme.textTheme.bodySmall,
          ),
          if (!download.estimating) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: download.tilesTotal == 0
                  ? null
                  : download.tiles / download.tilesTotal,
            ),
          ],
        ],
      );
    } else if (layer != null) {
      body = Text(
        '${source.label} · ${formatBytes(layer.sizeBytes)} · zoom '
        '${layer.minZoom}–${layer.maxZoom}',
        style: theme.textTheme.bodyMedium,
      );
    } else {
      body = Text(
        '${source.label} · not downloaded',
        style: theme.textTheme.bodySmall,
      );
    }
    final Widget trailing;
    if (download.isFor(parent, kind)) {
      trailing = download.estimating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(onPressed: onCancel, child: const Text('Cancel'));
    } else if (layer != null) {
      trailing = IconButton(
        tooltip: 'Delete ${source.label}',
        icon: const Icon(Icons.delete_outline_rounded),
        color: AppColors.textTertiary,
        onPressed: download.active ? null : () => onDelete(layer),
      );
    } else {
      trailing = TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('Add ${source.label}'),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: body),
          trailing,
        ],
      ),
    );
  }
}
