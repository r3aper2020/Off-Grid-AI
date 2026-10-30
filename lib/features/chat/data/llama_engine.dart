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

  /// Room for the system prompt, ~6,500 characters of passages, the last
  /// two exchanges and a full reply, with headroom for number-heavy text
  /// that tokenizes poorly. The KV cache for this is ~0.9 GB (f16) on a
  /// 4B model; phones under 8 GB should use a smaller model.
  static const _contextTokens = 6144;

  /// About 600 words: a complete answer (first action, steps, what to
  /// watch for) without letting a rambling reply run for minutes.
  static const _maxReplyTokens = 800;

  /// Earlier turns sent with each message: the last two exchanges, so a
  /// conversation flows ("what if it's raining?") without the model
  /// blending older questions into new answers, or every reply slowing.
  static const _priorTurns = 4;

  /// Earlier replies are cut to this length; enough to know what was said.
  static const _priorReplyChars = 800;

  static const systemPrompt =
      'You are OFFGRID AI, an experienced survival and emergency-'
      'preparedness instructor, running offline on the user\'s phone. You '
      'may be the only help they have, so be the expert: specific, '
      'complete and calm. Talk like a knowledgeable friend: plain words, '
      'direct sentences, no emojis, no headings, no lectures, no '
      'disclaimers about not being a professional.\n'
      'Shape of a reply: the single most important action in the first '
      'sentence. Then the steps in order as a numbered list, with the '
      'detail someone needs to actually do them: what to use, how, how '
      'long, what to watch for, and what not to do. Finish with what to do '
      'next or when to get help. Usually 150 to 350 words; a simple '
      'question gets a short answer.\n'
      'If the right action depends on something you don\'t know, give the '
      'safe first steps and then ask one short question. Stay on the '
      'latest message; earlier messages are context only.\n'
      'If someone is badly hurt or in danger, the first sentence tells them '
      'to call 911 (or local emergency services) if they can, then the '
      'steps follow.\n'
      'Never invent facts. If you are not sure, say so briefly and give the '
      'safest course.';

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
    if (_engine == null) {
      yield const GenerationProgress(GenerationPhase.loadingModel);
    }
    try {
      engine = await _ensureLoaded();
    } on Object catch (e) {
      yield GenerationFailed(_loadFailureMessage(e));
      return;
    }

    yield const GenerationProgress(GenerationPhase.thinking);
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
  Future<String?> complete(List<ChatTurn> turns, {int maxTokens = 64}) async {
    final llama.LlamaEngine engine;
    try {
      engine = await _ensureLoaded();
    } on Object {
      return null;
    }
    if (_generating) return null;
    _generating = true;
    final out = StringBuffer();
    try {
      await for (final chunk in engine.create(
        _toMessages(turns, withSystemPrompt: false),
        params: llama.GenerationParams(maxTokens: maxTokens),
        enableThinking: false,
      )) {
        out.write(chunk.text);
      }
    } on llama.LlamaException {
      return null;
    } finally {
      _generating = false;
    }
    return out.toString();
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
          // Phone CPUs mix fast and slow cores; llama.cpp's default uses
          // all of them, and the slow ones hold the fast ones back.
          numberOfThreads: Platform.isAndroid ? 4 : 0,
          numberOfThreadsBatch: Platform.isAndroid ? 4 : 0,
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

  static List<llama.LlamaChatMessage> _toMessages(
    List<ChatTurn> history, {
    bool withSystemPrompt = true,
  }) {
    // System turns (e.g. citation rules) extend the base system prompt.
    final instructions = [
      if (withSystemPrompt) systemPrompt,
      for (final t in history)
        if (t.speaker == ChatSpeaker.system) t.text,
    ].join('\n\n');

    // The latest user message plus the exchange before it.
    final turns = [
      for (final t in history)
        if (t.speaker != ChatSpeaker.system) t,
    ];
    final kept = [
      for (final t in turns.reversed.skip(1).take(_priorTurns))
        t.speaker == ChatSpeaker.assistant && t.text.length > _priorReplyChars
            ? ChatTurn(t.speaker, '${t.text.substring(0, _priorReplyChars)}…')
            : t,
    ];
    if (turns.isNotEmpty) kept.insert(0, turns.last);

    return [
      llama.LlamaChatMessage.fromText(
        role: llama.LlamaChatRole.system,
        text: instructions,
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
