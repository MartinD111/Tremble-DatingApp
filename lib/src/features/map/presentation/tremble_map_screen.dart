import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/event_geofence_service.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import 'event_pin_sheet.dart';

// OSM tile source — dev uses OpenStreetMap, prod points to the
// Cloudflare Worker in front of our R2-hosted planet.pmtiles file.
// TODO(infra): deploy Protomaps Worker before prod release.
const _tileUrl = String.fromEnvironment('FLAVOR', defaultValue: 'dev') == 'prod'
    ? 'https://maps.trembledating.com/{z}/{x}/{y}.png'
    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        isDark: isDark,
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
            radius: 28,
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
      final color =
          event.isActive ? const Color(0xFFF4436C) : TrembleTheme.accentYellow;

      return Marker(
        point: location,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showEventPinSheet(event, effectivePremium, lang),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                const Icon(Icons.location_pin, color: Colors.white, size: 20),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'sl';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPride = user?.isPrideMode ?? false;
    final isGenderBased = user?.isGenderBasedColor ?? false;
    final gender = user?.gender;
    final geofenceService = ref.watch(eventGeofenceServiceProvider);
    final effectivePremium = user?.effectiveIsPremium(
            inEventGeofence: geofenceService.inEventGeofence) ??
        false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TrembleTheme.getGradient(
              isDarkMode: isDark,
              isPrideMode: isPride,
              gender: gender,
              isGenderBasedColor: isGenderBased,
            ),
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
                    color: isDark ? Colors.white : TrembleTheme.textColor,
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
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _MapPill(
                    text: 'Tremble Events — prihaja kmalu',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MapZoomToggle(
                current: _zoom,
                isDark: isDark,
                onChanged: _setZoom,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _ljubljanaCenter,
                        initialZoom: _zoomLevels[_MapZoom.city]!,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl,
                          userAgentPackageName: 'tremble.dating.app',
                        ),
                        CircleLayer(
                          circles: _buildProximityCircles(effectivePremium),
                        ),
                        MarkerLayer(
                          markers: _buildEventMarkers(effectivePremium, lang),
                        ),
                      ],
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
  final bool isDark;
  final ValueChanged<_MapZoom> onChanged;

  const _MapZoomToggle({
    required this.current,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _MapZoom.values.map((zoom) {
          final isActive = zoom == current;
          final label = {
            _MapZoom.city: 'Mesto',
            _MapZoom.nearby: '1 km',
            _MapZoom.national: 'Slovenija',
          }[zoom]!;

          return GestureDetector(
            onTap: () => onChanged(zoom),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          ? Colors.white.withValues(alpha: 0.6)
                          : TrembleTheme.warmGray),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final String text;
  final bool isDark;

  const _MapPill({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TrembleTheme.uiFont(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : TrembleTheme.textColor,
        ),
      ),
    );
  }
}
