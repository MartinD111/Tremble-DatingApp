import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'radar_animation.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/liquid_nav_bar.dart'; // Import LiquidNavBar
import '../../matches/data/match_repository.dart';
import '../../matches/presentation/match_dialog.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../map/presentation/pulse_map_screen.dart';
import '../../../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../../shared/ui/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/notification_service.dart'; // FCM Notifications
import '../../../core/ble_service.dart'; // BLE must run in main isolate
import '../../../shared/ui/tremble_logo.dart';
import '../../../core/consent_service.dart'; // gdprConsentProvider
import 'package:flutter_animate/flutter_animate.dart'; // Animations
import '../../../core/translations.dart';
import '../../match/application/match_service.dart';
import '../../match/data/wave_repository.dart';
import '../../match/domain/match.dart' as wave_match;
import '../../../core/dev_mock_users.dart'; // Dev-only mock nearby users
import 'widgets/radar_search_overlay.dart';
import 'widgets/wave_simulation_overlay.dart';
import '../../profile/data/profile_repository.dart';

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
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Register FCM Token on dashboard load
      final user = ref.read(authStateProvider);
      if (user != null) {
        NotificationService.saveToken(user.id);
      }
      // Check whether to show first-launch tutorial
      hasSeenTutorial().then((seen) {
        if (!seen && mounted) setState(() => _showTutorial = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Wave Match Reveal Listener ────────────────────────────────────────
    // Reads the activeMatchesStream and triggers the reveal screen exactly once
    // per match by atomically marking seenBy BEFORE navigating.
    ref.listen(activeMatchesStreamProvider, (previous, next) {
      final matches = next.value;
      if (matches == null || matches.isEmpty) return;

      final myUid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (myUid == null) return;

      final unseenMatch = matches.cast<wave_match.Match?>().firstWhere(
            (m) => m != null && !m.seenBy.contains(myUid),
            orElse: () => null,
          );

      if (unseenMatch != null) {
        // Atomic: mark seen first to prevent re-trigger on next stream emission
        ref.read(waveRepositoryProvider).markMatchAsSeen(unseenMatch.id);
        if (mounted) {
          context.pushNamed('match_reveal', extra: unseenMatch);
        }
      }
    });

    // Listen to the stream and update controller with visual Sonar Ping
    ref.listen(matchesStreamProvider, (prev, next) {
      final isScanning = ref.read(isScanningProvider);
      if (!isScanning) return; // Only match when radar is active

      next.whenData((matches) {
        if (matches.isNotEmpty) {
          final newMatch = matches.first;
          final isNewMatch =
              prev?.valueOrNull?.any((m) => m.id == newMatch.id) != true;

          if (isNewMatch) {
            // Trigger visual ping
            // Simulating relative angle and distance since actual coordinate math
            // requires fetching the other user's location which is masked anyway.
            final randomAngle =
                (DateTime.now().millisecond / 1000) * 2 * 3.14159;
            final randomDist =
                0.4 + (DateTime.now().millisecond / 2000); // 0.4 to 0.9

            ref.read(pingAngleProvider.notifier).state = randomAngle;
            ref.read(pingDistanceProvider.notifier).state = randomDist;

            // Wait for the radar sweep to pass over the dot (1.5s) then pop dialog
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                ref.read(pingAngleProvider.notifier).state = null;
                ref.read(pingDistanceProvider.notifier).state = null;
                ref.read(matchControllerProvider.notifier).setMatch(newMatch);
              }
            });
          }
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
    final lang = ref.watch(appLanguageProvider);
    final navIndex = ref.watch(navIndexProvider);

    final isScanning = ref.watch(isScanningProvider);
    final pingDistance = ref.watch(pingDistanceProvider);
    final pingAngle = ref.watch(pingAngleProvider);
    final radarMode = ref.watch(radarModeProvider);
    final batteryLevel = ref.watch(radarBatteryLevelProvider);
    final bool bypassRadar = ref.watch(bypassRadarProvider);
    final bool localAdmin = kDebugMode && ref.watch(localAdminModeProvider);
    final bool canAccessRadar = user?.isEmailVerified == true ||
        user?.isAdmin == true ||
        bypassRadar ||
        localAdmin;
    final bool isPremium = user?.isPremium == true;

    // ── Active Search State ──────────────────────────────────────────────
    final activeMatch = ref.watch(currentSearchProvider);

    // Define Screens and Nav Items
    final List<Widget> screens;
    final List<LiquidNavItem> navItems;

    if (isPremium) {
      screens = [
        _buildRadarView(
            ref,
            context,
            user,
            canAccessRadar,
            isScanning,
            isPremium,
            pingDistance,
            pingAngle,
            radarMode,
            batteryLevel,
            activeMatch),
        const PulseMapScreen(),
        const MatchesScreen(),
        const SettingsScreen(),
      ];
      navItems = [
        LiquidNavItem(icon: LucideIcons.radar, label: t('tab_radar', lang)),
        LiquidNavItem(icon: LucideIcons.map, label: t('tab_map', lang)),
        LiquidNavItem(icon: LucideIcons.users, label: t('tab_people', lang)),
        LiquidNavItem(
            icon: LucideIcons.settings, label: t('tab_settings', lang)),
      ];
    } else {
      screens = [
        _buildRadarView(
            ref,
            context,
            user,
            canAccessRadar,
            isScanning,
            isPremium,
            pingDistance,
            pingAngle,
            radarMode,
            batteryLevel,
            activeMatch),
        const MatchesScreen(),
        const SettingsScreen(),
      ];
      navItems = [
        LiquidNavItem(icon: LucideIcons.radar, label: t('tab_radar', lang)),
        LiquidNavItem(icon: LucideIcons.users, label: t('tab_people', lang)),
        LiquidNavItem(
            icon: LucideIcons.settings, label: t('tab_settings', lang)),
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
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
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

        // First-launch wave tutorial overlay
        if (_showTutorial)
          Positioned.fill(
            child: WaveSimulationOverlay(
              tr: (key) => t(key, lang),
              onDismiss: () => setState(() => _showTutorial = false),
            ),
          ),
      ],
    );
  }

  Widget _buildRadarView(
      WidgetRef ref,
      BuildContext context,
      AuthUser? user,
      bool canAccessRadar,
      bool isScanning,
      bool isPremium,
      double? pingDistance,
      double? pingAngle,
      String radarMode,
      int batteryLevel,
      wave_match.Match? activeMatch) {
    final isDegraded = radarMode == 'degraded';
    final lang = ref.watch(appLanguageProvider);
    final bool isSearchActive = activeMatch != null;
    return Stack(
      children: [
        // ── Radar Header ─────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 50,
            child: Center(
              child: Text(
                t('tab_radar', lang),
                style: TrembleTheme.displayFont(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // Radar View (Conditional)
        canAccessRadar
            ? Stack(
                children: [
                  Positioned.fill(
                    child: RadarAnimation(
                      isScanning: isScanning &&
                          !isSearchActive, // stop visual pulse if searching
                      isVibrationEnabled: user?.isPingVibrationEnabled ?? true,
                      pingDistance: isSearchActive ? null : pingDistance,
                      pingAngle: isSearchActive ? null : pingAngle,
                      brandColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (isSearchActive)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black
                            .withValues(alpha: 0.2), // Dim radar during search
                        child: Center(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final partnerId =
                                  activeMatch.getPartnerId(user?.id ?? '');
                              final profile =
                                  ref.watch(publicProfileProvider(partnerId));
                              return profile.when(
                                data: (p) => RadarSearchOverlay(
                                  match: activeMatch,
                                  partnerName: p.name,
                                ),
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (_, __) => RadarSearchOverlay(
                                  match: activeMatch,
                                  partnerName: t('someone_nearby', lang),
                                ),
                              );
                            },
                          ),
                        ),
                      ).animate().fade(),
                    )
                  else ...[
                    // ── Pulsing Primary Action ────────────────────────
                    Center(
                      child: _PulsingRadarButton(
                        isScanning: isScanning,
                        onTap: () async {
                          final newState = !isScanning;
                          ref.read(isScanningProvider.notifier).state =
                              newState;

                          if (newState) {
                            debugPrint(
                                "📍 Location Captured: mock_lat: 46.05, mock_lng: 14.50 [Ljubljana]");
                            // Start background service (GeoService lives here).
                            FlutterBackgroundService().startService();
                            // BleService must run in the main isolate — flutter_blue_plus
                            // requires an Android Activity which the background isolate
                            // does not have. Gate on GDPR consent before starting.
                            final hasConsent =
                                ref.read(gdprConsentProvider).valueOrNull ??
                                    false;
                            if (hasConsent) {
                              await BleService().start();
                            }

                            // ── Admin Mode demo: inject mock nearby users ──────
                            // Only fires in kDebugMode when Admin Mode (Bypass Radar)
                            // is active — never touches real Firebase.
                            if (kDebugMode && ref.read(bypassRadarProvider)) {
                              _injectMockRadarPings(ref);
                            }
                          } else {
                            // Stop BLE in main isolate and signal background service.
                            BleService().stop();
                            FlutterBackgroundService()
                                .invoke('stopService', null);
                          }
                        },
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack),
                    ),

                    if (isScanning) ...[
                      Positioned(
                        bottom: 140,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            isDegraded
                                ? t('geo_matching_paused', lang)
                                : t('scanning', lang),
                            style: TrembleTheme.telemetryTextStyle(
                              context,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ).copyWith(letterSpacing: 2),
                          ).animate().fade().slideY(begin: 0.5),
                        ),
                      ),
                      // ── Power-Save Pill ────────────────────────
                      if (isDegraded)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 36,
                          left: 0,
                          child: Center(
                            child: _PowerSavePill(
                                    batteryLevel: batteryLevel, lang: lang)
                                .animate()
                                .fade()
                                .slideY(begin: -1.0, curve: Curves.easeOutBack),
                          ),
                        ),
                    ]
                  ],
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.lock,
                        size: 60, color: Colors.black26),
                    const SizedBox(height: 20),
                    Text(
                      t('radar_locked', lang),
                      style: GoogleFonts.instrumentSans(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('check_email_access', lang),
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: t('go_to_settings', lang),
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

/// Sequentially fires mock radar pings so the dev can experience every
/// notification + profile card UI state without any real BLE scanning.
///
/// Schedule:
///   t+2s  → Nika (22F)   — first ping
///   t+6s  → Luka (26M)   — second ping
///   t+11s → Sara (24F)   — third ping
///
/// Each ping:
///   1. Sets a random visual angle/distance on the radar canvas.
///   2. After 1.5s sweep, shows the MatchDialog (same as a real BLE match).
void _injectMockRadarPings(WidgetRef ref) {
  if (!kDebugMode) return; // Hard guard — never runs in prod

  // We simulate a single user approaching to demonstrate the dynamic feedback
  final user = kMockNearbyUsers[0];

  for (var i = 0; i <= 8; i++) {
    final delay = Duration(seconds: 2 + (i * 2));
    final distance = 0.9 - (i * 0.1); // 0.9 -> 0.8 -> ... -> 0.1

    Future.delayed(delay, () {
      // Set visual ping on radar canvas
      const angle = 0.8; // Fixed angle for tracking feel
      ref.read(pingAngleProvider.notifier).state = angle;
      ref.read(pingDistanceProvider.notifier).state = distance;

      // When very close, finalize with the MatchDialog after a short delay
      if (i == 8) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          ref.read(pingAngleProvider.notifier).state = null;
          ref.read(pingDistanceProvider.notifier).state = null;
          ref.read(matchControllerProvider.notifier).setMatch(user);
        });
      }
    });
  }
}

// navIndexProvider is intentionally defined here (after HomeScreen) so it is
// a global Riverpod provider that persists across GoRouter rebuilds.
// The Settings tab index is preserved when returning from pushed routes
// like /profile-preview or /edit-profile.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Amber animated pill shown on the Radar screen when the background engine
/// is in battery-saver (degraded) mode — BLE off, Geo-only matching.
class _PowerSavePill extends StatefulWidget {
  final int batteryLevel;
  final String lang;
  const _PowerSavePill({required this.batteryLevel, required this.lang});

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
              '${t('radar_power_save', widget.lang)}  •  ${widget.batteryLevel}%',
              style: TrembleTheme.telemetryTextStyle(
                context,
                color: Colors.black87,
              ).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRadarButton extends StatefulWidget {
  final bool isScanning;
  final VoidCallback onTap;

  const _PulsingRadarButton({required this.isScanning, required this.onTap});

  @override
  State<_PulsingRadarButton> createState() => _PulsingRadarButtonState();
}

class _PulsingRadarButtonState extends State<_PulsingRadarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isScanning) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(_PulsingRadarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // SizedBox provides a fixed canvas so ripple rings don't get clipped
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Expanding ripple rings when scanning
            if (widget.isScanning)
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final progress =
                        (_pulseController.value + (index * 0.33)) % 1.0;
                    return Container(
                      width: 130.0 + (120.0 * progress),
                      height: 130.0 + (120.0 * progress),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 1.0 - progress),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                );
              }),

            // Core button
            GlassCard(
              opacity: 0.15,
              borderRadius: 100,
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: widget.isScanning
                    ? TrembleLogo(key: const ValueKey('logo'), size: 90)
                    : Icon(
                        LucideIcons.play,
                        key: const ValueKey('play'),
                        size: 60,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
