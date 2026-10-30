import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../domain/pack_format.dart';
import '../domain/passage_vectors.dart';

/// Installs knowledge packs into SQLite. Each install is one transaction, so
/// a failure leaves the previous version (or nothing) in place.
class PackInstaller {
  PackInstaller(this._db);
  final AppDatabase _db;

  static const bundledDir = 'assets/packs/';
  static const vectorsDir = 'assets/packs/vectors/';

  /// Installs [json], replacing any installed pack with the same id.
  /// [vectors] (a `.vec` file, see [PassageVectors]) adds meaning vectors
  /// for sections and [docVectors] (`.docs.vec`) for documents; entries
  /// that don't match their text are ignored.
  Future<void> install(
    String json, {
    required String source,
    Uint8List? vectors,
    Uint8List? docVectors,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const PackFormatException('The pack file is not valid JSON.');
    }
    final pack = PackData.fromJson(decoded);
    final entries = vectors == null ? null : PassageVectors.decode(vectors);
    var k = 0;
    Uint8List? vectorFor(SectionData section) {
      final i = k++;
      if (entries == null || i >= entries.length) return null;
      final (hash, v) = entries[i];
      if (hash != PassageVectors.sectionHash(section.heading, section.body)) {
        return null;
      }
      return Uint8List.sublistView(v);
    }

    final docEntries = docVectors == null
        ? null
        : PassageVectors.decode(docVectors);
    Uint8List? docVectorFor(int i, DocumentData doc) {
      if (docEntries == null || i >= docEntries.length) return null;
      final (hash, v) = docEntries[i];
      if (hash != PassageVectors.docHash(doc.title, doc.aliases)) return null;
      return Uint8List.sublistView(v);
    }

    await _db.transaction(() async {
      await uninstall(pack.id);
      await _db
          .into(_db.knowledgePacks)
          .insert(
            KnowledgePacksCompanion.insert(
              id: pack.id,
              title: pack.title,
              description: Value(pack.description),
              category: pack.category,
              version: pack.version,
              publisher: pack.publisher,
              license: pack.license,
              attribution: Value(pack.attribution),
              reviewStatus: Value(pack.reviewStatus),
              sizeBytes: utf8.encode(json).length,
              source: source,
              installedAt: DateTime.now(),
            ),
          );
      for (final (di, doc) in pack.documents.indexed) {
        final docId = await _db
            .into(_db.packDocuments)
            .insert(
              PackDocumentsCompanion.insert(
                packId: pack.id,
                title: doc.title,
                sourceUrl: Value(doc.sourceUrl),
                position: di,
                aliases: Value(doc.aliases),
                libraryOnly: Value(doc.libraryOnly),
                embedding: Value(docVectorFor(di, doc)),
              ),
            );
        await _db.batch((b) {
          b.insertAll(_db.passages, [
            for (final (si, section) in doc.sections.indexed)
              PassagesCompanion.insert(
                documentId: docId,
                heading: section.heading,
                body: section.body,
                position: si,
                images: Value(
                  section.images.isEmpty
                      ? null
                      : jsonEncode([
                          for (final i in section.images) i.toJson(),
                        ]),
                ),
                embedding: Value(vectorFor(section)),
              ),
          ]);
        });
      }
    });
  }

  Future<void> uninstall(String packId) {
    // Documents, passages and their FTS rows go via cascades and triggers.
    return (_db.delete(
      _db.knowledgePacks,
    )..where((p) => p.id.equals(packId))).go();
  }

  /// Installs or updates packs shipped in [bundledDir]. Cheap when nothing
  /// changed: a pack is only (re)installed if its source or version differs.
  Future<void> syncBundled(
    AssetBundle bundle, {
    void Function(int done, int total)? onProgress,
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final assets = manifest.listAssets().where(
      (a) => a.startsWith(bundledDir) && a.endsWith('.json'),
    );

    final installed = {
      for (final p in await _db.select(_db.knowledgePacks).get()) p.id: p,
    };
    // A pack dropped from the app bundle is removed on update.
    for (final pack in installed.values) {
      final asset = pack.source.replaceFirst('asset:', '');
      if (pack.source.startsWith('asset:') && !assets.contains(asset)) {
        await uninstall(pack.id);
      }
    }

    final list = assets.toList();
    for (final (i, asset) in list.indexed) {
      onProgress?.call(i, list.length);
      // Let the UI breathe between packs while installing in the background.
      await Future<void>.delayed(Duration.zero);
      final json = await bundle.loadString(asset, cache: false);
      final Map<String, Object?> header;
      try {
        header = jsonDecode(json) as Map<String, Object?>;
      } catch (_) {
        continue; // A broken bundled pack must never block startup.
      }
      final current = installed[header['id']];
      if (current != null &&
          current.version == header['version'] &&
          current.source == 'asset:$asset') {
        continue;
      }
      final stem =
          '$vectorsDir${asset.substring(bundledDir.length).replaceFirst(RegExp(r'\.json$'), '')}';
      Future<Uint8List?> load(String name) async =>
          manifest.listAssets().contains(name)
          ? Uint8List.sublistView(await bundle.load(name))
          : null;
      try {
        await install(
          json,
          source: 'asset:$asset',
          vectors: await load('$stem.vec'),
          docVectors: await load('$stem.docs.vec'),
        );
      } on PackFormatException {
        continue;
      }
    }
    onProgress?.call(list.length, list.length);
  }
}
