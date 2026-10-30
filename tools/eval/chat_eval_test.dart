// Graded end-to-end eval: runs tools/eval/scenarios.tsv through the real
// app pipeline (GenerationController → library search → grounding →
// llama.cpp chat model) and scores each reply against the key points an
// experienced instructor would cover. Writes tools/eval/results/<label>.md.
//
//   CHAT_MODEL=/path/to/model.gguf EVAL_LABEL=after \
//     flutter test tools/eval/chat_eval_test.dart
//   ONLY=lost-dark-cold,choking  limits the run.
//
// Scores are keyword checks (did the reply mention direct pressure, did it
// say to call 911), so they measure coverage of essentials, not prose
// quality — read the replies in the report too.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/chat/chat_providers.dart';
import 'package:offgrid_ai/features/chat/data/llama_engine.dart';
import 'package:offgrid_ai/features/library/data/library_repository.dart';
import 'package:offgrid_ai/features/library/data/llama_embedder.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

import '../../test/support/test_db.dart';

class Scenario {
  Scenario(this.id, this.turns, this.must, this.avoid);
  final String id;
  final List<String> turns;
  final List<List<String>> must;
  final List<String> avoid;
}

List<Scenario> loadScenarios() {
  final out = <Scenario>[];
  for (final line in File('tools/eval/scenarios.tsv').readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final cols = line.split('\t');
    final must = cols.length > 2 && cols[2].trim().isNotEmpty
        ? [
            for (final g in cols[2].split(';'))
              [for (final a in g.split('|')) a.trim().toLowerCase()],
          ]
        : <List<String>>[];
    final avoid = cols.length > 3 && cols[3].trim().isNotEmpty
        ? [for (final a in cols[3].split('|')) a.trim().toLowerCase()]
        : <String>[];
    out.add(Scenario(cols[0], cols[1].split(' || '), must, avoid));
  }
  return out;
}

final disclaimer = RegExp(
  r"(guides?|library|references?|sources?)[^.\n]{0,24}"
  r"(don['’]t|doesn['’]t|do not|does not|didn['’]t|did not) "
  r'(cover|mention|include|address|say|specify|provide)'
  r"|(not|isn['’]t|aren['’]t|wasn['’]t|weren['’]t) (covered|from|in|found in|"
  r'checked against|based on) (your|the|their|my) (offline )?'
  r'(guides?|library|references?)',
  caseSensitive: false,
);

