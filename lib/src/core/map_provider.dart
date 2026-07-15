import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

const _pmtilesUrl = 'https://maps.trembledating.com/planet.pmtiles';

/// Maximum on-disk tile cache size: 200 MB.
const _cacheMaxBytes = 200 * 1024 * 1024;

/// On-disk tile cache TTL: 30 days.
const _cacheTtl = Duration(days: 30);

class MapInitData {
  final vtr.Theme theme;
  final VectorTileProvider tileProvider;

  /// Pre-resolved cache directory — pass to [VectorTileLayer.cacheFolder].
  final Directory cacheDir;

  MapInitData({
    required this.theme,
    required this.tileProvider,
    required this.cacheDir,
  });
}

/// Constants exposed so [VectorTileLayer] can be configured at the call site.
const mapCacheMaxBytes = _cacheMaxBytes;
const mapCacheTtl = _cacheTtl;

class SafePmTilesVectorTileProvider extends VectorTileProvider {
  final PmTilesVectorTileProvider _inner;

  SafePmTilesVectorTileProvider(this._inner);

  @override
  int get maximumZoom => _inner.maximumZoom;

  @override
  int get minimumZoom => _inner.minimumZoom;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    try {
      return await _inner.provide(tile);
    } catch (e) {
      if (kDebugMode) debugPrint('[MapProvider] Tile fetch failed: $e');
      return Uint8List(0);
    }
  }
}

/// Resolves the map style, the PmTiles provider, and the on-disk cache root.
/// AutoDispose: closes the PMTiles archive file handle when no screen is
/// watching the map, preventing tile-provider leaks across navigation.
final mapInitProvider = FutureProvider.autoDispose<MapInitData>((ref) async {
  final styleString =
      await rootBundle.loadString('assets/map/tremble_dark_style.json');
  final theme = vtr.ThemeReader(logger: const vtr.Logger.console())
      .read(jsonDecode(styleString) as Map<String, dynamic>);

  final pmProvider = await PmTilesVectorTileProvider.fromSource(_pmtilesUrl);
  ref.onDispose(() => unawaited(pmProvider.archive.close()));

  final docsDir = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${docsDir.path}/map_cache');

  return MapInitData(
    theme: theme,
    tileProvider: SafePmTilesVectorTileProvider(pmProvider),
    cacheDir: cacheDir,
  );
});
