import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/chat/data/llama_engine.dart';

void main() {
  test('trimReply keeps the opening and the closing question', () {
    final reply =
        'Stop and stay put. ${'Step detail. ' * 80}'
        'Do you have a whistle or a mirror with you?';
    final trimmed = LlamaInferenceEngine.trimReply(reply, limit: 300);
    expect(trimmed.length, lessThan(320));
    expect(trimmed, startsWith('Stop and stay put.'));
    expect(trimmed, endsWith('Do you have a whistle or a mirror with you?'));
    expect(trimmed, contains('…'));
    expect(LlamaInferenceEngine.trimReply('short'), 'short');
  });

  test('the system prompt tells the model to continue after an answer', () {
    expect(LlamaInferenceEngine.systemPrompt, contains('answers a question'));
  });
}
