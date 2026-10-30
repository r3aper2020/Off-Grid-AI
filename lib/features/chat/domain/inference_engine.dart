/// Contract between the chat feature and whatever runs the model.
///
/// Milestone 2 provides a llama.cpp-backed implementation. The UI depends
/// only on this interface so engines can be swapped without touching screens.
abstract interface class InferenceEngine {
  /// Current availability; checked before every generation.
  Future<EngineStatus> status();

  /// Streams a reply to [history]. The stream ends after a single
  /// [GenerationDone] or [GenerationFailed]. Cancelling the subscription
  /// must stop generation and release compute promptly.
  Stream<GenerationEvent> generate(List<ChatTurn> history);

  /// One short, non-streamed completion for internal use (rewriting a
  /// message into search queries). Returns null when no model can run.
  /// Must never be shown to the user as an answer.
  Future<String?> complete(List<ChatTurn> turns, {int maxTokens = 64});

  /// Frees model memory if idle. The next [generate] reloads the model.
  Future<void> release();

  /// Releases everything; the engine is not used afterwards.
  Future<void> dispose();
}

enum ChatSpeaker { user, assistant, system }

class ChatTurn {
  const ChatTurn(this.speaker, this.text);
  final ChatSpeaker speaker;
  final String text;
}

sealed class EngineStatus {
  const EngineStatus();
}

class EngineReady extends EngineStatus {
  const EngineReady(this.modelName);
  final String modelName;
}

/// No usable model. [reason] is shown to the user verbatim.
class EngineUnavailable extends EngineStatus {
  const EngineUnavailable(this.reason);
  final String reason;
}

sealed class GenerationEvent {
  const GenerationEvent();
}

class GenerationToken extends GenerationEvent {
  const GenerationToken(this.text);
  final String text;
}

/// What a reply is doing before (and while) text arrives.
enum GenerationPhase { searching, loadingModel, thinking, writing }

/// Progress update; engines emit [GenerationPhase.loadingModel] and
/// [GenerationPhase.thinking] before the first token.
class GenerationProgress extends GenerationEvent {
  const GenerationProgress(this.phase);
  final GenerationPhase phase;
}

class GenerationDone extends GenerationEvent {
  const GenerationDone();
}

class GenerationFailed extends GenerationEvent {
  const GenerationFailed(this.message);
  final String message;
}
