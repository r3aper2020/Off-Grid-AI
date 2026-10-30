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
    this.aliases = '',
    this.similarity,
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

  /// The document's plain-language aliases (retrieval only; never shown).
  final String aliases;

  /// Cosine similarity to the question this hit was ranked for, when
  /// vectors were available (set by [KnowledgeSearch.forQuestion] and
  /// [KnowledgeSearch.forQueries]); null otherwise.
  final double? similarity;

  PassageHit withSimilarity(double? value) => PassageHit(
    passageId: passageId,
    documentId: documentId,
    heading: heading,
    body: body,
    documentTitle: documentTitle,
    packTitle: packTitle,
    snippet: snippet,
    reviewStatus: reviewStatus,
    images: images,
    aliases: aliases,
    similarity: value,
  );

  /// Everything a question's words may match against.
  String get searchable => '$documentTitle $aliases $heading $body';
}

/// Search over installed passages: SQLite FTS5 (BM25) keywords fused with
/// meaning vectors, at section and document level.
///
/// Two entry points: [search] for the Library search box (any match, every
/// document) and [forQuestion]/[forQueries] for grounding an AI answer
/// (gated for relevance, library-only documents excluded, neighbouring
/// parts pulled in, near-duplicates dropped).
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
    // Ordering words ("what do I do first", "next step"): they matched
    // "First Aid kit" and pulled scrapes into a lost-in-the-woods answer.
    'first', 'next', 'step', 'steps', 'immediately', 'right', 'away',
    'exactly',
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

  /// Library search box: any term may match, best first, every document.
  Future<List<PassageHit>> search(String query, {int limit = 30}) {
    final terms = termsOf(query);
    if (terms.isEmpty) return Future.value(const []);
    return _query(_orQuery(terms), limit, chatOnly: false);
  }

  /// Passages to ground an AI answer to [question], best first.
  Future<List<PassageHit>> forQuestion(
    String question, {
    int limit = 12,
  }) async {
    return _finish(await _rank(question, limit), limit, question);
  }

  /// Passages for several phrasings of one need (the user's message plus
  /// rewrites of it): each is ranked on its own, then the rankings are
  /// fused so a passage found by more than one phrasing comes first. The
  /// first query is the user's own words and counts a little more.
  Future<List<PassageHit>> forQueries(
    List<String> queries, {
    int limit = 12,
  }) async {
    final lists = [for (final q in queries) await _rank(q, limit)];
    final score = <int, double>{};
    final byId = <int, PassageHit>{};
    for (final (qi, list) in lists.indexed) {
      final weight = qi == 0 ? 1.0 : rewriteWeight;
      for (final (rank, h) in list.indexed) {
        score[h.passageId] =
            (score[h.passageId] ?? 0) + weight / (_rrfK + rank);
        byId[h.passageId] = h;
      }
    }
    final ids = score.keys.toList()
      ..sort((a, b) => score[b]!.compareTo(score[a]!));
    return _finish(
      [for (final id in ids.take(limit)) byId[id]!],
      limit,
      queries.first,
    );
  }

  /// Weight of a rewritten query's ranking relative to the user's words.
  static const rewriteWeight = 0.8;

  /// Keyword and meaning rankings for [question], fused. Keyword matches
  /// must cover enough of the question's weight ([minCoverage]) so a
  /// single common word can't drag in an unrelated section; a word found
  /// in the heading, title or aliases counts [titleBoost] times.
  Future<List<PassageHit>> _rank(String question, int limit) async {
    final terms = termsOf(question);
    if (terms.isEmpty) return const [];

    final weights = await _termWeights(terms);
    final total = weights.values.fold(0.0, (a, b) => a + b);
    final q = await _queryVector(question);
    final vectors = q == null ? null : await _vectors();
    final lexical = <PassageHit>[];
    for (final hit in await _query(_orQuery(terms), lexicalCandidates)) {
      // A keyword match that means something else entirely ("hide" in
      // "Run, Hide, Fight" for "how do I tan a hide") is far from the
      // question in meaning; when vectors are available, drop it.
      final v = vectors?[hit.passageId];
      if (v != null &&
          PassageVectors.similarity(q!, v.vector) < lexicalSemanticFloor) {
        continue;
      }
      final titled = _matchedTerms(
        '${hit.documentTitle} ${hit.aliases} ${hit.heading}',
        terms,
      ).toSet();
      final covered = _matchedTerms(hit.searchable, terms).fold(
        0.0,
        (sum, t) => sum + weights[t]! * (titled.contains(t) ? titleBoost : 1),
      );
      if (covered >= total * minCoverage) lexical.add(hit);
      if (lexical.length == lexicalKept) break;
    }
    return _fuse(lexical, await _semantic(question, semanticKept), limit);
  }

  /// Keyword matches further than this from the question in meaning are
  /// not sources (calibrated with [semanticMin]).
  static const lexicalSemanticFloor = 0.55;

  /// BM25 candidates fetched and, of those, kept after the coverage gate.
  static const lexicalCandidates = 80;
  static const lexicalKept = 20;
  static const semanticKept = 20;

  /// Completes a ranked list: passages much further from the question in
  /// meaning than the best one are dropped (a keyword hit on "cell
  /// service" shouldn't ride along with the lost-hiker guidance), a short
  /// intro section brings its sub-sections, a "(part n)" section brings
  /// the parts around it, and near-duplicates (the same procedure in two
  /// manuals) are dropped. Each hit carries its similarity for callers.
  Future<List<PassageHit>> _finish(
    List<PassageHit> ranked,
    int limit,
    String question,
  ) async {
    final q = await _queryVector(question);
    final vectors = q == null ? null : await _vectors();
    double? simOf(PassageHit h) {
      final v = vectors?[h.passageId];
      return v == null ? null : PassageVectors.similarity(q!, v.vector);
    }

    final scored = [for (final h in ranked) h.withSimilarity(simOf(h))];
    final best = scored
        .map((h) => h.similarity ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);
    final out = <PassageHit>[];
    final seen = <int>{};
    // Neighbouring parts go after every ranked passage, so a long split
    // section's continuation doesn't take the budget from a better match.
    final parts = <PassageHit>[];
    for (final hit in scored) {
      if (!seen.add(hit.passageId)) continue;
      final sim = hit.similarity;
      if (sim != null && sim < best - relativeFloor) continue;
      if (_isDuplicate(hit, out)) continue;
      out.add(hit);
      if (hit.body.length < shortSectionChars) {
        for (final e in await _subsections(hit)) {
          if (seen.add(e.passageId)) out.add(e.withSimilarity(simOf(e)));
        }
      }
      for (final e in await _neighbourParts(hit)) {
        if (seen.add(e.passageId)) parts.add(e.withSimilarity(simOf(e)));
      }
      if (out.length >= limit * 2) break;
    }
    return [...out, ...parts];
  }

  /// How far below the best match's similarity a passage may fall and
  /// still be given to the model.
  static const relativeFloor = 0.12;

  /// A best match below this means the user's words didn't find the
  /// library's; worth asking the model to rephrase the search.
  static const confidentSimilarity = 0.72;

  /// Passages closest in meaning to [question], best first: section
  /// vectors, lifted by how well the whole document matches (a question
  /// about a "bug out bag" matches the "Build A Kit" document even when
  /// no single section says so). A section counts when it is itself close
  /// ([semanticMin]) or its document is clearly about the question
  /// ([docStrong]).
  Future<List<(PassageHit, double)>> _semantic(
    String question,
    int limit,
  ) async {
    final q = await _queryVector(question);
    if (q == null) return const [];
    final docSims = <int, double>{
      for (final MapEntry(:key, :value) in (await _docVectors()).entries)
        key: PassageVectors.similarity(q, value),
    };
    final scored = <(int, double)>[];
    for (final MapEntry(:key, :value) in (await _vectors()).entries) {
      final sim = PassageVectors.similarity(q, value.vector);
      final doc = docSims[value.documentId] ?? 0;
      final admitted =
          sim >= semanticMin || (doc >= docStrong && sim >= docMemberMin);
      if (!admitted) continue;
      scored.add((key, sim + docWeight * max(0.0, doc - docMin)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(limit).toList();
    final hits = await byIds([for (final (id, _) in top) id]);
    return [
      for (final (i, h) in hits.indexed)
        if (h != null) (h, top[i].$2),
    ];
  }

  /// The [limit] passages closest in meaning to [question] with their
  /// cosine similarity, regardless of thresholds (used by the coverage
  /// tool to calibrate them).
  Future<List<(PassageHit, double)>> semanticMatches(
    String question, {
    int limit = 6,
  }) async {
    final q = await _queryVector(question);
    if (q == null) return const [];
    final scored = [
      for (final MapEntry(:key, :value) in (await _vectors()).entries)
        (key, PassageVectors.similarity(q, value.vector)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(limit).toList();
    final hits = await byIds([for (final (id, _) in top) id]);
    return [
      for (final (i, h) in hits.indexed)
        if (h != null) (h, top[i].$2),
    ];
  }

  /// Documents closest in meaning to [question] (title + aliases), best
  /// first, with cosine similarity; for calibration and diagnostics.
  Future<List<(int documentId, double)>> documentMatches(
    String question, {
    int limit = 5,
  }) async {
    final q = await _queryVector(question);
    if (q == null) return const [];
    final scored = [
      for (final MapEntry(:key, :value) in (await _docVectors()).entries)
        (key, PassageVectors.similarity(q, value)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).toList();
  }

  /// Cosine similarity between [question] and [hit]'s stored vector, or 0
  /// when either is unavailable (diagnostics).
  Future<double> similarityTo(String question, PassageHit hit) async {
    final q = await _queryVector(question);
    final v = (await _vectors())[hit.passageId];
    if (q == null || v == null) return 0;
    return PassageVectors.similarity(q, v.vector);
  }

  Future<Int8List?> _queryVector(String question) async {
    final List<double>? v;
    try {
      v = await _embedder.embedQuery(question);
    } catch (_) {
      return null;
    }
    if (v == null || v.length != PassageVectors.dim) return null;
    return PassageVectors.quantize(v);
  }

  /// Cosine similarity a section needs to count as a semantic match on
  /// its own. Calibrated on tools/coverage/questions.tsv plus off-topic
  /// controls (see docs/decisions.md).
  static const semanticMin = 0.64;

  /// Document similarity above which a document's sections count even
  /// below [semanticMin] — as long as the section itself is at least
  /// loosely related ([docMemberMin]), so a strongly matching food chapter
  /// doesn't drag its fishing sections into a question about plants.
  static const docStrong = 0.70;
  static const docMemberMin = 0.58;

  /// Document similarity from which sections get lifted, and by how much
  /// per unit of similarity above it (kept small: it breaks ties between
  /// documents, it shouldn't outrank a closer section elsewhere).
  static const docMin = 0.60;
  static const docWeight = 0.3;

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
      final weight = 1 + max(0.0, sim - semanticMin) * _semanticBoost;
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

  /// Strong enough that a verified source on the same topic wins (the
  /// Wikibooks CPR rate predates the 2015 guidelines), while unreviewed
  /// or historical text still surfaces when nothing verified covers it.
  static const _trust = {
    ReviewStatus.verified: 1.0,
    ReviewStatus.needsReview: 0.5,
    ReviewStatus.historical: 0.4,
  };

  /// How much extra a meaning match earns per 0.1 of similarity above
  /// [semanticMin] (0.84 → ×2).
  static const _semanticBoost = 5.0;

  static const _rrfK = 10;

  /// Stored section vectors (chat-eligible documents only), cached until
  /// the library changes.
  Future<Map<int, ({int documentId, Int8List vector})>> _vectors() async {
    final key = await _libraryKey();
    if (key == _vectorKey && _vectorCache != null) return _vectorCache!;
    final rows = await _db
        .customSelect(
          'SELECT p.id, p.document_id, p.embedding FROM passages p '
          'JOIN pack_documents d ON d.id = p.document_id '
          'WHERE p.embedding IS NOT NULL AND d.library_only = 0',
          readsFrom: {_db.passages, _db.packDocuments},
        )
        .get();
    if (key != _vectorKey) _docVectorCache = null;
    _vectorKey = key;
    return _vectorCache = {
      for (final r in rows)
        r.read<int>('id'): (
          documentId: r.read<int>('document_id'),
          vector: Int8List.sublistView(r.read<Uint8List>('embedding')),
        ),
    };
  }

  Future<Map<int, Int8List>> _docVectors() async {
    final key = await _libraryKey();
    if (key == _vectorKey && _docVectorCache != null) return _docVectorCache!;
    final rows = await _db
        .customSelect(
          'SELECT id, embedding FROM pack_documents '
          'WHERE embedding IS NOT NULL AND library_only = 0',
          readsFrom: {_db.packDocuments},
        )
        .get();
    if (key != _vectorKey) _vectorCache = null;
    _vectorKey = key;
    return _docVectorCache = {
      for (final r in rows)
        r.read<int>('id'): Int8List.sublistView(r.read<Uint8List>('embedding')),
    };
  }

  Future<String> _libraryKey() async =>
      (await _db
              .customSelect('SELECT count(*) AS n, max(id) AS m FROM passages')
              .getSingle())
          .data
          .toString();

  String? _vectorKey;
  Map<int, ({int documentId, Int8List vector})>? _vectorCache;
  Map<int, Int8List>? _docVectorCache;

  /// Like [forQuestion] for a message in a conversation when no model is
  /// available to rewrite it. A short follow-up ("what about for a
  /// baby?") is searched together with the [previous] question it
  /// follows, but every passage must still match a word of the new
  /// message, so a change of topic ("bear attack" after a fire question)
  /// never brings back the old topic's passages.
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
        if (_matchedTerms(h.searchable, terms).isNotEmpty) h,
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

  /// "Heading (part 2)" → the parts just before and after it in the same
  /// document, so a procedure split by the builder isn't cut mid-way.
  Future<List<PassageHit>> _neighbourParts(PassageHit hit) async {
    final m = _partHeading.firstMatch(hit.heading);
    if (m == null) return const [];
    final base = m.group(1)!;
    final n = int.parse(m.group(2)!);
    final rows = await _db
        .customSelect(
          '$_select WHERE p.document_id = ? AND p.heading IN (?, ?) '
          'ORDER BY p.position',
          variables: [
            Variable.withInt(hit.documentId),
            Variable.withString('$base (part ${n - 1})'),
            Variable.withString('$base (part ${n + 1})'),
          ],
          readsFrom: {_db.passages, _db.packDocuments, _db.knowledgePacks},
        )
        .get();
    return rows.map(_hit).toList();
  }

  static final _partHeading = RegExp(r'^(.*) \(part (\d+)\)$');

  /// Same text in two sources (an Army chapter and a CERT unit both
  /// describing the same bleeding control): keep the higher-ranked one.
  static bool _isDuplicate(PassageHit hit, List<PassageHit> kept) {
    final words = _wordSet(hit.body);
    if (words.length < 20) return false;
    for (final k in kept) {
      final other = _wordSet(k.body);
      final common = words.intersection(other).length;
      final union = words.length + other.length - common;
      if (union > 0 && common / union > duplicateJaccard) return true;
    }
    return false;
  }

  static const duplicateJaccard = 0.5;

  static Set<String> _wordSet(String text) =>
      RegExp(r'[a-z]{3,}')
          .allMatches(text.toLowerCase())
          .map((m) => m.group(0)!)
          .toSet();

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
           d.title AS doc_title, d.aliases AS aliases, k.title AS pack_title,
           '' AS snip, k.review_status AS review, p.images AS images
    FROM passages p
    JOIN pack_documents d ON d.id = p.document_id
    JOIN knowledge_packs k ON k.id = d.pack_id''';

  /// BM25-ranked keyword matches. [chatOnly] leaves out documents marked
  /// library-only (regulation text), which the Library search box keeps.
  Future<List<PassageHit>> _query(
    String match,
    int limit, {
    bool chatOnly = true,
  }) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT p.id AS pid, p.document_id AS did, p.heading, p.body,
                 d.title AS doc_title, d.aliases AS aliases,
                 k.title AS pack_title,
                 snippet(passages_fts, 2, '[', ']', '…', 18) AS snip,
                 k.review_status AS review, p.images AS images
          FROM passages_fts
          JOIN passages p ON p.id = passages_fts.rowid
          JOIN pack_documents d ON d.id = p.document_id
          JOIN knowledge_packs k ON k.id = d.pack_id
          WHERE passages_fts MATCH ?${chatOnly ? ' AND d.library_only = 0' : ''}
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
    aliases: r.read<String>('aliases'),
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

  /// Extra weight for a question word found in a heading, title or alias.
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
