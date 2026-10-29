import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Composer used on the chat home and inside conversations. While
/// [generating] is true the send button becomes a stop button.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onStop,
    this.generating = false,
    this.autofocus = false,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final bool generating;
  final bool autofocus;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.generating) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.generating;
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      minLines: 1,
      maxLines: 5,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Ask anything…',
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: widget.generating
              ? IconButton.filled(
                  tooltip: 'Stop',
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceRaised,
                    foregroundColor: AppColors.textPrimary,
                  ),
                )
              : IconButton.filled(
                  tooltip: 'Send',
                  onPressed: canSend ? _submit : null,
                  icon: const Icon(Icons.near_me_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    disabledBackgroundColor: AppColors.accentMuted,
                    disabledForegroundColor: AppColors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}
