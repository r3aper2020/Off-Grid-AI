// Runs whole conversations through the real pipeline (bundled library,
// semantic search, grounding, llama.cpp chat model) and prints the replies
// with timings, for judging the assistant's behaviour by eye.
//   CHAT_MODEL=/path/to/model.gguf flutter test tools/eval/chat_eval_test.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/chat/data/llama_engine.dart';
import 'package:offgrid_ai/features/chat/domain/grounding.dart';
import 'package:offgrid_ai/features/chat/domain/inference_engine.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/llama_embedder.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

import '../../test/support/test_db.dart';

const conversations = [
  ['is there something other than gasoline I can use to start this car I found'],
  ['hi'],
  [
    "my friend cut his leg badly and it won't stop bleeding",
    "what if I don't have a tourniquet?",
  ],
  ['how long do I pressure can carrots?'],
  ['where should I put my generator?'],
  ["I'm lost in the woods"],
  [
    "I'm in the middle of nowhere how do I start a fire",
    'how do I make sure my water is clean to drink',
  ],
];

void main() {
  test('chat eval', () async {
    final db = testDatabase();
    final installer = PackInstaller(db);
    for (final f in Directory('assets/packs').listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final vec = File(
        f.path
            .replaceFirst('assets/packs/', 'assets/packs/vectors/')
            .replaceFirst(RegExp(r'\.json$'), '.vec'),
      );
      await installer.install(
        f.readAsStringSync(),
        source: 'eval',
        vectors: vec.existsSync() ? vec.readAsBytesSync() : null,
      );
    }
    final search = KnowledgeSearch(
      db,
      embedder: LlamaTextEmbedder.fromFile(File(LlamaTextEmbedder.asset)),
    );
    final engine = LlamaInferenceEngine(
      modelFile: File(Platform.environment['CHAT_MODEL']!),
      modelName: 'eval',
    );
    final only = Platform.environment['ONLY'];
    for (final (ci, convo) in conversations.indexed) {
      if (only != null && !only.split(',').contains('$ci')) continue;
      final history = <ChatTurn>[];
      for (final message in convo) {
        history.add(ChatTurn(ChatSpeaker.user, message));
        final asked = [
          for (final t in history)
            if (t.speaker == ChatSpeaker.user) t.text,
        ];
        final previous = asked.length > 1 ? asked[asked.length - 2] : null;
        final conversational = KnowledgeSearch.termsOf(message).isEmpty;
        final hits = conversational
            ? const <PassageHit>[]
            : Grounding.select(
                await search.forMessage(message, previous: previous),
              );
        final sw = Stopwatch()..start();
        int? firstToken;
        final reply = StringBuffer();
        await for (final e in engine.generate(
          Grounding.apply(history, hits, conversational: conversational),
        )) {
          if (e is GenerationToken) {
            firstToken ??= sw.elapsedMilliseconds;
            reply.write(e.text);
          }
        }
        history.add(ChatTurn(ChatSpeaker.assistant, reply.toString()));
        print('\n### USER: $message');
        print('sources: ${hits.map((h) => h.heading).join(' | ')}');
        print(
          'first token ${firstToken}ms, total ${sw.elapsedMilliseconds}ms, '
          '${reply.length} chars',
        );
        print('--- REPLY:\n$reply');
      }
    }
    await engine.dispose();
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 60)));
}
