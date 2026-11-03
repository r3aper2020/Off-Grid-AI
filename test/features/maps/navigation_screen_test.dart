import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/app/app.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/core/providers.dart';
import 'package:offgrid_ai/features/maps/data/map_store.dart';
import 'package:offgrid_ai/features/maps/domain/location_source.dart';
import 'package:offgrid_ai/features/maps/domain/map_bounds.dart';
import 'package:offgrid_ai/features/maps/domain/map_style.dart';
import 'package:offgrid_ai/features/maps/map_providers.dart';
import 'package:offgrid_ai/features/maps/presentation/map_view.dart';
import 'package:offgrid_ai/features/models/model_providers.dart';

import '../../support/test_db.dart';

class FakeLocation implements LocationSource {
  FakeLocation(this.access);
  final LocationAccess access;
  final fixes_ = StreamController<Fix>.broadcast();
  @override
  Future<LocationAccess> request() async => access;
  @override
  Stream<Fix> fixes() => fixes_.stream;
}

class FakeMap implements MapHandle {
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
  Future<MapBounds> visibleBounds() async =>
      const MapBounds(minLon: 0, minLat: 0, maxLon: 1, maxLat: 1);
}

void main() {
  late AppDatabase db;
  late Directory maps;
  late FakeLocation location;
  late FakeMap map;
  MapViewSpec? shown;

  setUp(() async {
    db = testDatabase();
    maps = await Directory.systemTemp.createTemp('nav');
    location = FakeLocation(LocationAccess.granted);
    map = FakeMap();
    shown = null;
  });
  tearDown(() async {
    await location.fixes_.close();
    await db.close();
    await maps.delete(recursive: true);
  });

  Future<void> pumpNavigation(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          modelsDirectoryProvider.overrideWithValue(
            Directory('${Directory.systemTemp.path}/offgrid_test_models'),
          ),
          mapsDirectoryProvider.overrideWithValue(maps),
          // No file or asset I/O inside the widget test's fake-async zone:
          // the asset copy has its own test (map_assets_test.dart).
          mapAssetsProvider.overrideWith(
            (ref) async => Directory('${maps.path}/assets'),
          ),
          mapLayersProvider.overrideWith(
            (ref) async => const [
              {'id': 'background', 'type': 'background', 'paint': {}},
              {
                'id': 'water',
                'type': 'fill',
                'source': 'protomaps',
                'source-layer': 'water',
              },
            ],
          ),
          locationSourceProvider.overrideWithValue(location),
          mapViewBuilderProvider.overrideWithValue((spec) {
            if (shown == null) scheduleMicrotask(() => spec.onMapCreated(map));
            shown = spec;
            return const ColoredBox(color: Colors.black, key: Key('map'));
          }),
        ],
        child: const OffgridApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navigation'));
    await tester.pumpAndSettle();
  }

  testWidgets('without a region: world overview, a nudge, GPS readings', (
    tester,
  ) async {
    await pumpNavigation(tester);
    expect(find.text('Only the world overview is installed'), findsOneWidget);
    expect(find.byKey(const Key('map')), findsOneWidget);
    expect(
      shown!.style,
      contains('pmtiles://file://${maps.path}/assets/world.pmtiles'),
    );
    expect(shown!.zoom, 1);
    expect(find.text('Waiting for a GPS fix…'), findsOneWidget);

    location.fixes_.add(
      Fix(
        latitude: 35.6,
        longitude: -83.475,
        altitude: 610.4,
        accuracy: 7.6,
        heading: 92,
        speed: 0,
        time: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('35.60000° N, 83.47500° W'), findsOneWidget);
    expect(find.text('610 m'), findsOneWidget);
    expect(find.text('±8 m'), findsOneWidget);
    expect(find.text('92°'), findsOneWidget);
    // The first fix brings the map to the phone, once.
    expect(map.moves, [(35.6, -83.475, 11.0)]);
    location.fixes_.add(
      Fix(
        latitude: 35.7,
        longitude: -83.4,
        altitude: null,
        accuracy: null,
        heading: null,
        speed: null,
        time: DateTime(2026),
      ),
    );
    await tester.pumpAndSettle();
    expect(map.moves, hasLength(1));
  });

  testWidgets('with a region: the map is shown with the credit', (
    tester,
  ) async {
    await tester.runAsync(
      () => MapStore(db, maps).import(
        originalName: 'smokies.pmtiles',
        bytes: Stream.value(fakePmtiles()),
      ),
    );
    await pumpNavigation(tester);
    expect(find.byKey(const Key('map')), findsOneWidget);
    expect(find.text('Only the world overview is installed'), findsNothing);
    expect(find.text(mapAttribution), findsOneWidget);
    final spec = shown!;
    expect(
      spec.style,
      contains('pmtiles://file://${maps.path}/smokies.pmtiles'),
    );
    expect(spec.locationEnabled, isTrue);
    expect(spec.centerLat, closeTo(35.6, 1e-6));
    expect(spec.style, contains('file://${maps.path}/assets/sprites/dark'));
  });

  testWidgets('the layers sheet toggles a legend drawn from the style', (
    tester,
  ) async {
    await pumpNavigation(tester);
    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    expect(find.text('Map layers'), findsOneWidget);
    // Nothing but streets is installed, so topo stays off.
    final topo = tester.widget<SegmentedButton<MapLayerKind>>(
      find.byType(SegmentedButton<MapLayerKind>),
    );
    expect(topo.segments[1].enabled, isFalse);
    await tester.tap(find.text('Legend'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();
    expect(find.text('Streets legend'), findsOneWidget);
    expect(find.text('Path or trail'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide legend'));
    await tester.pumpAndSettle();
    expect(find.text('Streets legend'), findsNothing);
  });

  testWidgets('permission denied is said plainly', (tester) async {
    location = FakeLocation(LocationAccess.deniedForever);
    await pumpNavigation(tester);
    expect(
      find.text('Location permission denied — allow it in system settings'),
      findsOneWidget,
    );
  });
}
