import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart' as llama;

import '../domain/passage_vectors.dart';
import '../domain/text_embedder.dart';

/// [TextEmbedder] running the bundled bge-base-en-v1.5 model (MIT, 118 MB)
/// through llama.cpp. The model ships inside the app, so semantic search
/// works offline from the first launch; it is copied out of the bundle
/// once (llama.cpp needs a file path) and loaded on the first question.
/// Any failure disables it for the session: search falls back to keywords.
class LlamaTextEmbedder implements TextEmbedder {
  LlamaTextEmbedder({required this.directory, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle,
      _modelFile = null;

  /// Uses a model file directly (tools and tests on a desktop).
  LlamaTextEmbedder.fromFile(File model)
    : directory = model.parent,
      _bundle = rootBundle,
      _modelFile = model;

  final Directory directory;
  final AssetBundle _bundle;
  final File? _modelFile;

  static const asset = 'assets/models/bge-base-en-v1.5-q8_0.gguf';
  static const sizeBytes = 117974304;

  Future<llama.LlamaEngine?>? _engine;

  @override
  Future<List<double>?> embedQuery(String text) async {
    final engine = await (_engine ??= _load());
    if (engine == null) return null;
    try {
      return await engine.embed('${PassageVectors.queryPrefix}$text');
    } catch (e) {
      debugPrint('Embedding failed: $e');
      return null;
    }
  }

  Future<llama.LlamaEngine?> _load() async {
    try {
      final file =
          _modelFile ?? File('${directory.path}/${asset.split('/').last}');
      if (_modelFile == null &&
          (!await file.exists() || await file.length() != sizeBytes)) {
        await directory.create(recursive: true);
        final data = await _bundle.load(asset);
        final tmp = File('${file.path}.part');
        await tmp.writeAsBytes(Uint8List.sublistView(data), flush: true);
        await tmp.rename(file.path);
      }
      return await llama.LlamaEngine.load(
        llama.LlamaModel(llama.ModelSource.path(file.path)),
        params: params,
      );
    } catch (e) {
      debugPrint('Semantic search unavailable: $e');
      return null;
    }
  }

  Future<void> dispose() async => (await _engine)?.dispose();

  /// Shared with the vector build tool so passages and questions are
  /// embedded identically. CPU only: GPU backends gave vectors that varied
  /// from call to call (cosine 0.7 for the same text on macOS Metal), and
  /// the model is small enough that the CPU takes well under a second.
  static llama.ModelParams get params => llama.ModelParams(
    contextSize: 512,
    device: llama.ComputeDevice.cpu,
    numberOfThreads: Platform.isAndroid ? 4 : 0,
  );
}
