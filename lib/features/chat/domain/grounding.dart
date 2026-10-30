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
  /// Total passage text given to the model (~1,700 tokens). Every prompt
  /// token must be read on the phone's CPU before the first word appears,
  /// so this is a balance between a complete answer and a quick one.
  static const passageBudgetChars = 6500;

  /// Passages given to the model at most; beyond this they repeat.
  static const maxPassages = 8;

  static const citeInstruction =
      'Reference passages from the user\'s offline library are attached to '
      'their message, numbered [1], [2] and so on. They are your evidence: '
      'where a passage backs up a sentence, put its number in brackets '
      'after that sentence, like [1]. Take specifics (amounts, times, '
      'order of steps, warnings) from the passages rather than from '
      'memory, and if a passage contradicts what you believe, follow the '
      'passage and say so. Ignore any passage that isn\'t about the user\'s '
      'situation and never mention it. Cover whatever the passages leave '
      'out from your own knowledge, without numbers in brackets. Medicine '
      'doses and chemical amounts (bleach, iodine, tablets) must come from '
      'a passage; if none gives them, say the exact amount isn\'t in their '
      'library rather than guessing. If you rely on a passage marked '
      'UNREVIEWED or HISTORICAL, say that part may be outdated. If a '
      'passage shows a [Table image], don\'t estimate its values: say the '
      'exact figures are in that table and to tap the source to see it. '
      'Don\'t say "passage", "excerpt" or "source"; the user sees your '
      'sources as links under the reply.';

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
  /// tourniquet"). A short generation, run before the search.
  static const rewriteInstruction =
      'You turn a chat message into search queries for an offline library '
      'of survival, first-aid, preparedness and homesteading guides. Write '
      '2 or 3 queries, one per line, 3 to 8 plain words each, naming the '
      'topic and the specific thing asked (for example: "lost in the woods '
      'what to do first", "staying warm overnight without a tent", '
      '"improvised tourniquet with a belt"). Resolve references to earlier '
      'messages into the actual topic. Output only the queries, nothing '
      'else.';

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
      turns[lastUser] = ChatTurn(
        ChatSpeaker.user,
        '${_passages(hits)}\n\nMy message: ${history[lastUser].text}',
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
