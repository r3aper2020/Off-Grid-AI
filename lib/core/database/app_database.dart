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

  /// Assistant replies only: JSON list of passage ids given to the model,
  /// where index 0 is citation [1]. `[]` means the library was searched and
  /// nothing matched; null means no search ran (e.g. older messages).
  TextColumn get citations => text().nullable()();

  /// User messages only: a photo attached to the message, as a file name
  /// inside the app's photos directory (not an absolute path, so the app
  /// container can move between OS updates/restores).
  TextColumn get imagePath => text().nullable()();
}

/// Category used by the Library filter chips.
enum PackCategory { guide, medical, map, note }

/// How far a pack's content can be trusted (the Survival Coverage Matrix
/// status, at pack level). Stored by name — never rename values.
enum ReviewStatus {
  /// Authoritative, current source; reviewed for inclusion.
  verified,

  /// Usable but not authoritative or possibly outdated (e.g. volunteer-
  /// written, superseded manuals). Shown with a warning.
  needsReview,

  /// Old public-domain material kept for traditional skills; practices
  /// (especially medical) may be outdated or unsafe.
  historical,
}

/// Installed knowledge packs (see docs/knowledge-packs.md for the format).
class KnowledgePacks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => textEnum<PackCategory>()();
  TextColumn get version => text()();
  TextColumn get publisher => text()();
  TextColumn get license => text()();
  TextColumn get attribution => text().withDefault(const Constant(''))();
  TextColumn get reviewStatus => textEnum<ReviewStatus>().withDefault(
    Constant(ReviewStatus.needsReview.name),
  )();
  IntColumn get sizeBytes => integer()();

  /// Where it was installed from, e.g. `asset:assets/packs/water.json`.
  TextColumn get source => text()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A source document inside a pack (e.g. one government guide).
class PackDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packId =>
      text().references(KnowledgePacks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get sourceUrl => text().nullable()();
  IntColumn get position => integer()();

  /// Retrieval-only plain-language phrasings (see `DocumentData.aliases`);
  /// indexed with the title in `passages_fts`.
  TextColumn get aliases => text().withDefault(const Constant(''))();

  /// Excluded from AI answers (regulation text, reference tables); still
  /// readable and searchable in the Library.
  BoolColumn get libraryOnly => boolean().withDefault(const Constant(false))();

  /// Meaning vector of the title and aliases (int8, see `PassageVectors`),
  /// so a question can match a document as a whole.
  BlobColumn get embedding => blob().nullable()();
}

/// One section of a document: the unit that is searched and cited.
/// Indexed by the `passages_fts` FTS5 table, kept in sync by triggers.
class Passages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(PackDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get heading => text()();

  /// Section text. `{{img:N}}` marks where [images] entry N appears.
  TextColumn get body => text()();
  IntColumn get position => integer()();

  /// JSON list of {asset, caption, kind} — figures and tables rendered
  /// from the original page (tables as images so values stay exact).
  TextColumn get images => text().nullable()();

  /// Meaning vector (int8, see `PassageVectors`) for semantic search;
  /// null when the pack shipped without vectors.
  BlobColumn get embedding => blob().nullable()();
}

/// GGUF models imported into app-private storage. At most one is active.
class InstalledModels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();

  /// File name inside the models directory (not an absolute path, so the
  /// app container can move between OS updates/restores).
  TextColumn get fileName => text().unique()();
  IntColumn get sizeBytes => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get installedAt => dateTime()();

  /// Multimodal projector (mmproj GGUF) file name in the models directory,
  /// when the model can see photos; null for text-only models.
  TextColumn get projectorFileName => text().nullable()();
}

/// What a map archive draws. `streets` is the Protomaps vector region;
/// the others are raster layers downloaded for a streets region.
/// Stored by name: never rename, only add.
enum MapLayerKind { streets, topo, imagery, terrain }

