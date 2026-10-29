import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Renders the light Markdown small models write — headings, numbered
/// and bulleted lists, **bold**, *italic*, `code` — and highlights
/// citation numbers like [1], so replies read like a message, not raw
/// syntax. Partial syntax while streaming is shown as plain text.
class MessageText extends StatelessWidget {
  const MessageText(this.text, {super.key});

  final String text;

  static final _numbered = RegExp(r'^(\d{1,2})[.)]\s+(.*)$');
  static final _bullet = RegExp(r'^[-*•]\s+(.*)$');
  static final _heading = RegExp(r'^#{1,4}\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final blocks = <Widget>[];
    var gap = false;

    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty) {
        gap = true;
        continue;
      }
      if (blocks.isNotEmpty) blocks.add(SizedBox(height: gap ? 8 : 3));
      gap = false;

      final indent = line.length - trimmed.length >= 2 ? 16.0 : 0.0;
      if (_heading.firstMatch(trimmed) case final m?) {
        blocks.add(
          Text.rich(_inline(m[1]!, base.copyWith(fontWeight: FontWeight.w700))),
        );
      } else if (_numbered.firstMatch(trimmed) case final m?) {
        blocks.add(_listItem('${m[1]}.', m[2]!, base, indent));
      } else if (_bullet.firstMatch(trimmed) case final m?) {
        blocks.add(_listItem('•', m[1]!, base, indent));
      } else {
        blocks.add(Text.rich(_inline(trimmed, base)));
      }
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks,
      ),
    );
  }

  Widget _listItem(String marker, String body, TextStyle base, double indent) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              marker,
              style: base.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text.rich(_inline(body, base))),
        ],
      ),
    );
  }

  static final _span = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])|`([^`]+)`|\[(\d{1,2})\]',
  );

  /// Inline styles. Exposed for tests.
  static TextSpan inlineSpan(String text, TextStyle base) =>
      _inline(text, base);

  static TextSpan _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _span.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m[1] != null || m[2] != null) {
        spans.add(
          TextSpan(
            text: m[1] ?? m[2],
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m[3] != null) {
        spans.add(
          TextSpan(
            text: m[3],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m[4] != null) {
        spans.add(
          TextSpan(
            text: m[4],
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '[${m[5]}]',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
