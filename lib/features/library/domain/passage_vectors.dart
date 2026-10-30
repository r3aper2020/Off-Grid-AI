import 'dart:convert';
import 'dart:typed_data';

import 'pack_format.dart';

/// Meaning vectors for a pack's sections and documents, so questions can
/// find passages that use different words ("emergency kit" ↔ "disaster
/// supplies").
///
/// Two `.vec` files per pack (`assets/packs/vectors/<pack>.vec` for
/// sections, `<pack>.docs.vec` for documents), written by
/// `tools/embed/embed_packs_test.dart` with the bundled embedding model.
/// Layout (little-endian): magic `OGV1`, dim (u16), reserved (u16), count
/// (u32), then per entry in pack order: a hash of its text (u32) and the
/// L2-normalized vector as int8 (value × 127). The hash lets the installer
/// skip stale vectors instead of attaching them to the wrong section.
abstract final class PassageVectors {
  /// bge-base-en-v1.5 output size.
  static const dim = 768;
  static const _magic = 0x3156474F; // "OGV1" as a little-endian u32

  /// Instruction prefix the embedding model (bge-base-en-v1.5) expects on
  /// search queries, not on passages.
  static const queryPrefix =
      'Represent this sentence for searching relevant passages: ';

  /// What is embedded for a section: its context and the start of its
  /// text (the model reads at most 512 tokens).
  static String passageText(String documentTitle, String heading, String body) {
    final clean = body
        .replaceAll(SectionImage.placeholder, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final text = '$documentTitle. $heading\n$clean';
    if (text.length <= maxChars) return text;
    final cut = text.lastIndexOf(' ', maxChars);
    return text.substring(0, cut > 0 ? cut : maxChars);
  }

  /// ~300 tokens: safely inside the model's 512-token window.
  static const maxChars = 1200;

  /// What is embedded for a document as a whole: its title and the
  /// plain-language aliases that say what it answers.
  static String docText(String title, String aliases) =>
      aliases.isEmpty ? title : '$title. $aliases';

  /// FNV-1a over the section text.
  static int sectionHash(String heading, String body) =>
      hashOf('$heading\n$body');

  static int docHash(String title, String aliases) =>
      hashOf(docText(title, aliases));

  static int hashOf(String text) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(text)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  static Uint8List encode(List<(int hash, List<double> vector)> entries) {
    final out = ByteData(12 + entries.length * (4 + dim));
    out
      ..setUint32(0, _magic, Endian.little)
      ..setUint16(4, dim, Endian.little)
      ..setUint16(6, 0, Endian.little)
      ..setUint32(8, entries.length, Endian.little);
    var o = 12;
    for (final (hash, v) in entries) {
      if (v.length != dim) throw ArgumentError('vector has ${v.length} dims');
      out.setUint32(o, hash, Endian.little);
      o += 4;
      for (final x in v) {
        out.setInt8(o++, (x * 127).round().clamp(-127, 127));
      }
    }
    return out.buffer.asUint8List();
  }

  /// Entries in section order, or null if [bytes] isn't a vector file
  /// this version understands.
  static List<(int hash, Int8List vector)>? decode(Uint8List bytes) {
    if (bytes.length < 12) return null;
    final d = ByteData.sublistView(bytes);
    if (d.getUint32(0, Endian.little) != _magic) return null;
    if (d.getUint16(4, Endian.little) != dim) return null;
    final count = d.getUint32(8, Endian.little);
    if (bytes.length != 12 + count * (4 + dim)) return null;
    return [
      for (var i = 0, o = 12; i < count; i++, o += 4 + dim)
        (
          d.getUint32(o, Endian.little),
          Int8List.sublistView(bytes, o + 4, o + 4 + dim),
        ),
    ];
  }

  /// Cosine similarity of two stored vectors (both normalized).
  static double similarity(Int8List a, Int8List b) {
    var s = 0;
    for (var i = 0; i < dim; i++) {
      s += a[i] * b[i];
    }
    return s / (127 * 127);
  }

  /// A query vector in the stored form.
  static Int8List quantize(List<double> v) => Int8List.fromList([
    for (final x in v) (x * 127).round().clamp(-127, 127),
  ]);
}
