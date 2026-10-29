// Writes assets/packs/vectors/<pack>.vec for every bundled pack, using the
// same model and llama.cpp runtime the app uses for questions. Packs whose
// vectors already match their sections are skipped. Run after building
// packs:
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
      final name = f.uri.pathSegments.last.replaceFirst('.json', '.vec');
      wanted.add(name);
      final target = File('${out.path}/$name');
      final hashes = [
        for (final (_, s) in sections)
          PassageVectors.sectionHash(s.heading, s.body),
      ];
      if (target.existsSync()) {
        final old = PassageVectors.decode(target.readAsBytesSync());
        if (old != null &&
            old.length == hashes.length &&
            [for (final (h, _) in old) h].join(',') == hashes.join(',')) {
          continue;
        }
      }
      final entries = <(int, List<double>)>[];
      for (final (i, (d, s)) in sections.indexed) {
        var text = PassageVectors.passageText(d.title, s.heading, s.body);
        List<double>? v;
        while (v == null) {
          try {
            v = await engine.embed(text);
          } on llama.LlamaException catch (e) {
            // Number-heavy text can exceed 512 tokens: keep the start.
            if (!e.message.contains('tokens') || text.length < 200) rethrow;
            text = text.substring(
              0,
              text.lastIndexOf(' ', text.length * 2 ~/ 3),
            );
          }
        }
        entries.add((hashes[i], v));
      }
      target.writeAsBytesSync(PassageVectors.encode(entries));
      // ignore: avoid_print
      print('${pack.id}: ${entries.length} vectors');
    }
    // Vectors of packs no longer bundled.
    for (final f in out.listSync().whereType<File>()) {
      if (!wanted.contains(f.uri.pathSegments.last)) f.deleteSync();
    }
    await engine.dispose();
  }, timeout: const Timeout(Duration(minutes: 60)));
}
