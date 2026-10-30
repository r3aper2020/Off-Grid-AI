import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart' as llama;
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
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

  test('only the latest photo is sent as an image; earlier ones are noted', () {
    final messages = LlamaInferenceEngine.toMessages(const [
      ChatTurn(ChatSpeaker.user, 'first', imagePath: '/p/one.jpg'),
      ChatTurn(ChatSpeaker.assistant, 'a leaf'),
      ChatTurn(ChatSpeaker.user, 'and this?', imagePath: '/p/two.jpg'),
    ]);
    expect(messages, hasLength(4));
    final earlier = messages[1];
    expect(earlier.role, llama.LlamaChatRole.user);
    expect(earlier.content, '[Photo attached] first');
    final latest = messages.last;
    final parts = latest.parts;
    expect(parts.first, isA<llama.LlamaImageContent>());
    expect((parts.first as llama.LlamaImageContent).path, '/p/two.jpg');
    expect((parts.last as llama.LlamaTextContent).text, 'and this?');
  });
}