/// Offline map regions: PMTiles archives in app-private storage, with
/// the bounds and zoom range read from the archive header. A raster
/// layer row points at its streets region through [parentId].
class MapRegions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  TextColumn get kind => textEnum<MapLayerKind>().withDefault(
    const Constant('streets'),
  )();
  IntColumn get parentId => integer().nullable()();

  /// File name inside the maps directory (not an absolute path).
  TextColumn get fileName => text().unique()();
  IntColumn get sizeBytes => integer()();
  RealColumn get minLon => real()();
  RealColumn get minLat => real()();
  RealColumn get maxLon => real()();
  RealColumn get maxLat => real()();
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();
  DateTimeColumn get installedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Conversations,
    Messages,
    KnowledgePacks,
    PackDocuments,
    Passages,
    InstalledModels,
    MapRegions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'offgrid'));

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createPassageIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(installedModels);
      if (from < 3) {
        // knowledge_packs never held rows before v3, so recreate it.
        await m.deleteTable('knowledge_packs');
        await m.createTable(knowledgePacks);
        await m.createTable(packDocuments);
        await m.createTable(passages);
        await m.addColumn(messages, messages.citations);
        await _createPassageIndex();
      }
      if (from == 3) {
        // v4: review status. Bundled packs are reinstalled with their real
        // status on startup (their versions changed with this release).
        await m.addColumn(knowledgePacks, knowledgePacks.reviewStatus);
        // v4: the search index also covers document titles.
        await customStatement('DROP TRIGGER IF EXISTS passages_ai');
        await customStatement('DROP TRIGGER IF EXISTS passages_ad');
        await customStatement('DROP TABLE IF EXISTS passages_fts');
        await _createPassageIndex();
        await customStatement('''
          INSERT INTO passages_fts(rowid, title, heading, body)
          SELECT p.id, d.title, p.heading, p.body
          FROM passages p JOIN pack_documents d ON d.id = p.document_id''');
      }
      if (from >= 3 && from < 5) {
        // v5: figure/table images per passage (v<3 creates the table fresh).
        await m.addColumn(passages, passages.images);
      }
      if (from >= 3 && from < 6) {
        // v6: meaning vectors per passage.
        await m.addColumn(passages, passages.embedding);
      }
      if (from >= 3 && from < 7) {
        // v7: document aliases, library-only documents and document
        // vectors; the search index also covers aliases. The embedding
        // model changed (384 → 768 dims), so every stored vector is stale.
        await m.addColumn(packDocuments, packDocuments.aliases);
        await m.addColumn(packDocuments, packDocuments.libraryOnly);
        await m.addColumn(packDocuments, packDocuments.embedding);
        await customStatement('UPDATE passages SET embedding = NULL');
        await customStatement('DROP TRIGGER IF EXISTS passages_ai');
        await customStatement('DROP TRIGGER IF EXISTS passages_ad');
        await customStatement('DROP TABLE IF EXISTS passages_fts');
        await _createPassageIndex();
        await customStatement('''
          INSERT INTO passages_fts(rowid, title, heading, body)
          SELECT p.id, d.title || ' ' || d.aliases, p.heading, p.body
          FROM passages p JOIN pack_documents d ON d.id = p.document_id''');
      }
      if (from < 8) {
        // v8: photos on user messages; vision projector on installed models.
        await m.addColumn(messages, messages.imagePath);
        // A v1 database had installed_models created above with the column.
        if (from >= 2) {
          await m.addColumn(installedModels, installedModels.projectorFileName);
        }
      }
      if (from >= 3 && from < 9) {
        // v9: the search index also covers figure and table captions, so
        // "square knot" finds the splinting section whose figure shows one.
        await customStatement('DROP TRIGGER IF EXISTS passages_ai');
        await customStatement('DROP TRIGGER IF EXISTS passages_ad');
        await customStatement('DROP TABLE IF EXISTS passages_fts');
        await _createPassageIndex();
        await customStatement('''
          INSERT INTO passages_fts(rowid, title, heading, body)
          SELECT p.id, d.title || ' ' || d.aliases || ' ' ||
                 ${_captionsSql('p.images')},
                 p.heading, p.body
          FROM passages p JOIN pack_documents d ON d.id = p.document_id''');
      }
      if (from < 10) {
        // v10: offline map regions (navigation milestone).
        await m.createTable(mapRegions);
      }
      if (from >= 10 && from < 11) {
        // v11: raster layers (topo, imagery, terrain) hang off a region.
        await m.addColumn(mapRegions, mapRegions.kind);
        await m.addColumn(mapRegions, mapRegions.parentId);
      }
      if (from >= 3 && from < 7) {
        // Bundled packs are removed so the startup sync reinstalls them
        // with current vectors (foreign keys are off during migrations, so
        // delete children explicitly).
        const bundled =
            "SELECT id FROM knowledge_packs WHERE source LIKE 'asset:%'";
        await customStatement(
          'DELETE FROM passages WHERE document_id IN (SELECT id FROM '
          'pack_documents WHERE pack_id IN ($bundled))',
        );
        await customStatement(
          'DELETE FROM pack_documents WHERE pack_id IN ($bundled)',
        );
        await customStatement(
          "DELETE FROM knowledge_packs WHERE source LIKE 'asset:%'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// SQL for the captions of a passage's figures and tables (its `images`
  /// JSON column), space-separated; '' when it has none.
  static String _captionsSql(String imagesColumn) =>
      "COALESCE((SELECT group_concat(json_extract(j.value, '\$.caption'), ' ') "
      "FROM json_each($imagesColumn) j), '')";

  /// FTS5 index over passages with porter stemming ("boil" matches
  /// "boiling"). Each row also carries its document's title, aliases and
  /// figure captions, because a section often never repeats its subject
  /// ("Remove any wet clothing" sits under "Preventing Hypothermia"), the
  /// source's words are rarely the user's ("Build A Kit" vs "bug out
  /// bag"), and a figure can show what the text never names ("Square
  /// knots tied away from the casualty" under a splinting procedure).
  /// Triggers keep it in sync, including cascade deletes when a pack is
  /// removed.
  Future<void> _createPassageIndex() async {
    await customStatement('''
      CREATE VIRTUAL TABLE passages_fts USING fts5(
        title, heading, body,
        tokenize='porter unicode61'
      )''');
    await customStatement('''
      CREATE TRIGGER passages_ai AFTER INSERT ON passages BEGIN
        INSERT INTO passages_fts(rowid, title, heading, body)
        VALUES (
          new.id,
          (SELECT title || ' ' || aliases FROM pack_documents
           WHERE id = new.document_id) || ' ' || ${_captionsSql('new.images')},
          new.heading,
          new.body
        );
      END''');
    await customStatement('''
      CREATE TRIGGER passages_ad AFTER DELETE ON passages BEGIN
        DELETE FROM passages_fts WHERE rowid = old.id;
      END''');
  }
}
