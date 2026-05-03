import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/match.dart';
import 'widgets/match_background_animation.dart';
import '../../../shared/ui/glass_card.dart';
import '../../matches/data/match_repository.dart';
import '../application/match_service.dart';
import '../../../core/translations.dart';
import '../../../core/upload_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/ui/primary_button.dart';

class MatchRevealScreen extends ConsumerWidget {
  final Match match;
  const MatchRevealScreen({super.key, required this.match});

  static const Color _rose = Color(0xFFF4436C);
  static const Color _deepGraphite = Color(0xFF1A1A18);
  static const Color _warmCream = Color(0xFFFAFAF7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final lang = ref.watch(appLanguageProvider);

    if (myUid == null) {
      return Scaffold(
        backgroundColor: _deepGraphite,
        body: Center(
          child: Text(
            t('auth_error', lang),
            style: GoogleFonts.instrumentSans(color: _warmCream),
          ),
        ),
      );
    }

    // Use live stream so we pick up the match document once Firestore finishes
    // writing both userIds — avoids the race condition where the snapshot passed
    // via `extra` had an empty or incomplete userIds list.
    final liveMatch = ref
            .watch(activeMatchesStreamProvider)
            .value
            ?.firstWhere((m) => m.id == match.id, orElse: () => match) ??
        match;

    final partnerId = liveMatch.getPartnerId(myUid);

    // Still propagating — wait for the live document to have both userIds.
    if (partnerId.isEmpty) {
      return const Scaffold(
        backgroundColor: _deepGraphite,
        body: Center(
          child: CircularProgressIndicator(color: _rose, strokeWidth: 2),
        ),
      );
    }

    final partnerProfileAsync = ref.watch(publicProfileProvider(partnerId));

    return Scaffold(
      backgroundColor: _deepGraphite,
      body: Stack(
        children: [
          // Animated Rose radar pulse background
          const Positioned.fill(child: MatchBackgroundAnimation()),

          // Subtle deep graphite gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepGraphite.withValues(alpha: 0.2),
                    _deepGraphite.withValues(alpha: 0.6),
                    _deepGraphite.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: partnerProfileAsync.when(
              data: (profile) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // Brand headline - architectural and stoic
                    Text(
                      t('mutual_wave', lang).toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _rose,
                        letterSpacing: -1.28, // -0.04em for 32px
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('both_sent_wave', lang).toUpperCase(),
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _warmCream.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Partner avatar with rose glow
                    Stack(
                      children: [
                        Hero(
                          tag: 'match_avatar_${profile.id}',
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _rose.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _rose.withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profile.primaryPhotoUrl.isNotEmpty
                                  ? Image.network(
                                      profile.primaryPhotoUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.person,
                                          size: 80, color: Colors.white10),
                                    ),
                            ),
                          ),
                        ),
                        if (profile.isTraveler)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _deepGraphite.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Text('🌴',
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Partner name
                    Text(
                      profile.name.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _warmCream,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.age} LET',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _warmCream.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 72),

                    // Primary CTA — uses shared PrimaryButton for consistency
                    PrimaryButton(
                      text: t('open_radar', lang).toUpperCase(),
                      onPressed: () => context.pop(),
                    ),

                    const SizedBox(height: 16),

                    // Secondary action — dismiss
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        t('decide_later', lang).toUpperCase(),
                        style: GoogleFonts.instrumentSans(
                          color: _warmCream.withValues(alpha: 0.3),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Pulse Intercept — architectural signal tiles
                    _PulseInterceptConsole(match: match),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _rose,
                  strokeWidth: 2,
                ),
              ),
              error: (err, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: _rose, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    t('error_loading_profile', lang),
                    style: GoogleFonts.instrumentSans(
                      color: _warmCream.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      t('close', lang).toUpperCase(),
                      style: TextStyle(
                        color: _rose,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseInterceptConsole extends ConsumerWidget {
  final Match match;
  const _PulseInterceptConsole({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      opacity: 0.04,
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _PulseInterceptButton(match: match),
            ),
            Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _PulseReceiverButton(match: match),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseInterceptButton extends ConsumerStatefulWidget {
  final Match match;
  const _PulseInterceptButton({required this.match});

  @override
  ConsumerState<_PulseInterceptButton> createState() =>
      __PulseInterceptButtonState();
}

class __PulseInterceptButtonState extends ConsumerState<_PulseInterceptButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _showInterceptOptions() async {
    final lang = ref.read(appLanguageProvider);
    final user = ref.read(authStateProvider);
    final hasPhone = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: GlassCard(
          opacity: 0.15,
          borderRadius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                t('pulse_intercept', lang).toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: MatchRevealScreen._rose,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('intercept_desc', lang).toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 48),

              // Option 1: Share Phone
              _buildOption(
                icon: Icons.grid_3x3_rounded,
                label: t('share_phone', lang).toUpperCase(),
                enabled: hasPhone,
                onTap: () {
                  Navigator.pop(ctx);
                  _handleInterceptRequest('phone');
                },
              ),
              const SizedBox(height: 16),

              // Option 2: Send Photo
              _buildOption(
                icon: Icons.camera_rounded,
                label: t('send_photo', lang).toUpperCase(),
                enabled: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _handlePhotoIntercept();
                },
              ),

              if (!hasPhone) ...[
                const SizedBox(height: 32),
                Text(
                  t('intercept_disabled', lang).toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    color: MatchRevealScreen._rose.withValues(alpha: 0.4),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        opacity: enabled ? 0.08 : 0.03,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? MatchRevealScreen._rose : Colors.white10,
              size: 22,
            ),
            const SizedBox(width: 24),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: enabled ? Colors.white : Colors.white10,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            if (enabled)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleInterceptRequest(String type, {String? data}) async {
    final lang = ref.read(appLanguageProvider);
    setState(() => _isLoading = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final partnerId = widget.match.getPartnerId(myUid!);

      await ref.read(matchControllerProvider.notifier).requestIntercept(
            targetUid: partnerId,
            type: type,
            data: data,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('signal_emitted', lang).toUpperCase(),
            style: GoogleFonts.instrumentSans(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          backgroundColor: MatchRevealScreen._rose,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${t('signal_error', lang).toUpperCase()}: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhotoIntercept() async {
    final lang = ref.read(appLanguageProvider);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.uploadPhoto(image);
      await _handleInterceptRequest('photo', data: url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${t('upload_failure', lang).toUpperCase()}: ${e.toString()}'),
          backgroundColor:
              MatchRevealScreen._rose, // Using brand rose instead of redAccent
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return InkWell(
      onTap: _isLoading ? null : _showInterceptOptions,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_rounded,
              color: _isLoading
                  ? MatchRevealScreen._rose.withValues(alpha: 0.3)
                  : MatchRevealScreen._rose,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              t('action_share', lang).toUpperCase(),
              style: GoogleFonts.instrumentSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MatchRevealScreen._warmCream.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseReceiverButton extends ConsumerStatefulWidget {
  final Match match;
  const _PulseReceiverButton({required this.match});

  @override
  ConsumerState<_PulseReceiverButton> createState() =>
      __PulseReceiverButtonState();
}

class __PulseReceiverButtonState extends ConsumerState<_PulseReceiverButton> {
  bool _isLoading = false;

  Future<void> _checkPulse() async {
    final lang = ref.read(appLanguageProvider);
    setState(() => _isLoading = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final partnerId = widget.match.getPartnerId(myUid!);

      final data = await ref
          .read(matchControllerProvider.notifier)
          .fetchIntercept(partnerId);

      if (!mounted) return;

      _showPulseInterceptDialog(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('no_pulse_detected', lang).toUpperCase()),
          backgroundColor: const Color(0xFFF5C842),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPulseInterceptDialog(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final payload = data['data'] as String;
    final lang = ref.read(appLanguageProvider);
    const gold = Color(0xFFF5C842);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            opacity: 0.2,
            borderRadius: 32,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  color: gold,
                  size: 44,
                ),
                const SizedBox(height: 24),
                Text(
                  t('pulse_intercept', lang).toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t(type == 'phone' ? 'temporary_contact' : 'view_once_frame',
                          lang)
                      .toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 40),
                if (type == 'phone')
                  GlassCard(
                    opacity: 0.08,
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    child: Text(
                      payload,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.network(
                        payload,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: gold,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
                Text(
                  t('intercept_data_deleted', lang).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    color: gold.withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Text(
                      t('close_purge', lang).toUpperCase(),
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    const gold = Color(0xFFF5C842);

    return InkWell(
      onTap: _isLoading ? null : _checkPulse,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar_rounded,
              color: _isLoading ? gold.withValues(alpha: 0.3) : gold,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              t('action_view', lang).toUpperCase(),
              style: GoogleFonts.instrumentSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MatchRevealScreen._warmCream.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
