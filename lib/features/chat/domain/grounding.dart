import '../../../core/database/app_database.dart';
import '../../library/data/knowledge_search.dart';
import '../../library/domain/pack_format.dart';
import 'inference_engine.dart';

/// Builds the turns sent to the model so answers are grounded in the
/// offline library: numbered passages are attached to the latest question,
/// and a system instruction says how to use them. The model is the
/// instructor and the passages are its evidence — it answers fully from
/// what it knows, cites the passages where they back it up, and defers to
/// them where they disagree.
abstract final class Grounding {
  /// Total passage text given to the model (~1,000 tokens). Every prompt
  /// token is re-read on the phone's CPU before the first word appears
  /// (no prompt cache), so this is the main first-word latency knob:
  /// 6,500 took over two minutes on a Pixel Fold; 4,000 is the ceiling
  /// until a faster model or prompt caching lands.
  static const passageBudgetChars = 4500;

  /// Passages given to the model at most. Fewer, better passages keep the
  /// model answering the question instead of summarising the notes; a 4B
  /// model given four covers all four.
  static const maxPassages = 3;

  static const citeInstruction =
      'Reference passages from the user\'s offline library are attached to '
      'their message, numbered [1], [2] and so on. They are notes for you, '
      'not a script: answer the person in front of you, in your own words, '
      'applied to their exact situation. A passage may be written for '
      'someone else (a parent, a group leader, a soldier); translate its '
      'advice, don\'t repeat it. Take specifics (amounts, times, order of '
      'steps, warnings) from the passages and follow them where they '
      'disagree with you. Put a bracketed number after a sentence only when '
      'it takes a specific fact from that passage, a few times at most, and '
      'never use the numbers as list numbering. Ignore passages that don\'t '
      'fit; never mention them or say what the library covers. Medicine '
      'doses and chemical amounts only from a passage; if none gives them, '
      'say the exact amount isn\'t in their library. Say so if you rely on a '
      'passage marked UNREVIEWED or HISTORICAL. For a [Table image], don\'t '
      'guess its values; say to tap the source.';

  static const noSourceInstruction =
      'Nothing in the user\'s offline library matched their latest message. '
      'Answer fully from your own knowledge, the way an experienced '
      'instructor would, without bracketed numbers. Don\'t give medicine '
      'doses or chemical amounts from memory. If the message asks for '
      'facts or instructions, end with one short sentence noting this '
      'wasn\'t checked against their library.';

  /// Asks the model for search queries that would find what the user
  /// needs, in the library's plainer vocabulary and with references to
  /// earlier turns spelled out ("what if I don't have one?" → "improvised
  /// tourniquet"). A short generation, run before the search — but only
  /// when the direct search comes up short (see [rewriteBelowHits]),
  /// because on a phone every extra prompt pass costs seconds.
  static const rewriteInstruction =
      'You turn a chat message into search queries for an offline library '
      'of survival, first-aid, preparedness and homesteading guides. Write '
      '2 or 3 queries, one per line, 3 to 8 plain words each, naming the '
      'topic and the specific thing asked (for example: "lost in the woods '
      'what to do first", "staying warm overnight without a tent", '
      '"improvised tourniquet with a belt"). Resolve references to earlier '
      'messages into the actual topic. If a photo is attached, name what it '
      'shows (the plant, animal, injury, device or label) in the queries. '
      'Output only the queries, nothing else.';

  /// Turns for the rewrite call: the previous exchange for context and
  /// the latest message to rewrite.
  static List<ChatTurn> rewriteTurns(List<ChatTurn> history) {
    final turns = [
      for (final t in history)
        if (t.speaker != ChatSpeaker.system) t,
    ];
    final recent = turns.length > 3 ? turns.sublist(turns.length - 3) : turns;
    return [
      const ChatTurn(ChatSpeaker.system, rewriteInstruction),
      for (final t in recent)
        t == recent.last
            ? ChatTurn(
                ChatSpeaker.user,
                'Message to turn into queries: ${t.text}',
              )
            : t,
    ];
  }

