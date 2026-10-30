import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class ChatRepository {
  ChatRepository(this._db);
  final AppDatabase _db;

  static const _titleLength = 48;

  Stream<List<Conversation>> watchConversations() {
    return (_db.select(
      _db.conversations,
    )..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])).watch();
  }

  Stream<Conversation?> watchConversation(int id) {
    return (_db.select(
      _db.conversations,
    )..where((c) => c.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<Message>> watchMessages(int conversationId) {
    return (_db.select(_db.messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.id)]))
        .watch();
  }

  Future<List<Message>> messages(int conversationId) {
    return (_db.select(_db.messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.id)]))
        .get();
  }

  /// Creates a conversation seeded with the user's first message, which
  /// may carry a photo ([imagePath], a file name in the photos directory).
  Future<int> startConversation(String firstMessage, {String? imagePath}) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final id = await _db
          .into(_db.conversations)
          .insert(
            ConversationsCompanion.insert(
              title: _titleFrom(
                firstMessage.trim().isEmpty && imagePath != null
                    ? 'Photo'
                    : firstMessage,
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _insert(
        id,
        MessageRole.user,
        firstMessage,
        MessageStatus.complete,
        imagePath: imagePath,
      );
      return id;
    });
  }

  Future<int> addUserMessage(
    int conversationId,
    String text, {
    String? imagePath,
  }) {
    return _insert(
      conversationId,
      MessageRole.user,
      text,
      MessageStatus.complete,
      imagePath: imagePath,
    );
  }

  Future<int> addAssistantMessage(
    int conversationId,
    String text,
    MessageStatus status, {
    List<int>? citations,
  }) {
    return _insert(
      conversationId,
      MessageRole.assistant,
      text,
      status,
      citations: citations,
    );
  }

  Future<void> setCitations(int id, List<int> passageIds) {
    return (_db.update(_db.messages)..where((m) => m.id.equals(id))).write(
      MessagesCompanion(citations: Value(jsonEncode(passageIds))),
    );
  }

  Future<void> updateMessage(int id, String text, MessageStatus status) {
    return (_db.update(_db.messages)..where((m) => m.id.equals(id))).write(
      MessagesCompanion(content: Value(text), status: Value(status)),
    );
  }

  Future<void> deleteConversation(int id) {
    return (_db.delete(_db.conversations)..where((c) => c.id.equals(id))).go();
  }

  Future<void> deleteAll() => _db.delete(_db.conversations).go();

  /// Any message left `streaming` was interrupted by an app kill.
  Future<void> recoverInterrupted() {
    return (_db.update(_db.messages)
          ..where((m) => m.status.equalsValue(MessageStatus.streaming)))
        .write(const MessagesCompanion(status: Value(MessageStatus.cancelled)));
  }

  Future<int> _insert(
    int conversationId,
    MessageRole role,
    String text,
    MessageStatus status, {
    List<int>? citations,
    String? imagePath,
  }) async {
    final id = await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            conversationId: conversationId,
            role: role,
            content: text,
            status: status,
            createdAt: DateTime.now(),
            citations: Value(citations == null ? null : jsonEncode(citations)),
            imagePath: Value(imagePath),
          ),
        );
    await (_db.update(_db.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
    return id;
  }

  static String _titleFrom(String text) {
    final oneLine = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (oneLine.length <= _titleLength) return oneLine;
    return '${oneLine.substring(0, _titleLength).trimRight()}…';
  }
}
