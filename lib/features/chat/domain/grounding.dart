import '../../../core/database/app_database.dart';
import '../../library/data/knowledge_search.dart';
import '../../library/domain/pack_format.dart';
import 'inference_engine.dart';

/// Builds the turns sent to the model so answers are checked against the
/// offline library. The model is the instructor: it answers from its own
/// expertise, and the numbered passages ride along in the system
/// instruction as a check on that answer — a place to take an exact
/// amount or order of steps from, and to cite when it does — never as a
/// text to summarise. They are deliberately kept out of the user's
/// message: a small model given notes ahead of the question answers the
/// notes, not the person.
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
      'You answer from your own expertise, like an instructor who has done '
      'this many times. Below are passages a search pulled from the user\'s '
      'offline library for their latest message, numbered [1], [2] and so '
      'on. They are a check on your answer, not its source, and some may '
      'be off-topic. Decide what you would tell this person, in your own '
      'words, for their exact situation; then compare it with the passages '
      'that are about that same situation. Where such a passage gives a '
      'specific (an amount, a time, an order of steps, a warning) that '
      'differs from what you were going to say, use the passage\'s and put '
      'its number after that sentence. A passage about a different setting '
      '(a woodstove when they\'re outdoors, a hospital when they\'re not) '
      'changes nothing. A number '
      'marks a specific fact taken from a passage, a few at most, never as '
      'list numbering. A passage written for someone else (a parent, a '
      'group leader, a soldier) is translated, never repeated. The user '
      'never sees the passages: don\'t describe them, compare them, or say '
      'which you relied on, and ignore ones that don\'t fit without a word '
      'about them or about what the library covers. Medicine doses and '
      'chemical amounts come only from a passage; if none gives them, say '
      'the exact amount isn\'t in their library. If a fact comes from a '
      'passage marked UNREVIEWED or HISTORICAL, add a few words saying it '
      'is from an unreviewed or old source. The user sees each [Figure] '
      'and [Table image] from these passages next to your answer, so when '
      'one shows what you\'re describing, point to it by its caption '
      '("see Figure A-8"); don\'t guess a table\'s values, say to tap it.';

  static const noSourceInstruction =
      'Nothing in the user\'s offline library matched their latest message. '
      'Answer fully from your own knowledge, the way an experienced '
      'instructor would, without bracketed numbers. Don\'t give medicine '
      'doses or chemical amounts from memory. If the message asks for '
      'facts or instructions, end with one short sentence noting this '
      'wasn\'t checked against their library.';

  /// True for a message with no topic of its own that is not an answer
  /// to the assistant's last question: "hi", "thanks", "ok". Those get a
  /// plain reply with no library lookup. A short answer to a question the
  /// assistant asked ("I think it's 1%", "yes, he's awake") continues the
  /// topic, so it is grounded against the [previous] question instead —
  /// a dose for 1% bleach must still come from a passage, not memory.
  static bool isSmallTalk(
    String message, {
    String? previous,
    String? lastReply,
  }) {
    if (KnowledgeSearch.termsOf(message).isNotEmpty) return false;
    if (previous == null) return true;
    if (RegExp(r'\d').hasMatch(message)) return false;
    final words = message
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.isNotEmpty);
    if (words.every(_pleasantries.contains)) return true;
    return !(lastReply?.trimRight().endsWith('?') ?? false);
  }

  static const _pleasantries = {
    'hi', 'hello', 'hey', 'thanks', 'thank', 'you', 'thx', 'ty', 'ok',
    'okay', 'cool', 'great', 'nice', 'awesome', 'got', 'it', 'bye',
    'cheers', 'good', 'perfect', 'sure', 'alright', 'understood',
  };

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
  /// The passages go into the system turn with the citation rules; the
  /// user's message is sent exactly as written. A [conversational]
  /// message (a greeting, thanks) gets no library instruction at all, so
  /// the model just replies like a person.
  static List<ChatTurn> apply(
    List<ChatTurn> history,
    List<PassageHit> hits, {
    bool conversational = false,
  }) {
    final lastUser = history.lastIndexWhere(
      (t) => t.speaker == ChatSpeaker.user,
    );
    if (lastUser < 0) return history;

    return [
      if (!conversational)
        ChatTurn(
          ChatSpeaker.system,
          hits.isEmpty
              ? noSourceInstruction
              : '$citeInstruction\n\n${_passages(hits)}',
        ),
      ...history,
    ];
  }

  static String _passages(List<PassageHit> hits) {
    final b = StringBuffer(
      'Passages from the user\'s offline library for their latest message:',
    );
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
