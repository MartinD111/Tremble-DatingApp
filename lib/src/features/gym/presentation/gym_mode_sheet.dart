import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/core/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/gym_repository.dart';
import '../application/gym_mode_controller.dart';

class GymModeSheet extends ConsumerStatefulWidget {
  const GymModeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GymModeSheet(),
    );
  }

  @override
  ConsumerState<GymModeSheet> createState() => _GymModeSheetState();
}

class _GymModeSheetState extends ConsumerState<GymModeSheet> {
  List<Gym>? _gyms;
  bool _loadingGyms = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadGyms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNotificationOnboarding();
    });
  }

  /// Shows the gym notification onboarding prompt the first time the sheet
  /// is opened if the user has not yet made a choice.
  void _maybeShowNotificationOnboarding() {
    final user = ref.read(authStateProvider);
    if (!mounted || user == null) return;
    if (user.gymNotificationsEnabled != null) return; // already decided

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassCard(
            opacity: 0.18,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.bell,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  'Gym obvestila',
                  style: TrembleTheme.displayFont(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Te obvestimo, ko 10 minut prebivaš v bližini fitnesa?',
                  style: GoogleFonts.instrumentSans(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          foregroundColor: Colors.white70,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _saveGymNotificationsPref(enabled: false);
                        },
                        child: const Text('Zavrni'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _saveGymNotificationsPref(enabled: true);
                        },
                        child: const Text('Omogoči'),
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
  }

  void _saveGymNotificationsPref({required bool enabled}) {
    ref.read(authStateProvider.notifier).updateProfile(
          ref.read(authStateProvider)!.copyWith(
                gymNotificationsEnabled: enabled,
              ),
        );
  }

  Future<void> _loadGyms() async {
    try {
      final gyms = await ref.read(gymRepositoryProvider).getGyms();
      if (mounted) {
        setState(() {
          _gyms = gyms;
          _loadingGyms = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingGyms = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymState = ref.watch(gymModeControllerProvider);
    final controller = ref.read(gymModeControllerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.dumbbell,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Gym Mode',
                      style: TrembleTheme.displayFont(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (gymState.isActive)
                      TextButton(
                        onPressed: gymState.isLoading
                            ? null
                            : () async {
                                await controller.deactivate();
                                if (context.mounted) Navigator.pop(context);
                              },
                        child: const Text(
                          'Deactivate',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status / description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: gymState.isActive
                    ? _ActiveBanner(gymName: gymState.activeGymName ?? '')
                    : Text(
                        'Select your gym to connect with others working out there right now.',
                        style: GoogleFonts.instrumentSans(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
              ),

              // Error message
              if (gymState.status == GymModeStatus.error &&
                  gymState.errorMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    gymState.errorMessage!,
                    style: GoogleFonts.instrumentSans(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Gym list
              Expanded(
                child: _buildGymList(
                  context,
                  scrollController,
                  gymState,
                  controller,
                ),
              ),

              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGymList(
    BuildContext context,
    ScrollController scrollController,
    GymModeState gymState,
    GymModeController controller,
  ) {
    if (_loadingGyms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Text(
          'Failed to load gyms.',
          style: GoogleFonts.instrumentSans(color: Colors.white54),
        ),
      );
    }

    final gyms = _gyms ?? [];
    if (gyms.isEmpty) {
      return Center(
        child: Text(
          'No gyms available yet.',
          style: GoogleFonts.instrumentSans(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: gyms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final gym = gyms[index];
        final isActiveGym = gymState.activeGymId == gym.id;

        return _GymTile(
          gym: gym,
          isActive: isActiveGym,
          isLoading: gymState.isLoading,
          onTap: isActiveGym || gymState.isLoading
              ? null
              : () async {
                  await controller.activate(
                    gymId: gym.id,
                    gymName: gym.name,
                  );
                  // Close only on success
                  if (context.mounted &&
                      ref.read(gymModeControllerProvider).isActive) {
                    Navigator.pop(context);
                  }
                },
        );
      },
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final String gymName;
  const _ActiveBanner({required this.gymName});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            color: Colors.greenAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Active at $gymName',
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymTile extends StatelessWidget {
  final Gym gym;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GymTile({
    required this.gym,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GlassCard(
      opacity: isActive ? 0.22 : 0.08,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.dumbbell,
            size: 20,
            color: isActive ? primary : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        title: Text(
          gym.name,
          style: GoogleFonts.instrumentSans(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        subtitle: gym.address.isNotEmpty
            ? Text(
                gym.address,
                style: GoogleFonts.instrumentSans(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isActive
            ? const Icon(
                LucideIcons.checkCircle,
                color: Colors.greenAccent,
                size: 20,
              )
            : isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 18,
                  ),
        onTap: (isLoading || isActive) ? null : onTap,
      ),
    );
  }
}
