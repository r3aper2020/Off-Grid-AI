import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/data/map_store.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late MapStore store;

  setUp(() async {
    db = testDatabase();
    dir = await Directory.systemTemp.createTemp('maps');
    store = MapStore(db, dir);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('imports a region with the bounds from its header', () async {
    final region = await store.import(
      originalName: 'great_smoky-mountains.pmtiles',
      bytes: Stream.value(fakePmtiles(maxZoom: 13)),
    );
    expect(region.displayName, 'great smoky mountains');
    expect(region.fileName, 'great_smoky-mountains.pmtiles');
    expect(region.maxZoom, 13);
    expect(region.minLon, closeTo(-83.95, 1e-6));
    expect(region.maxLat, closeTo(35.8, 1e-6));
    expect(store.fileFor(region).existsSync(), isTrue);
    expect(store.fileFor(region).lengthSync(), region.sizeBytes);
    expect(await store.regions(), hasLength(1));
  });

  test('a second file with the same name gets a new file name', () async {
    for (var i = 0; i < 2; i++) {
      await store.import(
        originalName: 'x.pmtiles',
        bytes: Stream.value(fakePmtiles()),
      );
    }
    final names = (await store.regions()).map((r) => r.fileName).toList();
    expect(names, unorderedEquals(['x.pmtiles', 'x-2.pmtiles']));
  });

  test(
    'rejects the wrong extension, a non-PMTiles file and raster tiles',
    () async {
      expect(
        () => store.import(originalName: 'x.gguf', bytes: Stream.value([1])),
        throwsA(isA<MapImportException>()),
      );
      expect(
        () => store.import(
          originalName: 'x.pmtiles',
          bytes: Stream.value(List.filled(200, 0)),
        ),
        throwsA(isA<MapImportException>()),
      );
      expect(
        () => store.import(
          originalName: 'png.pmtiles',
          bytes: Stream.value(fakePmtiles(tileType: 2)),
        ),
        throwsA(isA<MapImportException>()),
      );
      await pumpEventQueue();
      expect(dir.listSync(), isEmpty);
      expect(await store.regions(), isEmpty);
    },
  );

  test('delete removes the row and the file', () async {
    final region = await store.import(
      originalName: 'x.pmtiles',
      bytes: Stream.value(fakePmtiles()),
    );
    await store.delete(region);
    expect(await store.regions(), isEmpty);
    expect(store.fileFor(region).existsSync(), isFalse);
  });
}
