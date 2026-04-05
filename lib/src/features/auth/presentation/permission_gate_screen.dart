import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/consent_service.dart';
import 'radar_background.dart';

class PermissionGateScreen extends ConsumerStatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  ConsumerState<PermissionGateScreen> createState() =>
      _PermissionGateScreenState();
}

class _PermissionGateScreenState extends ConsumerState<PermissionGateScreen> {
  bool _isRequesting = false;

  Future<void> _onEnable() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    await ConsentService.requestLocation();
    await ConsentService.requestBluetooth();
    await ConsentService.markPresented();

    if (mounted) {
      ref.read(permissionsPresentedProvider.notifier).state = true;
      // Router redirect handles navigation to '/' automatically
    }
  }

  Future<void> _onSkip() async {
    await ConsentService.markPresented();
    if (mounted) {
      ref.read(permissionsPresentedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RadarBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Text(
                  'Enable\nRadar',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tremble needs two permissions to detect nearby people.',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),
                _PermissionTile(
                  icon: LucideIcons.mapPin,
                  title: 'Location',
                  description:
                      'Used to show you on the Radar and find people nearby. '
                      'Only a ~38m geohash is stored — your exact coordinates are never saved.',
                ),
                const SizedBox(height: 16),
                _PermissionTile(
                  icon: LucideIcons.bluetooth,
                  title: 'Bluetooth',
                  description:
                      'Detects other Tremble users within physical proximity. '
                      'No data is exchanged over BLE — only a presence signal.',
                ),
                const Spacer(),
                _buildCta(),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isRequesting ? null : _onSkip,
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRequesting ? null : _onEnable,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: _isRequesting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                'Enable Radar',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
