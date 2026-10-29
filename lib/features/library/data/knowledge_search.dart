import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/pack_format.dart';
import '../domain/passage_vectors.dart';
import '../domain/text_embedder.dart';

/// A passage with the context needed to cite and open it.
class PassageHit {
  const PassageHit({
    required this.passageId,
    required this.documentId,
    required this.heading,
    required this.body,
    required this.documentTitle,
    required this.packTitle,
    required this.snippet,
    this.reviewStatus = ReviewStatus.verified,
    this.images = const [],
  });

  final int passageId;
  final int documentId;
  final String heading;
  final String body;
  final String documentTitle;
  final String packTitle;

  /// Short excerpt with matches wrapped in `[` `]` (search results only).
  final String snippet;

  /// Trust level of the pack this passage came from.
  final ReviewStatus reviewStatus;

  /// Figures/tables referenced from [body] by `{{img:N}}`.
  final List<SectionImage> images;
}

/// Full-text search over installed passages (SQLite FTS5, BM25 ranking).
class KnowledgeSearch {
  KnowledgeSearch(this._db, {this._embedder = const NoTextEmbedder()});
  final AppDatabase _db;
  final TextEmbedder _embedder;

  /// Words too common to say anything about relevance.
  static const _stopwords = {
    'a',
    'about',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'but',
    'by',
    'can',
    'could',
    'do',
    'does',
    'for',
    'from',
    'get',
    'have',
    'how',
    'i',
    'if',
    'in',
    'into',
    'is',
    'it',
    'its',
    'me',
    'my',
    'of',
    'on',
    'or',
    'should',
    'so',
    'some',
    'than',
    'that',
    'the',
    'their',
    'them',
    'then',
    'there',
    'these',
    'they',
    'this',
    'to',
    'up',
    'was',
    'we',
    'what',
    'when',
    'where',
    'which',
    'who',
    'why',
    'will',
    'with',
    'would',
    'you',
    'your',
    'need',
    'tell',
    'please',
    'best',
    'way',
    'help',
    'know',
    'want',
    'make',
    'out',
    'any',
    'all',
    'just',
    'one',
    'off',
    'very',
    'much',
    'long',
    'many',
    // Who/when phrasing, not topics.
    'someone', 'somebody', 'anyone', 'anybody', 'everyone', 'people',
    'person', 'during', 'while', 'happens', 'happen', 'case',
    // Request scaffolding, not topics.
    'explain', 'describe', 'write', 'recommend', 'list', 'give', 'show',
    'good', 'great', 'today', 'tonight', 'now', 'something', 'thing',
    'things', 'anything', 'kind', 'find', 'use', 'using', 'used',
    'often',
    // Describing the situation, not the topic ("I'm in the middle of
    // nowhere"): rare enough to outweigh the real topic word.
    'middle', 'nowhere', 'stuck', 'currently', 'situation', 'trying',
    'try', 'able', 'gonna', 'got', 'think', 'maybe', 'actually',
    'outside', 'badly', 'bad', 'pretty', 'lot',
    // Greetings and acknowledgements: no topic to look up.
    'hi', 'hello', 'hey', 'thanks', 'thank', 'thx', 'yes', 'yeah', 'yep',
    'nope', 'sure', 'cool', 'nice', 'awesome', 'bye', 'goodbye', 'lol',
    'wow', 'alright', 'morning', 'afternoon', 'evening',
    // Pronouns and helper verbs.
    'he', 'she', 'him', 'her', 'his', 'hers', 'our', 'us', 'has', 'had',
    'am', 'im', 'been', 'being', 'were', 'did', 'done', 'go', 'going',
    // Who it's happening to (the topic is what's wrong, not who).
    'friend', 'buddy', 'guy', 'wife', 'husband', 'partner', 'dad', 'mom',
    'brother', 'sister', 'son', 'daughter',
    'ok',
    'okay',
    'safely',
    'really',
    'still',
  };

