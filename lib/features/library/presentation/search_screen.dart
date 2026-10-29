import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../library_providers.dart';
import 'passage_body.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? null
        : ref.watch(librarySearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search the offline library',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
      ),
      body: switch (results) {
        null => const SizedBox.shrink(),
        AsyncValue(:final value?) when value.isEmpty => const Center(
          child: Text(
            'No matches in the installed references',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        AsyncValue(:final value?) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(indent: 16),
          itemBuilder: (context, i) {
            final hit = value[i];
            return ListTile(
              title: Text(hit.heading),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.documentTitle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    highlightSnippet(PassageBody.plainText(hit.snippet)),
                  ),
                ],
              ),
              onTap: () => context.push(
                '/doc/${hit.documentId}?passage=${hit.passageId}',
              ),
            );
          },
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

/// Renders FTS snippet text, bolding the `[match]` spans.
TextSpan highlightSnippet(String snippet) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\[([^\]]*)\]');
  var last = 0;
  for (final m in pattern.allMatches(snippet)) {
    spans.add(TextSpan(text: snippet.substring(last, m.start)));
    spans.add(
      TextSpan(
        text: m.group(1),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    last = m.end;
  }
  spans.add(TextSpan(text: snippet.substring(last)));
  return TextSpan(
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    children: spans,
  );
}
