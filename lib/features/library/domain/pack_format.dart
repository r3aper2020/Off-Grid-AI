import 'dart:convert';

import '../../../core/database/app_database.dart';

/// Thrown for a pack file that doesn't match the format. [message] is shown
/// to the user.
class PackFormatException implements Exception {
  const PackFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A parsed knowledge pack (format `offgrid-pack` v1). See
/// docs/knowledge-packs.md. Built from Markdown by tools/packs/build_pack.py.
class PackData {
  const PackData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.version,
    required this.publisher,
    required this.license,
    required this.attribution,
    required this.reviewStatus,
    required this.documents,
  });

  static const formatName = 'offgrid-pack';
  static const formatVersion = 1;

  final String id;
  final String title;
  final String description;
  final PackCategory category;
  final String version;
  final String publisher;
  final String license;
  final String attribution;
  final ReviewStatus reviewStatus;
  final List<DocumentData> documents;

  factory PackData.fromJson(Object? json) {
    final m = _map(json, 'pack');
    if (m['format'] != formatName) {
      throw const PackFormatException('Not an OFFGRID knowledge pack.');
    }
    final v = m['formatVersion'];
    if (v is! int || v > formatVersion) {
      throw const PackFormatException(
        'This pack needs a newer version of the app.',
      );
    }
    final categoryName = _str(m, 'category');
    final category = PackCategory.values
        .where((c) => c.name == categoryName)
        .firstOrNull;
    if (category == null) {
      throw PackFormatException('Unknown pack category "$categoryName".');
    }
    final id = _str(m, 'id');
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{1,63}$').hasMatch(id)) {
      throw PackFormatException('Invalid pack id "$id".');
    }
    final docs = m['documents'];
    if (docs is! List || docs.isEmpty) {
      throw const PackFormatException('The pack has no documents.');
    }
    // Missing status means unreviewed: never assume content is verified.
    final reviewName = _optStr(m, 'review') ?? 'needs-review';
    final review = switch (reviewName) {
      'verified' => ReviewStatus.verified,
      'needs-review' => ReviewStatus.needsReview,
      'historical' => ReviewStatus.historical,
      _ => throw PackFormatException('Unknown review status "$reviewName".'),
    };
    return PackData(
      id: id,
      title: _str(m, 'title'),
      description: _optStr(m, 'description') ?? '',
      category: category,
      version: _str(m, 'version'),
      publisher: _str(m, 'publisher'),
      license: _str(m, 'license'),
      attribution: _optStr(m, 'attribution') ?? '',
      reviewStatus: review,
      documents: [for (final d in docs) DocumentData._fromJson(d)],
    );
  }
}

class DocumentData {
  const DocumentData({
    required this.title,
    required this.sourceUrl,
    required this.sections,
    this.aliases = '',
    this.libraryOnly = false,
  });

  final String title;
  final String? sourceUrl;
  final List<SectionData> sections;

  /// Plain-language phrasings of what the document answers ("bug out
  /// bag, go bag, 72 hour kit"). Indexed for search, never shown: the
  /// verbatim text stays verbatim, this only bridges vocabulary.
  final String aliases;

  /// Readable and searchable in the Library but never given to the model
  /// (regulation text, reference tables): true when the pack sets
  /// `"libraryOnly": true`.
  final bool libraryOnly;

  factory DocumentData._fromJson(Object? json) {
    final m = _map(json, 'document');
    final sections = m['sections'];
    if (sections is! List || sections.isEmpty) {
      throw PackFormatException('Document "${m['title']}" has no sections.');
    }
    return DocumentData(
      title: _str(m, 'title'),
      sourceUrl: _optStr(m, 'sourceUrl'),
      sections: [for (final s in sections) SectionData._fromJson(s)],
      aliases: _optStr(m, 'aliases') ?? '',
      libraryOnly: m['libraryOnly'] == true,
    );
  }
}

class SectionData {
  const SectionData({
    required this.heading,
    required this.body,
    this.images = const [],
  });

  final String heading;
  final String body;
  final List<SectionImage> images;

  factory SectionData._fromJson(Object? json) {
    final m = _map(json, 'section');
    final images = m['images'];
    return SectionData(
      heading: _str(m, 'heading'),
      body: _str(m, 'body'),
      images: images is List
          ? [for (final i in images) SectionImage.fromJson(i)]
          : const [],
    );
  }
}

/// A figure or table rendered from the source page, shown inline where
/// `{{img:N}}` appears in the section body.
class SectionImage {
  const SectionImage({
    required this.asset,
    required this.caption,
    required this.isTable,
  });

  final String asset;
  final String caption;

  /// Tables carry exact values (doses, times) only the image shows.
  final bool isTable;

  factory SectionImage.fromJson(Object? json) {
    final m = _map(json, 'image');
    return SectionImage(
      asset: _str(m, 'asset'),
      caption: _str(m, 'caption'),
      isTable: m['kind'] == 'table',
    );
  }

  Map<String, Object> toJson() => {
    'asset': asset,
    'caption': caption,
    'kind': isTable ? 'table' : 'figure',
  };

  static final placeholder = RegExp(r'\{\{img:(\d+)\}\}');

  static List<SectionImage> listFromJson(String? json) {
    if (json == null || json.isEmpty) return const [];
    return [for (final i in jsonDecode(json) as List) SectionImage.fromJson(i)];
  }
}

Map<String, Object?> _map(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  throw PackFormatException('Malformed pack: expected a $what object.');
}

String _str(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is String && v.trim().isNotEmpty) return v;
  throw PackFormatException('Malformed pack: missing "$key".');
}

String? _optStr(Map<String, Object?> m, String key) {
  final v = m[key];
  return v is String && v.trim().isNotEmpty ? v : null;
}
