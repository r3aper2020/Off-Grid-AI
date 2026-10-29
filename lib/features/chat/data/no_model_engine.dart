import '../domain/inference_engine.dart';

/// Engine used while no model is installed. It never pretends to answer.
class NoModelEngine implements InferenceEngine {
  const NoModelEngine();

  static const reason =
      'No on-device AI model is installed, so I can\'t generate an answer '
      'yet. Once a model is installed from Settings, chats run entirely on '
      'this phone — no internet needed.';

  @override
  Future<EngineStatus> status() async => const EngineUnavailable(reason);

  @override
  Stream<GenerationEvent> generate(List<ChatTurn> history) =>
      Stream.value(const GenerationFailed(reason));
}
