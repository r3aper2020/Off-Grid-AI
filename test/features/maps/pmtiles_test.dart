import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/features/maps/domain/map_bounds.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles_header.dart';

/// Reads every tile id an archive addresses, through its leaves.
Set<int> addressedIds(Uint8List archive) {
  final h = PmtilesHeader.parse(archive)!;
  List<PmtilesEntry> dir(int offset, int length) => decodeDirectory(
    gunzipBytes(Uint8List.sublistView(archive, offset, offset + length)),
  );
  final ids = <int>{};
  void addRun(PmtilesEntry e) {
    for (var i = 0; i < e.runLength; i++) {
      ids.add(e.tileId + i);
    }
  }

  for (final e in dir(h.rootDirOffset, h.rootDirLength)) {
    if (e.isLeaf) {
      dir(h.leafDirsOffset + e.offset, e.length).forEach(addRun);
    } else {
      addRun(e);
    }
  }
  return ids;
}

void main() {
  test('tile ids follow the spec vectors', () {
    expect(zxyToTileId(0, 0, 0), 0);
    expect(zxyToTileId(1, 0, 0), 1);
    expect(zxyToTileId(1, 0, 1), 2);
    expect(zxyToTileId(1, 1, 1), 3);
    expect(zxyToTileId(1, 1, 0), 4);
    expect(zxyToTileId(2, 0, 0), 5);
    expect(zxyToTileId(3, 0, 0), 21);
    // Distinct within a zoom and in the zoom's id block.
    final z4 = {
      for (var x = 0; x < 16; x++)
        for (var y = 0; y < 16; y++) zxyToTileId(4, x, y),
    };
    expect(z4.length, 256);
    expect(z4.reduce(min), 85);
    expect(z4.reduce(max), 85 + 255);
  });

  test('tile ranges cover the bounds', () {
    const smokies = MapBounds(
      minLon: -83.95,
      minLat: 35.4,
      maxLon: -83.0,
      maxLat: 35.8,
    );
    expect(tileRange(smokies, 0), (minX: 0, minY: 0, maxX: 0, maxY: 0));
    final r = tileRange(smokies, 14);
    expect(r.minX, 4371);
    expect(r.maxX, 4414);
    expect(r.minY, 6444);
    expect(r.maxY, greaterThan(r.minY));
    expect(tileCount(smokies, 0, 14), 1451);
    expect(tileIdsIn(smokies, 0, 14).length, 1451);
    const world = MapBounds(minLon: -180, minLat: -90, maxLon: 180, maxLat: 90);
    expect(tileCount(world, 0, 5), 1365);
  });

  test('the CLI-made fixture addresses exactly the tiles of its bounds', () {
    final archive = File('test/fixtures/smokies_z10-12.pmtiles')
        .readAsBytesSync();
    final h = PmtilesHeader.parse(archive)!;
    expect((h.minZoom, h.maxZoom), (10, 12));
    expect(h.tileEntries, 21);
    expect(h.internalCompression, PmtilesHeader.compressionGzip);
    final bounds = MapBounds(
      minLon: h.minLon,
      minLat: h.minLat,
      maxLon: h.maxLon,
      maxLat: h.maxLat,
    );
    expect(addressedIds(archive), tileIdsIn(bounds, 10, 12).toSet());
    expect(PmtilesHeader.parse(h.toBytes())!.toBytes(), h.toBytes());
    expect(h.toBytes(), archive.sublist(0, PmtilesHeader.length));
  });

  test('directories round trip, including runs and leaf pointers', () {
    final entries = [
      const PmtilesEntry(tileId: 0, offset: 0, length: 10, runLength: 1),
      const PmtilesEntry(tileId: 1, offset: 10, length: 20, runLength: 4),
      const PmtilesEntry(tileId: 5, offset: 10, length: 20, runLength: 1),
      const PmtilesEntry(tileId: 9, offset: 300, length: 5, runLength: 0),
      const PmtilesEntry(
        tileId: 1 << 40,
        offset: 1 << 50,
        length: 1,
        runLength: 1,
      ),
    ];
    final back = decodeDirectory(encodeDirectory(entries));
    expect(back.map((e) => e.toString()), entries.map((e) => e.toString()));
    expect(findEntry(back, 3)!.tileId, 1);
    expect(findEntry(back, 4)!.tileId, 1);
    expect(findEntry(back, 5)!.tileId, 5);
    expect(findEntry(back, 6), isNull);
    expect(findEntry(back, 9)!.isLeaf, isTrue);
    expect(findEntry(back, 100)!.isLeaf, isTrue);
  });

  test('a big directory is split into leaves the root can reach', () {
    final rnd = Random(1);
    var offset = 0;
    final entries = <PmtilesEntry>[];
    var id = 0;
    for (var i = 0; i < 20000; i++) {
      id += 1 + rnd.nextInt(3);
      final length = 100 + rnd.nextInt(100000);
      entries.add(
        PmtilesEntry(tileId: id, offset: offset, length: length, runLength: 1),
      );
      offset += length;
    }
    final dirs = buildDirectories(entries, maxRootBytes: 2000);
    expect(dirs.root.length, lessThanOrEqualTo(2000));
    final root = decodeDirectory(gunzipBytes(dirs.root));
    expect(root.every((e) => e.isLeaf), isTrue);
    for (final want in [entries.first, entries[777], entries.last]) {
      final leafPtr = findEntry(root, want.tileId)!;
      final leaf = decodeDirectory(
        gunzipBytes(
          Uint8List.sublistView(
            dirs.leaves,
            leafPtr.offset,
            leafPtr.offset + leafPtr.length,
          ),
        ),
      );
      expect(findEntry(leaf, want.tileId)!.offset, want.offset);
    }
    final small = buildDirectories(entries.take(10).toList());
    expect(small.leaves, isEmpty);
  });
}