  /// Everyday words mapped to the wording official sources use, so a
  /// question about the "fridge" finds the CDC's "refrigerator" guidance.
  static const _synonyms = {
    'fridge': 'refrigerator',
    'fridges': 'refrigerator',
    'meds': 'medications',
    'pills': 'medications',
    'bandaid': 'bandage',
    'bandaids': 'bandage',
    'carbs': 'carbohydrates',
  };

  /// Meaningful query terms: lowercase words, stopwords removed, everyday
  /// words mapped to official wording ([_synonyms]).
  static List<String> termsOf(String text) {
    final words = RegExp(r"[a-z0-9]+(?:'[a-z]+)?")
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!.replaceAll(RegExp(r"'.*"), ''))
        .where((w) => w.length >= 2 && !_stopwords.contains(w))
        .map((w) => _synonyms[w] ?? w);
    return words.toSet().toList();
  }

  /// Library search box: any term may match, best first.
  Future<List<PassageHit>> search(String query, {int limit = 30}) {
    final terms = termsOf(query);
    if (terms.isEmpty) return Future.value(const []);
    return _query(_orQuery(terms), limit);
  }

  /// Passages to ground an AI answer, best first, in BM25 order (which
  /// already weights rare, specific words like "boil" above common ones
  /// like "safe"). Partial matches must share at least two terms with the
  /// question, so a single common word doesn't drag in unrelated sections.
  ///
  /// A short matching section is usually an intro ("Boil") whose substance
  /// is in its sub-sections ("Boil: Steps for boiling water"), so those
  /// follow it directly. [Grounding.select] later trims to the size budget.
  Future<List<PassageHit>> forQuestion(String question, {int limit = 6}) async {
    final terms = termsOf(question);
    if (terms.isEmpty) return const [];

    final weights = await _termWeights(terms);
    final total = weights.values.fold(0.0, (a, b) => a + b);
    final lexical = <PassageHit>[];
    for (final hit in await _query(_orQuery(terms), 40)) {
      // A word in the section's heading or document title names what the
      // section is about, so it counts for more than a passing mention:
      // "I'm in contact with a bear" belongs to "Bear Encounters".
      final titled = _matchedTerms(
        '${hit.documentTitle} ${hit.heading}',
        terms,
      ).toSet();
      final covered =
          _matchedTerms(
            '${hit.documentTitle} ${hit.heading} ${hit.body}',
            terms,
          ).fold(
            0.0,
            (sum, t) =>
                sum + weights[t]! * (titled.contains(t) ? titleBoost : 1),
          );
      if (covered >= total * minCoverage) lexical.add(hit);
      if (lexical.length == limit) break;
    }
    final ranked = _fuse(lexical, await _semantic(question, limit), limit);

    final out = <PassageHit>[];
    final seen = <int>{};
    for (final hit in ranked) {
      if (seen.add(hit.passageId)) out.add(hit);
      if (hit.body.length < shortSectionChars) {
        for (final child in await _subsections(hit)) {
          if (seen.add(child.passageId)) out.add(child);
        }
      }
    }
    return out;
  }

  /// Passages closest in meaning to [question], best first, above
  /// [semanticMin]; empty when no embedder or no vectors are available.
  Future<List<(PassageHit, double)>> _semantic(
    String question,
    int limit,
  ) async => [
    for (final (hit, score) in await semanticMatches(question, limit: limit))
      if (score >= semanticMin) (hit, score),
  ];

  /// The [limit] passages closest in meaning to [question] with their
  /// cosine similarity, regardless of [semanticMin] (also used by the
  /// coverage tool to calibrate it).
  Future<List<(PassageHit, double)>> semanticMatches(
    String question, {
    int limit = 6,
  }) async {
    final List<double>? v;
    try {
      v = await _embedder.embedQuery(question);
    } catch (_) {
      return const [];
    }
    if (v == null || v.length != PassageVectors.dim) return const [];
    final q = PassageVectors.quantize(v);
    final scored = [
      for (final MapEntry(:key, :value) in (await _vectors()).entries)
        (key, PassageVectors.similarity(q, value)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(limit).toList();
    final hits = await byIds([for (final (id, _) in top) id]);
    return [
      for (final (i, h) in hits.indexed)
        if (h != null) (h, top[i].$2),
    ];
  }

  /// Cosine similarity a passage needs to count as a semantic match.
  /// Calibrated on tools/coverage/questions.tsv plus off-topic questions
  /// (see docs/decisions.md).
  static const semanticMin = 0.70;

  /// Merges keyword and meaning rankings (reciprocal rank fusion): a
  /// passage both find ranks first; one found by only one still counts.
  /// A meaning match counts for more the closer it is, so a strong match
  /// ("solar still" ↔ "Below-ground solar still") beats a keyword hit
  /// on a stray word ("put" in "put something soft under their head").
  static List<PassageHit> _fuse(
    List<PassageHit> lexical,
    List<(PassageHit, double)> semantic,
    int limit,
  ) {
    final score = <int, double>{};
    final byId = <int, PassageHit>{};
    for (final (rank, h) in lexical.indexed) {
      score[h.passageId] = 1 / (_rrfK + rank);
      byId[h.passageId] = h;
    }
    for (final (rank, (h, sim)) in semantic.indexed) {
      final weight = 1 + (sim - semanticMin) * _semanticBoost;
      score[h.passageId] = (score[h.passageId] ?? 0) + weight / (_rrfK + rank);
      byId[h.passageId] = h;
    }
    // Current official guidance outranks old or unreviewed text on the
    // same topic (a 1911 scout handbook shouldn't answer "I'm lost").
    for (final MapEntry(:key, :value) in byId.entries) {
      score[key] = score[key]! * _trust[value.reviewStatus]!;
    }
    final ids = score.keys.toList()
      ..sort((a, b) => score[b]!.compareTo(score[a]!));
    return [for (final id in ids.take(limit)) byId[id]!];
  }

  static const _trust = {
    ReviewStatus.verified: 1.0,
    ReviewStatus.needsReview: 0.8,
    ReviewStatus.historical: 0.5,
  };

  /// How much extra a meaning match earns per 0.1 of similarity above
  /// [semanticMin] (0.80 → ×2).
  static const _semanticBoost = 10.0;

  static const _rrfK = 10;

  /// Stored vectors by passage id, cached until the library changes.
  Future<Map<int, Int8List>> _vectors() async {
    final key =
        (await _db
                .customSelect(
                  'SELECT count(*) AS n, max(id) AS m FROM passages',
                )
                .getSingle())
            .data
            .toString();
    if (key == _vectorKey && _vectorCache != null) return _vectorCache!;
    final rows = await _db
        .customSelect(
          'SELECT id, embedding FROM passages WHERE embedding IS NOT NULL',
          readsFrom: {_db.passages},
        )
        .get();
    _vectorKey = key;
    return _vectorCache = {
      for (final r in rows)
        r.read<int>('id'): Int8List.sublistView(r.read<Uint8List>('embedding')),
    };
  }

  String? _vectorKey;
  Map<int, Int8List>? _vectorCache;

  /// Like [forQuestion] for a message in a conversation. A short
  /// follow-up ("what about for a baby?") is searched together with the
  /// [previous] question it follows, but every passage must still match a
  /// word of the new message, so a change of topic ("bear attack" after a
  /// fire question) never brings back the old topic's passages.
  Future<List<PassageHit>> forMessage(
    String question, {
    String? previous,
  }) async {
    final terms = termsOf(question);
    if (previous == null || terms.isEmpty) return forQuestion(question);
    if (terms.length > followUpMaxTerms) {
      final hits = await forQuestion(question);
      if (hits.isNotEmpty) return hits;
    }
    final combined = [
      for (final h in await forQuestion('$previous $question'))
        if (_matchedTerms(
          '${h.documentTitle} ${h.heading} ${h.body}',
          terms,
        ).isNotEmpty)
          h,
    ];
    if (combined.isNotEmpty) return combined;
    return terms.length > followUpMaxTerms ? const [] : forQuestion(question);
  }

  /// Messages with at most this many topic words may be follow-ups.
  static const followUpMaxTerms = 2;

  /// Sections shorter than this pull in their sub-sections.
  static const shortSectionChars = 400;

  Future<List<PassageHit>> _subsections(PassageHit parent) async {
    final rows = await _db
        .customSelect(
          '$_select WHERE p.document_id = ? AND p.heading LIKE ? ESCAPE '
          "'\\' ORDER BY p.position",
          variables: [
            Variable.withInt(parent.documentId),
            Variable.withString('${_escapeLike(parent.heading)}: %'),
          ],
          readsFrom: {_db.passages, _db.packDocuments, _db.knowledgePacks},
        )
        .get();
    return rows.map(_hit).toList();
  }

  static String _escapeLike(String s) =>
      s.replaceAllMapped(RegExp(r'[%_\\]'), (m) => '\\${m[0]}');

  /// Passages for [ids], position for position; null where a passage no
  /// longer exists (its pack was removed), so citation numbers stay aligned.
  Future<List<PassageHit?>> byIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _db
        .customSelect(
          '$_select WHERE p.id IN (${List.filled(ids.length, '?').join(',')})',
          variables: [for (final id in ids) Variable.withInt(id)],
          readsFrom: {_db.passages, _db.packDocuments, _db.knowledgePacks},
        )
        .get();
    final byId = {for (final r in rows.map(_hit)) r.passageId: r};
    return [for (final id in ids) byId[id]];
  }

  /// Figures and tables that go with [hits]: each passage's own images,
  /// then any its text refers to by number ("see Figure 5-5") that the
  /// PDF happened to place in a neighbouring section of the same document.
  /// Numbers are only matched within a document, so "Figure 4-5" in one
  /// manual never pulls in another manual's Figure 4-5.
  Future<List<SectionImage>> figuresFor(List<PassageHit> hits) async {
    final out = <SectionImage>[];
    final seen = <String>{};
    void add(SectionImage img) {
      if (seen.add(img.asset)) out.add(img);
    }

    final docImages = <int, List<SectionImage>>{};
    for (final hit in hits) {
      hit.images.forEach(add);
      final refs = _figureRef
          .allMatches(hit.body)
          .map((m) => '${_kindOf(m[1]!)} ${m[2]!.toLowerCase()}')
          .toSet();
      if (refs.isEmpty) continue;
      final images = docImages[hit.documentId] ??= await _documentImages(
        hit.documentId,
      );
      for (final img in images) {
        final m = _figureRef.matchAsPrefix(img.caption);
        if (m != null &&
            refs.contains('${_kindOf(m[1]!)} ${m[2]!.toLowerCase()}')) {
          add(img);
        }
      }
    }
    return out;
  }

  /// "Figure 5-5", "Fig. 3", "Table A-2" (number without trailing period).
  static final _figureRef = RegExp(
    r'\b(Figures?|Figs?\.?|Tables?)\s+([A-Z]?-?\d+(?:-\d+)*[a-z]?)',
    caseSensitive: false,
  );

  static String _kindOf(String word) =>
      word.toLowerCase().startsWith('t') ? 'table' : 'figure';

  Future<List<SectionImage>> _documentImages(int documentId) async {
    final rows = await _db
        .customSelect(
          "SELECT images FROM passages WHERE document_id = ? AND images IS "
          "NOT NULL AND images != '[]' ORDER BY position",
          variables: [Variable.withInt(documentId)],
          readsFrom: {_db.passages},
        )
        .get();
    return [
      for (final r in rows)
        ...SectionImage.listFromJson(r.readNullable<String>('images')),
    ];
  }

  static const _select = '''
    SELECT p.id AS pid, p.document_id AS did, p.heading, p.body,
           d.title AS doc_title, k.title AS pack_title, '' AS snip,
           k.review_status AS review, p.images AS images
    FROM passages p
    JOIN pack_documents d ON d.id = p.document_id
    JOIN knowledge_packs k ON k.id = d.pack_id''';

  Future<List<PassageHit>> _query(String match, int limit) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT p.id AS pid, p.document_id AS did, p.heading, p.body,
                 d.title AS doc_title, k.title AS pack_title,
                 snippet(passages_fts, 2, '[', ']', '…', 18) AS snip,
                 k.review_status AS review, p.images AS images
          FROM passages_fts
          JOIN passages p ON p.id = passages_fts.rowid
          JOIN pack_documents d ON d.id = p.document_id
          JOIN knowledge_packs k ON k.id = d.pack_id
          WHERE passages_fts MATCH ?
          ORDER BY bm25(passages_fts, 2.0, 3.0, 1.0)
          LIMIT ?''',
          variables: [Variable.withString(match), Variable.withInt(limit)],
          readsFrom: {_db.passages, _db.packDocuments, _db.knowledgePacks},
        )
        .get();
    return rows.map(_hit).toList();
  }

  static PassageHit _hit(QueryRow r) => PassageHit(
    passageId: r.read<int>('pid'),
    documentId: r.read<int>('did'),
    heading: r.read<String>('heading'),
    body: r.read<String>('body'),
    documentTitle: r.read<String>('doc_title'),
    packTitle: r.read<String>('pack_title'),
    snippet: r.read<String>('snip'),
    reviewStatus: ReviewStatus.values.byName(r.read<String>('review')),
    images: SectionImage.listFromJson(r.readNullable<String>('images')),
  );

  /// Quoted so user text can never inject FTS5 query syntax.
  static String _quote(String term) => '"${term.replaceAll('"', '')}"';

  static String _orQuery(List<String> terms) => terms.map(_quote).join(' OR ');

  /// Approximates stemmed matching with a shared 4-letter prefix
  /// ("boil" ~ "boiling").
  static List<String> _matchedTerms(String text, List<String> terms) {
    text = text.toLowerCase();
    return terms.where((t) {
      final stem = stemOf(t);
      // Short stems must match a whole word ("won" ≠ "wonderful"); longer
      // stems may take a suffix ("boil" ~ "boiling", "comput" ≠ "compass").
      final pattern = stem.length < 4
          ? '\\b${RegExp.escape(stem)}\\b'
          : '\\b${RegExp.escape(stem)}[a-z]{0,4}\\b';
      return RegExp(pattern).hasMatch(text);
    }).toList();
  }

  /// Light suffix stripping, close enough to FTS5's porter stemmer for
  /// relevance checks: "boiling"→"boil", "snares"→"snare", "computing"→
  /// "comput".
  static String stemOf(String word) {
    for (final suffix in const [
      'ations',
      'ation',
      'ings',
      'ing',
      'edly',
      'ies',
      'ied',
      'ed',
      'es',
      's',
    ]) {
      // Keep at least 4 letters so "water" or "uses" aren't over-trimmed.
      if (word.length - suffix.length >= 4 && word.endsWith(suffix)) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  /// Share of the question's weight a passage must cover to count as a
  /// source. Words are weighted by rarity in the library (BM25-style IDF),
  /// so the topic word ("hypothermia") carries a question while everyday
  /// words ("someone", "world", "cup") barely count, and a word the library
  /// has never seen ("quantum", "1998") weighs the most — which keeps
  /// off-topic questions from finding false sources as the library grows.
  static const minCoverage = 0.55;

  /// Extra weight for a question word found in a heading or title.
  static const titleBoost = 1.5;

  Future<Map<String, double>> _termWeights(List<String> terms) async {
    final n =
        (await _db
                .customSelect('SELECT count(*) AS n FROM passages')
                .getSingle())
            .read<int>('n');
    final weights = <String, double>{};
    for (final t in terms) {
      final df =
          (await _db
                  .customSelect(
                    'SELECT count(*) AS n FROM passages_fts '
                    'WHERE passages_fts MATCH ?',
                    variables: [Variable.withString(_quote(t))],
                  )
                  .getSingle())
              .read<int>('n');
      weights[t] = log((n - df + 0.5) / (df + 0.5) + 1);
    }
    return weights;
  }
}
