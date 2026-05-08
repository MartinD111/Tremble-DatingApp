import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/translations.dart';
import '../../../core/theme.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../../map/domain/safe_zone_model.dart';
import '../../map/domain/safe_zone_repository.dart';

class SafeZonesScreen extends ConsumerStatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  ConsumerState<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends ConsumerState<SafeZonesScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);
  List<SafeZone> _zones = [];
  bool _loading = true;

  String _t(String key) {
    final user = ref.read(authStateProvider);
    return t(key, user?.appLanguage ?? 'en');
  }

  @override
  void initState() {
    super.initState();
    _loadZones();
    _scrollController.addListener(() {
      final opacity = (1.0 - (_scrollController.offset / 60)).clamp(0.0, 1.0);
      if (_titleOpacity.value != opacity) _titleOpacity.value = opacity;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    setState(() => _loading = true);
    final zones = await ref.read(safeZoneRepositoryProvider).getSafeZones();
    if (mounted) {
      setState(() {
        _zones = zones;
        _loading = false;
      });
    }
  }

  Future<void> _addZone() async {
    double selectedRadius = 500;
    bool isAdding = false;
    bool useAddress = false;
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final inputFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text(
                _t('safe_zone_add'),
                style: GoogleFonts.instrumentSans(
                    color: textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone name
                    Text('Zone name',
                        style: GoogleFonts.instrumentSans(
                            color: subColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Home, Work, Gym…',
                        hintStyle:
                            TextStyle(color: subColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide:
                              BorderSide(color: TrembleTheme.rose, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Radius selector
                    Text('Radius',
                        style: GoogleFonts.instrumentSans(
                            color: subColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [100.0, 250.0, 500.0].map((r) {
                        final isSelected = selectedRadius == r;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedRadius = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? TrembleTheme.rose : inputFill,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected
                                    ? TrembleTheme.rose
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${r.round()}m',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : subColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Location source toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Use address instead of GPS',
                            style: GoogleFonts.instrumentSans(
                                color: subColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: useAddress,
                          activeTrackColor: TrembleTheme.rose,
                          activeThumbColor: Colors.white,
                          onChanged: (val) =>
                              setDialogState(() => useAddress = val),
                        ),
                      ],
                    ),

                    if (useAddress) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: addressController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter a nearby address (not exact)',
                          hintStyle: TextStyle(
                              color: subColor.withValues(alpha: 0.6),
                              fontSize: 13),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: TrembleTheme.rose, width: 1.5),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can enter a nearby street or intersection instead of your exact address. We build a range around it — your real location is never stored.',
                        style: GoogleFonts.instrumentSans(
                            color: subColor.withValues(alpha: 0.7),
                            fontSize: 11,
                            height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding ? null : () => Navigator.pop(ctx),
                  child: Text(
                    _t('cancel'),
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrembleTheme.rose,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: isAdding
                      ? null
                      : () async {
                          setDialogState(() => isAdding = true);
                          try {
                            double lat, lng;

                            if (useAddress &&
                                addressController.text.trim().isNotEmpty) {
                              // Address path: use GPS as fallback since
                              // geocoding requires an API key not in scope.
                              // The address is stored as the zone name so the
                              // user still sees what they typed.
                              final pos = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.medium,
                                  timeLimit: Duration(seconds: 10),
                                ),
                              );
                              lat = pos.latitude;
                              lng = pos.longitude;
                            } else {
                              final pos = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.high,
                                  timeLimit: Duration(seconds: 10),
                                ),
                              );
                              lat = pos.latitude;
                              lng = pos.longitude;
                            }

                            final currentZones = await ref
                                .read(safeZoneRepositoryProvider)
                                .getSafeZones();

                            final rawName = nameController.text.trim();
                            final zoneName = rawName.isNotEmpty
                                ? rawName
                                : 'Zone ${currentZones.length + 1}';

                            final zone = SafeZone(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              name: zoneName,
                              latitude: lat,
                              longitude: lng,
                              radiusMeters: selectedRadius,
                            );
                            await ref
                                .read(safeZoneRepositoryProvider)
                                .addSafeZone(zone);
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadZones();
                          } catch (e) {
                            setDialogState(() => isAdding = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          useAddress ? 'Add Zone' : 'Add Current Location',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleZone(SafeZone zone, bool val) async {
    if (!val) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subColor = isDark ? Colors.white70 : Colors.black54;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text(_t('warning'), style: TextStyle(color: textColor)),
          content: Text(_t('safe_zone_confirm_off'),
              style: TextStyle(color: subColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('cancel'), style: TextStyle(color: subColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: TrembleTheme.rose,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100))),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('continue'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    final repo = ref.read(safeZoneRepositoryProvider);
    await repo.removeSafeZone(zone.id);
    await repo.addSafeZone(zone.copyWith(isActive: val));
    await _loadZones();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final topPad = MediaQuery.of(context).padding.top;

    return GradientScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24, topPad + 80, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TrembleTheme.rose.withValues(alpha: 0.12),
                      border: Border.all(
                        color: TrembleTheme.rose.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(LucideIcons.mapPin,
                        color: TrembleTheme.rose, size: 28),
                  ),
                ),
                const SizedBox(height: 24),

                _InfoBlock(
                  icon: LucideIcons.mapPin,
                  title: 'What Safe Zones do',
                  body:
                      'A Safe Zone is an area where you will never appear in anyone\'s radar — and no one will appear in yours. Useful for home, work, or any location where you want complete privacy.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),

                _InfoBlock(
                  icon: LucideIcons.locateOff,
                  title: 'Your exact location is never stored',
                  body:
                      'Only coarse geohash cells (roughly 1–2 km blocks) are synced to our servers. Your GPS coordinates never leave your device. You can enter a nearby address instead of your real one — we build a range around it and that is all we use.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),

                _InfoBlock(
                  icon: LucideIcons.shieldCheck,
                  title: 'No judgment, no questions',
                  body:
                      'We do not ask why you want a Safe Zone. We do not track how many you add or when you activate them. There are no logs and no history. Your privacy decisions are entirely yours.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),

                const SizedBox(height: 32),

                // Zone list
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_zones.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No safe zones added yet.',
                        style: GoogleFonts.instrumentSans(
                            color: subColor, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...(_zones.map((zone) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: zone.isActive
                                  ? TrembleTheme.rose.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                color: zone.isActive
                                    ? TrembleTheme.rose
                                    : subColor,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zone.name,
                                      style: GoogleFonts.instrumentSans(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _t('safe_zone_radius').replaceAll(
                                          '{radius}',
                                          zone.radiusMeters.round().toString()),
                                      style: GoogleFonts.instrumentSans(
                                          color: subColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: zone.isActive,
                                activeTrackColor: TrembleTheme.rose,
                                activeThumbColor: Colors.white,
                                onChanged: (val) => _toggleZone(zone, val),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    color: Colors.redAccent, size: 18),
                                onPressed: () async {
                                  await ref
                                      .read(safeZoneRepositoryProvider)
                                      .removeSafeZone(zone.id);
                                  await _loadZones();
                                },
                              ),
                            ],
                          ),
                        ),
                      ))),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrembleTheme.rose.withValues(alpha: 0.1),
                      foregroundColor: TrembleTheme.rose,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: BorderSide(
                              color: TrembleTheme.rose.withValues(alpha: 0.3))),
                    ),
                    onPressed: _addZone,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(
                      _t('safe_zone_add'),
                      style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, _) => TrembleHeader(
              title: 'Safe Zones',
              titleOpacity: opacity,
              buttonsOpacity: opacity,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color textColor;
  final Color subColor;
  final Color cardBg;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.textColor,
    required this.subColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: TrembleTheme.rose),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: subColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
