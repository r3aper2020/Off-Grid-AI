import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'data/model_catalog.dart';
import 'data/model_downloader.dart';
import 'data/model_store.dart';

/// App-private directory holding GGUF files. Resolved once in `main` and
/// overridden there (and in tests).
final modelsDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('Override modelsDirectoryProvider'),
);

final modelStoreProvider = Provider<ModelStore>(
  (ref) => ModelStore(
    ref.watch(databaseProvider),
    ref.watch(modelsDirectoryProvider),
  ),
);

final installedModelsProvider = StreamProvider<List<InstalledModel>>(
  (ref) => ref.watch(modelStoreProvider).watchModels(),
);

final activeModelProvider = StreamProvider<InstalledModel?>(
  (ref) => ref.watch(modelStoreProvider).watchActive(),
);

/// Download state shown on the AI model screen. Lives in a provider so a
/// download keeps going if the user leaves the screen.
class DownloadState {
  const DownloadState({this.written, this.total, this.message, this.model});

  /// The catalog entry being downloaded, while one is.
  final CatalogModel? model;

  /// Non-null while a download is running.
  final int? written;
  final int? total;

  /// Outcome to show once (success or error); null while running.
  final String? message;

  bool get active => written != null;
}

final modelDownloadProvider =
    NotifierProvider<ModelDownloadController, DownloadState>(
      ModelDownloadController.new,
    );

class ModelDownloadController extends Notifier<DownloadState> {
  ModelDownload? _download;
  int _lastShown = 0;

  @override
  DownloadState build() {
    ref.onDispose(() => _download?.cancel());
    return const DownloadState();
  }

  Future<void> start(CatalogModel model) async {
    if (_download != null) return;
    final download = ModelDownload(ref.read(modelStoreProvider), model);
    _download = download;
    _lastShown = 0;
    state = DownloadState(written: 0, total: model.sizeBytes, model: model);
    try {
      final installed = await download.run(
        onProgress: (written) {
          // Rebuild roughly every 8 MB, not on every network chunk.
          if (written - _lastShown < 8 << 20) return;
          _lastShown = written;
          state = DownloadState(
            written: written,
            total: model.sizeBytes,
            model: model,
          );
        },
      );
      state = DownloadState(message: 'Downloaded ${installed.displayName}');
    } on DownloadCancelled {
      state = const DownloadState(message: 'Download cancelled');
    } on ModelImportException catch (e) {
      state = DownloadState(message: e.message);
    } finally {
      _download = null;
    }
  }

  void cancel() => _download?.cancel();
}
