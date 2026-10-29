import '../../../core/database/app_database.dart';
import '../../library/data/knowledge_search.dart';
import '../../library/domain/pack_format.dart';
import 'inference_engine.dart';

/// Builds the turns sent to the model so answers are grounded in the
/// offline library: numbered passages are attached to the latest question,
/// and a system instruction says how to cite them — or, when nothing
/// matched, to say so before answering from general knowledge.
abstract final class Grounding {
  /// Total passage text given to the model (~1,000 tokens). Every prompt
  /// token must be read on the phone's CPU before the first word appears,
  /// so this is kept to what a focused answer needs.
  static const passageBudgetChars = 3500;

  static const citeInstruction =
      'Excerpts from the user\'s offline survival guides are attached to '
      'their latest message, numbered [1], [2] and so on. Treat them as your '
      'source of truth. Right after a sentence that uses one, put its '
      'number in square brackets, like [1]; only use numbers you were given. '
      'Answer naturally: don\'t mention "excerpts" or "passages", and don\'t '
      'quote them at length. If they don\'t answer the question, say in one '
      'short sentence that your offline guides don\'t cover it, then give '
      'brief general guidance without bracketed numbers. Excerpts marked '
      'UNREVIEWED or HISTORICAL may be outdated: if you rely on one, briefly '
      'tell the user to double-check critical steps. An excerpt may mention '
      'a [Table image] or [Figure] you cannot see: never guess its numbers; '
      'tell the user to tap that source to see it.';

  static const noSourceInstruction =
      'Nothing in the user\'s offline survival guides matched their latest '
      'message. If it asks for facts or instructions, say in a few words '
      'that this isn\'t from their offline guides, then answer briefly from '
      'general knowledge. Don\'t use bracketed numbers.';

  /// Picks which ranked [hits] to give the model. Passages are never cut
  /// short — a truncated passage could drop the one line that matters (a
  /// dosage, a warning) — so lower-ranked passages that don't fit the
  /// budget are left out instead. The best match is always included (pack
  /// sections are capped at 4,000 characters by the builder).
  static List<PassageHit> select(List<PassageHit> hits) {
    final chosen = <PassageHit>[];
    var used = 0;
    for (final h in hits) {
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
    final b = StringBuffer('Excerpts from my offline guides:');
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
