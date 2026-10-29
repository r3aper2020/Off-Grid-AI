// Coverage report: runs every question in questions.tsv against the
// bundled library and writes what the model would be given.
//   flutter test tools/coverage/coverage_report_test.dart
// Output: tools/coverage/report.tsv (review by eye: a hit is not
// automatically a good answer).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/chat/domain/grounding.dart';
import 'package:offgrid_ai/features/library/domain/text_embedder.dart';
import 'package:offgrid_ai/features/library/data/knowledge_search.dart';
import 'package:offgrid_ai/features/library/data/llama_embedder.dart';
import 'package:offgrid_ai/features/library/data/pack_installer.dart';

import '../../test/support/test_db.dart';

void main() {
  test('coverage report', () async {
    final db = testDatabase();
    final installer = PackInstaller(db);
    for (final f in Directory('assets/packs').listSync().whereType<File>()) {
      if (f.path.endsWith('.json')) {
        final vec = File(
          f.path
              .replaceFirst('assets/packs/', 'assets/packs/vectors/')
              .replaceFirst(RegExp(r'\.json$'), '.vec'),
        );
        await installer.install(
          f.readAsStringSync(),
          source: 'coverage',
          vectors: vec.existsSync() ? vec.readAsBytesSync() : null,
        );
      }
    }
    // KEYWORDS_ONLY=1 measures the keyword search alone.
    final semantic = Platform.environment['KEYWORDS_ONLY'] != '1';
    final search = KnowledgeSearch(
      db,
      embedder: semantic
          ? LlamaTextEmbedder.fromFile(File(LlamaTextEmbedder.asset))
          : const NoTextEmbedder(),
    );
    final out = StringBuffer(
      'pack\ttopic\tquestion\thits\tsources\tbest_semantic\n',
    );
    var missing = 0;
    for (final line in File('tools/coverage/questions.tsv').readAsLinesSync()) {
      if (line.startsWith('#') || line.trim().isEmpty) continue;
      final [pack, topic, question] = line.split('\t');
      final hits = Grounding.select(await search.forQuestion(question));
      if (hits.isEmpty) missing++;
      final sources = hits
          .take(3)
          .map((h) => '${h.documentTitle} › ${h.heading}')
          .join(' | ');
      final best = await search.semanticMatches(question, limit: 1);
      final sem = best.isEmpty
          ? '-'
          : '${best.first.$2.toStringAsFixed(3)} ${best.first.$1.heading}';
      out.writeln('$pack\t$topic\t$question\t${hits.length}\t$sources\t$sem');
    }
    File('tools/coverage/report.tsv').writeAsStringSync(out.toString());
    await db.close();
    printOnFailure('$missing questions with no sources');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
