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

/// llama.cpp engine for the model that answers text
/// ([textModelProvider]), or [NoModelEngine] when none is installed.
/// Rebuilt (and the old model freed) only when that model changes.
final inferenceEngineProvider = Provider<InferenceEngine>((ref) {
  final text = ref.watch(
    textModelProvider.select(
      (m) => m == null ? null : (id: m.id, name: m.displayName),
    ),
  );
  if (text == null) return const NoModelEngine();

  final store = ref.read(modelStoreProvider);
  final model = ref.read(textModelProvider)!;
  final engine = LlamaInferenceEngine(
    modelFile: store.fileFor(model),
    modelName: text.name,
    projectorFile: store.projectorFor(model),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Engine for the model that answers photos ([visionModelProvider]) when
/// it is a different model from the text one; null otherwise. The
/// controller loads it only for a conversation with a photo in it
/// ([GenerationController.engineFor]), so the user never switches models.
final visionEngineProvider = Provider<InferenceEngine?>((ref) {
  final vision = ref.watch(
    visionModelProvider.select(
      (m) => m == null ? null : (id: m.id, name: m.displayName),
    ),
  );
  final textId = ref.watch(textModelProvider.select((m) => m?.id));
  if (vision == null || vision.id == textId) return null;

  final store = ref.read(modelStoreProvider);
  final model = ref.read(visionModelProvider)!;
  final engine = LlamaInferenceEngine(
    modelFile: store.fileFor(model),
    modelName: vision.name,
    projectorFile: store.projectorFor(model),
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

    final photos = ref.read(photosDirectoryProvider);
    final history = (await _repo.messages(conversationId))
        .where((m) => m.status == MessageStatus.complete)
        .map(
          (m) => ChatTurn(
            _speaker(m.role),
            m.content,
            imagePath: m.imagePath == null
                ? null
                : '${photos.path}/${m.imagePath}',
          ),
        )
        .toList();
    final asked = [
      for (final t in history)
        if (t.speaker == ChatSpeaker.user) t,
    ];
    final latest = asked.isEmpty ? null : asked.last;
    final question = latest?.text ?? '';
    final hasPhoto = latest?.imagePath != null;
    final previous = asked.length > 1 ? asked[asked.length - 2].text : null;

    final engine = await engineFor(history);
    final status = await engine.status();
    if (status is EngineUnavailable) {
      await _repo.addAssistantMessage(
        conversationId,
        status.reason,
        MessageStatus.notice,
      );
      return;
    }

    // A photo needs a model that can see it; never pretend to look.
    if (hasPhoto && status is EngineReady && !status.canSeeImages) {
      await _repo.addAssistantMessage(
        conversationId,
        noVisionReason,
        MessageStatus.notice,
      );
      return;
    }

    // "Hi", "thanks", "ok" carry no topic: reply like a person, without
    // library lookups or a "not from the library" disclaimer. An answer
    // to the assistant's own question ("I think it's 1%") is not that.
    final lastReply = history.lastIndexWhere(
      (t) => t.speaker == ChatSpeaker.assistant,
    );
    final conversational =
        !hasPhoto &&
        Grounding.isSmallTalk(
          question,
          previous: previous,
          lastReply: lastReply < 0 ? null : history[lastReply].text,
        );

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
            await _sourcesFor(
              engine,
              history,
              question,
              previous,
              hasPhoto: hasPhoto,
            ),
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

  /// The engine for this conversation: the text model, unless the
  /// conversation has a photo in it and a separate vision model is
  /// installed. A conversation with a photo stays on the vision model
  /// (every switch reloads a model), and a new text conversation goes
  /// back to the text one. The other engine is released so only one
  /// model is in memory.
  Future<InferenceEngine> engineFor(List<ChatTurn> history) async {
    final text = ref.read(inferenceEngineProvider);
    final vision = ref.read(visionEngineProvider);
    final hasPhoto = history.any(
      (t) => t.speaker == ChatSpeaker.user && t.imagePath != null,
    );
    if (vision == null || !hasPhoto) {
      await vision?.release();
      return text;
    }
    await text.release();
    return vision;
  }

  /// Library passages for [question]. The user's own words are searched
  /// first (a short follow-up together with the [previous] question). Only
  /// when that finds fewer than [Grounding.rewriteBelowHits] passages, or
  /// its best match is not close in meaning
  /// ([KnowledgeSearch.confidentSimilarity]), or the message looks like a
  /// follow-up, does the model rewrite the
  /// message into plainer search queries (an extra prompt pass that costs
  /// seconds on a phone); then the user's words and the rewrites are
  /// searched together. A search failure must never stop the assistant
  /// from answering, so it degrades to "no sources".
  Future<List<PassageHit>> _sourcesFor(
    InferenceEngine engine,
    List<ChatTurn> history,
    String question,
    String? previous, {
    bool hasPhoto = false,
  }) async {
    try {
      final search = ref.read(knowledgeSearchProvider);
      final direct = question.trim().isEmpty
          ? const <PassageHit>[]
          : await search.forMessage(question, previous: previous);
      final followUp =
          previous != null &&
          KnowledgeSearch.termsOf(question).length <=
              KnowledgeSearch.followUpMaxTerms;
      final confident =
          direct.isNotEmpty &&
          (direct.first.similarity ?? 1) >= KnowledgeSearch.confidentSimilarity;
      // With a photo the words alone rarely say what it shows, so the
      // model (which sees it) always writes the queries.
      if (direct.length >= Grounding.rewriteBelowHits &&
          confident &&
          !followUp &&
          !hasPhoto) {
        return direct;
      }
      final rewrites = Grounding.parseRewrites(
        await engine.complete(Grounding.rewriteTurns(history)),
        question,
      );
      if (rewrites.isEmpty) return direct;
      return await search.forQueries([
        if (question.trim().isNotEmpty) question,
        ...rewrites,
      ]);
    } catch (_) {
      return const [];
    }
  }

  /// Stored as a notice when a photo is sent to a text-only model.
  static const noVisionReason =
      'I can\'t see photos with the AI model on this phone. Install "Qwen3 '
      'VL 4B Instruct (vision)" from Settings → AI model and I\'ll use it '
      'for photos automatically, or describe what you\'re looking at in '
      'words.';

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
