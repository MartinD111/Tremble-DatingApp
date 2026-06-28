import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/event_geofence_service.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import 'event_pin_sheet.dart';
import '../../../core/map_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

class TrembleMapScreen extends ConsumerStatefulWidget {
  const TrembleMapScreen({super.key});

  @override
  ConsumerState<TrembleMapScreen> createState() => _TrembleMapScreenState();
}

enum _MapZoom { city, nearby, national }

class _TrembleMapScreenState extends ConsumerState<TrembleMapScreen> {
  late final MapController _mapController;
  _MapZoom _zoom = _MapZoom.city;

  static const bool _isDev =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';

  // Last-resort fallback when no last-known device position is available
  // (first launch, permission denied, location services off). Not used in
  // any always-on path — see [_effectiveCenter].
  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);

  // Resolved from Geolocator.getLastKnownPosition() on init. Null until that
  // returns; UI uses [_effectiveCenter] which falls back to [_ljubljanaCenter].
  LatLng? _userCenter;

  LatLng get _effectiveCenter => _userCenter ?? _ljubljanaCenter;

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
    unawaited(_resolveUserCenter());
  }

  /// Pulls the cached device position without triggering a permission dialog.
  /// If a usable position is returned, we snap the map (and any future zoom
  /// toggles) to it; otherwise we keep the [_ljubljanaCenter] fallback.
  Future<void> _resolveUserCenter() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null || !mounted) return;
      setState(() {
        _userCenter = LatLng(pos.latitude, pos.longitude);
      });
      if (_mapController.camera.zoom > 0) {
        _mapController.move(_userCenter!, _zoomLevels[_zoom]!);
      }
    } catch (_) {
      // Permission denied / location services off — keep the fallback.
    }
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
    _mapController.move(_effectiveCenter, _zoomLevels[zoom]!);
  }

  void _showEventPinSheet(
    TrembleEventData event,
    bool effectivePremium,
    String lang,
  ) {
    final geofenceService = ref.read(eventGeofenceServiceProvider);
    final isTasteOfPremium = geofenceService.inEventGeofence &&
        !ref.read(effectiveIsPremiumProvider);

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
    if (_proximityPoints.isEmpty) return const [];
    return _proximityPoints
        .map(
          (point) => CircleMarker(
            point: point,
            radius: 120,
            useRadiusInMeter: true,
            color: TrembleTheme.rose.withValues(alpha: 0.12),
            borderColor: TrembleTheme.rose.withValues(alpha: 0.35),
            borderStrokeWidth: 1.5,
          ),
        )
        .toList();
  }

  List<Marker> _buildProximityCountBadges() {
    return _proximityPoints
        .map(
          (point) => Marker(
            point: point,
            width: 30,
            height: 30,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _proximityPoints.length.toString(),
                style: const TextStyle(
                  color: TrembleTheme.rose,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  List<Marker> _buildEventMarkers(bool effectivePremium, String lang) {
    // Hardcoded Ljubljana venue coordinates in [_eventLocations] must never
    // reach a prod render path. Until venue coords are sourced from Firestore
    // they are dev-only fixtures.
    if (!_isDev) return const [];
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
    final effectivePremium = ref.watch(effectiveIsPremiumProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = TrembleTheme.getGradient(
      isDarkMode: isDark,
      isPrideMode: user?.isPrideMode ?? false,
      gender: user?.gender,
      isGenderBasedColor: user?.isGenderBasedColor ?? false,
    );
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
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
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (kDebugMode ||
                      const String.fromEnvironment('FLAVOR') == 'dev') ...[
                    _MapPill(
                      text: t('active_people_count', lang)
                          .replaceAll('{count}', '${_proximityPoints.length}'),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                    color: isDark
                        ? TrembleTheme.textColor.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFD9D7CF).withValues(alpha: 0.95),
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
                    child: ref.watch(mapInitProvider).when(
                          loading: () => const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading map: $e',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          data: (initData) => Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _effectiveCenter,
                                  initialZoom: _zoomLevels[_MapZoom.city]!,
                                  maxZoom: 16.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
                                  ),
                                ),
                                children: [
                                  VectorTileLayer(
                                    theme: initData.theme,
                                    tileProviders: TileProviders({
                                      'protomaps': initData.tileProvider,
                                    }),
                                    cacheFolder: () async => initData.cacheDir,
                                    fileCacheTtl: mapCacheTtl,
                                    fileCacheMaximumSizeInBytes:
                                        mapCacheMaxBytes,
                                  ),
                                  CircleLayer(
                                    circles: _buildProximityCircles(
                                        effectivePremium),
                                  ),
                                  if (effectivePremium)
                                    MarkerLayer(
                                      markers: _buildProximityCountBadges(),
                                    ),
                                  MarkerLayer(
                                    markers: _buildEventMarkers(
                                        effectivePremium, lang),
                                  ),
                                ],
                              ),
                              if (effectivePremium)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: CircleAvatar(
                                    backgroundColor: isDark
                                        ? const Color(0xFF2A2A2E)
                                        : Colors.white,
                                    child: const Icon(
                                      Icons.filter_list,
                                      color: TrembleTheme.rose,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2E).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFD9D7CF).withValues(alpha: 0.95),
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
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    label,
                    style: TrembleTheme.uiFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? Colors.white60
                              : TrembleTheme.textColor.withValues(alpha: 0.68)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2E).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFD9D7CF).withValues(alpha: 0.95),
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
              color: isDark
                  ? Colors.white70
                  : TrembleTheme.textColor.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}
