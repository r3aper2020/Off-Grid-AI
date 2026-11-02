import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format.dart';
import '../../../core/widgets/screen_header.dart';
import '../data/map_store.dart';
import '../domain/map_style.dart';
import '../map_providers.dart';

/// Installed offline map regions: import a .pmtiles file, delete one.
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
      messenger.showSnackBar(SnackBar(content: Text('Couldn\'t open file: $e')));
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

  Future<void> _delete(MapRegion region) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${region.displayName}?'),
        content: Text(
          'Frees ${formatBytes(region.sizeBytes)}. You can import the file '
          'again later.',
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
    final regions = ref.watch(mapRegionsProvider).value ?? const [];
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
              'A map region is a .pmtiles file made on a computer with the '
              'Protomaps extract tool (tools/maps/extract_region.sh in the '
              'project). Copy it to this phone and import it here; the map '
              'then works with no connection at all.',
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
            else
              FilledButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import a .pmtiles region'),
              ),
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
              Card(
                child: Column(
                  children: [
                    for (final r in regions)
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
                          onPressed: busy ? null : () => _delete(r),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Map data: $mapAttribution (ODbL). Fonts: Noto (OFL).',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _bounds(MapRegion r) =>
      '${r.minLat.toStringAsFixed(2)}, ${r.minLon.toStringAsFixed(2)} to '
      '${r.maxLat.toStringAsFixed(2)}, ${r.maxLon.toStringAsFixed(2)}';
}
