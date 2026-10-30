import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Composer used on the chat home and inside conversations. While
/// [generating] is true the send button becomes a stop button. With
/// [onAttach] set, a camera button lets the user attach one photo; the
/// stored file name is passed to [onSend] with the text.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onStop,
    this.onAttach,
    this.photosDirectory,
    this.generating = false,
    this.autofocus = false,
  });

  final void Function(String text, String? imagePath) onSend;
  final VoidCallback? onStop;

  /// Picks a photo and returns its stored file name, or null.
  final Future<String?> Function()? onAttach;

  /// Where attached photos live, for the preview thumbnail.
  final Directory? photosDirectory;
  final bool generating;
  final bool autofocus;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  String? _imagePath;

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

  bool get _canSend =>
      (_controller.text.trim().isNotEmpty || _imagePath != null) &&
      !widget.generating;

  void _submit() {
    if (!_canSend) return;
    final text = _controller.text.trim();
    final image = _imagePath;
    _controller.clear();
    setState(() => _imagePath = null);
    widget.onSend(text, image);
  }

  Future<void> _attach() async {
    final picked = await widget.onAttach?.call();
    if (picked != null && mounted) setState(() => _imagePath = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dir = widget.photosDirectory;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagePath != null && dir != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File('${dir.path}/$_imagePath'),
                    height: 88,
                    width: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 88,
                      width: 88,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton.filled(
                    tooltip: 'Remove photo',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceRaised,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          minLines: 1,
          maxLines: 5,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: _imagePath == null
                ? 'Ask anything…'
                : 'Ask about the photo (optional)…',
            prefixIcon: widget.onAttach == null
                ? null
                : IconButton(
                    tooltip: 'Add a photo',
                    onPressed: widget.generating ? null : _attach,
                    icon: Icon(
                      Icons.photo_camera_outlined,
                      color: _imagePath == null
                          ? AppColors.textSecondary
                          : AppColors.accent,
                    ),
                  ),
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
                      onPressed: _canSend ? _submit : null,
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
        ),
      ],
    );
  }
}
