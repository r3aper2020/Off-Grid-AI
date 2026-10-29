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

  /// About 400 words: room for a full procedure, while keeping a
  /// rambling reply from running for minutes on a phone CPU.
  static const _maxReplyTokens = 600;

  /// Earlier turns sent with each message: the last two exchanges, so a
  /// conversation flows ("what if it's raining?") without the model
  /// blending older questions into new answers, or every reply slowing.
  static const _priorTurns = 4;

  /// Earlier replies are cut to this length; enough to know what was said.
  static const _priorReplyChars = 500;

  static const systemPrompt =
      'You are OFFGRID AI, a survival and preparedness companion running '
      'entirely on the user\'s phone with no internet. Talk like a calm, '
      'experienced friend: warm, plain words, short sentences, speaking '
      'directly to the user. No lectures, no jargon, no filler.\n'
      'How you answer:\n'
      '- Most important action first. If someone may be in danger right '
      'now, start with what to do immediately, as a few short numbered '
      'steps.\n'
      '- Keep it short, usually under 150 words, unless asked for more.\n'
      '- If the best answer depends on something you don\'t know (who is '
      'hurt and how badly, what supplies they have, the weather, where they '
      'are), give the safe first steps, then ask one short question so you '
      'can tailor the next steps.\n'
      '- When it helps, end with a brief offer of the next useful thing, '
      'like "Want me to walk you through making a splint?". Not every time.\n'
      '- Remember what the user told you earlier in this conversation and '
      'build on it. Never repeat or re-answer an earlier question; if the '
      'latest message changes topic, answer only the new topic.\n'
      '- If life may be at risk and help could be reachable, tell them to '
      'call emergency services (911 in the US) first.\n'
      '- Never invent facts, numbers or doses. If you aren\'t sure, say so.\n'
      '- For greetings, thanks or small talk, reply briefly and naturally.';

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

  static List<llama.LlamaChatMessage> _toMessages(List<ChatTurn> history) {
    // System turns (e.g. citation rules) extend the base system prompt.
    final instructions = [
      systemPrompt,
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
