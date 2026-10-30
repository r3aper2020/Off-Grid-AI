import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../library/data/knowledge_search.dart';
import '../library/data/library_repository.dart';
import '../models/model_providers.dart';
import 'data/chat_repository.dart';
import 'data/llama_engine.dart';
import 'data/no_model_engine.dart';
import 'domain/grounding.dart';
import 'domain/inference_engine.dart';

/// llama.cpp engine for the active model, or [NoModelEngine] when none is
/// installed. Rebuilt (and the old model freed) only when the active model
/// actually changes.
final inferenceEngineProvider = Provider<InferenceEngine>((ref) {
  final active = ref.watch(
    activeModelProvider.select((a) {
      final m = a.value;
      return m == null ? null : (id: m.id, name: m.displayName);
    }),
  );
  if (active == null) return const NoModelEngine();

  final store = ref.read(modelStoreProvider);
  final model = ref.read(activeModelProvider).requireValue!;
  final engine = LlamaInferenceEngine(
    modelFile: store.fileFor(model),
    modelName: active.name,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final engineStatusProvider = FutureProvider<EngineStatus>(
  (ref) => ref.watch(inferenceEngineProvider).status(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(databaseProvider)),
);

final conversationsProvider = StreamProvider<List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).watchConversations(),
);

final conversationProvider = StreamProvider.family<Conversation?, int>(
  (ref, id) => ref.watch(chatRepositoryProvider).watchConversation(id),
);

final messagesProvider = StreamProvider.family<List<Message>, int>(
  (ref, id) => ref.watch(chatRepositoryProvider).watchMessages(id),
);

final generationControllerProvider =
    NotifierProvider<GenerationController, Map<int, GenerationPhase>>(
      GenerationController.new,
    );

/// Runs assistant replies. State maps each conversation with a reply in
/// progress to what it is doing right now, so the UI can say so.
class GenerationController extends Notifier<Map<int, GenerationPhase>> {
  static const _flushInterval = Duration(milliseconds: 120);

  final _active = <int, _ActiveGeneration>{};

  @override
  Map<int, GenerationPhase> build() {
    ref.onDispose(() {
      for (final g in _active.values) {
        g.subscription?.cancel();
        g.flushTimer?.cancel();
      }
    });
    return const {};
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  Future<void> reply(int conversationId) async {
    if (_active.containsKey(conversationId)) return;
    final engine = ref.read(inferenceEngineProvider);

    final status = await engine.status();
    if (status is EngineUnavailable) {
      await _repo.addAssistantMessage(
        conversationId,
        status.reason,
        MessageStatus.notice,
      );
      return;
    }

    final history = (await _repo.messages(conversationId))
        .where((m) => m.status == MessageStatus.complete)
        .map((m) => ChatTurn(_speaker(m.role), m.content))
        .toList();
    final asked = [
      for (final t in history)
        if (t.speaker == ChatSpeaker.user) t.text,
    ];
    final question = asked.isEmpty ? '' : asked.last;
    final previous = asked.length > 1 ? asked[asked.length - 2] : null;
    // "Hi", "thanks", "ok" carry no topic: reply like a person, without
    // library lookups or a "not from the library" disclaimer.
    final conversational = KnowledgeSearch.termsOf(question).isEmpty;

    // Show the reply bubble (and allow Stop) before any slow work starts.
    final messageId = await _repo.addAssistantMessage(
      conversationId,
      '',
      MessageStatus.streaming,
    );
    final active = _ActiveGeneration(messageId);
    _active[conversationId] = active;
    _setPhase(conversationId, GenerationPhase.searching);

    final hits = conversational
        ? const <PassageHit>[]
        : Grounding.select(
            await _sourcesFor(engine, history, question, previous),
          );
    if (active.cancelled) return;
    if (!conversational) {
      await _repo.setCitations(messageId, [for (final h in hits) h.passageId]);
    }

    active.subscription = engine
        .generate(
          Grounding.apply(history, hits, conversational: conversational),
        )
        .listen(
          (event) {
            switch (event) {
              case GenerationProgress(:final phase):
                _setPhase(conversationId, phase);
              case GenerationToken(:final text):
                if (active.buffer.isEmpty) {
                  _setPhase(conversationId, GenerationPhase.writing);
                }
                active.buffer.write(text);
                active.flushTimer ??= Timer(_flushInterval, () {
                  active.flushTimer = null;
                  _repo.updateMessage(
                    messageId,
                    active.buffer.toString(),
                    MessageStatus.streaming,
                  );
                });
              case GenerationDone():
                _finish(conversationId, MessageStatus.complete);
              case GenerationFailed(:final message):
                if (active.buffer.isEmpty) active.buffer.write(message);
                _finish(conversationId, MessageStatus.failed);
            }
          },
          onError: (Object error) {
            if (active.buffer.isEmpty) {
              active.buffer.write('Generation failed.');
            }
            _finish(conversationId, MessageStatus.failed);
          },
          onDone: () {
            if (_active.containsKey(conversationId)) {
              _finish(conversationId, MessageStatus.complete);
            }
          },
        );
  }

  /// Library passages for [question]. The model first rewrites the
  /// message into two or three search queries in the library's plainer
  /// words, with follow-ups resolved against the conversation; the
  /// user's own words are always searched too. Without a model (or if the
  /// rewrite fails) the [previous] question stands in for that context. A
  /// search failure must never stop the assistant from answering, so it
  /// degrades to "no sources".
  Future<List<PassageHit>> _sourcesFor(
    InferenceEngine engine,
    List<ChatTurn> history,
    String question,
    String? previous,
  ) async {
    try {
      final search = ref.read(knowledgeSearchProvider);
      final rewrites = Grounding.parseRewrites(
        await engine.complete(Grounding.rewriteTurns(history)),
        question,
      );
      if (rewrites.isEmpty) {
        return await search.forMessage(question, previous: previous);
      }
      return await search.forQueries([question, ...rewrites]);
    } catch (_) {
      return const [];
    }
  }

  Future<void> cancel(int conversationId) async {
    final active = _active[conversationId];
    if (active == null) return;
    active.cancelled = true;
    await active.subscription?.cancel();
    await _finish(conversationId, MessageStatus.cancelled);
  }

  void _setPhase(int conversationId, GenerationPhase phase) {
    if (!_active.containsKey(conversationId)) return;
    state = {...state, conversationId: phase};
  }

  Future<void> _finish(int conversationId, MessageStatus status) async {
    final active = _active.remove(conversationId);
    if (active == null) return;
    active.flushTimer?.cancel();
    state = {...state}..remove(conversationId);
    await _repo.updateMessage(
      active.messageId,
      active.buffer.toString(),
      status,
    );
  }

  static ChatSpeaker _speaker(MessageRole role) => switch (role) {
    MessageRole.user => ChatSpeaker.user,
    MessageRole.assistant => ChatSpeaker.assistant,
    MessageRole.system => ChatSpeaker.system,
  };
}

class _ActiveGeneration {
  _ActiveGeneration(this.messageId);
  final int messageId;
  final buffer = StringBuffer();
  StreamSubscription<GenerationEvent>? subscription;
  Timer? flushTimer;
  bool cancelled = false;
}
