import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'radar_animation.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/liquid_nav_bar.dart'; // Import LiquidNavBar
import '../../../shared/ui/form_factor.dart'; // Foldable form-factor adaptation
import '../../../shared/ui/warmth_empty_state.dart';
import '../../../shared/ui/tremble_loading_spinner.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../map/presentation/tremble_map_screen.dart';
import '../../../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../../shared/ui/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/notification_service.dart'; // FCM Notifications
import '../../../core/ble_service.dart'; // BLE must run in main isolate
import '../../../core/ble_restore_service.dart'; // iOS BLE state restoration
import '../../../core/geo_service.dart';
import '../../../shared/widgets/tremble_radar_heart.dart';
import '../../../shared/widgets/running_stickman.dart';
import '../../../core/consent_service.dart'; // gdprConsentProvider
import 'package:flutter_animate/flutter_animate.dart'; // Animations
import '../../../core/translations.dart';
import '../../match/application/match_service.dart';
import '../../match/data/wave_repository.dart';
import '../../match/domain/match.dart' as wave_match;
import '../../../core/radar_integration_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/radar_search_overlay.dart';
import 'widgets/radar_schedule_modal.dart';
import 'widgets/premium_tutorial_overlay.dart';
import '../../profile/data/profile_repository.dart';
import '../application/dev_simulation_controller.dart';
import '../application/radar_search_session.dart';
import '../application/tutorial_notifier.dart';
import '../../match/presentation/widgets/match_notification_pill.dart';
import '../../../shared/ui/wave_pill_service.dart';
import '../../../shared/ui/premium_paywall.dart';
import 'package:geolocator/geolocator.dart';
import '../../gym/application/gym_mode_controller.dart';
import '../../gym/data/gym_repository.dart';
import '../../gym/presentation/gym_mode_sheet.dart';
import '../../gym/application/gym_dwell_service.dart';
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

  static final GlobalKey homeStackKey = GlobalKey(debugLabel: 'homeStackKey');

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // Prevents duplicate recap prompts for the same run session transition.
  bool _runRecapShown = false;
  bool _tutorialOptInShowing = false;

  // Background service / native bridge subscriptions. Registered once in
  // initState and cancelled in dispose so async events cannot fire against a
  // disposed ref. Prior to this fix these were registered inside build(),
  // which both leaked subscriptions on every rebuild and produced the
  // "Cannot use ref after the widget was disposed" crash (Sentry 131353377)
  // when a background radarState event arrived post-dispose.
  StreamSubscription<bool>? _radarStateChangesSub;
  StreamSubscription<Map<String, dynamic>?>? _radarStateSub;
  StreamSubscription<Map<String, dynamic>?>? _runClubStateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-warm the swipe-hint counter so shouldShowHint is accurate on first pill show.
    WavePillService.preloadHintCount();

    // Native tile / widget → radar toggle bridge.
    _radarStateChangesSub =
        RadarIntegrationService.instance.radarStateChanges.listen((active) {
      if (!mounted) return;
      final current = ref.read(isScanningProvider);
      if (active == current) return; // already in sync
      ref.read(isScanningProvider.notifier).state = active;
      if (active) {
        unawaited(
          _syncBackgroundEffectivePremium(ref.read(effectiveIsPremiumProvider)),
        );
        // Android: trampoline service satisfies the 5s startForeground
        // deadline before relay-starting the plugin. iOS: no-op.
        if (Platform.isAndroid) {
          RadarIntegrationService.instance.startRadarService();
        } else {
          FlutterBackgroundService().startService();
        }
      } else {
        BleService().stop();
        if (Platform.isAndroid) {
          RadarIntegrationService.instance.stopRadarService();
        } else {
          FlutterBackgroundService().invoke('stopService', null);
        }
      }
    });

    // Radar mode / battery updates pushed from the background service isolate.
    _radarStateSub =
        FlutterBackgroundService().on('radarState').listen((event) {
      if (!mounted || event == null) return;
      final mode = event['mode'] as String? ?? 'full';
      final battery = event['batteryLevel'] as int? ?? 100;
      ref.read(radarModeProvider.notifier).state = mode;
      ref.read(radarBatteryLevelProvider.notifier).state = battery;
    });

    // Run Club state changes from the background motion service. When the
    // motion filter detects 5+ min of running (or 15+ min stationary),
    // BleService restarts advertising with the updated manufacturerId
    // (0xFF01 vs 0xFFFF).
    _runClubStateSub =
        FlutterBackgroundService().on('onRunClubStateChanged').listen((event) {
      if (!mounted || event == null) return;
      BleService().updateAdvertisingMode();
      final isActive = event['active'] as bool? ?? true;
      if (isActive) {
        _runRecapShown = false; // New run started — reset flag
      } else if (!_runRecapShown) {
        _runRecapShown = true;
        _showRunRecapPrompt();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Register FCM Token on dashboard load
      final user = ref.read(authStateProvider);
      if (user != null) {
        NotificationService.saveToken(user.id);
        BleRestoreService().initialize();
        NotificationService.initialize(
          onForegroundWave: ({
            required String name,
            required int age,
            required String imageUrl,
            required String targetUid,
            required bool isIncomingWave,
          }) {
            if (!mounted) return;
            WavePillService.show(
              overlay: Overlay.of(context),
              data: WavePillData(
                name: name,
                age: age,
                imageUrl: imageUrl,
                targetUid: targetUid,
                isIncomingWave: isIncomingWave,
              ),
              onWave: (uid) async {
                final user = ref.read(authStateProvider);
                if (user?.hasReachedWaveLimit == true) {
                  PremiumPaywallBottomSheet.show(context);
                  return;
                }
                await ref.read(waveRepositoryProvider).sendWave(uid);
              },
            );
          },
        );
      }
      ref.read(tutorialProvider.notifier).checkFirstLaunch();
    });
  }

  @override
  void dispose() {
    _radarStateChangesSub?.cancel();
    _radarStateSub?.cancel();
    _runClubStateSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // iOS keeps CBCentralManager scanning under the `bluetooth-central`
    // background mode, so stopping BLE on pause would kill proximity
    // detection the moment the app backgrounds. Only Android — which
    // lacks an equivalent activity-less BLE mode — needs the pause stop.
    if (state == AppLifecycleState.paused && Platform.isAndroid) {
      BleService().stop();
    } else if (state == AppLifecycleState.resumed) {
      BleService().start();
      ref.invalidate(bluetoothPermissionStatusProvider);
    }
  }

  Future<void> _syncBackgroundEffectivePremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(geoServiceEffectivePremiumPrefsKey, isPremium);
    FlutterBackgroundService().invoke(
      'effectivePremiumChanged',
      {'isPremium': isPremium},
    );
  }

  Future<void> _showTutorialOptInSheet() async {
    final lang = ref.read(appLanguageProvider);
    final tutorialNotifier = ref.read(tutorialProvider.notifier);
    final navNotifier = ref.read(navIndexProvider.notifier);
    final radarModeNotifier = ref.read(selectedRadarModeProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        const textColor = Colors.white;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: GlassCard(
            borderRadius: 24,
            useGlassEffect: false,
            solidDarkBg: const Color(0xFF2A2A3E),
            borderColor: TrembleTheme.rose.withValues(alpha: 0.28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('tutorial_opt_in_title', lang),
                  style: GoogleFonts.lora(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t('tutorial_opt_in_desc', lang),
                  style: GoogleFonts.instrumentSans(
                    color: textColor.withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await tutorialNotifier.completeTutorial();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(t('tutorial_opt_in_no', lang)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrembleTheme.rose,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          navNotifier.state = 0;
                          radarModeNotifier.state = RadarModeKind.gym;
                          tutorialNotifier.startTutorial();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(t('tutorial_opt_in_yes', lang)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) {
      _tutorialOptInShowing = false;
    }
  }

  void _handleTutorialNavTap({
    required int index,
    required bool isPremium,
  }) {
    final tutorial = ref.read(tutorialProvider);
    if (!tutorial.isActive) return;

    final mapIndex = isPremium ? 1 : -1;
    final peopleIndex = isPremium ? 2 : 1;
    final settingsIndex = isPremium ? 3 : 2;

    if (tutorial.currentStep == 2 && index == mapIndex) {
      ref.read(tutorialProvider.notifier).nextStep();
      return;
    }
    if (tutorial.currentStep == 3 && index == peopleIndex) {
      _showTutorialStepPopup(step: 3);
      return;
    }
    if (tutorial.currentStep == 4 && index == settingsIndex) {
      _showTutorialStepPopup(step: 4);
    }
  }

  Future<void> _showTutorialStepPopup({required int step}) async {
    final lang = ref.read(appLanguageProvider);
    final navNotifier = ref.read(navIndexProvider.notifier);
    final tutorialNotifier = ref.read(tutorialProvider.notifier);

    tutorialNotifier.setPopupActive(true);

    // Let the overlay rebuild and hide the card in the current frame before showing the dialog
    await Future<void>.delayed(Duration.zero);

    try {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (ctx) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassCard(
              borderRadius: 24,
              borderColor: TrembleTheme.rose.withValues(alpha: 0.34),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t('tutorial_step${step}_popup_title', lang),
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('tutorial_step${step}_popup_desc', lang),
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrembleTheme.rose,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        child: Text(t('tutorial_got_it', lang)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      tutorialNotifier.setPopupActive(false);
    }

    if (step == 4) {
      navNotifier.state = 0;
    }
    await tutorialNotifier.nextStep();
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
        unawaited(Future<void>.delayed(
          const Duration(milliseconds: 400),
          () {
            if (mounted) {
              WavePillService.dismiss();
              context.pushNamed('match_reveal', extra: unseenMatch);
            }
          },
        ));
      }
    });

    // Legacy proximity ping → MatchDialog flow has been removed.
    // All wave interactions now flow exclusively through MatchNotificationPill,
    // driven by DevSimulationController (and, in production, the future BLE
    // wave controller). See lib/src/features/match/presentation/widgets/
    // match_notification_pill.dart and DevSimPhase mapping below in
    // _phaseToPillState().
    //
    // The native tile / widget bridge (radarStateChanges), the background
    // radarState event, and the onRunClubStateChanged event are all wired
    // once in initState and cancelled in dispose. Registering them here in
    // build() previously leaked a subscription per rebuild and crashed with
    // "Cannot use ref after the widget was disposed" when events fired
    // post-dispose (Sentry 131353377).

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

    final lang = ref.watch(appLanguageProvider);
    final navIndex = ref.watch(navIndexProvider);

    // Reactive mapping of active nav index during Premium/Free transitions
    ref.listen<bool>(
      effectiveIsPremiumProvider,
      (previous, next) {
        if (previous == null) return;
        if (previous != next) {
          unawaited(_syncBackgroundEffectivePremium(next));
          final currentIndex = ref.read(navIndexProvider);
          if (next) {
            // Downgrade to Upgrade: Free (3 tabs) -> Premium (4 tabs)
            // Free: 0: Radar, 1: Matches, 2: Settings
            // Premium: 0: Radar, 1: Map, 2: Matches, 3: Settings
            if (currentIndex == 1) {
              ref.read(navIndexProvider.notifier).state =
                  2; // Matches stays Matches
            } else if (currentIndex == 2) {
              ref.read(navIndexProvider.notifier).state =
                  3; // Settings stays Settings
            }
          } else {
            // Upgrade to Downgrade: Premium (4 tabs) -> Free (3 tabs)
            // Premium: 0: Radar, 1: Map, 2: Matches, 3: Settings
            // Free: 0: Radar, 1: Matches, 2: Settings
            if (currentIndex == 1) {
              ref.read(navIndexProvider.notifier).state =
                  0; // Map redirects to Radar
            } else if (currentIndex == 2) {
              ref.read(navIndexProvider.notifier).state =
                  1; // Matches stays Matches
            } else if (currentIndex == 3) {
              ref.read(navIndexProvider.notifier).state =
                  2; // Settings stays Settings
            }
          }
        }
      },
    );

    ref.listen<TutorialState>(tutorialProvider, (previous, next) {
      if (!next.showOptIn || _tutorialOptInShowing || !mounted) return;
      _tutorialOptInShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorialOptInSheet();
      });
    });

    final bool isPremium = ref.watch(effectiveIsPremiumProvider);

    // Define Screens and Nav Items
    final List<Widget> screens;
    final List<LiquidNavItem> navItems;
    final radarScreen = _RadarSection(
      isPremium: isPremium,
      lang: lang,
      builder: _buildRadarView,
    );

    if (isPremium) {
      screens = [
        radarScreen,
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
        radarScreen,
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

    // Defensively clamp navIndex to prevent out of bounds RangeErrors
    // during fast state/role transitions or initial bootup.
    final int safeNavIndex = navIndex.clamp(0, screens.length - 1);

    final hideNavBarPref = ref.watch(hideNavBarPrefProvider);
    final isNavBarVisible = ref.watch(isNavBarVisibleProvider);

    // Foldable form factor. STANDARD phones keep the existing layout exactly;
    // only the compact (flip cover) and expanded (Fold inner) surfaces adapt.
    final formFactor = formFactorOf(context);
    final isCompact = formFactor == FormFactor.compact;
    final isExpanded = formFactor == FormFactor.expanded;
    // Cutout/gesture-bar safe gap below the floating nav bar. Standard phones
    // keep the original fixed 30px; foldables add the device's bottom inset so
    // the bar never sits under a camera cutout or gesture handle.
    final double navBottomGap = formFactor == FormFactor.standard
        ? 30
        : 30 + MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      key: HomeScreen.homeStackKey,
      fit: StackFit.expand,
      children: [
        // Content with Liquid Transition
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (isPremium && safeNavIndex == 1)
                ? null
                : (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -300) {
                      final next =
                          (safeNavIndex + 1).clamp(0, screens.length - 1);
                      if (next != safeNavIndex) {
                        HapticFeedback.selectionClick();
                        ref.read(navIndexProvider.notifier).state = next;
                      }
                    } else if (velocity > 300) {
                      final prev =
                          (safeNavIndex - 1).clamp(0, screens.length - 1);
                      if (prev != safeNavIndex) {
                        HapticFeedback.selectionClick();
                        ref.read(navIndexProvider.notifier).state = prev;
                      }
                    }
                  },
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
                  key: ValueKey<int>(safeNavIndex),
                  // On the unfolded Fold inner screen, keep the phone-tuned
                  // layout centered within a max width instead of stretching
                  // edge to edge. No effect on standard / compact surfaces.
                  child: isExpanded
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: kExpandedContentMaxWidth,
                            ),
                            child: screens[safeNavIndex],
                          ),
                        )
                      : screens[safeNavIndex],
                ),
              ),
            ),
          ),
        ),

        // Floating Liquid Navigation Bar
        _BottomNavBar(
          navItems: navItems,
          screensLength: screens.length,
          isPremium: isPremium,
          isCompact: isCompact,
          navBottomGap: navBottomGap,
          onTutorialNavTap: _handleTutorialNavTap,
        ),

        // ── Global Match Notification Pill ───────────────────────────────
        // Rendered above all tabs (Radar / Map / People / Settings) AND above
        // the LiquidNavBar so a wave is impossible to miss regardless of which
        // tab the user is on. Driven by DevSimulationController; in production
        // the same hook will be fed by the BLE wave controller.
        const _MatchNotificationPillOverlay(),

        // ── Global Live Run / Near-Miss Overlay + Gym Dwell + Tutorial ──
        _OverlayStack(lang: lang),
      ],
    );
  }

  Future<void> _showDeactivateModeDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String activeModeName,
    required VoidCallback onDeactivate,
    required String lang,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

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
                    color: primary.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.12),
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
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(LucideIcons.power,
                            color: Colors.redAccent, size: 24),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        lang == 'sl'
                            ? 'Izklopi $activeModeName?'
                            : 'Deactivate $activeModeName?',
                        style: TrembleTheme.displayFont(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : TrembleTheme.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang == 'sl'
                            ? 'Ali ste prepričani, da želite izklopiti $activeModeName in prenehati z ujemanjem v tem načinu?'
                            : 'Are you sure you want to turn off $activeModeName and stop matching in this mode?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : TrembleTheme.textColor.withValues(alpha: 0.6),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  t('cancel', lang),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.instrumentSans(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                onDeactivate();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.30),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  lang == 'sl' ? 'IZKLOPI' : 'DEACTIVATE',
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
      bool showNearMissEmpty,
      DevSimulationState devSim,
      int signalPulseKey,
      String lang,
      bool gymModeActive,
      bool runModeActive,
      bool eventModeActive) {
    final bool isAnyModeActive =
        gymModeActive || runModeActive || eventModeActive;
    final isDegraded = radarMode == 'degraded';
    final radarTutorialState = ref.watch(
      tutorialProvider.select(
        (state) => (
          isActive: state.isActive,
          currentStep: state.currentStep,
        ),
      ),
    );
    final bleIssue = canAccessRadar ? ref.watch(radarBleIssueProvider) : null;
    final bool isDevSearchActive = devSim.isMutualWaveActive;
    final bool isSearchActive = activeMatch != null || isDevSearchActive;
    return Stack(
      children: [
        // Radar View (Conditional)
        canAccessRadar
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: RadarAnimation(
                      isScanning: (isScanning || isAnyModeActive) &&
                          !isSearchActive &&
                          bleIssue ==
                              null, // stop visual pulse if searching/blocked
                      isVibrationEnabled: user?.isPingVibrationEnabled ?? true,
                      pingDistance: pingDistance,
                      pingAngle: pingAngle,
                      brandColor: Theme.of(context).primaryColor,
                      signalPulseKey: signalPulseKey,
                    ),
                  ),
                  if (bleIssue != null)
                    Center(
                      child: RadarBleIssueMessage(
                        issue: bleIssue,
                        onOpenSettings: () {
                          openAppSettings();
                          ref.invalidate(bluetoothAdapterStateProvider);
                          ref.invalidate(bluetoothPermissionStatusProvider);
                        },
                        onGrantPermission: () async {
                          await ConsentService.requestBluetooth();
                          ref.invalidate(bluetoothPermissionStatusProvider);
                        },
                      ),
                    )
                  else if (isSearchActive)
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
                                      loading: () => TrembleLoadingSpinner(
                                        style: LoadingStyle.dynamic,
                                        duration: const Duration(seconds: 2),
                                        messages: [
                                          t('loading_scanning', lang),
                                          t('loading_connecting', lang),
                                          t('loading_signals', lang),
                                        ],
                                      ),
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
                      child: _TutorialTarget(
                        step: 5,
                        child: _PulsingRadarButton(
                          isScanning: isScanning,
                          isHighlighted: radarTutorialState.isActive &&
                              radarTutorialState.currentStep == 5,
                          onTap: () async {
                            final selectedMode =
                                ref.read(selectedRadarModeProvider);
                            final gymState =
                                ref.read(gymModeControllerProvider);
                            final runState =
                                ref.read(runModeControllerProvider);
                            final eventState =
                                ref.read(eventModeControllerProvider);

                            if (selectedMode == RadarModeKind.gym) {
                              if (gymState.isActive) {
                                unawaited(_showDeactivateModeDialog(
                                  context: context,
                                  ref: ref,
                                  activeModeName: lang == 'sl'
                                      ? 'Način za fitnes'
                                      : 'Gym Mode',
                                  lang: lang,
                                  onDeactivate: () {
                                    ref
                                        .read(
                                            gymModeControllerProvider.notifier)
                                        .deactivate();
                                  },
                                ));
                              } else {
                                GymModeSheet.show(context);
                              }
                              return;
                            }

                            if (selectedMode == RadarModeKind.run) {
                              // A single tap toggles Run Mode directly — no
                              // deactivation confirmation dialog.
                              if (runState.isActive) {
                                ref
                                    .read(runModeControllerProvider.notifier)
                                    .deactivate();
                              } else {
                                ref
                                    .read(runModeControllerProvider.notifier)
                                    .activate();
                              }
                              return;
                            }

                            if (selectedMode == RadarModeKind.event) {
                              if (eventState.isActive) {
                                unawaited(_showDeactivateModeDialog(
                                  context: context,
                                  ref: ref,
                                  activeModeName: lang == 'sl'
                                      ? 'Način za dogodke'
                                      : 'Event Mode',
                                  lang: lang,
                                  onDeactivate: () {
                                    ref
                                        .read(eventModeControllerProvider
                                            .notifier)
                                        .deactivate();
                                  },
                                ));
                              } else {
                                unawaited(_activateEventMode());
                              }
                              return;
                            }

                            // Otherwise, selectedMode == RadarModeKind.radar (Tremble Radar Mode)
                            final newState = !isScanning;
                            ref.read(isScanningProvider.notifier).state =
                                newState;

                            if (newState) {
                              if (kDebugMode) {
                                debugPrint(
                                    '[Radar] location captured by GeoService');
                              }
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
                                await _syncBackgroundEffectivePremium(
                                    isPremium);
                                await RadarIntegrationService.instance
                                    .startRadarService();
                              } else {
                                await _syncBackgroundEffectivePremium(
                                    isPremium);
                                FlutterBackgroundService().startService();
                              }
                              // Flip RadarStateBridge → tile + widget re-tint and
                              // (on the active edge) the rich notification refresh
                              // is broadcast. Notif builder is identical to the
                              // one our trampoline already posted, so this is a
                              // no-op repaint.
                              await RadarIntegrationService.instance
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
                                    .read(devSimulationControllerProvider
                                        .notifier)
                                    .start();
                              }
                            } else {
                              // Stop BLE in main isolate and signal background service.
                              await RadarIntegrationService.instance
                                  .setRadarActive(false);
                              BleService().stop();
                              if (Platform.isAndroid) {
                                await RadarIntegrationService.instance
                                    .stopRadarService();
                              } else {
                                FlutterBackgroundService()
                                    .invoke('stopService', null);
                              }
                              // Cancel any in-flight dev simulation without persisting.
                              if (kDebugMode) {
                                ref
                                    .read(devSimulationControllerProvider
                                        .notifier)
                                    .cancelWithoutPersist();
                              }
                            }
                            if (radarTutorialState.isActive &&
                                radarTutorialState.currentStep == 5) {
                              await ref
                                  .read(tutorialProvider.notifier)
                                  .completeTutorial();
                            }
                          },
                        ),
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
                              if (pingDistance == null) ...[
                                const SizedBox(height: 18),
                                WarmthEmptyState(
                                  title: t('radar_empty_title', lang),
                                  subtitle: t('radar_empty_sub', lang),
                                ),
                              ],
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

        // ── Radar Header ─────────────────────────────────────────
        // Placed AFTER the radar view so it renders on top of
        // RadarAnimation's full-bleed canvas and receives gestures.
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Mode icon
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedMode = ref.watch(selectedRadarModeProvider);

                      final isActive = switch (selectedMode) {
                        RadarModeKind.gym => ref.watch(
                            gymModeControllerProvider.select(
                              (state) => state.isActive,
                            ),
                          ),
                        RadarModeKind.run => ref.watch(
                            runModeControllerProvider.select(
                              (state) => state.isActive,
                            ),
                          ),
                        RadarModeKind.event => ref.watch(
                            eventModeControllerProvider.select(
                              (state) => state.isActive,
                            ),
                          ),
                        RadarModeKind.radar => isScanning,
                      };
                      final tutorialHeaderState = ref.watch(
                        tutorialProvider.select(
                          (state) => (
                            isActive: state.isActive,
                            currentStep: state.currentStep,
                          ),
                        ),
                      );

                      final (modeIcon, modeColor) = switch (selectedMode) {
                        RadarModeKind.gym => (
                            LucideIcons.dumbbell,
                            TrembleTheme.accentYellow
                          ),
                        RadarModeKind.run => (
                            LucideIcons.footprints,
                            TrembleTheme.rose
                          ),
                        RadarModeKind.event => (
                            LucideIcons.calendar,
                            TrembleTheme.accentYellow
                          ),
                        RadarModeKind.radar => (
                            LucideIcons.radar,
                            Theme.of(context).primaryColor
                          ),
                      };

                      return _TutorialTarget(
                        step: 0,
                        child: _PulseIcon(
                          icon: modeIcon,
                          color: modeColor,
                          isActive: isActive,
                          isHighlighted: tutorialHeaderState.isActive &&
                              tutorialHeaderState.currentStep == 0,
                          onTap: () {
                            _showModeSelector(context);
                            if (tutorialHeaderState.isActive &&
                                tutorialHeaderState.currentStep == 0) {
                              ref.read(tutorialProvider.notifier).nextStep();
                            }
                          },
                        ),
                      );
                    },
                  ),

                  // Center: Tremble text
                  Text(
                    'Tremble',
                    style: TrembleTheme.displayFont(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // Right: Schedule icon
                  const _TutorialTarget(
                    step: 1,
                    child: _RadarScheduleButton(),
                  ),
                ],
              ),
            ),
          ),
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

  void _showModeSelector(BuildContext context) {
    final lang = ref.read(appLanguageProvider);
    final accentColor = Theme.of(context).primaryColor;

    // Mode configuration
    final items = [
      (
        RadarModeKind.radar,
        LucideIcons.radar,
        lang == 'sl' ? 'Tremble Radar način' : 'Tremble Radar Mode',
        accentColor
      ),
      (
        RadarModeKind.gym,
        LucideIcons.dumbbell,
        t('gym_mode_info_title', lang),
        accentColor
      ),
      (
        RadarModeKind.event,
        LucideIcons.calendar,
        t('event_mode_info_title', lang),
        accentColor
      ),
      (
        RadarModeKind.run,
        LucideIcons.footprints,
        t('run_mode_info_title', lang),
        accentColor
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? TrembleTheme.textColor.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(ctx).padding.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Text(
                      t('select_radar_mode', lang),
                      style: TrembleTheme.displayFont(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : TrembleTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mode List
                    Consumer(
                      builder: (context, ref, child) {
                        final currentSelected =
                            ref.watch(selectedRadarModeProvider);

                        return Column(
                          children: items.map((item) {
                            final (kind, icon, label, color) = item;
                            final isSelected = kind == currentSelected;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  if (kind != currentSelected) {
                                    final gymState =
                                        ref.read(gymModeControllerProvider);
                                    final runState =
                                        ref.read(runModeControllerProvider);
                                    final eventState =
                                        ref.read(eventModeControllerProvider);
                                    final isScanning =
                                        ref.read(isScanningProvider);
                                    // Deactivate all specialized active modes since we are changing selection
                                    if (gymState.isActive) {
                                      ref
                                          .read(gymModeControllerProvider
                                              .notifier)
                                          .deactivate();
                                    }
                                    if (runState.isActive) {
                                      ref
                                          .read(runModeControllerProvider
                                              .notifier)
                                          .deactivate();
                                    }
                                    if (eventState.isActive) {
                                      ref
                                          .read(eventModeControllerProvider
                                              .notifier)
                                          .deactivate();
                                    }
                                    // If scanning is active and we select a specialized mode, stop scanning
                                    if (kind != RadarModeKind.radar &&
                                        isScanning) {
                                      ref
                                          .read(isScanningProvider.notifier)
                                          .state = false;
                                      BleService().stop();
                                      if (Platform.isAndroid) {
                                        RadarIntegrationService.instance
                                            .stopRadarService();
                                      } else {
                                        FlutterBackgroundService()
                                            .invoke('stopService', null);
                                      }
                                      RadarIntegrationService.instance
                                          .setRadarActive(false);
                                    }
                                    ref
                                        .read(
                                            selectedRadarModeProvider.notifier)
                                        .state = kind;
                                  }
                                  Navigator.pop(ctx);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.black
                                                .withValues(alpha: 0.03)),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.5)
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.08)),
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.2),
                                              blurRadius: 15,
                                              spreadRadius: -2,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withValues(alpha: 0.25)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.08)
                                                  : Colors.black
                                                      .withValues(alpha: 0.05)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          size: 22,
                                          color: isSelected
                                              ? color
                                              : (isDark
                                                  ? Colors.white60
                                                  : Colors.black54),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 17,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : TrembleTheme.rose)
                                                : (isDark
                                                    ? Colors.white
                                                    : Colors.black87),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: color,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _activateEventMode() async {
    final lang = ref.read(appLanguageProvider);
    await showEventActivationFlow(context, ref, lang);
  }
}

/// Fetches active events, sorts by proximity/time, and shows a selection sheet.
/// If no events are found, shows a "No events nearby" snackbar instead.
/// Exported so it can be called from matches_screen.dart without circular import issues.
Future<void> showEventActivationFlow(
  BuildContext context,
  WidgetRef ref,
  String lang,
) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(lang == 'sl'
          ? 'Lokacija je potrebna za Event Mode.'
          : 'Location is required for Event Mode.'),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  final gymRepo = ref.read(gymRepositoryProvider);
  List<TrembleEvent> events;
  try {
    events = await gymRepo.getActiveEvents();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(lang == 'sl'
          ? 'Napaka pri nalaganju dogodkov.'
          : 'Failed to load events.'),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  if (!context.mounted) return;

  if (events.isEmpty) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return Center(
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
                      color: primary.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
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
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.calendar,
                            color: primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          t('event_no_nearby', lang),
                          style: TrembleTheme.displayFont(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : TrembleTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          switch (lang) {
                            'sl' =>
                              'V vaši bližini trenutno ni aktivnih dogodkov. Poskusite znova kasneje.',
                            'hr' ||
                            'sr' =>
                              'Trenutno nema aktivnih događaja u vašoj blizini. Pokušajte ponovo kasnije.',
                            'de' =>
                              'Derzeit gibt es keine aktiven Events in Ihrer Nähe. Bitte versuchen Sie es später noch einmal.',
                            'it' =>
                              'Al momento non ci sono eventi attivi nelle vicinanze. Riprova più tardi.',
                            'fr' =>
                              'Il n\'y a actuellement aucun événement actif à proximité. Veuillez réessayer plus tard.',
                            'hu' =>
                              'Jelenleg nincsenek aktív események a közelben. Kérjük, próbálja meg később.',
                            _ =>
                              'There are currently no active events in your area. Please check back later.',
                          },
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            height: 1.45,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.70)
                                : TrembleTheme.textColor
                                    .withValues(alpha: 0.70),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              t('ok', lang),
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return;
  }

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 5));
  } catch (e, st) {
    debugPrint('[HomeScreen] caught: $e\n$st');
  }

  if (position != null) {
    final pos = position;
    events.sort((a, b) {
      if (a.lat == null || a.lng == null) return 1;
      if (b.lat == null || b.lng == null) return -1;
      final da = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, a.lat!, a.lng!);
      final db = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, b.lat!, b.lng!);
      return da.compareTo(db);
    });
  } else {
    events.sort((a, b) {
      if (a.startsAt == null) return 1;
      if (b.startsAt == null) return -1;
      return a.startsAt!.compareTo(b.startsAt!);
    });
  }

  if (!context.mounted) return;
  _showEventSelectionSheetFor(
      context, ref, events.take(3).toList(), position, lang);
}

