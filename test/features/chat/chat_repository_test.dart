import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/chat/data/chat_repository.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ChatRepository repo;

  setUp(() {
    db = testDatabase();
    repo = ChatRepository(db);
  });
  tearDown(() => db.close());

  test(
    'startConversation stores the first message and a short title',
    () async {
      final long =
          'How do I purify water from a stream when I have no '
          'filter and only a metal pot?';
      final id = await repo.startConversation(long);

      final conversation = await repo.watchConversation(id).first;
      expect(conversation!.title.length, lessThanOrEqualTo(49));
      expect(conversation.title, endsWith('…'));

      final messages = await repo.messages(id);
      expect(messages.single.content, long);
      expect(messages.single.role, MessageRole.user);
    },
  );

  test('recoverInterrupted marks streaming messages as cancelled', () async {
    final id = await repo.startConversation('hi');
    final msg = await repo.addAssistantMessage(
      id,
      'partial',
      MessageStatus.streaming,
    );

    await repo.recoverInterrupted();

    final stored = (await repo.messages(id)).firstWhere((m) => m.id == msg);
    expect(stored.status, MessageStatus.cancelled);
    expect(stored.content, 'partial');
  });

  test('deleting a conversation cascades to its messages', () async {
    final id = await repo.startConversation('hi');
    await repo.addAssistantMessage(id, 'hello', MessageStatus.complete);

    await repo.deleteConversation(id);

    expect(await repo.messages(id), isEmpty);
  });

  test(
    'a photo on a message is kept, and a photo-only message gets a title',
    () async {
      final id = await repo.startConversation('', imagePath: 'a.jpg');
      await repo.addUserMessage(id, 'what plant is this', imagePath: 'b.jpg');
      final msgs = await repo.messages(id);
      expect(msgs.map((m) => m.imagePath), ['a.jpg', 'b.jpg']);
      expect((await db.select(db.conversations).getSingle()).title, 'Photo');
    },
  );
}
