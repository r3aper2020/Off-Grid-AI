// Writes assets/packs/vectors/<pack>.vec (sections) and <pack>.docs.vec
// (documents: title + aliases) for every bundled pack, using the same
// model and llama.cpp runtime the app uses for questions. Files whose
// vectors already match their text are skipped. Run after building packs:
//   flutter test tools/embed/embed_packs_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart' as llama;
import 'package:offgrid_ai/features/library/data/llama_embedder.dart';
import 'package:offgrid_ai/features/library/domain/pack_format.dart';
import 'package:offgrid_ai/features/library/domain/passage_vectors.dart';

void main() {
  test('embed bundled packs', () async {
    final engine = await llama.LlamaEngine.load(
      llama.LlamaModel(llama.ModelSource.path(LlamaTextEmbedder.asset)),
      params: LlamaTextEmbedder.params,
    );
    final out = Directory('assets/packs/vectors')..createSync(recursive: true);
    final packs =
        Directory('assets/packs')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final wanted = <String>{};
    for (final f in packs) {
      final pack = PackData.fromJson(jsonDecode(f.readAsStringSync()));
      final sections = [
        for (final d in pack.documents)
          for (final s in d.sections) (d, s),
      ];
      final stem = f.uri.pathSegments.last.replaceFirst('.json', '');
      wanted.addAll(['$stem.vec', '$stem.docs.vec']);

      Future<List<double>> embed(String input) async {
        var text = input;
        while (true) {
          try {
            return await engine.embed(text);
          } on llama.LlamaException catch (e) {
            // Number-heavy text can exceed 512 tokens: keep the start.
            if (!e.message.contains('tokens') || text.length < 200) rethrow;
            text = text.substring(
              0,
              text.lastIndexOf(' ', text.length * 2 ~/ 3),
            );
          }
        }
      }

      Future<void> write(
        String name,
        List<int> hashes,
        List<String> texts,
      ) async {
        final target = File('${out.path}/$name');
        if (target.existsSync()) {
          final old = PassageVectors.decode(target.readAsBytesSync());
          if (old != null &&
              old.length == hashes.length &&
              [for (final (h, _) in old) h].join(',') == hashes.join(',')) {
            return;
          }
        }
        final entries = <(int, List<double>)>[];
        for (final (i, text) in texts.indexed) {
          entries.add((hashes[i], await embed(text)));
        }
        target.writeAsBytesSync(PassageVectors.encode(entries));
        // ignore: avoid_print
        print('$name: ${entries.length} vectors');
      }

      await write(
        '$stem.vec',
        [
          for (final (_, s) in sections)
            PassageVectors.sectionHash(s.heading, s.body),
        ],
        [
          for (final (d, s) in sections)
            PassageVectors.passageText(d.title, s.heading, s.body),
        ],
      );
      await write(
        '$stem.docs.vec',
        [
          for (final d in pack.documents)
            PassageVectors.docHash(d.title, d.aliases),
        ],
        [
          for (final d in pack.documents)
            PassageVectors.docText(d.title, d.aliases),
        ],
      );
    }
    // Vectors of packs no longer bundled.
    for (final f in out.listSync().whereType<File>()) {
      if (!wanted.contains(f.uri.pathSegments.last)) f.deleteSync();
    }
    await engine.dispose();
  }, timeout: const Timeout(Duration(minutes: 60)));
}
