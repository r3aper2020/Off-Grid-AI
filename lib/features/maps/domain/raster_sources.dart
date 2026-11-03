import '../../../core/database/app_database.dart';

/// A public tile service a raster layer is downloaded from, tile by tile.
class RasterTileSource {
  const RasterTileSource({
    required this.kind,
    required this.label,
    required this.template,
    required this.maxZoom,
    required this.attribution,
    required this.isElevation,
  });

  final MapLayerKind kind;
  final String label;

  /// URL with `{z}`, `{x}` and `{y}` placeholders.
  final String template;

  /// Deepest zoom worth fetching (the service's own limit, or less when
  /// the renderer overzooms well, as with elevation).
  final int maxZoom;
  final String attribution;

  /// Terrarium-encoded elevation, drawn as hillshade rather than an image.
  final bool isElevation;

  Uri tileUrl(int z, int x, int y) => Uri.parse(
    template
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y'),
  );
}

/// Public domain or openly licensed sources only; see docs/decisions.md.
const rasterSources = <MapLayerKind, RasterTileSource>{
  MapLayerKind.topo: RasterTileSource(
    kind: MapLayerKind.topo,
    label: 'Topo',
    template:
        'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/'
        'MapServer/tile/{z}/{y}/{x}',
    maxZoom: 16,
    attribution: 'USGS The National Map',
    isElevation: false,
  ),
  MapLayerKind.imagery: RasterTileSource(
    kind: MapLayerKind.imagery,
    label: 'Satellite',
    template:
        'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/'
        'MapServer/tile/{z}/{y}/{x}',
    maxZoom: 16,
    attribution: 'USGS The National Map, USDA',
    isElevation: false,
  ),
  MapLayerKind.terrain: RasterTileSource(
    kind: MapLayerKind.terrain,
    label: 'Hillshade',
    template: 'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png',
    // Hillshade reads fine overzoomed; zoom 12 is 1/16 the tiles of 14.
    maxZoom: 12,
    attribution: 'Terrain Tiles (Mapzen) · NASA SRTM · USGS 3DEP',
    isElevation: true,
  ),
};

/// Shallowest zoom a raster layer covers; the world overview and the
/// streets region cover the map when zoomed out further.
const rasterMinZoom = 7;

/// Credits for everything that can be on the map.
String get allMapCredits =>
    rasterSources.values.map((s) => s.attribution).toSet().join(' · ');
