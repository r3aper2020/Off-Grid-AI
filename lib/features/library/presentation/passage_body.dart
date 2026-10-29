import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/pack_format.dart';

/// Section text with its figures and tables shown inline, in order.
/// Tables are images of the original page so their values stay exact;
/// tap any image to view it full screen and zoom.
class PassageBody extends StatelessWidget {
  const PassageBody({super.key, required this.body, required this.images});

  final String body;
  final List<SectionImage> images;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5);
    final children = <Widget>[];
    var last = 0;
    for (final m in SectionImage.placeholder.allMatches(body)) {
      final text = body.substring(last, m.start).trim();
      if (text.isNotEmpty) children.add(SelectableText(text, style: style));
      final n = int.parse(m.group(1)!);
      if (n < images.length) children.add(_InlineImage(image: images[n]));
      last = m.end;
    }
    final rest = body.substring(last).trim();
    if (rest.isNotEmpty) children.add(SelectableText(rest, style: style));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, w) in children.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          w,
        ],
      ],
    );
  }

  /// Body text without image placeholders (for snippets and previews).
  static String plainText(String body) =>
      body.replaceAll(SectionImage.placeholder, '').trim();
}

class _InlineImage extends StatelessWidget {
  const _InlineImage({required this.image});

  final SectionImage image;

  void _open(BuildContext context) => openImageViewer(context, image);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: image.caption,
      button: true,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Source pages are black on white; keep them that way for
              // legibility rather than inverting in dark mode.
              child: ColoredBox(
                color: Colors.white,
                child: Image.asset(
                  image.asset,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  image.isTable
                      ? Icons.table_chart_outlined
                      : Icons.image_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${image.caption} · tap to zoom',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of a figure or table.
void openImageViewer(BuildContext context, SectionImage image) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _ImageViewer(image: image),
    ),
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.image});

  final SectionImage image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          image.caption,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: ColoredBox(
            color: Colors.white,
            child: Image.asset(image.asset),
          ),
        ),
      ),
    );
  }
}
