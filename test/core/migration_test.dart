import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

/// Upgrades a real schema-v2 database (created by the Milestone 2 code and
/// saved in test/fixtures) to the current schema, as happens on phones that
/// already ran the app.
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
}
