import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'radar_animation.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/liquid_nav_bar.dart'; // Import LiquidNavBar
import '../../settings/presentation/settings_screen.dart';
import '../../map/presentation/tremble_map_screen.dart';
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
import '../../../core/android_integration_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/radar_search_overlay.dart';
import 'widgets/radar_schedule_modal.dart';
import 'widgets/wave_simulation_overlay.dart';
import '../../profile/data/profile_repository.dart';
import '../application/dev_simulation_controller.dart';
import '../application/radar_search_session.dart';
import '../../match/presentation/widgets/match_notification_pill.dart';
import '../../../shared/ui/premium_paywall.dart';
import '../../gym/application/gym_mode_controller.dart';
import '../../gym/application/gym_dwell_service.dart';
import '../../gym/presentation/gym_mode_sheet.dart';
import '../data/run_club_repository.dart';
import 'widgets/live_run_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // Prevents duplicate recap prompts for the same run session transition.
  bool _runRecapShown = false;

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

    // Legacy proximity ping → MatchDialog flow has been removed.
    // All wave interactions now flow exclusively through MatchNotificationPill,
    // driven by DevSimulationController (and, in production, the future BLE
    // wave controller). See lib/src/features/match/presentation/widgets/
    // match_notification_pill.dart and DevSimPhase mapping below in
    // _phaseToPillState().

    // Listen for Radar state changes pushed from native tile / widget (Android).
    // When the user toggles via QS tile or home-screen widget, this fires and
    // starts/stops the background service to match.
    AndroidIntegrationService.instance.radarStateChanges.listen((active) {
      if (!mounted) return;
      final current = ref.read(isScanningProvider);
      if (active == current) return; // already in sync
      ref.read(isScanningProvider.notifier).state = active;
      if (active) {
        // Android: trampoline service satisfies the 5s startForeground
        // deadline before relay-starting the plugin. iOS: pluginsko pot.
        if (Platform.isAndroid) {
          AndroidIntegrationService.instance.startRadarService();
        } else {
          FlutterBackgroundService().startService();
        }
      } else {
        BleService().stop();
        if (Platform.isAndroid) {
          AndroidIntegrationService.instance.stopRadarService();
        } else {
          FlutterBackgroundService().invoke('stopService', null);
        }
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

    // Listen for Run Club state changes from the background motion service.
    // When the motion filter detects 5+ min of running (or 15+ min stationary),
    // it writes SharedPreferences and signals here. BleService then restarts
    // advertising with the updated manufacturerId (0xFF01 vs 0xFFFF).
    FlutterBackgroundService().on('onRunClubStateChanged').listen((event) {
      if (event == null) return;
      BleService().updateAdvertisingMode();
      final isActive = event['active'] as bool? ?? true;
      if (isActive) {
        _runRecapShown = false; // New run started — reset flag
      } else if (!_runRecapShown && mounted) {
        _runRecapShown = true;
        _showRunRecapPrompt();
      }
    });

    // ── Dev Simulation → Radar Ping bridge ─────────────────────────────────
    // Pipes the dev sim's tracking values into pingDistance/pingAngle so the
    // radar canvas reacts only after a mutual wave (Phase 3 of the plan).
    ref.listen(devSimulationControllerProvider, (prev, next) {
      if (next.isMutualWaveActive) {
        ref.read(pingDistanceProvider.notifier).state = next.pingDistance;
        ref.read(pingAngleProvider.notifier).state = next.pingAngle;
      } else if (prev?.isMutualWaveActive == true) {
        // Search ended — clear the radar ping.
        ref.read(pingDistanceProvider.notifier).state = null;
        ref.read(pingAngleProvider.notifier).state = null;
      }
    });

    // Keep the gym dwell service alive as long as HomeScreen is in the tree.
    ref.watch(gymDwellServiceProvider);

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
    final devSim = ref.watch(devSimulationControllerProvider);

    // ── Run Club Crosses State ───────────────────────────────────────────
    final runCrossesAsync = user != null
        ? ref.watch(activeRunCrossesProvider(user.id))
        : const AsyncValue.data([]);
    final DocumentSnapshot? activeRunCross = runCrossesAsync.maybeWhen(
      data: (docs) => docs.isNotEmpty ? docs.first : null,
      orElse: () => null,
    );

    // Signal pulse key: increments each time a new run encounter arrives,
    // triggering the one-shot expanding ring on the radar canvas.
    final int signalPulseKey = runCrossesAsync.maybeWhen(
      data: (docs) => docs.length,
      orElse: () => 0,
    );

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
            activeMatch,
            devSim,
            signalPulseKey),
        const TrembleMapScreen(),
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
            activeMatch,
            devSim,
            signalPulseKey),
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
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
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
            items: navItems,
            onTap: (index) {
              ref.read(navIndexProvider.notifier).state = index;
            },
          ),
        ),

        // ── Global Match Notification Pill ───────────────────────────────
        // Rendered above all tabs (Radar / Map / People / Settings) AND above
        // the LiquidNavBar so a wave is impossible to miss regardless of which
        // tab the user is on. Driven by DevSimulationController; in production
        // the same hook will be fed by the BLE wave controller.
        if (devSim.hasPillVisible && devSim.profile != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: MatchNotificationPill(
                  name: devSim.profile!.name,
                  age: devSim.profile!.age,
                  imageUrl: devSim.profile!.imageUrl,
                  birthDate: devSim.profile!.birthDate,
                  pillState: _phaseToPillState(devSim.phase),
                  onWave: () {
                    final notifier =
                        ref.read(devSimulationControllerProvider.notifier);
                    if (devSim.phase == DevSimPhase.waitingForAction) {
                      notifier.onUserWave();
                    } else if (devSim.phase == DevSimPhase.waveReceived) {
                      notifier.onUserWaveBack();
                    }
                  },
                  onIgnore: () => ref
                      .read(devSimulationControllerProvider.notifier)
                      .onIgnore(),
                  // Premium → open profile reveal. Free → paywall bottom sheet.
                  // Source of truth for premium gating is AuthUser.isPremium
                  // (same provider used by matches_screen and settings).
                  onTap: () {
                    final tapUser = ref.read(authStateProvider);
                    final tapIsPremium = tapUser?.isPremium == true;
                    if (!tapIsPremium) {
                      PremiumPaywallBottomSheet.show(context);
                      return;
                    }
                    // Synthesize a wave_match.Match from the dev profile so the
                    // production match_reveal route accepts it without a
                    // dev-only sibling. id uses ms-since-epoch (good enough
                    // for an ephemeral dev object — no Firestore write).
                    final now = DateTime.now();
                    final synthesized = wave_match.Match(
                      id: 'dev-${now.microsecondsSinceEpoch}',
                      userIds: [
                        tapUser?.id ?? 'dev-self',
                        devSim.profile!.id,
                      ],
                      createdAt: now,
                      seenBy: [tapUser?.id ?? 'dev-self'],
                      status: 'found',
                      isFound: true,
                      gestures: {
                        (tapUser?.id ?? 'dev-self'): true,
                        devSim.profile!.id: true,
                      },
                      expiresAt: now.add(const Duration(minutes: 30)),
                    );
                    context.pushNamed('match_reveal', extra: synthesized);
                  },
                )
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: -0.4, curve: Curves.easeOutCubic),
              ),
            ),
          ),

        // ── Global Live Run Card ─────────────────────────────────────────
        if (activeRunCross != null && user != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Consumer(
                  builder: (context, ref, child) {
                    final data = activeRunCross.data() as Map<String, dynamic>;
                    final userIds = List<String>.from(data['userIds'] ?? []);
                    final partnerId = userIds.firstWhere((id) => id != user.id,
                        orElse: () => '');
                    if (partnerId.isEmpty) return const SizedBox.shrink();

                    final dismissedBy =
                        List<String>.from(data['dismissedBy'] ?? []);
                    if (dismissedBy.contains(user.id))
                      return const SizedBox.shrink();

                    final profileAsync =
                        ref.watch(publicProfileProvider(partnerId));
                    return profileAsync.when(
                      data: (profile) {
                        return LiveRunCard(
                          name: profile.name,
                          age: profile.age,
                          onWave: () {
                            ref
                                .read(runClubRepositoryProvider)
                                .sendWave(activeRunCross.id, user.id);
                          },
                          onDismiss: () {
                            ref
                                .read(runClubRepositoryProvider)
                                .dismissEncounter(activeRunCross.id, user.id);
                          },
                        )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: -0.4, curve: Curves.easeOutCubic);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
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
      wave_match.Match? activeMatch,
      DevSimulationState devSim,
      int signalPulseKey) {
    final isDegraded = radarMode == 'degraded';
    final lang = ref.watch(appLanguageProvider);
    final bool isDevSearchActive = devSim.isMutualWaveActive;
    final bool isSearchActive = activeMatch != null || isDevSearchActive;
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
                      pingDistance: pingDistance,
                      pingAngle: pingAngle,
                      brandColor: Theme.of(context).primaryColor,
                      signalPulseKey: signalPulseKey,
                    ),
                  ),
                  if (isSearchActive)
                    // Bottom-anchored, NOT centered, NOT dimmed — the radar
                    // canvas + ping must remain 100% visible during a mutual
                    // wave so the user can see the partner approaching.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 120,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: isDevSearchActive
                              ? RadarSearchOverlay(
                                  session: RadarSearchSession(
                                    partnerName: devSim.profile?.name ??
                                        t('someone_nearby', lang),
                                    expiresAt: devSim.mutualWaveExpiresAt ??
                                        DateTime.now()
                                            .add(const Duration(minutes: 30)),
                                    showMutualFlash: devSim.showMutualFlash,
                                    onStop: () => ref
                                        .read(devSimulationControllerProvider
                                            .notifier)
                                        .stopAndPersist(),
                                  ),
                                )
                              : Consumer(
                                  builder: (context, ref, child) {
                                    final partnerId = activeMatch!
                                        .getPartnerId(user?.id ?? '');
                                    final profile = ref.watch(
                                        publicProfileProvider(partnerId));
                                    Widget buildOverlay(String name) =>
                                        RadarSearchOverlay(
                                          session: RadarSearchSession(
                                            partnerName: name,
                                            expiresAt: activeMatch.createdAt
                                                .add(const Duration(
                                                    minutes: 30)),
                                            onStop: () => ref
                                                .read(waveRepositoryProvider)
                                                .markMatchAsFound(
                                                    activeMatch.id),
                                          ),
                                        );
                                    return profile.when(
                                      data: (p) => buildOverlay(p.name),
                                      loading: () =>
                                          const CircularProgressIndicator(),
                                      error: (_, __) => buildOverlay(
                                          t('someone_nearby', lang)),
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
                            // Android 13+: POST_NOTIFICATIONS is a runtime grant.
                            // Without this the foreground service notification
                            // (and our CallStyle live activity) is invisible.
                            if (Platform.isAndroid) {
                              final status =
                                  await Permission.notification.status;
                              if (!status.isGranted) {
                                await Permission.notification.request();
                              }
                            }
                            // Start background service. On Android we go through
                            // RadarForegroundService (trampoline) which calls
                            // startForeground() synchronously on its first line
                            // — that satisfies Android 14+'s 5s deadline and
                            // eliminates ForegroundServiceDidNotStartInTime
                            // crashes. The trampoline then relay-starts
                            // flutter_background_service which boots the Dart
                            // isolate without deadline pressure. iOS keeps
                            // the original plugin path. Same NOTIF_ID 888 +
                            // channel tremble_radar_v2 → no flicker on swap.
                            if (Platform.isAndroid) {
                              await AndroidIntegrationService.instance
                                  .startRadarService();
                            } else {
                              FlutterBackgroundService().startService();
                            }
                            // Flip RadarStateBridge → tile + widget re-tint and
                            // (on the active edge) the rich notification refresh
                            // is broadcast. Notif builder is identical to the
                            // one our trampoline already posted, so this is a
                            // no-op repaint.
                            await AndroidIntegrationService.instance
                                .setRadarActive(true);
                            // BleService must run in the main isolate — flutter_blue_plus
                            // requires an Android Activity which the background isolate
                            // does not have. Gate on GDPR consent before starting.
                            final hasConsent =
                                ref.read(gdprConsentProvider).valueOrNull ??
                                    false;
                            if (hasConsent) {
                              await BleService().start();
                            }

                            // ── Dev Mode: passive-discovery simulation ──────────
                            // Phase 1 fires after 10s — pill first, radar empty
                            // until mutual wave. kDebugMode guards production;
                            // localAdminMode/bypassRadar OR canAccessRadar
                            // both qualify so the sim works whether the dev
                            // is signed in as admin or as a normal verified
                            // user during testing.
                            if (kDebugMode &&
                                (ref.read(bypassRadarProvider) ||
                                    canAccessRadar)) {
                              ref
                                  .read(
                                      devSimulationControllerProvider.notifier)
                                  .start();
                            }
                          } else {
                            // Stop BLE in main isolate and signal background service.
                            await AndroidIntegrationService.instance
                                .setRadarActive(false);
                            BleService().stop();
                            if (Platform.isAndroid) {
                              await AndroidIntegrationService.instance
                                  .stopRadarService();
                            } else {
                              FlutterBackgroundService()
                                  .invoke('stopService', null);
                            }
                            // Cancel any in-flight dev simulation without persisting.
                            if (kDebugMode) {
                              ref
                                  .read(
                                      devSimulationControllerProvider.notifier)
                                  .cancelWithoutPersist();
                            }
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
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
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('system_nominal', lang).toUpperCase(),
                                style: TrembleTheme.telemetryTextStyle(
                                  context,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.5),
                                ).copyWith(fontSize: 10, letterSpacing: 1.5),
                              ),
                            ],
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

        // ── Schedule Radar Clock Icon (top-right, top of stack) ───
        // Placed last so it sits above RadarAnimation's full-bleed canvas
        // and remains tappable. Wrapped in Material for the InkWell ripple.
        Positioned(
          top: MediaQuery.of(context).padding.top + 24,
          right: 12,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showRadarScheduleModal(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  LucideIcons.clock,
                  size: 22,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),

        // ── Gym Mode Button (top-left, top of stack) ─────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 24,
          left: 12,
          child: const _GymModeButton(),
        ),

        // Match notification pill is rendered globally in HomeScreen.build —
        // see the main Stack above the LiquidNavBar. This keeps it visible
        // across Radar / Map / People / Settings tabs.
      ],
    );
  }

  void _showRunRecapPrompt() {
    final lang = ref.read(appLanguageProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          borderColor: Colors.white.withValues(alpha: 0.12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TrembleTheme.rose.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.zap,
                      color: TrembleTheme.rose,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('run_finished_title', lang),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: TrembleTheme.rose.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t('run_finished_sub', lang),
                          style: TrembleTheme.displayFont(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.push('/run-recap');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: TrembleTheme.rose.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.heart,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                t('run_finished_action', lang),
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PillState _phaseToPillState(DevSimPhase phase) {
    switch (phase) {
      case DevSimPhase.waveSent:
        return PillState.waveSent;
      case DevSimPhase.waveReceived:
        return PillState.waveReceived;
      case DevSimPhase.waitingForAction:
      default:
        return PillState.waitingForAction;
    }
  }
}

// navIndexProvider is intentionally defined here (after HomeScreen) so it is
// a global Riverpod provider that persists across GoRouter rebuilds.
// The Settings tab index is preserved when returning from pushed routes
// like /profile-preview or /edit-profile.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Tracks which radar mode icon is selected in the top-left button.
/// Persists across sessions within the same app run.
final selectedRadarModeProvider =
    StateProvider<RadarModeKind>((ref) => RadarModeKind.gym);

/// Top-left radar mode button.
/// Tap → directly activates/deactivates the selected mode (no info dialog).
/// Long-press → bottom sheet to switch between Gym / Event / Run modes.
/// Active mode shows an animated gold circular border around the icon.
class _GymModeButton extends ConsumerStatefulWidget {
  const _GymModeButton();

  @override
  ConsumerState<_GymModeButton> createState() => _GymModeButtonState();
}

class _GymModeButtonState extends ConsumerState<_GymModeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  static const _gold = Color(0xFFF5C842);
  static const _rose = Color(0xFFF4436C);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _syncAnimation(bool isActive) {
    if (isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  void _onTap() {
    final mode = ref.read(selectedRadarModeProvider);
    switch (mode) {
      case RadarModeKind.gym:
        final gymState = ref.read(gymModeControllerProvider);
        if (gymState.isActive) {
          ref.read(gymModeControllerProvider.notifier).deactivate();
        } else {
          _activateGym();
        }
      case RadarModeKind.run:
        final runState = ref.read(runModeControllerProvider);
        if (runState.isActive) {
          ref.read(runModeControllerProvider.notifier).deactivate();
        } else {
          ref.read(runModeControllerProvider.notifier).activate();
        }
      case RadarModeKind.event:
        // Event activation requires picking an event — no standalone sheet yet.
        // Tapping navigates to the People > Event section so the user can
        // initiate activation from there.
        final isPremium = ref.read(authStateProvider)?.isPremium == true;
        ref.read(navIndexProvider.notifier).state = isPremium ? 2 : 1;
        ref.read(matchSectionProvider.notifier).state = MatchSection.event;
    }
  }

  void _onLongPress() {
    final lang = ref.read(appLanguageProvider);
    final selectedMode = ref.read(selectedRadarModeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final items = [
          (RadarModeKind.gym, LucideIcons.dumbbell, t('gym_mode_info_title', lang)),
          (RadarModeKind.event, LucideIcons.calendar, t('event_mode_info_title', lang)),
          (RadarModeKind.run, LucideIcons.footprints, t('run_mode_info_title', lang)),
        ];

        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A18).withValues(alpha: 0.97)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: EdgeInsets.fromLTRB(
                  0, 12, 0, MediaQuery.of(ctx).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ...items.map((item) {
                    final (kind, icon, label) = item;
                    final isSelected = kind == selectedMode;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon,
                            size: 18,
                            color: isSelected ? primary : Colors.white38),
                      ),
                      title: Text(
                        label,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white60,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check,
                              size: 16, color: primary)
                          : null,
                      onTap: () {
                        ref.read(selectedRadarModeProvider.notifier).state =
                            kind;
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _activateGym() {
    GymModeSheet.show(context).then((_) {
      if (!mounted) return;
      final gymState = ref.read(gymModeControllerProvider);
      if (gymState.isActive) {
        final isPremium = ref.read(authStateProvider)?.isPremium == true;
        ref.read(navIndexProvider.notifier).state = isPremium ? 2 : 1;
        ref.read(matchSectionProvider.notifier).state = MatchSection.gym;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gymState = ref.watch(gymModeControllerProvider);
    final runState = ref.watch(runModeControllerProvider);
    final eventState = ref.watch(eventModeControllerProvider);
    final selectedMode = ref.watch(selectedRadarModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAnyActive = switch (selectedMode) {
      RadarModeKind.gym => gymState.isActive,
      RadarModeKind.run => runState.isActive,
      RadarModeKind.event => eventState.isActive,
    };
    _syncAnimation(isAnyActive);

    final (icon, activeColor) = switch (selectedMode) {
      RadarModeKind.gym => (LucideIcons.dumbbell, _gold),
      RadarModeKind.run => (LucideIcons.footprints, _rose),
      RadarModeKind.event => (LucideIcons.calendar, _gold),
    };

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Animated frosted-glass circular border — only when active
            if (isAnyActive)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? activeColor.withValues(alpha: 0.18)
                              : activeColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Mode icon — colored when active
            Icon(
              icon,
              size: 20,
              color: isAnyActive
                  ? activeColor
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
            ),

            // Small colored dot (active indicator)
            if (isAnyActive)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A18) : Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mode kinds (for info popup) ───────────────────────────────────────────────
enum RadarModeKind { gym, run, event }

/// Shows the mode info popup for gym / run / event.
/// [onActivate] is called when the user taps Activate.
/// [onDeactivate] is called when the mode is already active and user deactivates.
Future<void> showModeInfoDialog({
  required BuildContext context,
  required WidgetRef ref,
  required RadarModeKind mode,
  required String lang,
  required bool isActive,
  required VoidCallback onActivate,
  VoidCallback? onDeactivate,
}) async {
  final (titleKey, bodyKey, icon) = switch (mode) {
    RadarModeKind.gym => ('gym_mode_info_title', 'gym_mode_info_body', LucideIcons.dumbbell),
    RadarModeKind.run => ('run_mode_info_title', 'run_mode_info_body', LucideIcons.personStanding),
    RadarModeKind.event => ('event_mode_info_title', 'event_mode_info_body', LucideIcons.calendar),
  };

  final dontShowNotifier = ValueNotifier<bool>(false);

  final primary = Theme.of(context).colorScheme.primary;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const gold = Color(0xFFF5C842);
  final ringColor = isActive ? gold : primary;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1C).withValues(alpha: 0.97)
                    : Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: ringColor.withValues(alpha: 0.30),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ringColor.withValues(alpha: 0.12),
                        border: Border.all(
                          color: ringColor.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: ringColor, size: 24),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      t(titleKey, lang),
                      style: TrembleTheme.displayFont(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A18),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Body
                    Text(
                      t(bodyKey, lang),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF1A1A18).withValues(alpha: 0.6),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Don't show again checkbox
                    ValueListenableBuilder<bool>(
                      valueListenable: dontShowNotifier,
                      builder: (_, val, __) => GestureDetector(
                        onTap: () => dontShowNotifier.value = !val,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: val
                                    ? primary.withValues(alpha: 0.9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: val
                                      ? primary
                                      : Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: val
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('mode_info_dont_show', lang),
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons row
                    Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                t('cancel', lang),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Activate / Deactivate
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              if (isActive) {
                                onDeactivate?.call();
                              } else {
                                onActivate();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.redAccent.withValues(alpha: 0.85)
                                    : primary,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isActive ? Colors.redAccent : primary)
                                        .withValues(alpha: 0.30),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                isActive
                                    ? t('gym_mode_info_deactivate', lang)
                                        .toUpperCase()
                                    : t('gym_mode_info_activate', lang)
                                        .toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

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

            GlassCard(
              opacity: 0.15,
              borderRadius: 100,
              padding: const EdgeInsets.all(20),
              child: TrembleLogo(
                key: const ValueKey('logo'),
                size: 90,
                isAnimated: widget.isScanning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
