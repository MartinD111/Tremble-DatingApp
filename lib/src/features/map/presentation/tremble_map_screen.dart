import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/event_geofence_service.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme.dart';
import 'event_pin_sheet.dart';

class TrembleMapScreen extends ConsumerStatefulWidget {
  const TrembleMapScreen({super.key});

  @override
  ConsumerState<TrembleMapScreen> createState() => _TrembleMapScreenState();
}

enum _MapZoom { city, nearby, national }

class _TrembleMapScreenState extends ConsumerState<TrembleMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  /// Pre-generated mock heatmap circles. Only rendered when the user has
  /// effective premium access (real Pro or Taste of Premium via event geofence).
  late final Set<Circle> _heatmapCircles;
  _MapZoom _zoom = _MapZoom.city;

  static const int _activePeople = 47;

  static const bool _isDev =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';

  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);

  static const _zoomLevels = {
    _MapZoom.city: 13.5,
    _MapZoom.nearby: 16.0,
    _MapZoom.national: 7.5,
  };

  static const List<TrembleEventData> _events = [
    TrembleEventData(
      id: 'club_monokel',
      name: 'Club Monokel',
      isActive: true,
      peopleCount: 34,
      locationLabel: 'Club Monokel, Ljubljana',
    ),
    TrembleEventData(
      id: 'labaratorij',
      name: 'Labaratorij Festival',
      isActive: true,
      peopleCount: 19,
      locationLabel: 'Labaratorij, Ljubljana',
    ),
    TrembleEventData(
      id: 'metelkova',
      name: 'Metelkova Odprta Noč',
      isActive: false,
      startsAt: '22:00',
      peopleCount: 0,
      locationLabel: 'Metelkova, Ljubljana',
    ),
  ];

  static const Map<String, LatLng> _eventLocations = {
    'club_monokel': LatLng(46.0514, 14.5058),
    'labaratorij': LatLng(46.0540, 14.5120),
    'metelkova': LatLng(46.0560, 14.5097),
  };

  @override
  void initState() {
    super.initState();
    _heatmapCircles =
        _isDev ? _generateMockHeatmapCircles() : const <Circle>{};

    // Register event locations with the geofence service so real GPS
    // proximity checks start immediately (if location permission is granted).
    ref.read(eventGeofenceServiceProvider).setActiveEvents(
          _events
              .where((e) => e.isActive)
              .map((e) => GeofenceTarget(
                    id: e.id,
                    name: e.name,
                    lat: _eventLocations[e.id]!.latitude,
                    lng: _eventLocations[e.id]!.longitude,
                  ))
              .toList(),
        );
  }

  /// Visual-only simulation of clustered radar users around Ljubljana.
  Set<Circle> _generateMockHeatmapCircles() {
    final rng = math.Random(42);
    final count = 15 + rng.nextInt(16);
    const brand = Color(0xFFF4436C);

    final circles = <Circle>{};
    for (var i = 0; i < count; i++) {
      final dLat = (rng.nextDouble() - rng.nextDouble()) * 0.012;
      final dLng = (rng.nextDouble() - rng.nextDouble()) * 0.018;
      final position = LatLng(
        _ljubljanaCenter.latitude + dLat,
        _ljubljanaCenter.longitude + dLng,
      );

      final radius = 60.0 + rng.nextDouble() * 220.0;
      final fillOpacity = 0.10 + rng.nextDouble() * 0.30;
      final strokeOpacity = 0.25 + rng.nextDouble() * 0.45;
      final strokeWidth = 1 + rng.nextInt(3);

      circles.add(
        Circle(
          circleId: CircleId('mock_heat_$i'),
          center: position,
          radius: radius,
          fillColor: brand.withValues(alpha: fillOpacity),
          strokeColor: brand.withValues(alpha: strokeOpacity),
          strokeWidth: strokeWidth,
        ),
      );
    }
    return circles;
  }

  void _setZoom(_MapZoom zoom) {
    setState(() => _zoom = zoom);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _ljubljanaCenter,
          zoom: _zoomLevels[zoom]!,
        ),
      ),
    );
  }

  Set<Marker> _buildEventMarkers(bool effectivePremium, String lang) {
    return _events.map((event) {
      final location = _eventLocations[event.id]!;
      final hue = event.isActive
          ? BitmapDescriptor.hueRose
          : BitmapDescriptor.hueYellow;

      return Marker(
        markerId: MarkerId(event.id),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _showEventPinSheet(event, effectivePremium, lang),
      );
    }).toSet();
  }

  void _showEventPinSheet(
    TrembleEventData event,
    bool effectivePremium,
    String lang,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final geofenceService = ref.read(eventGeofenceServiceProvider);
    final isTasteOfPremium =
        geofenceService.inEventGeofence && !ref.read(authStateProvider)!.isPremium;

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

  void _centerToEvent(TrembleEventData event, bool effectivePremium, String lang) {
    final location = _eventLocations[event.id]!;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.5),
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      _showEventPinSheet(event, effectivePremium, lang);
    });
  }

  void _showEventsSheet(String lang, bool effectivePremium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _SheetSectionHeader(
                        title: 'Aktivni eventi', isDark: isDark),
                    const SizedBox(height: 8),
                    ..._events.where((e) => e.isActive).map(
                          (e) => _EventTile(
                            event: e,
                            isDark: isDark,
                            lang: lang,
                            onTap: () {
                              Navigator.pop(context);
                              Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => _centerToEvent(e, effectivePremium, lang));
                            },
                          ),
                        ),
                    const SizedBox(height: 4),
                    _SheetSectionHeader(
                        title: 'Prihajajoči eventi', isDark: isDark),
                    const SizedBox(height: 8),
                    ..._events.where((e) => !e.isActive).map(
                          (e) => _EventTile(
                            event: e,
                            isDark: isDark,
                            lang: lang,
                            onTap: () {
                              Navigator.pop(context);
                              Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => _centerToEvent(e, effectivePremium, lang));
                            },
                          ),
                        ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "color": "#373737" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "#3C3C3C" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#000000" }]
  },
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "transit",
    "stylers": [{ "visibility": "off" }]
  }
]
''';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'sl';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPride = user?.isPrideMode ?? false;
    final isGenderBased = user?.isGenderBasedColor ?? false;
    final gender = user?.gender;
    final geofenceService = ref.watch(eventGeofenceServiceProvider);
    final effectivePremium =
        user?.effectiveIsPremium(inEventGeofence: geofenceService.inEventGeofence) ?? false;

    final eventMarkers = _buildEventMarkers(effectivePremium, lang);

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
                        .replaceAll('{count}', '$_activePeople'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _MapPill(
                    text: t('events_count', lang)
                        .replaceAll('{count}', '${_events.length}'),
                    isDark: isDark,
                    onTap: () => _showEventsSheet(lang, effectivePremium),
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
                    child: GoogleMap(
                      style: isDark ? _darkMapStyle : null,
                      initialCameraPosition: const CameraPosition(
                        target: _ljubljanaCenter,
                        zoom: 13.5,
                      ),
                      onMapCreated: (controller) =>
                          _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      markers: {..._markers, ...eventMarkers},
                      circles: effectivePremium ? _heatmapCircles : const {},
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
  final VoidCallback? onTap;
  final bool isDark;

  const _MapPill({required this.text, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
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

    if (onTap == null) return pill;

    return GestureDetector(
      onTap: onTap,
      child: pill
          .animate(onPlay: (c) {})
          .scaleXY(end: 0.96, duration: 80.ms, curve: Curves.easeIn)
          .then()
          .scaleXY(end: 1.0, duration: 80.ms, curve: Curves.easeOut),
    );
  }
}

class _SheetSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SheetSectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TrembleTheme.displayFont(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TrembleTheme.textColor,
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final TrembleEventData event;
  final bool isDark;
  final String lang;
  final VoidCallback onTap;
  const _EventTile(
      {required this.event,
      required this.isDark,
      required this.lang,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = event.isActive
        ? Theme.of(context).primaryColor
        : TrembleTheme.accentYellow;
    final statusText = event.isActive
        ? t('active_now', lang)
        : t('coming_at', lang).replaceAll('{time}', event.startsAt ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: TrembleTheme.uiFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : TrembleTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.isActive
                        ? t('people_here', lang)
                            .replaceAll('{count}', '${event.peopleCount}')
                        : t('nobody_here', lang),
                    style: TrembleTheme.uiFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color:
                          isDark ? Colors.white54 : TrembleTheme.warmGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                statusText,
                style: TrembleTheme.uiFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
