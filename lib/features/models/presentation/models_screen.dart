import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format.dart';
import '../data/model_catalog.dart';
import '../data/model_store.dart';
import '../model_providers.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  /// Non-null while importing: bytes written and total size if known.
  ({int written, int? total})? _progress;

  Future<void> _import() async {
    final store = ref.read(modelStoreProvider);
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
      final model = await store.import(
        originalName: picked.name,
        bytes: picked.readAsByteStream(),
        onProgress: (written) {
          // Throttle rebuilds to roughly every 16 MB.
          if (written - lastShown < 16 << 20 || !mounted) return;
          lastShown = written;
          setState(() => _progress = (written: written, total: total));
        },
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Imported ${model.displayName}')),
      );
    } on ModelImportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      await FilePicker.clearTemporaryFiles().catchError((_) {});
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _delete(InstalledModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.displayName}?'),
        content: Text(
          'Frees ${formatBytes(model.sizeBytes)}. You can import it again '
          'later from the file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(modelStoreProvider).delete(model);
  }

  Future<void> _download(CatalogModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.displayName}?'),
        content: Text(
          'This downloads ${formatBytes(model.sizeBytes)}. Use Wi-Fi if you '
          'can, and keep the app open until it finishes. After that the '
          'model works with no connection.',
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
    if (ok == true) ref.read(modelDownloadProvider.notifier).start(model);
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(installedModelsProvider).value ?? const [];
    final textModel = ref.watch(textModelProvider);
    final visionModel = ref.watch(visionModelProvider);
    final progress = _progress;
    final download = ref.watch(modelDownloadProvider);
    final busy = progress != null || download.active;
    final available = [
      for (final c in ModelCatalog.models)
        if (!models.any(
          (m) => ModelCatalog.isInstalled(c, m.fileName, m.displayName),
        ))
          c,
    ];

    ref.listen(modelDownloadProvider.select((d) => d.message), (_, message) {
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('AI model')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Models run entirely on this phone. Downloading one needs an '
            'internet connection once; after that it works with no '
            'connection at all.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (download.active)
            _ImportProgress(
              label: 'Downloading ${download.model?.displayName ?? 'model'}…',
              written: download.written!,
              total: download.total,
              onCancel: ref.read(modelDownloadProvider.notifier).cancel,
            ),
          if (available.isNotEmpty && !download.active) ...[
            const Text(
              'DOWNLOAD',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in available) ...[
              _CatalogCard(
                model: c,
                recommended: c == ModelCatalog.recommended,
                onDownload: busy ? null : () => _download(c),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          if (progress != null)
            _ImportProgress(
              label: 'Importing model…',
              written: progress.written,
              total: progress.total,
            )
          else
            OutlinedButton.icon(
              onPressed: busy ? null : _import,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Import a .gguf file instead'),
            ),
          const SizedBox(height: 24),
          if (models.isNotEmpty) ...[
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
                  for (final m in models)
                    ListTile(
                      leading: Icon(
                        m.id == textModel?.id || m.id == visionModel?.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color:
                            m.id == textModel?.id || m.id == visionModel?.id
                            ? AppColors.accent
                            : AppColors.textTertiary,
                      ),
                      title: Text(m.displayName),
                      subtitle: Text(
                        [
                          formatBytes(m.sizeBytes),
                          _roleOf(m, textModel, visionModel),
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: m.isActive
                          ? null
                          : () => ref.read(modelStoreProvider).setActive(m.id),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.textTertiary,
                        onPressed: busy ? null : () => _delete(m),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.model,
    required this.recommended,
    required this.onDownload,
  });

  final CatalogModel model;
  final bool recommended;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommended) ...[
              const Text(
                'RECOMMENDED',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              model.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(model.summary, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              '${formatBytes(model.sizeBytes)} • ${model.license} license • '
              'needs ${model.minMemoryGb} GB+ phone',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: recommended
                  ? FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    )
                  : OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportProgress extends StatelessWidget {
  const _ImportProgress({
    required this.label,
    required this.written,
    required this.total,
    this.onCancel,
  });

  final String label;
  final int written;
  final int? total;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = total;
    final fraction = t == null || t == 0 ? null : written / t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                if (onCancel != null)
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              t == null
                  ? formatBytes(written)
                  : '${formatBytes(written)} of ${formatBytes(t)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// What a model does on this phone. The app picks models by kind, so the
/// user only ever chooses a preference, never switches by hand.
String _roleOf(
  InstalledModel m,
  InstalledModel? textModel,
  InstalledModel? visionModel,
) {
  final answersText = m.id == textModel?.id;
  final answersPhotos = m.id == visionModel?.id;
  if (answersText && answersPhotos) return 'Answers text and photos';
  if (answersText) return 'Answers text';
  if (answersPhotos) return 'Answers photos';
  return m.projectorFileName != null
      ? 'Tap to use for photos'
      : 'Tap to use for text';
}
