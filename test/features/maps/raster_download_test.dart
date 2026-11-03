import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_ai/core/database/app_database.dart';
import 'package:offgrid_ai/features/maps/data/map_store.dart';
import 'package:offgrid_ai/features/maps/data/raster_download.dart';
import 'package:offgrid_ai/features/maps/data/range_reader.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles.dart';
import 'package:offgrid_ai/features/maps/domain/pmtiles_header.dart';
import 'package:offgrid_ai/features/maps/domain/raster_sources.dart';

import '../../support/test_db.dart';
import 'pmtiles_test.dart' show addressedIds;

/// A 1x1 PNG; tiles get the path appended so most differ.
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late AppDatabase db;
  late Directory dir;
  late MapStore store;
  late HttpServer server;
  final requests = <String>[];
  var fail = 0; // how many requests to fail with 503 first

  setUp(() async {
    db = testDatabase();
    dir = await Directory.systemTemp.createTemp('raster');
    store = MapStore(db, dir);
    requests.clear();
    fail = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests.add(req.uri.path);
      if (fail > 0) {
        fail--;
        req.response.statusCode = HttpStatus.serviceUnavailable;
        await req.response.close();
        return;
      }
      // /tile/z/y/x like the USGS services. One tile is missing, two are
      // identical (blank sea).
      final parts = req.uri.pathSegments;
      final z = parts[1], y = parts[2], x = parts[3];
      if (z == '9' && y == '201' && x == '140') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final blank = z == '9' && (x == '141' || x == '142') && y == '201';
      req.response.headers.contentType = ContentType('image', 'png');
      req.response.add(png);
      if (!blank) req.response.add(utf8.encode(req.uri.path));
      await req.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await db.close();
    await dir.delete(recursive: true);
  });

  RasterTileSource source(MapLayerKind kind, {int maxZoom = 16}) =>
      RasterTileSource(
        kind: kind,
        label: 'Topo',
        template: 'http://127.0.0.1:${server.port}/tile/{z}/{y}/{x}',
        maxZoom: maxZoom,
        attribution: 'test',
        isElevation: kind == MapLayerKind.terrain,
      );

  Future<MapRegion> parent({int maxZoom = 10}) => store.import(
    originalName: 'smokies.pmtiles',
    bytes: Stream.value(
      fakePmtiles(
        minLon: -82.0,
        minLat: 35.0,
        maxLon: -80.0,
        maxLat: 36.5,
        maxZoom: maxZoom,
      ),
    ),
  );

  test('estimates from sample tiles without fetching them all', () async {
    final region = await parent();
    final dl = RasterLayerDownload(store, source(MapLayerKind.topo));
    final plan = await dl.estimate(region);
    expect(plan.minZoom, rasterMinZoom);
    expect(plan.maxZoom, 10);
    expect(plan.tileCount, tileCount(plan.bounds, 7, 10));
    expect(plan.tileCount, greaterThan(12));
    expect(requests.length, 12);
    expect(requests.every((r) => r.startsWith('/tile/10/')), isTrue);
    expect(plan.estimatedBytes, greaterThan(png.length * plan.tileCount));
    dl.close();
  });

  test('downloads every tile into a clustered raster archive', () async {
    final region = await parent();
    final dl = RasterLayerDownload(
      store,
      source(MapLayerKind.topo),
      retryDelay: (_) => Duration.zero,
    );
    final plan = await dl.estimate(region);
    requests.clear();
    fail = 2; // two transient failures, retried
    final progress = <(int, int)>[];
    final layer = await dl.run(
      plan,
      onProgress: (t, b) => progress.add((t, b)),
    );

    expect(layer.kind, MapLayerKind.topo);
    expect(layer.parentId, region.id);
    expect(layer.displayName, 'smokies · Topo');
    expect(layer.fileName, 'smokies-topo.pmtiles');
    expect((layer.minZoom, layer.maxZoom), (7, 10));
    expect(progress.last.$1, plan.tileCount);
    expect(requests.toSet().length, plan.tileCount);
    expect(
      dir.listSync().map((f) => f.path.split('/').last),
      unorderedEquals(['smokies.pmtiles', 'smokies-topo.pmtiles']),
    );

    final out = await store.fileFor(layer).readAsBytes();
    final h = PmtilesHeader.parse(out)!;
    expect(h.tileType, 2); // PNG
    expect(h.tileCompression, PmtilesHeader.compressionNone);
    expect(h.clustered, isTrue);
    expect(h.tileEntries, plan.tileCount - 1); // one 404
    expect(h.tileContents, plan.tileCount - 2); // two identical tiles
    expect(h.tileDataOffset + h.tileDataLength, out.length);
    final ids = addressedIds(out);
    expect(ids, isNot(contains(zxyToTileId(9, 140, 201))));
    expect(ids, contains(zxyToTileId(9, 141, 201)));
    final root = decodeDirectory(
      gunzipBytes(
        Uint8List.sublistView(
          out,
          h.rootDirOffset,
          h.rootDirOffset + h.rootDirLength,
        ),
      ),
    );
    final a = root.firstWhere((e) => e.tileId == zxyToTileId(9, 141, 201));
    final b = root.firstWhere((e) => e.tileId == zxyToTileId(9, 142, 201));
    expect(a.offset, b.offset);
    final tile = out.sublist(
      h.tileDataOffset + a.offset,
      h.tileDataOffset + a.offset + a.length,
    );
    expect(tile, png);
    final meta = utf8.decode(
      gunzipBytes(
        Uint8List.sublistView(
          out,
          h.metadataOffset,
          h.metadataOffset + h.metadataLength,
        ),
      ),
    );
    expect(meta, contains('"attribution":"test"'));

    // Deleting the region takes its layers with it.
    await store.delete(region);
    expect(await store.regions(), isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  test('elevation layers stop at the source zoom and say terrarium', () async {
    final region = await parent(maxZoom: 14);
    final dl = RasterLayerDownload(
      store,
      source(MapLayerKind.terrain, maxZoom: 8),
      sampleSize: 2,
    );
    final plan = await dl.estimate(region);
    expect(plan.maxZoom, 8);
    final layer = await dl.run(plan);
    expect(layer.kind, MapLayerKind.terrain);
    final out = await store.fileFor(layer).readAsBytes();
    final h = PmtilesHeader.parse(out)!;
    final meta = utf8.decode(
      gunzipBytes(
        Uint8List.sublistView(
          out,
          h.metadataOffset,
          h.metadataOffset + h.metadataLength,
        ),
      ),
    );
    expect(meta, contains('terrarium'));
  });

  test('cancel leaves nothing behind', () async {
    final region = await parent();
    final dl = RasterLayerDownload(store, source(MapLayerKind.imagery));
    final plan = await dl.estimate(region);
    dl.cancel();
    await expectLater(dl.run(plan), throwsA(isA<RegionDownloadCancelled>()));
    expect(dir.listSync().map((f) => f.path.split('/').last), [
      'smokies.pmtiles',
    ]);
    expect((await store.regions()).length, 1);
  });
}
