import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/translations.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme.dart';

class _TrembleEvent {
  final String name;
  final bool isActive;
  final String? startsAt; // e.g. "22:00", null if active
  final int peopleCount;
  final LatLng location;

  const _TrembleEvent({
    required this.name,
    required this.isActive,
    this.startsAt,
    required this.peopleCount,
    required this.location,
  });
}

class TrembleMapScreen extends ConsumerStatefulWidget {
  const TrembleMapScreen({super.key});

  @override
  ConsumerState<TrembleMapScreen> createState() => _TrembleMapScreenState();
}

enum _MapZoom { city, nearby, national }

class _TrembleMapScreenState extends ConsumerState<TrembleMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  _MapZoom _zoom = _MapZoom.city;

  static const int _activePeople = 47;

  // Dev-only heatmap simulation. In production, this layer is populated via
  // the proximity aggregation backend (Phase 3 heatmap implementation).
  static const bool _isDev =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';

  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);

  static const _zoomLevels = {
    _MapZoom.city: 13.5,
    _MapZoom.nearby: 16.0,
    _MapZoom.national: 7.5,
  };

  @override
  void initState() {
    super.initState();
    if (_isDev) {
      _circles = _generateMockHeatmapCircles();
    }
  }

  /// Visual-only simulation of clustered radar users around Ljubljana.
  /// Not backed by real presence data — exists so the map does not look
  /// empty during dev. Replace with a real Heatmap layer once the
  /// Firestore presence aggregation Cloud Function is in place.
  Set<Circle> _generateMockHeatmapCircles() {
    // Stable seed so the cluster does not jitter on every rebuild.
    final rng = math.Random(42);
    final count = 15 + rng.nextInt(16); // 15–30
    const brand = Color(0xFFF4436C);

    final circles = <Circle>{};
    for (var i = 0; i < count; i++) {
      // Gaussian-ish offset: two uniforms summed → tighter cluster around center.
      final dLat = (rng.nextDouble() - rng.nextDouble()) * 0.012;
      final dLng = (rng.nextDouble() - rng.nextDouble()) * 0.018;
      final position = LatLng(
        _ljubljanaCenter.latitude + dLat,
        _ljubljanaCenter.longitude + dLng,
      );

      final radius = 60.0 + rng.nextDouble() * 220.0; // 60–280 m
      final fillOpacity = 0.10 + rng.nextDouble() * 0.30; // 0.10–0.40
      final strokeOpacity = 0.25 + rng.nextDouble() * 0.45; // 0.25–0.70
      final strokeWidth = 1 + rng.nextInt(3); // 1–3 px

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

  static final List<_TrembleEvent> _events = [
    _TrembleEvent(
      name: 'Club Monokel',
      isActive: true,
      peopleCount: 34,
      location: LatLng(46.0514, 14.5058),
    ),
    _TrembleEvent(
      name: 'Labaratorij Festival',
      isActive: true,
      peopleCount: 19,
      location: LatLng(46.0540, 14.5120),
    ),
    _TrembleEvent(
      name: 'Metelkova Odprta Noč',
      isActive: false,
      startsAt: '22:00',
      peopleCount: 0,
      location: LatLng(46.0560, 14.5097),
    ),
  ];

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

  void _showEventsSheet(String lang) {
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
              // Drag handle
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
                              Future.delayed(const Duration(milliseconds: 300),
                                  () => _centerToEvent(e));
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
                              Future.delayed(const Duration(milliseconds: 300),
                                  () => _centerToEvent(e));
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

  void _centerToEvent(_TrembleEvent event) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: event.location, zoom: 15.5),
      ),
    );
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(event.name),
          position: event.location,
          infoWindow: InfoWindow(title: event.name),
        ),
      };
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _mapController?.showMarkerInfoWindow(MarkerId(event.name));
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'sl';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPride = user?.isPrideMode ?? false;
    final isGenderBased = user?.isGenderBasedColor ?? false;
    final gender = user?.gender;

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
                    fontSize: 32, // Standardized to 32px
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
                    onTap: () => _showEventsSheet(lang),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Zoom toggle ───────────────────────────────────────
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
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      markers: _markers,
                      circles: _circles,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  height:
                      120), // clears the floating nav bar (80h + 30pos) with minimal damping
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
  final _TrembleEvent event;
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
                      color: isDark ? Colors.white54 : TrembleTheme.warmGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
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
