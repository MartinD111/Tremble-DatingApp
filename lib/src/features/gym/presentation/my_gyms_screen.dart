import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../application/gym_selection_notifier.dart';
import 'gym_search_widget.dart';

class MyGymsScreen extends ConsumerStatefulWidget {
  const MyGymsScreen({super.key});

  @override
  ConsumerState<MyGymsScreen> createState() => _MyGymsScreenState();
}

class _MyGymsScreenState extends ConsumerState<MyGymsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final opacity = (1.0 - (_scrollController.offset / 60)).clamp(0.0, 1.0);
      if (_titleOpacity.value != opacity) _titleOpacity.value = opacity;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _focusSearch() {
    _searchFocus.requestFocus();
    // Scroll the search field into a comfortable position.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final topPad = MediaQuery.of(context).padding.top;

    final user = ref.watch(authStateProvider);
    final selectedGyms = user?.selectedGyms ?? [];

    return GradientScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24, topPad + 100, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    child: const Icon(LucideIcons.dumbbell,
                        color: TrembleTheme.rose, size: 28),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Search bar ──────────────────────────────────────────────
                GymSearchWidget(
                  focusNode: _searchFocus,
                  selectedGyms: selectedGyms,
                  onAdd: (gym) async =>
                      ref.read(gymSelectionProvider.notifier).addGym(gym),
                  onRemove: (placeId) => ref
                      .read(gymSelectionProvider.notifier)
                      .removeGym(placeId),
                ),

                // ── + Add button ────────────────────────────────────────────
                const SizedBox(height: 12),
                _AddGymButton(
                  enabled: selectedGyms.length < 3,
                  onTap: _focusSearch,
                  textColor: textColor,
                  subColor: subColor,
                ),

                // ── Gym Mode explanation ────────────────────────────────────
                const SizedBox(height: 28),
                _InfoBlock(
                  icon: LucideIcons.dumbbell,
                  title: 'What is Gym Mode?',
                  body:
                      'When you arrive at one of your saved gyms, Tremble activates Gym Mode automatically. Your profile is surfaced to other members who are working out at the same location right now.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),
                _InfoBlock(
                  icon: LucideIcons.mapPin,
                  title: 'Location-based matching',
                  body:
                      'Gym Mode uses your device\'s location to detect when you enter a gym radius. No check-in needed — it\'s fully automatic and only active while you\'re physically at the gym.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),
                _InfoBlock(
                  icon: LucideIcons.shield,
                  title: 'You stay in control',
                  body:
                      'Add up to 3 gyms. You can remove any saved gym at any time. Gym Mode is automatically disabled the moment you leave the gym premises.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, _) => TrembleHeader(
              title: 'My Gyms',
              titleOpacity: opacity,
              buttonsOpacity: opacity,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGymButton extends StatelessWidget {
  const _AddGymButton({
    required this.enabled,
    required this.onTap,
    required this.textColor,
    required this.subColor,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? TrembleTheme.rose : subColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: enabled ? 0.45 : 0.25),
              width: 1.2,
            ),
            color: enabled
                ? TrembleTheme.rose.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                enabled ? 'Add' : 'Max 3 gyms reached',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