void main() {
  test('chat eval', () async {
    final modelPath = Platform.environment['CHAT_MODEL'];
    if (modelPath == null) {
      fail('Set CHAT_MODEL=/path/to/model.gguf');
    }
    final label = Platform.environment['EVAL_LABEL'] ?? 'run';
    final only = Platform.environment['ONLY']?.split(',');

    final db = testDatabase();
    final installer = PackInstaller(db);
    for (final f in Directory('assets/packs').listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final vec = File(
        f.path
            .replaceFirst('assets/packs/', 'assets/packs/vectors/')
            .replaceFirst(RegExp(r'\.json$'), '.vec'),
      );
      final docVec = File(vec.path.replaceFirst('.vec', '.docs.vec'));
      await installer.install(
        f.readAsStringSync(),
        source: 'eval',
        vectors: vec.existsSync() ? vec.readAsBytesSync() : null,
        docVectors: docVec.existsSync() ? docVec.readAsBytesSync() : null,
      );
    }
    final embedder = LlamaTextEmbedder.fromFile(File(LlamaTextEmbedder.asset));
    final engine = LlamaInferenceEngine(
      modelFile: File(modelPath),
      modelName: 'eval',
    );
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        textEmbedderProvider.overrideWithValue(embedder),
        inferenceEngineProvider.overrideWithValue(engine),
      ],
    );
    c.listen(generationControllerProvider, (_, _) {});
    final repo = c.read(chatRepositoryProvider);
    final search = c.read(knowledgeSearchProvider);
    final controller = c.read(generationControllerProvider.notifier);

    final report = StringBuffer('# Chat eval: $label\n\n');
    final rows = <String>[];
    final details = StringBuffer();
    var totalScore = 0.0, scored = 0, totalChars = 0, totalMs = 0;
    var disclaimers = 0, cited = 0, turns = 0;

    for (final s in loadScenarios()) {
      if (only != null && !only.contains(s.id)) continue;
      int? convo;
      String reply = '';
      String sources = '';
      var ms = 0;
      for (final turn in s.turns) {
        if (convo == null) {
          convo = await repo.startConversation(turn);
        } else {
          await repo.addUserMessage(convo, turn);
        }
        final sw = Stopwatch()..start();
        await controller.reply(convo);
        while (c.read(generationControllerProvider).containsKey(convo)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        ms = sw.elapsedMilliseconds;
        final last = (await repo.messages(convo)).last;
        reply = last.content;
        final ids = last.citations == null
            ? const <int>[]
            : [
                for (final v
                    in last.citations!
                        .replaceAll(RegExp(r'[\[\]\s]'), '')
                        .split(','))
                  if (v.isNotEmpty) int.parse(v),
              ];
        final hits = await search.byIds(ids);
        sources = hits
            .map((h) => h == null ? '?' : '${h.documentTitle} › ${h.heading}')
            .join(' | ');
        turns++;
        totalMs += ms;
        totalChars += reply.length;
        if (disclaimer.hasMatch(reply)) disclaimers++;
        if (RegExp(r'\[\d\]').hasMatch(reply)) cited++;
        print('\n### ${s.id} — USER: $turn');
        print('sources: $sources');
        print('${ms}ms, ${reply.length} chars');
        print('--- REPLY:\n$reply');
      }
      final lower = reply.toLowerCase();
      final hit = [for (final g in s.must) g.any(lower.contains)];
      final avoided = [for (final a in s.avoid) lower.contains(a)];
      final score = s.must.isEmpty
          ? 1.0
          : hit.where((h) => h).length / s.must.length;
      totalScore += score;
      scored++;
      final missing = [
        for (final (i, g) in s.must.indexed)
          if (!hit[i]) g.first,
      ];
      rows.add(
        '| ${s.id} | ${(score * 100).round()}% | ${reply.length} | '
        '${(ms / 1000).toStringAsFixed(0)}s | '
        '${missing.isEmpty ? '' : missing.join(', ')}'
        '${avoided.any((a) => a) ? ' ⚠ avoid' : ''} |',
      );
      details.writeln('## ${s.id}\n');
      for (final t in s.turns) {
        details.writeln('**User:** $t\n');
      }
      details.writeln('**Sources:** ${sources.isEmpty ? 'none' : sources}\n');
      details.writeln(
        '**Score:** ${(score * 100).round()}%'
        '${missing.isEmpty ? '' : ' — missing: ${missing.join(', ')}'}\n',
      );
      details.writeln(reply.split('\n').map((l) => '> $l').join('\n'));
      details.writeln();
    }

    report.writeln('| metric | value |\n|---|---|');
    report.writeln(
      '| mean key-point score | ${(100 * totalScore / scored).round()}% |',
    );
    report.writeln('| scenarios | $scored |');
    report.writeln('| mean reply length | ${totalChars ~/ turns} chars |');
    report.writeln('| mean time per turn | ${totalMs ~/ turns ~/ 1000}s |');
    report.writeln('| replies with [n] citations | $cited / $turns |');
    report.writeln(
      '| replies with a "not in your guides" line | '
      '$disclaimers / $turns |',
    );
    report.writeln('\n| scenario | score | chars | time | missing |');
    report.writeln('|---|---|---|---|---|');
    rows.forEach(report.writeln);
    report.writeln('\n$details');
    final out = File('tools/eval/results/$label.md')
      ..createSync(recursive: true)
      ..writeAsStringSync(report.toString());
    print('\nwrote ${out.path}');
    await embedder.dispose();
    await engine.dispose();
    c.dispose();
    await db.close();
  }, timeout: const Timeout(Duration(hours: 8)));
}
