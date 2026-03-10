import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/data/auth_repository.dart';

class PulseMapScreen extends ConsumerStatefulWidget {
  const PulseMapScreen({super.key});

  @override
  ConsumerState<PulseMapScreen> createState() => _PulseMapScreenState();
}

class _PulseMapScreenState extends ConsumerState<PulseMapScreen> {
  GoogleMapController? _mapController;

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
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isDark = user?.isDarkMode ?? true;

    return Stack(
      children: [
        GoogleMap(
          style: isDark ? _darkMapStyle : null,
          initialCameraPosition: const CameraPosition(
            target: LatLng(46.0569, 14.5058), // Ljubljana
            zoom: 13.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('ljubljana'),
              position: const LatLng(46.0569, 14.5058),
              infoWindow: const InfoWindow(
                title: 'Ljubljana center',
                snippet: '124 aktivnih',
              ),
              onTap: () => _showPingDetails(context, "Ljubljana", 124),
            ),
            Marker(
              markerId: const MarkerId('btc'),
              position: const LatLng(46.0500, 14.5200),
              infoWindow: const InfoWindow(
                title: 'BTC City',
                snippet: '45 aktivnih',
              ),
              onTap: () => _showPingDetails(context, "BTC City", 45),
            ),
            Marker(
              markerId: const MarkerId('tivoli'),
              position: const LatLng(46.0600, 14.4900),
              infoWindow: const InfoWindow(
                title: 'Park Tivoli',
                snippet: '32 aktivnih',
              ),
              onTap: () => _showPingDetails(context, "Park Tivoli", 32),
            ),
          },
        ),

        // Top + Bottom gradient overlay (non-interactive)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.8),
                    Colors.transparent,
                    Colors.transparent,
                    isDark
                        ? Colors.black.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Header — respects safe area
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tremble Map",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Poglej kje je največ dogajanja",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPingDetails(BuildContext context, String label, int intensity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Aktivnost: Visoka\n$intensity aktivnih v bližini",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Zapri",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
