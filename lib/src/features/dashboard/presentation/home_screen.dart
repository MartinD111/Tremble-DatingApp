import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'radar_animation.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/liquid_nav_bar.dart'; // Import LiquidNavBar
import '../../matches/data/match_repository.dart';
import '../../matches/presentation/match_dialog.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../map/presentation/pulse_map_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../../shared/ui/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/notification_service.dart'; // FCM Notifications

final isScanningProvider =
    StateProvider<bool>((ref) => false); // Manual Toggle State

// Simulates match ping distance (1.0 = edge, 0.0 = center, null = no ping)
final pingDistanceProvider = StateProvider<double?>((ref) => null);
final pingAngleProvider = StateProvider<double?>((ref) => null);

// Tracks whether the nav bar is currently visible
final isNavBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Radar power mode — updated by background service isolate via 'radarState' event.
/// 'full' = BLE + Geo active, 'degraded' = Geo-only (battery saver on)
final radarModeProvider = StateProvider<String>((ref) => 'full');
final radarBatteryLevelProvider = StateProvider<int>((ref) => 100);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Register FCM Token on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider);
      if (user != null) {
        NotificationService.getAndSaveToken(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the stream and update controller
    ref.listen(matchesStreamProvider, (prev, next) {
      final isScanning = ref.read(isScanningProvider);
      if (!isScanning) return; // Only match when radar is active

      next.whenData((matches) {
        if (matches.isNotEmpty) {
          ref.read(matchControllerProvider.notifier).setMatch(matches.first);
        }
      });
    });

    // Listen to controller to show dialog
    ref.listen(matchControllerProvider, (prev, match) {
      if (match != null) {
        showGeneralDialog(
          context: context,
          pageBuilder: (ctx, a1, a2) => MatchDialog(match: match),
          barrierDismissible: true,
          barrierLabel: "Dismiss",
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 200),
        ).then((_) {
          ref.read(matchControllerProvider.notifier).dismiss();
        });
      }
    });

    // Listen for radar mode updates from the background service isolate
    FlutterBackgroundService().on('radarState').listen((event) {
      if (event == null) return;
      final mode = event['mode'] as String? ?? 'full';
      final battery = event['batteryLevel'] as int? ?? 100;
      ref.read(radarModeProvider.notifier).state = mode;
      ref.read(radarBatteryLevelProvider.notifier).state = battery;
    });

    final user = ref.watch(authStateProvider);
    final navIndex = ref.watch(navIndexProvider);
    final isScanning = ref.watch(isScanningProvider);
    final pingDistance = ref.watch(pingDistanceProvider);
    final pingAngle = ref.watch(pingAngleProvider);
    final radarMode = ref.watch(radarModeProvider);
    final batteryLevel = ref.watch(radarBatteryLevelProvider);
    final bool canAccessRadar =
        user?.isEmailVerified == true || user?.isAdmin == true;
    final bool isPremium = user?.isPremium == true;

    // Define Screens and Nav Items
    final List<Widget> screens;
    final List<LiquidNavItem> navItems;

    if (isPremium) {
      screens = [
        _buildRadarView(ref, context, canAccessRadar, isScanning, isPremium,
            pingDistance, pingAngle, radarMode, batteryLevel),
        const PulseMapScreen(),
        const MatchesScreen(),
        const SettingsScreen(),
      ];
      navItems = [
        LiquidNavItem(icon: LucideIcons.radar, label: 'Radar'),
        LiquidNavItem(icon: LucideIcons.map, label: 'Map'),
        LiquidNavItem(icon: LucideIcons.users, label: 'Matches'),
        LiquidNavItem(icon: LucideIcons.settings, label: 'Settings'),
      ];
    } else {
      screens = [
        _buildRadarView(ref, context, canAccessRadar, isScanning, isPremium,
            pingDistance, pingAngle, radarMode, batteryLevel),
        const MatchesScreen(),
        const SettingsScreen(),
      ];
      navItems = [
        LiquidNavItem(icon: LucideIcons.radar, label: 'Radar'),
        LiquidNavItem(icon: LucideIcons.users, label: 'Matches'),
        LiquidNavItem(icon: LucideIcons.settings, label: 'Settings'),
      ];
    }

    final hideNavBarPref = ref.watch(hideNavBarPrefProvider);
    final isNavBarVisible = ref.watch(isNavBarVisibleProvider);

    return Stack(
      children: [
        // Content with Liquid Transition
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!hideNavBarPref) {
                // If preference is off, make sure nav bar is visible
                if (!ref.read(isNavBarVisibleProvider)) {
                  ref.read(isNavBarVisibleProvider.notifier).state = true;
                }
                return false;
              }

              if (notification is ScrollUpdateNotification) {
                if (notification.scrollDelta != null) {
                  if (notification.scrollDelta! > 5 && isNavBarVisible) {
                    ref.read(isNavBarVisibleProvider.notifier).state = false;
                  } else if (notification.scrollDelta! < -5 &&
                      !isNavBarVisible) {
                    ref.read(isNavBarVisibleProvider.notifier).state = true;
                  }
                }
              }
              return false;
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(navIndex),
                child: screens[navIndex],
              ),
            ),
          ),
        ),

        // Floating Liquid Navigation Bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: isNavBarVisible ? 30 : -100,
          left: 0,
          right: 0,
          child: LiquidNavBar(
            currentIndex: navIndex,
            isPremium: isPremium,
            items: navItems,
            onTap: (index) {
              ref.read(navIndexProvider.notifier).state = index;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRadarView(
      WidgetRef ref,
      BuildContext context,
      bool canAccessRadar,
      bool isScanning,
      bool isPremium,
      double? pingDistance,
      double? pingAngle,
      String radarMode,
      int batteryLevel) {
    final isDegraded = radarMode == 'degraded';
    return Stack(
      children: [
        // Radar View (Conditional)
        canAccessRadar
            ? Stack(
                children: [
                  Positioned.fill(
                      child: RadarAnimation(
                    isScanning: isScanning,
                    pingDistance: pingDistance,
                    pingAngle: pingAngle,
                  )),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final newState = !isScanning;
                        ref.read(isScanningProvider.notifier).state = newState;

                        if (newState) {
                          debugPrint(
                              "📍 Location Captured: mock_lat: 46.05, mock_lng: 14.50 [Ljubljana]");
                          // In real app, call Location Service here
                          FlutterBackgroundService().startService();
                        } else {
                          // Stop service? Or just let it run but stop notifying?
                          // Simply invoking stop might kill the isolate
                          // FlutterBackgroundService().invoke("stopService");
                        }
                      },
                      child: GlassCard(
                        opacity: 0.1,
                        borderRadius: 100,
                        padding: const EdgeInsets.all(30),
                        child: Icon(
                            isScanning ? LucideIcons.radio : LucideIcons.play,
                            size: 60,
                            color: isScanning ? Colors.white : Colors.white70),
                      ),
                    ),
                  ),
                  if (isScanning) ...[
                    Positioned(
                      bottom: 140,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          isDegraded
                              ? "Geo matching \u2014 BLE paused"
                              : "Skeniranje...",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 2),
                        ),
                      ),
                    ),
                    // ── Power-Save Pill ────────────────────────
                    if (isDegraded)
                      Positioned(
                        top: 56,
                        left: 0,
                        child: Center(
                          child: _PowerSavePill(batteryLevel: batteryLevel),
                        ),
                      ),
                    // ── DEV TEST: Mock Hotspot Button ────────────────
                    Positioned(
                      top: 100,
                      right: 20,
                      child: IconButton(
                        icon:
                            const Icon(LucideIcons.flame, color: Colors.amber),
                        onPressed: () {
                          // Allow the user to manually trigger the Notification
                          NotificationService.showMockHotspotNotification();
                        },
                      ),
                    ),
                  ]
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.lock,
                        size: 60, color: Colors.white54),
                    const SizedBox(height: 20),
                    Text(
                      "Radar je zaklenjen.",
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Prosim preveri svoj email za dostop.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: "Pojdi v nastavitve",
                      width: 200,
                      onPressed: () {
                        ref.read(navIndexProvider.notifier).state =
                            isPremium ? 3 : 2; // Settings index varies
                      },
                    )
                  ],
                ),
              ),
      ],
    );
  }
}

final navIndexProvider = StateProvider<int>((ref) => 0);

/// Amber animated pill shown on the Radar screen when the background engine
/// is in battery-saver (degraded) mode — BLE off, Geo-only matching.
class _PowerSavePill extends StatefulWidget {
  final int batteryLevel;
  const _PowerSavePill({required this.batteryLevel});

  @override
  State<_PowerSavePill> createState() => _PowerSavePillState();
}

class _PowerSavePillState extends State<_PowerSavePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.battery_saver_rounded,
                color: Colors.black87, size: 16),
            const SizedBox(width: 7),
            Text(
              'Radar v varč. načinu  •  ${widget.batteryLevel}%',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
