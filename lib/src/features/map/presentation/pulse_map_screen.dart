import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class PulseMapScreen extends ConsumerStatefulWidget {
  const PulseMapScreen({super.key});

  @override
  ConsumerState<PulseMapScreen> createState() => _PulseMapScreenState();
}

class _PulseMapScreenState extends ConsumerState<PulseMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  static const int _activePeople = 47;

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

  void _showEventsSheet() {
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
                            onTap: () {
                              Navigator.pop(context);
                              _centerToEvent(e);
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
                            onTap: () {
                              Navigator.pop(context);
                              _centerToEvent(e);
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
                  "Tremble Map",
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
                    text: "$_activePeople active",
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _MapPill(
                    text: "${_events.length} events",
                    isDark: isDark,
                    onTap: _showEventsSheet,
                  ),
                ],
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
                        target: LatLng(46.0569, 14.5058),
                        zoom: 13.5,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      markers: _markers,
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
  final VoidCallback onTap;
  const _EventTile(
      {required this.event, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = event.isActive
        ? Theme.of(context).primaryColor
        : TrembleTheme.accentYellow;
    final statusText =
        event.isActive ? 'Aktiven zdaj' : 'Prihaja ob ${event.startsAt}';

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
                        ? '${event.peopleCount} ljudi trenutno tukaj'
                        : 'Še nihče — prihaja kmalu',
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
