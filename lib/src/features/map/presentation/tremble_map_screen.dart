import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/event_geofence_service.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import 'event_pin_sheet.dart';
import 'dart:convert';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

const _pmtilesUrl = 'https://maps.trembledating.com/planet.pmtiles';

class _MapInitData {
  final vtr.Theme theme;
  final PmTilesVectorTileProvider tileProvider;
  _MapInitData({required this.theme, required this.tileProvider});
}

class TrembleMapScreen extends ConsumerStatefulWidget {
  const TrembleMapScreen({super.key});

  @override
  ConsumerState<TrembleMapScreen> createState() => _TrembleMapScreenState();
}

enum _MapZoom { city, nearby, national }

class _TrembleMapScreenState extends ConsumerState<TrembleMapScreen> {
  late final MapController _mapController;
  _MapZoom _zoom = _MapZoom.city;
  late final Future<_MapInitData> _mapInitFuture;

  static const bool _isDev =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';

  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);

  static const _zoomLevels = {
    _MapZoom.city: 13.5,
    _MapZoom.nearby: 16.0,
    _MapZoom.national: 7.5,
  };

  static const List<TrembleEventData> _events = [];

  static const Map<String, LatLng> _eventLocations = {
    'club_monokel': LatLng(46.0514, 14.5058),
    'labaratorij': LatLng(46.0540, 14.5120),
    'metelkova': LatLng(46.0560, 14.5097),
  };

  // Dev mock proximity circles (replace with Firestore stream in prod).
  late final List<LatLng> _proximityPoints;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _proximityPoints = _isDev ? _generateProximityPoints() : const [];

    ref.read(eventGeofenceServiceProvider).setActiveEvents([]);
    _mapInitFuture = _initializeMap();
  }

  Future<_MapInitData> _initializeMap() async {
    final styleString = await DefaultAssetBundle.of(context)
        .loadString('assets/map/tremble_dark_style.json');
    final Map<String, dynamic> styleJson = jsonDecode(styleString);
    final theme =
        vtr.ThemeReader(logger: const vtr.Logger.console()).read(styleJson);

    final tileProvider =
        await PmTilesVectorTileProvider.fromSource(_pmtilesUrl);

    return _MapInitData(theme: theme, tileProvider: tileProvider);
  }

  List<LatLng> _generateProximityPoints() {
    final rng = math.Random(42);
    return List.generate(22 + rng.nextInt(10), (_) {
      final dLat = (rng.nextDouble() - rng.nextDouble()) * 0.018;
      final dLng = (rng.nextDouble() - rng.nextDouble()) * 0.024;
      return LatLng(
        _ljubljanaCenter.latitude + dLat,
        _ljubljanaCenter.longitude + dLng,
      );
    });
  }

  void _setZoom(_MapZoom zoom) {
    setState(() => _zoom = zoom);
    _mapController.move(_ljubljanaCenter, _zoomLevels[zoom]!);
  }

  void _showEventPinSheet(
    TrembleEventData event,
    bool effectivePremium,
    String lang,
  ) {
    final geofenceService = ref.read(eventGeofenceServiceProvider);
    final isTasteOfPremium = geofenceService.inEventGeofence &&
        !ref.read(authStateProvider)!.isPremium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventPinSheet(
        event: event,
        effectiveIsPremium: effectivePremium,
        isTasteOfPremium: isTasteOfPremium,
        isDark: false,
        lang: lang,
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<CircleMarker> _buildProximityCircles(bool effectivePremium) {
    if (!effectivePremium || _proximityPoints.isEmpty) return const [];
    return _proximityPoints
        .map(
          (point) => CircleMarker(
            point: point,
            radius: 120,
            useRadiusInMeter: true,
            color: const Color(0xFFF4436C).withValues(alpha: 0.12),
            borderColor: const Color(0xFFF4436C).withValues(alpha: 0.35),
            borderStrokeWidth: 1.5,
          ),
        )
        .toList();
  }

  List<Marker> _buildEventMarkers(bool effectivePremium, String lang) {
    return _events.map((event) {
      final location = _eventLocations[event.id]!;
      final accent = event.isActive ? TrembleTheme.azure : TrembleTheme.rose;
      final fill = Colors.white.withValues(alpha: 0.96);

      return Marker(
        point: location,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showEventPinSheet(event, effectivePremium, lang),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.location_pin,
              color:
                  event.isActive ? TrembleTheme.azure : TrembleTheme.textColor,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'sl';
    final geofenceService = ref.watch(eventGeofenceServiceProvider);
    final effectivePremium = user?.effectiveIsPremium(
            inEventGeofence: geofenceService.inEventGeofence) ??
        false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8F7F3),
              const Color(0xFFEFECE0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  t('map_title', lang),
                  textAlign: TextAlign.center,
                  style: TrembleTheme.displayFont(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: TrembleTheme.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MapPill(
                    text: t('active_people_count', lang)
                        .replaceAll('{count}', '${_proximityPoints.length}'),
                  ),
                  const SizedBox(width: 8),
                  _MapPill(
                    text: t('tremble_events_coming_soon', lang),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MapZoomToggle(
                current: _zoom,
                onChanged: _setZoom,
                lang: lang,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: FutureBuilder<_MapInitData>(
                      future: _mapInitFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading map: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          );
                        }
                        final initData = snapshot.data!;
                        return FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _ljubljanaCenter,
                            initialZoom: _zoomLevels[_MapZoom.city]!,
                            maxZoom: 16.0,
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            VectorTileLayer(
                              theme: initData.theme,
                              tileProviders: TileProviders({
                                'protomaps': initData.tileProvider,
                              }),
                            ),
                            CircleLayer(
                              circles: _buildProximityCircles(effectivePremium),
                            ),
                            MarkerLayer(
                              markers:
                                  _buildEventMarkers(effectivePremium, lang),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapZoomToggle extends StatelessWidget {
  final _MapZoom current;
  final ValueChanged<_MapZoom> onChanged;
  final String lang;

  const _MapZoomToggle({
    required this.current,
    required this.onChanged,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _MapZoom.values.map((zoom) {
              final isActive = zoom == current;
              final label = {
                _MapZoom.city: t('zoom_city', lang),
                _MapZoom.nearby: '1 km',
                _MapZoom.national: t('zoom_national', lang),
              }[zoom]!;

              return GestureDetector(
                onTap: () => onChanged(zoom),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isActive ? const Color(0xFF007AFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    label,
                    style: TrembleTheme.uiFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : TrembleTheme.textColor.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final String text;

  const _MapPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TrembleTheme.uiFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TrembleTheme.textColor.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}