  /// Parses the rewrite output: one query per line, list markers,
  /// numbering and quotes stripped, nothing too short or too long, at
  /// most [maxRewrites], and never a copy of [question].
  static List<String> parseRewrites(String? output, String question) {
    if (output == null) return const [];
    final seen = {_normalize(question)};
    final out = <String>[];
    for (final raw in output.split('\n')) {
      final line = raw
          .replaceAll(RegExp(r'^[\s\-\*\d\.\)]+'), '')
          .replaceAll(RegExp(r'^["“]|["”]$'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final words = line.split(' ').where((w) => w.isNotEmpty).length;
      if (words < 2 || words > 12 || line.length > 80) continue;
      if (line.endsWith(':')) continue;
      if (!seen.add(_normalize(line))) continue;
      out.add(line);
      if (out.length == maxRewrites) break;
    }
    return out;
  }

  static const maxRewrites = 3;

  /// The rewrite runs only when the user's own words find fewer passages
  /// than this, or the message looks like a follow-up.
  static const rewriteBelowHits = 3;

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  /// Picks which ranked [hits] to give the model. Passages are never cut
  /// short — a truncated passage could drop the one line that matters (a
  /// dosage, a warning) — so lower-ranked passages that don't fit the
  /// budget are left out instead. The best match is always included (pack
  /// sections are capped at 4,000 characters by the builder).
  static List<PassageHit> select(List<PassageHit> hits) {
    final chosen = <PassageHit>[];
    var used = 0;
    for (final h in hits) {
      if (chosen.length == maxPassages) break;
      final size = h.body.length + h.heading.length + h.documentTitle.length;
      if (chosen.isNotEmpty && used + size > passageBudgetChars) continue;
      chosen.add(h);
      used += size;
    }
    return chosen;
  }

  /// [hits] must already be [select]ed; their order defines [1], [2], ….
  /// A [conversational] message (a greeting, thanks) gets no library
  /// instruction at all, so the model just replies like a person.
  static List<ChatTurn> apply(
    List<ChatTurn> history,
    List<PassageHit> hits, {
    bool conversational = false,
  }) {
    final lastUser = history.lastIndexWhere(
      (t) => t.speaker == ChatSpeaker.user,
    );
    if (lastUser < 0) return history;

    final turns = [...history];
    if (hits.isNotEmpty) {
      turns[lastUser] = history[lastUser].copyWith(
        text: '${_passages(hits)}\n\nMy message: ${history[lastUser].text}',
      );
    }
    return [
      if (!conversational)
        ChatTurn(
          ChatSpeaker.system,
          hits.isEmpty ? noSourceInstruction : citeInstruction,
        ),
      ...turns,
    ];
  }

  static String _passages(List<PassageHit> hits) {
    final b = StringBuffer('Reference passages from my offline library:');
    for (final (i, h) in hits.indexed) {
      final flag = switch (h.reviewStatus) {
        ReviewStatus.verified => '',
        ReviewStatus.needsReview =>
          ' (UNREVIEWED SOURCE: not from an official authority; may be '
              'outdated)',
        ReviewStatus.historical =>
          ' (HISTORICAL SOURCE, pre-1929: practices may be outdated or '
              'unsafe)',
      };
      final body = h.body.replaceAllMapped(SectionImage.placeholder, (m) {
        final n = int.parse(m.group(1)!);
        if (n >= h.images.length) return '';
        final img = h.images[n];
        return img.isTable
            ? '[Table image: ${img.caption} — exact values are shown to the '
                  'user in this passage; not available as text]'
            : '[Figure: ${img.caption}]';
      });
      b.write('\n\n[${i + 1}] ${h.documentTitle} — ${h.heading}$flag\n$body');
    }
    return b.toString();
  }

  /// Citation numbers that appear in [text], in order of first use.
  static List<int> citedNumbers(String text) {
    final seen = <int>{};
    for (final m in RegExp(r'\[(\d{1,2})\]').allMatches(text)) {
      seen.add(int.parse(m.group(1)!));
    }
    return seen.toList();
  }
}