void _showEventSelectionSheetFor(
  BuildContext context,
  WidgetRef ref,
  List<TrembleEvent> events,
  Position? position,
  String lang,
) {
  final now = DateTime.now();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? TrembleTheme.textColor.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, MediaQuery.of(ctx).padding.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    t('event_choose_title', lang),
                    style: TrembleTheme.displayFont(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : TrembleTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...events.map((event) {
                    final isLive =
                        event.startsAt == null || event.startsAt!.isBefore(now);
                    final String timeLabel;
                    if (isLive) {
                      timeLabel = t('event_live_now', lang);
                    } else {
                      final h = event.startsAt!.hour.toString().padLeft(2, '0');
                      final m =
                          event.startsAt!.minute.toString().padLeft(2, '0');
                      timeLabel = '${t('event_starts_at', lang)} $h:$m';
                    }

                    String? distLabel;
                    if (position != null &&
                        event.lat != null &&
                        event.lng != null) {
                      final dist = Geolocator.distanceBetween(position.latitude,
                          position.longitude, event.lat!, event.lng!);
                      distLabel = dist < 1000
                          ? '${dist.round()} m'
                          : '${(dist / 1000).toStringAsFixed(1)} km';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          Position? pos = position;
                          if (pos == null) {
                            try {
                              pos = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high),
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(lang == 'sl'
                                      ? 'Ni mogoče pridobiti lokacije.'
                                      : 'Could not get location.'),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                              return;
                            }
                          }
                          try {
                            await ref
                                .read(eventModeControllerProvider.notifier)
                                .activate(
                                  eventId: event.id,
                                  eventName: event.name,
                                  latitude: pos.latitude,
                                  longitude: pos.longitude,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              final msg = e.toString().contains('Not at event')
                                  ? (lang == 'sl'
                                      ? 'Niste na lokaciji tega dogodka.'
                                      : 'You are not at the event location.')
                                  : (lang == 'sl'
                                      ? 'Napaka pri aktivaciji.'
                                      : 'Failed to activate event mode.');
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(msg),
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: TrembleTheme.accentYellow
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLive
                                      ? LucideIcons.zap
                                      : LucideIcons.calendar,
                                  size: 20,
                                  color: TrembleTheme.accentYellow,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : TrembleTheme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (isLive)
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            decoration: const BoxDecoration(
                                              color: TrembleTheme.successGreen,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          timeLabel,
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 12,
                                            color: isLive
                                                ? TrembleTheme.successGreen
                                                : (isDark
                                                    ? Colors.white54
                                                    : Colors.black45),
                                            fontWeight: isLive
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (distLabel != null)
                                          Text(
                                            ' · $distLabel',
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// navIndexProvider is intentionally defined here (after HomeScreen) so it is
// a global Riverpod provider that persists across GoRouter rebuilds.
// The Settings tab index is preserved when returning from pushed routes
// like /profile-preview or /edit-profile.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Tracks which radar mode icon is selected in the top-left button.
/// Persists across sessions within the same app run.
final selectedRadarModeProvider =
    StateProvider<RadarModeKind>((ref) => RadarModeKind.radar);

typedef _RadarViewBuilder = Widget Function(
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
  bool showNearMissEmpty,
  DevSimulationState devSim,
  int signalPulseKey,
  String lang,
  bool gymModeActive,
  bool runModeActive,
  bool eventModeActive,
);

class _RadarSection extends ConsumerWidget {
  const _RadarSection({
    required this.isPremium,
    required this.lang,
    required this.builder,
  });

  final bool isPremium;
  final String lang;
  final _RadarViewBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
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
    final activeMatch = ref.watch(currentSearchProvider);
    final devSim = ref.watch(devSimulationControllerProvider);
    final gymModeActive = ref.watch(
      gymModeControllerProvider.select((state) => state.isActive),
    );
    final runModeActive = ref.watch(
      runModeControllerProvider.select((state) => state.isActive),
    );
    final eventModeActive = ref.watch(
      eventModeControllerProvider.select((state) => state.isActive),
    );
    final runCrossesAsync = user != null
        ? ref.watch(activeRunCrossesProvider(user.id))
        : const AsyncValue.data([]);
    final DocumentSnapshot? activeRunCross = runCrossesAsync.maybeWhen(
      data: (docs) => docs.isNotEmpty ? docs.first : null,
      orElse: () => null,
    );
    final showNearMissEmpty = isScanning &&
        runModeActive &&
        activeRunCross == null &&
        runCrossesAsync.maybeWhen(
          data: (_) => true,
          orElse: () => false,
        );
    final int signalPulseKey = runCrossesAsync.maybeWhen(
      data: (docs) => docs.length,
      orElse: () => 0,
    );

    return builder(
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
      showNearMissEmpty,
      devSim,
      signalPulseKey,
      lang,
      gymModeActive,
      runModeActive,
      eventModeActive,
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar({
    required this.navItems,
    required this.screensLength,
    required this.isPremium,
    required this.isCompact,
    required this.navBottomGap,
    required this.onTutorialNavTap,
  });

  final List<LiquidNavItem> navItems;
  final int screensLength;
  final bool isPremium;
  final bool isCompact;
  final double navBottomGap;
  final void Function({required int index, required bool isPremium})
      onTutorialNavTap;

  Set<int> _pulsingIndexes({
    required bool isActive,
    required int currentStep,
  }) {
    if (!isActive) return const {};
    if (currentStep == 2 && isPremium) return const {1};
    if (currentStep == 3) return {isPremium ? 2 : 1};
    if (currentStep == 4) return {isPremium ? 3 : 2};
    return const {};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navIndexProvider);
    final tutorialNavState = ref.watch(
      tutorialProvider.select(
        (state) => (
          isActive: state.isActive,
          currentStep: state.currentStep,
        ),
      ),
    );
    final isNavBarVisible = ref.watch(isNavBarVisibleProvider);
    final safeNavIndex = navIndex.clamp(0, screensLength - 1);
    final pulsing = _pulsingIndexes(
      isActive: tutorialNavState.isActive,
      currentStep: tutorialNavState.currentStep,
    );

    void handleSwipe(DragEndDetails details) {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity < -300) {
        final next = (safeNavIndex + 1).clamp(0, screensLength - 1);
        if (next != safeNavIndex) {
          HapticFeedback.selectionClick();
          ref.read(navIndexProvider.notifier).state = next;
        }
      } else if (velocity > 300) {
        final prev = (safeNavIndex - 1).clamp(0, screensLength - 1);
        if (prev != safeNavIndex) {
          HapticFeedback.selectionClick();
          ref.read(navIndexProvider.notifier).state = prev;
        }
      }
    }

    void handleTap(int index) {
      ref.read(navIndexProvider.notifier).state = index;
      onTutorialNavTap(index: index, isPremium: isPremium);
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: (isNavBarVisible && MediaQuery.of(context).viewInsets.bottom == 0)
          ? navBottomGap
          : -100,
      left: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: handleSwipe,
        child: isCompact
            ? CompactNavBar(
                currentIndex: safeNavIndex,
                items: navItems,
                pulsingIndexes: pulsing,
                onTap: handleTap,
              )
            : LiquidNavBar(
                currentIndex: safeNavIndex,
                items: navItems,
                pulsingIndexes: pulsing,
                onTap: handleTap,
                itemWrapper: (index, child) {
                  // Premium: Map (1)->Step 2, People (2)->Step 3, Settings (3)->Step 4
                  // Free: People (1)->Step 3, Settings (2)->Step 4
                  final int? step = isPremium
                      ? (index == 1
                          ? 2
                          : (index == 2 ? 3 : (index == 3 ? 4 : null)))
                      : (index == 1 ? 3 : (index == 2 ? 4 : null));
                  if (step != null) {
                    return _TutorialTarget(step: step, child: child);
                  }
                  return child;
                },
              ),
      ),
    );
  }
}

class _OverlayStack extends StatelessWidget {
  const _OverlayStack({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _LiveRunNearMissOverlay(lang: lang),
        const _GymDwellKeepAlive(),
        const PremiumTutorialOverlay(),
      ],
    );
  }
}

class _LiveRunNearMissOverlay extends ConsumerWidget {
  const _LiveRunNearMissOverlay({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user == null) return const SizedBox.shrink();

    final runCrossesAsync = ref.watch(activeRunCrossesProvider(user.id));
    final activeRunCross = runCrossesAsync.maybeWhen(
      data: (docs) => docs.isNotEmpty ? docs.first : null,
      orElse: () => null,
    );
    final isScanning = ref.watch(isScanningProvider);
    final runModeActive = ref.watch(
      runModeControllerProvider.select((state) => state.isActive),
    );
    final showNearMissEmpty = isScanning &&
        runModeActive &&
        activeRunCross == null &&
        runCrossesAsync.maybeWhen(
          data: (_) => true,
          orElse: () => false,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (activeRunCross != null)
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
                    final partnerId = userIds.firstWhere(
                      (id) => id != user.id,
                      orElse: () => '',
                    );
                    if (partnerId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final dismissedBy =
                        List<String>.from(data['dismissedBy'] ?? []);
                    if (dismissedBy.contains(user.id)) {
                      return const SizedBox.shrink();
                    }

                    final profileAsync =
                        ref.watch(publicProfileProvider(partnerId));
                    return profileAsync.when(
                      data: (profile) {
                        return LiveRunCard(
                          name: profile.name,
                          age: profile.age,
                          onWave: () {
                            unawaited(HapticFeedback.lightImpact());
                            return ref
                                .read(runClubRepositoryProvider)
                                .sendWave(activeRunCross.id, user.id);
                          },
                          onDismiss: () {
                            ref
                                .read(runClubRepositoryProvider)
                                .dismissEncounter(activeRunCross.id, user.id);
                          },
                        ).animate().fadeIn(duration: 250.ms).slideY(
                              begin: -0.4,
                              curve: Curves.easeOutCubic,
                            );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ),
        if (showNearMissEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: SafeArea(
              bottom: false,
              child: WarmthEmptyState(
                title: t('near_miss_empty_title', lang),
                subtitle: t('near_miss_empty_sub', lang),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                maxWidth: 320,
              ),
            ),
          ),
      ],
    );
  }
}

class _GymDwellKeepAlive extends ConsumerWidget {
  const _GymDwellKeepAlive();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the gym dwell service alive as long as HomeScreen is in the tree.
    ref.watch(gymDwellServiceProvider);
    return const SizedBox.shrink();
  }
}

class _MatchNotificationPillOverlay extends ConsumerStatefulWidget {
  const _MatchNotificationPillOverlay();

  @override
  ConsumerState<_MatchNotificationPillOverlay> createState() =>
      _MatchNotificationPillOverlayState();
}

class _MatchNotificationPillOverlayState
    extends ConsumerState<_MatchNotificationPillOverlay> {
  bool _showSwipeHint = false;

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

  @override
  Widget build(BuildContext context) {
    // Snapshot hint state when the pill first becomes visible.
    ref.listen(devSimulationControllerProvider, (prev, next) {
      final wasVisible = prev?.hasPillVisible ?? false;
      if (!wasVisible && next.hasPillVisible) {
        final hint = WavePillService.shouldShowHint;
        if (hint) unawaited(WavePillService.recordPillShown());
        if (mounted) setState(() => _showSwipeHint = hint);
      }
    });

    final devSimPill = ref.watch(
      devSimulationControllerProvider.select(
        (state) => (
          phase: state.phase,
          profile: state.profile,
        ),
      ),
    );
    final profile = devSimPill.profile;
    final hasPillVisible = devSimPill.phase == DevSimPhase.waitingForAction ||
        devSimPill.phase == DevSimPhase.waveSent ||
        devSimPill.phase == DevSimPhase.waveReceived;
    if (!hasPillVisible || profile == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: MatchNotificationPill(
            name: profile.name,
            age: profile.age,
            imageUrl: profile.imageUrl,
            birthDate: profile.birthDate,
            pillState: _phaseToPillState(devSimPill.phase),
            onWave: () {
              unawaited(HapticFeedback.lightImpact());
              final notifier =
                  ref.read(devSimulationControllerProvider.notifier);
              if (devSimPill.phase == DevSimPhase.waitingForAction) {
                // Outgoing wave: pill stays visible (waveSent), so the
                // pill's own onMatch callback fires reliably after its
                // shake animation completes. Nothing else to do here.
                notifier.onUserWave();
              } else if (devSimPill.phase == DevSimPhase.waveReceived) {
                // Wave-back: navigate FIRST, then transition sim state.
                // The pill's onMatch is unreliable on this path — the
                // state transition flips devSim.hasPillVisible to false
                // on the same frame, unmounting the pill mid-await
                // before onMatch ever runs. Driving the navigation here
                // guarantees the reveal animation always shows.
                final matchUser = ref.read(authStateProvider);
                final now = DateTime.now();
                final synthesized = wave_match.Match(
                  id: 'dev-${now.microsecondsSinceEpoch}',
                  userIds: [
                    matchUser?.id ?? 'dev-self',
                    profile.id,
                  ],
                  createdAt: now,
                  seenBy: [matchUser?.id ?? 'dev-self'],
                  status: 'found',
                  isFound: true,
                  gestures: {
                    (matchUser?.id ?? 'dev-self'): true,
                    profile.id: true,
                  },
                  expiresAt: now.add(const Duration(minutes: 30)),
                );
                context.pushNamed('match_reveal', extra: synthesized);
                notifier.onUserWaveBack();
              }
            },
            onIgnore: () =>
                ref.read(devSimulationControllerProvider.notifier).onIgnore(),
            onMatch: () {
              // Only the outgoing-wave path (waitingForAction → tap) is
              // routed through here. The wave-back path navigates from
              // onWave directly (see above) to sidestep the pill unmount
              // race, so reaching this callback while devSim was already
              // past waitingForAction means it's stale — bail to avoid
              // double-pushing the reveal screen.
              if (devSimPill.phase != DevSimPhase.waitingForAction) {
                return;
              }
              WavePillService.dismiss();
              final matchUser = ref.read(authStateProvider);
              final now = DateTime.now();
              final synthesized = wave_match.Match(
                id: 'dev-${now.microsecondsSinceEpoch}',
                userIds: [
                  matchUser?.id ?? 'dev-self',
                  profile.id,
                ],
                createdAt: now,
                seenBy: [matchUser?.id ?? 'dev-self'],
                status: 'found',
                isFound: true,
                gestures: {
                  (matchUser?.id ?? 'dev-self'): true,
                  profile.id: true,
                },
                expiresAt: now.add(const Duration(minutes: 30)),
              );
              context.pushNamed('match_reveal', extra: synthesized);
            },
            // Tap on the pill avatar → open the full profile card with
            // Wave / Ignore actions. The match reveal animation is NOT
            // shown here — it's reserved for the actual mutual-wave
            // moment (outgoing wave accepted, or wave-back tapped from
            // the pill itself). Premium users see the profile; free
            // users see the paywall (existing gate).
            onTap: () {
              final tapIsPremium = ref.read(effectiveIsPremiumProvider);
              if (!tapIsPremium) {
                PremiumPaywallBottomSheet.show(context);
                return;
              }
              context.push('/profile', extra: profile);
            },
            showSwipeHint: _showSwipeHint,
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: -0.4, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}

class _TutorialTarget extends ConsumerStatefulWidget {
  const _TutorialTarget({
    required this.step,
    required this.child,
  });

  final int step;
  final Widget child;

  @override
  ConsumerState<_TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends ConsumerState<_TutorialTarget> {
  Rect? _lastReported;

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(
      tutorialProvider.select((state) => state.isActive),
    );
    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReport());
    }
    return widget.child;
  }

  void _maybeReport() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;

    final homeStackBox = HomeScreen.homeStackKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (homeStackBox == null ||
        !homeStackBox.hasSize ||
        !homeStackBox.attached) {
      return;
    }

    final rect =
        box.localToGlobal(Offset.zero, ancestor: homeStackBox) & box.size;
    if (rect == _lastReported) return;
    _lastReported = rect;

    final current = ref.read(tutorialTargetRectsProvider);
    if (current[widget.step] == rect) return;
    ref.read(tutorialTargetRectsProvider.notifier).state = {
      ...current,
      widget.step: rect,
    };
  }
}

class _TutorialPulse extends StatefulWidget {
  const _TutorialPulse({
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  State<_TutorialPulse> createState() => _TutorialPulseState();
}

class _TutorialPulseState extends State<_TutorialPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.13).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TutorialPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.animateTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _scale.value : 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF4436C).withValues(alpha: 0.42),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _RadarScheduleButton extends ConsumerWidget {
  const _RadarScheduleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tutorialScheduleState = ref.watch(
      tutorialProvider.select(
        (state) => (
          isActive: state.isActive,
          currentStep: state.currentStep,
        ),
      ),
    );
    final isHighlighted = tutorialScheduleState.isActive &&
        tutorialScheduleState.currentStep == 1;

    return _TutorialPulse(
      isActive: isHighlighted,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          border: Border.all(
            color: isHighlighted
                ? TrembleTheme.rose.withValues(alpha: 0.62)
                : isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              showRadarScheduleModal(context);
              if (isHighlighted) {
                ref.read(tutorialProvider.notifier).nextStep();
              }
            },
            child: const Center(
              child: Icon(
                LucideIcons.clock,
                size: 20,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pulsing icon button used for the Radar Mode indicator.
class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _PulseIcon({
    required this.icon,
    required this.color,
    required this.isActive,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (widget.isActive || widget.isHighlighted) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.isActive || widget.isHighlighted;
    final wasPulsing = oldWidget.isActive || oldWidget.isHighlighted;
    if (shouldPulse != wasPulsing) {
      if (shouldPulse) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveIconColor = isDark ? Colors.white38 : Colors.black26;
    final inactiveBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final inactiveBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isActive || widget.isHighlighted
                  ? widget.color.withValues(alpha: 0.2)
                  : inactiveBgColor,
              border: Border.all(
                color: widget.isActive || widget.isHighlighted
                    ? widget.color.withValues(alpha: 0.6)
                    : inactiveBorderColor,
                width: 1.5,
              ),
              boxShadow: widget.isActive || widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.2),
                        blurRadius: 12 * _pulse.value,
                        spreadRadius: 2 * _pulse.value,
                      ),
                    ]
                  : [],
            ),
            child: Transform.scale(
              scale:
                  widget.isActive || widget.isHighlighted ? _pulse.value : 1.0,
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isActive || widget.isHighlighted
                      ? widget.color
                      : inactiveIconColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mode kinds (for info popup) ───────────────────────────────────────────────
enum RadarModeKind { radar, gym, run, event }

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
    RadarModeKind.gym => (
        'gym_mode_info_title',
        'gym_mode_info_body',
        LucideIcons.dumbbell
      ),
    RadarModeKind.run => (
        'run_mode_info_title',
        'run_mode_info_body',
        LucideIcons.personStanding
      ),
    RadarModeKind.event => (
        'event_mode_info_title',
        'event_mode_info_body',
        LucideIcons.calendar
      ),
    RadarModeKind.radar => throw UnimplementedError(),
  };

  final dontShowNotifier = ValueNotifier<bool>(false);

  final primary = Theme.of(context).colorScheme.primary;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const gold = TrembleTheme.accentYellow;
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
                        color: isDark ? Colors.white : TrembleTheme.textColor,
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
                            : TrembleTheme.textColor.withValues(alpha: 0.6),
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
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                t('cancel', lang),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
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
                                    ? TrembleTheme.rose.withValues(alpha: 0.85)
                                    : primary,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isActive ? Colors.redAccent : primary)
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

class RadarBleIssueMessage extends StatelessWidget {
  const RadarBleIssueMessage({
    super.key,
    required this.issue,
    required this.onOpenSettings,
    required this.onGrantPermission,
  });

  final RadarBleIssue issue;
  final VoidCallback onOpenSettings;
  final VoidCallback onGrantPermission;

  @override
  Widget build(BuildContext context) {
    final isBluetoothOff = issue == RadarBleIssue.bluetoothOff;
    final message = isBluetoothOff
        ? 'Bluetooth is off. Turn it on in Control Center to use radar.'
        : 'Bluetooth permission required.';
    final actionLabel = isBluetoothOff ? 'Open Settings' : 'Grant Permission';
    final action = isBluetoothOff ? onOpenSettings : onGrantPermission;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GlassCard(
          useGlassEffect: false,
          solidDarkBg: const Color(0xFF222220),
          borderRadius: 24,
          borderColor: TrembleTheme.rose.withValues(alpha: 0.28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TrembleTheme.rose.withValues(alpha: 0.14),
                ),
                child: Icon(
                  isBluetoothOff
                      ? LucideIcons.bluetoothOff
                      : LucideIcons.shieldAlert,
                  color: TrembleTheme.rose,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                text: actionLabel,
                onPressed: action,
                width: 220,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _PulsingRadarButton extends ConsumerStatefulWidget {
  final bool isScanning;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _PulsingRadarButton({
    required this.isScanning,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  ConsumerState<_PulsingRadarButton> createState() =>
      _PulsingRadarButtonState();
}

class _PulsingRadarButtonState extends ConsumerState<_PulsingRadarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isScanning || widget.isHighlighted) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(_PulsingRadarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.isScanning || widget.isHighlighted;
    final wasPulsing = oldWidget.isScanning || oldWidget.isHighlighted;
    if (shouldPulse != wasPulsing) {
      if (shouldPulse) {
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
    final selectedMode = ref.watch(selectedRadarModeProvider);

    const Color buttonColor = TrembleTheme.rose;

    final Widget logoWidget = switch (selectedMode) {
      RadarModeKind.gym =>
        const Icon(LucideIcons.dumbbell, size: 60, color: Colors.white),
      RadarModeKind.run => RunningStickman(
          isRunning: ref.watch(
            runModeControllerProvider.select((state) => state.isActive),
          ),
          size: 94,
          color: Colors.white,
        ),
      RadarModeKind.event =>
        const Icon(LucideIcons.calendar, size: 60, color: Colors.white),
      RadarModeKind.radar => SizedBox(
          width: 100,
          height: 100,
          child: TrembleRadarHeart(
            isScanning: widget.isScanning || widget.isHighlighted,
            size: 100,
            color: Colors.white,
          ),
        ),
    };

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
            if (widget.isScanning || widget.isHighlighted)
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
                          color: (widget.isHighlighted
                                  ? TrembleTheme.rose
                                  : Theme.of(context).colorScheme.onSurface)
                              .withValues(alpha: 1.0 - progress),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                );
              }),

            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: buttonColor,
              ),
              child: Center(
                child: logoWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
