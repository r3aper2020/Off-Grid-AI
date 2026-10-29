import 'dart:async';
import 'dart:io';

import 'package:llamadart/llamadart.dart' as llama;

import '../domain/inference_engine.dart';

/// [InferenceEngine] backed by llama.cpp through `llamadart`.
///
/// The model loads lazily on the first [generate] and stays resident until
/// [release] (memory pressure) or [dispose] (model switched or deleted).
/// llamadart runs llama.cpp on its own isolate, so the UI stays responsive.
class LlamaInferenceEngine implements InferenceEngine {
  LlamaInferenceEngine({required this.modelFile, required this.modelName});

  final File modelFile;
  final String modelName;

  static const _contextTokens = 4096;
  static const _maxReplyTokens = 1024;

  /// Conservative prompt budget in characters (~3 chars per token), leaving room
  /// for the reply inside the context window.
  static const _historyCharBudget = (_contextTokens - _maxReplyTokens) * 3;

  static const systemPrompt =
      'You are OFFGRID AI, a calm, practical assistant running entirely on '
      'the user\'s phone with no internet access. Give clear, concise, '
      'step-by-step answers. Prioritize safety. If something could be a '
      'life-threatening emergency and help may be reachable, say to contact '
      'emergency services first. If you are not sure, say so plainly rather '
      'than guessing.';

  llama.LlamaEngine? _engine;
  Future<llama.LlamaEngine>? _loading;
  bool _generating = false;
  bool _disposed = false;

  @override
  Future<EngineStatus> status() async {
    if (!await modelFile.exists()) {
      return const EngineUnavailable(
        'The installed model file is missing. Re-import it from Settings → '
        'AI model.',
      );
    }
    return EngineReady(modelName);
  }

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) async* {
    final llama.LlamaEngine engine;
    try {
      engine = await _ensureLoaded();
    } on Object catch (e) {
      yield GenerationFailed(_loadFailureMessage(e));
      return;
    }

    _generating = true;
    try {
      final chunks = engine.create(
        _toMessages(history),
        params: const llama.GenerationParams(maxTokens: _maxReplyTokens),
        enableThinking: false,
      );
      // Cancelling our subscription cancels this await-for, which llamadart
      // forwards to the backend immediately.
      await for (final chunk in chunks) {
        final text = chunk.text;
        if (text.isNotEmpty) yield GenerationToken(text);
      }
      yield const GenerationDone();
    } on llama.LlamaException catch (e) {
      yield GenerationFailed('The model stopped with an error: ${e.message}');
    } finally {
      _generating = false;
    }
  }

  @override
  Future<void> release() async {
    if (_generating) return;
    final engine = _engine;
    _engine = null;
    _loading = null;
    await engine?.dispose();
  }

  @override
  Future<void> dispose() async {
    // A load still in flight sees [_disposed] and frees itself.
    _disposed = true;
    final engine = _engine;
    _engine = null;
    _loading = null;
    engine?.cancelGeneration();
    await engine?.dispose();
  }

  Future<llama.LlamaEngine> _ensureLoaded() {
    if (_disposed) throw StateError('Engine disposed');
    final ready = _engine;
    if (ready != null) return Future.value(ready);
    return _loading ??= _load();
  }

  Future<llama.LlamaEngine> _load() async {
    try {
      final engine = await llama.LlamaEngine.load(
        llama.LlamaModel(llama.ModelSource.path(modelFile.path)),
        params: llama.ModelParams(
          contextSize: _contextTokens,
          // Android Vulkan support in llamadart is experimental; CPU is the
          // reliable baseline. Apple devices use Metal automatically.
          device: Platform.isAndroid
              ? llama.ComputeDevice.cpu
              : llama.ComputeDevice.auto,
        ),
      );
      if (_disposed) {
        await engine.dispose();
        throw StateError('Engine disposed');
      }
      _engine = engine;
      return engine;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static List<llama.LlamaChatMessage> _toMessages(List<ChatTurn> history) {
    // Keep the most recent turns that fit the budget, always including the
    // latest user message.
    final kept = <ChatTurn>[];
    var used = 0;
    for (final turn in history.reversed) {
      if (turn.speaker == ChatSpeaker.system) continue;
      used += turn.text.length;
      if (kept.isNotEmpty && used > _historyCharBudget) break;
      kept.add(turn);
    }

    return [
      const llama.LlamaChatMessage.fromText(
        role: llama.LlamaChatRole.system,
        text: systemPrompt,
      ),
      for (final turn in kept.reversed)
        llama.LlamaChatMessage.fromText(
          role: turn.speaker == ChatSpeaker.user
              ? llama.LlamaChatRole.user
              : llama.LlamaChatRole.assistant,
          text: turn.text,
        ),
    ];
  }

  static String _loadFailureMessage(Object error) {
    final detail = error is llama.LlamaException ? error.message : '$error';
    return 'Couldn\'t load the AI model. The file may be corrupt, an '
        'unsupported format, or too large for this phone\'s memory.\n\n'
        'Details: $detail';
  }
}
