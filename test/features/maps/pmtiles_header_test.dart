import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/maps/data/map_store.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles_header.dart';

void main() {
  test('parses bounds, zooms and tile type from a v3 header', () {
    final h = PmtilesHeader.parse(fakePmtiles(maxZoom: 12))!;
    expect(h.isVector, isTrue);
    expect(h.minZoom, 0);
    expect(h.maxZoom, 12);
    expect(h.minLon, closeTo(-83.95, 1e-6));
    expect(h.minLat, closeTo(35.4, 1e-6));
    expect(h.maxLon, closeTo(-83.0, 1e-6));
    expect(h.maxLat, closeTo(35.8, 1e-6));
    expect(h.centerLon, closeTo(-83.475, 1e-6));
    expect(h.centerLat, closeTo(35.6, 1e-6));
  });

  test('rejects other files', () {
    expect(PmtilesHeader.parse(Uint8List(10)), isNull);
    final gguf = Uint8List(PmtilesHeader.length)
      ..setRange(0, 4, 'GGUF'.codeUnits);
    expect(PmtilesHeader.parse(gguf), isNull);
    final v2 = fakePmtiles()..[7] = 2;
    expect(PmtilesHeader.parse(v2), isNull);
  });
}
