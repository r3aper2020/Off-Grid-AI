import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/inference_engine.dart';

/// Animated "working" state for a reply that has no text yet, with a line
/// saying what is happening — so a slow first reply (model loading) never
/// looks frozen.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key, required this.phase});

  /// Null when the reply is streaming but the phase is unknown (e.g. a
  /// reply interrupted by an app restart).
  final GenerationPhase? phase;

  static String label(GenerationPhase? phase) => switch (phase) {
    GenerationPhase.searching => 'Searching the offline library…',
    GenerationPhase.loadingModel =>
      'Loading the AI model… the first reply takes a little longer',
    GenerationPhase.thinking || GenerationPhase.writing => 'Thinking…',
    null => 'Working…',
  };

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = ThinkingIndicator.label(widget.phase);
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < 3; i++) _dot(i)],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Each dot rises and brightens in turn.
  Widget _dot(int i) {
    final t = (_controller.value - i * 0.18) % 1.0;
    final wave = t < 0.5 ? (t * 2) : (2 - t * 2); // 0→1→0
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.translate(
        offset: Offset(0, -3 * wave),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(AppColors.textTertiary, AppColors.accent, wave),
          ),
        ),
      ),
    );
  }
}
