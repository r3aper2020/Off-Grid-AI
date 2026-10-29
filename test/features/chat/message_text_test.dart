import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/chat/presentation/message_text.dart';

void main() {
  testWidgets('renders lists and bold text without Markdown symbols', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageText(
            '**Stay calm.**\n\n1. Apply pressure [1].\n2. Raise the limb.\n- Keep warm',
          ),
        ),
      ),
    );
    final text = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('\n');
    expect(text, contains('Stay calm.'));
    expect(text, isNot(contains('**')));
    expect(text, contains('Apply pressure [1].'));
    expect(text, contains('1.'));
    expect(text, contains('•'));
  });

  test('citation numbers and bold get their own styles', () {
    final span = MessageText.inlineSpan(
      'Do **this** now [2].',
      const TextStyle(),
    );
    final parts = span.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text), ['Do ', 'this', ' now ', '[2]', '.']);
    expect(parts[1].style!.fontWeight, FontWeight.w700);
    expect(parts[3].style!.fontWeight, FontWeight.w700);
  });
}
