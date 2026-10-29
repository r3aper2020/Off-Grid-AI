import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A chat thread. Titles are derived from the first user message.
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Role of a message author. Stored by name, so never rename values.
enum MessageRole { user, assistant, system }

/// Lifecycle of a message. `notice` marks app-generated assistant text
/// (e.g. "no model installed") that must never be sent back to a model.
enum MessageStatus { complete, streaming, cancelled, failed, notice }

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => textEnum<MessageRole>()();
  TextColumn get content => text()();
  TextColumn get status => textEnum<MessageStatus>()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Category used by the Library filter chips.
enum PackCategory { guide, medical, map, note }

/// Registry of installed knowledge packs. Files live in app-private storage
/// at [path]; the indexed passages arrive with the knowledge engine.
class KnowledgePacks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => textEnum<PackCategory>()();
  TextColumn get format => text()();
  TextColumn get version => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get path => text()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Conversations, Messages, KnowledgePacks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'offgrid'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
