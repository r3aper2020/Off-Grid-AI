import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'data/chat_repository.dart';
import 'data/no_model_engine.dart';
import 'domain/inference_engine.dart';

/// Swapped for the llama.cpp engine once model management exists.
final inferenceEngineProvider = Provider<InferenceEngine>(
  (ref) => const NoModelEngine(),
);

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
    NotifierProvider<GenerationController, Set<int>>(GenerationController.new);

/// Runs assistant replies and tracks which conversations are generating.
/// State is the set of conversation ids with a reply in progress.
class GenerationController extends Notifier<Set<int>> {
  static const _flushInterval = Duration(milliseconds: 120);

  final _active = <int, _ActiveGeneration>{};

  @override
  Set<int> build() {
    ref.onDispose(() {
      for (final g in _active.values) {
        g.subscription.cancel();
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

    final messageId = await _repo.addAssistantMessage(
      conversationId,
      '',
      MessageStatus.streaming,
    );
    final active = _ActiveGeneration(messageId);
    _active[conversationId] = active;
    state = {...state, conversationId};

    active.subscription = engine
        .generate(history)
        .listen(
          (event) {
            switch (event) {
              case GenerationToken(:final text):
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

  Future<void> cancel(int conversationId) async {
    final active = _active[conversationId];
    if (active == null) return;
    await active.subscription.cancel();
    await _finish(conversationId, MessageStatus.cancelled);
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
  late StreamSubscription<GenerationEvent> subscription;
  Timer? flushTimer;
}
