import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/app.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/maps/domain/location_source.dart';
import 'package:offgrid_ai/features/maps/domain/map_bounds.dart';
import 'package:offgrid_ai/features/maps/map_providers.dart';
import 'package:offgrid_ai/features/maps/presentation/map_download_screen.dart'
    show suggestedName;
import 'package:offgrid_ai/features/maps/presentation/map_view.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/memory_range_reader.dart';
import '../../support/test_db.dart';

class FakeMap implements MapHandle {
  FakeMap(this.bounds);
  MapBounds bounds;
  final moves = <(double, double, double)>[];
  @override
  Future<void> zoomIn() async {}
  @override
  Future<void> zoomOut() async {}
  @override
  Future<void> moveTo(double lat, double lon, double zoom) async =>
      moves.add((lat, lon, zoom));
  @override
  Future<void> setFollowHeading(bool on) async {}
  @override
  Future<(double, double)?> myLocation() async => null;
  @override
  Future<MapBounds> visibleBounds() async => bounds;
}

class FakeLocation implements LocationSource {
  @override
  Future<LocationAccess> request() async => LocationAccess.granted;
  @override
  Stream<Fix> fixes() => const Stream.empty();
}

void main() {
  final planet = File('test/fixtures/smokies_z10-12.pmtiles').readAsBytesSync();
  const part = MapBounds(
    minLon: -83.55,
    minLat: 35.55,
    maxLon: -83.45,
    maxLat: 35.65,
  );

  late AppDatabase db;
  late Directory maps;
  late FakeMap map;
  MapViewSpec? shown;

  setUp(() async {
    db = testDatabase();
    maps = await Directory.systemTemp.createTemp('mapdl');
    map = FakeMap(part);
    shown = null;
  });
  tearDown(() async {
    await db.close();
    await maps.delete(recursive: true);
  });

  Future<void> pumpDownload(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var created = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          modelsDirectoryProvider.overrideWithValue(
            Directory('${Directory.systemTemp.path}/offgrid_test_models'),
          ),
          mapsDirectoryProvider.overrideWithValue(maps),
          mapAssetsProvider.overrideWith(
            (ref) async => Directory('${maps.path}/assets'),
          ),
          mapLayersProvider.overrideWith(
            (ref) async => const [
              {'id': 'background', 'type': 'background', 'paint': {}},
            ],
          ),
          locationSourceProvider.overrideWithValue(FakeLocation()),
          planetOpenerProvider.overrideWithValue(
            () async => MemoryRangeReader(planet),
          ),
          mapViewBuilderProvider.overrideWithValue((spec) {
            shown = spec;
            if (!created) {
              created = true;
              scheduleMicrotask(() => spec.onMapCreated(map));
            }
            return const ColoredBox(color: Colors.black, key: Key('map'));
          }),
        ],
        child: const OffgridApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map regions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download a region'));
    await tester.pumpAndSettle();
  }

  // Whole tests run in runAsync: the download writes a real file and the
  // database must not be opened in the fake-async zone first.
  testWidgets(
    'checks the exact size, then downloads and lists the region',
    (tester) => tester.runAsync(() async {
      await pumpDownload(tester);
      expect(find.text('Download a map'), findsOneWidget);
      expect(find.byKey(const Key('map')), findsOneWidget);

      await tester.tap(find.text('Check size'));
      await tester.pumpAndSettle();
      // 21 tiles of the fixture at zoom 10–12 lie in the box... minus the
      // ones outside it: the planner found 16.
      expect(find.textContaining('tiles · zoom 10–12'), findsOneWidget);
      expect(find.textContaining('61.2 KB'), findsNWidgets(2));
      expect(find.text('Map 35.6°N 83.5°W'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Little Smokies');
      await tester.pump();
      await tester.tap(find.text('Download 61.2 KB'));
      // Real file I/O: give it real time, pumping so the screen can pop.
      // (find.text also matches the name field, so wait for the screen.)
      for (
        var i = 0;
        i < 400 && find.text('Offline maps').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      // Back on the regions screen with the new region installed.
      expect(find.text('Offline maps'), findsOneWidget);
      expect(find.text('Little Smokies'), findsOneWidget);
      expect(find.textContaining('zoom 10–12'), findsOneWidget);
      expect(File('${maps.path}/little-smokies.pmtiles').existsSync(), isTrue);
    }),
  );

  testWidgets(
    'a huge area is refused before anything is fetched',
    (tester) => tester.runAsync(() async {
      map.bounds = const MapBounds(
        minLon: -180,
        minLat: -85,
        maxLon: 180,
        maxLat: 85,
      );
      await pumpDownload(tester);
      await tester.tap(find.text('Check size'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Zoom in or choose less detail.'),
        findsOneWidget,
      );
      expect(find.text('Check size'), findsOneWidget);
    }),
  );

  testWidgets(
    'moving the map drops the size until it is checked again',
    (tester) => tester.runAsync(() async {
      await pumpDownload(tester);
      await tester.tap(find.text('Check size'));
      await tester.pumpAndSettle();
      expect(find.text('Download 61.2 KB'), findsOneWidget);
      shown!.onCameraIdle!();
      await tester.pumpAndSettle();
      expect(find.text('Download 61.2 KB'), findsNothing);
      expect(find.text('Check size'), findsOneWidget);
    }),
  );

  test('suggested names read like coordinates', () {
    expect(suggestedName(part), 'Map 35.6°N 83.5°W');
    expect(
      suggestedName(
        const MapBounds(minLon: 10, minLat: -40, maxLon: 12, maxLat: -38),
      ),
      'Map 39.0°S 11.0°E',
    );
  });
}
