import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

/// Upgrades a real schema-v2 database (created by the Milestone 2 code and
/// saved in test/fixtures) to the current schema, as happens on phones that
/// already ran the app.
/// Makes a fresh database look like schema v6: no document aliases,
/// library-only flag or vectors, and the index trigger that only knew
/// document titles.
Future<void> dropV7Columns(AppDatabase db) async {
  await db.customStatement('DROP TRIGGER passages_ai');
  for (final c in ['aliases', 'library_only', 'embedding']) {
    await db.customStatement('ALTER TABLE pack_documents DROP COLUMN $c');
  }
  // v8 columns, added after these fixtures' versions.
  await db.customStatement('ALTER TABLE messages DROP COLUMN image_path');
  await db.customStatement(
    'ALTER TABLE installed_models DROP COLUMN projector_file_name',
  );
  await db.customStatement('''
    CREATE TRIGGER passages_ai AFTER INSERT ON passages BEGIN
      INSERT INTO passages_fts(rowid, title, heading, body)
      VALUES (new.id,
        (SELECT title FROM pack_documents WHERE id = new.document_id),
        new.heading, new.body);
    END''');
}

void main() {
  late File file;
  late AppDatabase db;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('migrate');
    file = File('${dir.path}/app.sqlite');
    File('test/fixtures/v2_database.sqlite').copySync(file.path);
    db = AppDatabase(NativeDatabase(file));
  });
  tearDown(() async {
    await db.close();
    await file.parent.delete(recursive: true);
  });

  test('v2 data survives the upgrade', () async {
    final model = await db.select(db.installedModels).getSingle();
    expect(model.displayName, 'Qwen3 4B Instruct');
    expect(model.isActive, isTrue);

    final chat = await db.select(db.conversations).getSingle();
    expect(chat.title, 'Old chat');
    final msg = await db.select(db.messages).getSingle();
    expect(msg.content, 'hello');
    expect(msg.citations, isNull);
  });

  test('library works after the upgrade', () async {
    await PackInstaller(db).install(
      File('test/fixtures/test_pack.json').readAsStringSync(),
      source: 'test',
    );
    final hits = await KnowledgeSearch(db).search('boil');
    expect(hits.single.heading, 'Boiling water');
  });

  test('upgraded database reports the current schema version', () async {
    await db.select(db.conversations).get(); // opens and migrates
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), db.schemaVersion);
  });

  test('v3 database gains review status, defaulting to needs-review', () async {
    // Make a v3-shaped file: current schema minus the v4 column.
    final dir = await Directory.systemTemp.createTemp('v3');
    final f = File('${dir.path}/v3.sqlite');
    final fresh = AppDatabase(NativeDatabase(f));
    await fresh.customStatement(
      'ALTER TABLE knowledge_packs DROP COLUMN review_status',
    );
    await fresh.customStatement('ALTER TABLE passages DROP COLUMN images');
    await fresh.customStatement('ALTER TABLE passages DROP COLUMN embedding');
    await dropV7Columns(fresh);
    await fresh.customStatement(
      "INSERT INTO knowledge_packs (id, title, description, category, version, "
      "publisher, license, attribution, size_bytes, source, installed_at) "
      "VALUES ('old', 'Old pack', '', 'guide', '1', 'P', 'L', '', 1, 'file:x', 0)",
    );
    await fresh.customStatement('PRAGMA user_version = 3');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(f));
    final pack = await upgraded.select(upgraded.knowledgePacks).getSingle();
    expect(pack.title, 'Old pack');
    expect(pack.reviewStatus, ReviewStatus.needsReview);
    await upgraded.close();
    await dir.delete(recursive: true);
  });

  test('v5 database drops bundled packs so they reinstall with vectors', () async {
    final dir = await Directory.systemTemp.createTemp('v5');
    final f = File('${dir.path}/v5.sqlite');
    final fresh = AppDatabase(NativeDatabase(f));
    await fresh.customStatement('ALTER TABLE passages DROP COLUMN embedding');
    await dropV7Columns(fresh);
    for (final (id, source) in [
      ('bundled', 'asset:a.json'),
      ('mine', 'file:b'),
    ]) {
      await fresh.customStatement(
        "INSERT INTO knowledge_packs (id, title, description, category, "
        "version, publisher, license, attribution, review_status, size_bytes, "
        "source, installed_at) VALUES ('$id', '$id', '', 'guide', '1', 'P', "
        "'L', '', 'verified', 1, '$source', 0)",
      );
      await fresh.customStatement(
        "INSERT INTO pack_documents (pack_id, title, position) "
        "VALUES ('$id', 'Doc', 0)",
      );
      await fresh.customStatement(
        "INSERT INTO passages (document_id, heading, body, position) "
        "VALUES (last_insert_rowid(), 'H', 'Body text about $id', 0)",
      );
    }
    await fresh.customStatement('PRAGMA user_version = 5');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(f));
    final packs = await upgraded.select(upgraded.knowledgePacks).get();
    expect(packs.map((p) => p.id), ['mine']);
    final passages = await upgraded.select(upgraded.passages).get();
    expect(passages.map((p) => p.body), ['Body text about mine']);
    // The search index no longer returns the removed pack's text.
    final fts = await upgraded
        .customSelect(
          "SELECT rowid FROM passages_fts WHERE passages_fts MATCH 'bundled'",
        )
        .get();
    expect(fts, isEmpty);
    await upgraded.close();
    await dir.delete(recursive: true);
  });

  test('v6 database loses stale vectors and reindexes with aliases', () async {
    final dir = await Directory.systemTemp.createTemp('v6');
    final f = File('${dir.path}/v6.sqlite');
    final fresh = AppDatabase(NativeDatabase(f));
    await dropV7Columns(fresh);
    await fresh.customStatement(
      "INSERT INTO knowledge_packs (id, title, description, category, "
      "version, publisher, license, attribution, review_status, size_bytes, "
      "source, installed_at) VALUES ('mine', 'mine', '', 'guide', '1', 'P', "
      "'L', '', 'verified', 1, 'file:b', 0)",
    );
    await fresh.customStatement(
      "INSERT INTO pack_documents (pack_id, title, position) "
      "VALUES ('mine', 'Doc', 0)",
    );
    await fresh.customStatement(
      "INSERT INTO passages (document_id, heading, body, position, embedding) "
      "VALUES (last_insert_rowid(), 'H', 'Old text', 0, X'0102')",
    );
    await fresh.customStatement('PRAGMA user_version = 6');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(f));
    final passage = await upgraded.select(upgraded.passages).getSingle();
    expect(passage.embedding, isNull);
    final doc = await upgraded.select(upgraded.packDocuments).getSingle();
    expect(doc.aliases, '');
    expect(doc.libraryOnly, isFalse);
    // The rebuilt index still finds the old text.
    expect(await KnowledgeSearch(upgraded).search('old text'), hasLength(1));
    await upgraded.close();
    await dir.delete(recursive: true);
  });

  test('v7 database gains photo and projector columns', () async {
    final dir = await Directory.systemTemp.createTemp('v7');
    final f = File('${dir.path}/v7.sqlite');
    final fresh = AppDatabase(NativeDatabase(f));
    await fresh.customStatement('ALTER TABLE messages DROP COLUMN image_path');
    await fresh.customStatement(
      'ALTER TABLE installed_models DROP COLUMN projector_file_name',
    );
    await fresh.customStatement('PRAGMA user_version = 7');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(f));
    await upgraded.customStatement(
      "INSERT INTO installed_models (display_name, file_name, size_bytes, "
      "is_active, installed_at, projector_file_name) VALUES ('m', 'm.gguf', "
      "1, 1, 0, 'p.gguf')",
    );
    final model = await upgraded.select(upgraded.installedModels).getSingle();
    expect(model.projectorFileName, 'p.gguf');
    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
