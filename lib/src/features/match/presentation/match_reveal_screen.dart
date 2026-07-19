import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/data/auth_repository.dart';
import '../../matches/data/match_repository.dart';
import '../../../features/profile/domain/public_profile.dart';
import '../domain/match.dart';
import '../../../features/safety/screen_protection_service.dart';
import '../application/match_service.dart';
import '../../../shared/ui/tremble_loading_spinner.dart';
import '../../../core/theme.dart';

// ── Pep talk data ────────────────────────────────────────────────────────────

typedef _Pep = ({String message, String? note});

const List<_Pep> _pepTalks = [
  (
    message: "Go shoot your shot",
    note: "Please don't actually shoot anybody. Thank you"
  ),
  (
    message: "You got this!",
    note: "We at Tremble believe that you believe in yourself"
  ),
  (
    message: "What's the worst thing they can say?",
    note: 'Best thing they can say is "I\'m Batman"'
  ),
  (
    message: "You miss 100% of the shots you don't take",
    note: "Please don't actually shoot anybody. Thank you"
  ),
  (
    message: "Life's too short to overthink it",
    note: "But not too short to avoid making it weird"
  ),
  (
    message: "Take the leap",
    note: "Metaphorical leaps only. Knees are expensive"
  ),
  (
    message: "Fortune favors the brave",
    note: "Brave people still respect boundaries"
  ),
  (message: "Trust your rizz", note: "Confidence is attractive. Arson is not"),
  (
    message: "Stop rehearsing conversations in your head and just go for it",
    note: "They can't hear the imaginary version anyway"
  ),
  (
    message: "Go create your rom-com moment",
    note: "Keep it cute and non-criminal"
  ),
  (
    message: "The “what if” will haunt you more than the rejection",
    note: "Unless you confess during their grandma's funeral. Timing matters"
  ),
  (
    message: "Confidence looks good on you",
    note: "Overconfidence looks like a LinkedIn motivational post"
  ),
  (
    message: "Make your move",
    note: "Preferably without dramatic background music"
  ),
  (
    message: "Take the chance — your future self might thank you",
    note: "Your future self might also cringe. That's part of life"
  ),
  (
    message: "Romantic risks build character",
    note: "So do restraining orders. Avoid those"
  ),
  (
    message:
        "Worst case? You get rejected. Best case? Main character arc begins",
    note: "Please do not start narrating your life out loud"
  ),
  (
    message: "Just be yourself",
    note: "Unless “yourself” was planning a surprise ukulele performance"
  ),
  (message: "Go flirt a little", note: "“A little” is the key phrase here"),
  (
    message: "Say hi — it's not a federal offense",
    note: "Unless you're trespassing. Then maybe leave first"
  ),
  (
    message:
        "Your soulmate probably isn't going to materialize in your living room",
    note: "If they do, contact a physicist"
  ),
  (
    message: "Take the risk. Great stories rarely start with “I stayed home”",
    note: "Great court cases sometimes do, though"
  ),
  (
    message: "Confidence is attractive. Panic monologues are less so",
    note: "Keep the TED Talk under 30 seconds"
  ),
  (
    message: "Do it scared if you have to",
    note: "Just don't do it illegal while scared"
  ),
  (
    message: "Make your intentions known",
    note: "Subtle hints are not a universal language"
  ),
  (
    message: "Take the chance — life doesn't do reruns",
    note: "Except in your brain at 3 a.m"
  ),
  (
    message: "You'll never know unless you try",
    note: "And yes, that includes making the first move"
  ),
  (
    message: "If you feel the fear, that probably means it matters",
    note: "Or you just had too much caffeine — check both"
  ),
  (
    message: "Go on, be a little courageous",
    note: "Not “jump off a cliff” courageous. The other kind"
  ),
  (
    message: "If it works, great. If it doesn't, you still get closure",
    note: "Closure is underrated and slightly bitter"
  ),
];

_Pep _pickPep() => _pepTalks[math.Random().nextInt(_pepTalks.length)];

/// Adapts a [MatchProfile] (from the getMatches path) into the [PublicProfile]
/// shape the reveal scene renders, so `_buildScene` stays unchanged. Returns
/// null when the partner is not yet in the matches list.
PublicProfile? _publicProfileFromMatch(MatchProfile? match) {
  if (match == null) return null;
  return PublicProfile(
    id: match.id,
    name: match.name,
    age: match.age,
    photoUrls: match.photoUrls,
    hobbies: match.hobbies,
    lookingFor: match.lookingFor.isNotEmpty ? match.lookingFor.first : null,
    isTraveler: match.isTraveler,
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MatchRevealScreen extends ConsumerStatefulWidget {
  final Match match;

  const MatchRevealScreen({
    super.key,
    required this.match,
  });

  @override
  ConsumerState<MatchRevealScreen> createState() => _MatchRevealScreenState();
}

class _MatchRevealScreenState extends ConsumerState<MatchRevealScreen>
    with SingleTickerProviderStateMixin {
  // ── Colors (Tremble design tokens) ─────────────────────────────────────────
  static const _bgDeep = Color(0xFF0B0B09);
  static const _bgMid = Color(0xFF13130F);
  static const _bgBottom = Color(0xFF0E0E0C);
  static const _greenDark = TrembleTheme.successGreen;
  static const _greenLight = Color(0xFF5BBF93);
  static const _cream = TrembleTheme.backgroundColor;

  late final AnimationController _ctrl;
  late final _Pep _pep;
  bool _isRecording = false;
  late final void Function(bool) _recordingListener;

  @override
  void initState() {
    super.initState();
    _pep = _pickPep();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    )..forward();
    _recordingListener = (v) {
      if (mounted) setState(() => _isRecording = v);
    };
    ScreenProtectionService.enable();
    ScreenProtectionService.addRecordingListener(_recordingListener);
    unawaited(_haptic());
  }

  Future<void> _haptic() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    ScreenProtectionService.removeRecordingListener();
    ScreenProtectionService.disable();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Matrix4 _rotateY(double rad) => Matrix4.identity()
    ..setEntry(3, 2, 1 / 1200.0)
    ..rotateY(rad);

  static double _easeOutCubic(double x) =>
      1.0 - math.pow(1.0 - x.clamp(0.0, 1.0), 3.0).toDouble();

  static double _easeOut(double x) =>
      Curves.easeOut.transform(x.clamp(0.0, 1.0));

  static double _easeOutBack(double x) =>
      Curves.easeOutBack.transform(x.clamp(0.0, 1.0));

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isRecording) return const RecordingShield();

    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(
        backgroundColor: _bgDeep,
        body: Center(
          child: TrembleLoadingSpinner(
            style: LoadingStyle.simple,
            accentColor: _greenLight,
          ),
        ),
      );
    }

    final liveMatch = ref.watch(activeMatchesStreamProvider).value?.firstWhere(
            (m) => m.id == widget.match.id,
            orElse: () => widget.match) ??
        widget.match;
    final partnerId = liveMatch.getPartnerId(myUid);

    if (partnerId.isEmpty) {
      return const Scaffold(
        backgroundColor: _bgDeep,
        body: Center(
          child: TrembleLoadingSpinner(
            style: LoadingStyle.simple,
            accentColor: _greenLight,
          ),
        ),
      );
    }

    // Partner identity is sourced from the getMatches path (MatchProfile), not
    // getPublicProfile — the latter returned null and rendered the reveal as "?"
    // (BLOCKER-POSTMATCH-PHOTO). whenOrNull keeps `profile` null while the
    // stream loads so the reveal animation plays and fills in on arrival.
    final profile = ref
        .watch(partnerMatchProfileProvider(partnerId))
        .whenOrNull(data: _publicProfileFromMatch);
    final myHobbies = ref.watch(authStateProvider)?.hobbies ?? const [];

    return Scaffold(
      backgroundColor: _bgDeep,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => _buildScene(context, profile, myHobbies),
      ),
    );
  }

  Widget _buildScene(
    BuildContext context,
    PublicProfile? profile,
    List<Map<String, dynamic>> myHobbies,
  ) {
    final size = MediaQuery.of(context).size;

    // t: elapsed seconds (0 → 4.4)
    final t = _ctrl.value * 4.4;

    // ── Background ──────────────────────────────────────────────────────────
    final bgIn = (t / 0.6).clamp(0.0, 1.0);

    // ── Avatar rise + Y-axis spin ───────────────────────────────────────────
    // 0.20 s → start; 1.40 s → fully landed (rise stops, spin ends face-forward)
    final riseRaw = ((t - 0.20) / 1.20).clamp(0.0, 1.0);
    final rise = _easeOutCubic(riseRaw);
    final avatarOffsetY = (1.0 - rise) * size.height * 1.3;
    // 2 full Y-axis turns (4π rad) → lands face-forward (cos 4π = 1)
    final spinRad = rise * 4.0 * math.pi;
    final avatarOp = (riseRaw * 4).clamp(0.0, 1.0);
    final isFront = math.cos(spinRad) >= 0;

    // ── Text stages ─────────────────────────────────────────────────────────
    final titleOp = _easeOut((t - 1.45) / 0.46);
    final titleTy = (1.0 - _easeOutBack((t - 1.45) / 0.62)) * 20.0;
    final msgOp = _easeOut((t - 1.70) / 0.42);
    final msgTy = (1.0 - _easeOut((t - 1.70) / 0.52)) * 10.0;
    final noteOp = _easeOut((t - 1.95) / 0.36);
    final noteTy = (1.0 - _easeOut((t - 1.95) / 0.42)) * 6.0;
    // Start radar button — last to appear, gentle pulse afterwards
    final hintOp = _easeOut((t - 2.40) / 0.50);
    final hintPulse =
        t > 2.90 ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin((t - 2.90) * 2.2)) : 1.0;

    // ── Partner data ─────────────────────────────────────────────────────────
    final photoUrl = profile != null && profile.primaryPhotoUrl.isNotEmpty
        ? profile.primaryPhotoUrl
        : null;
    final name = profile?.name ?? '';
    final age = profile?.age;
    final commonHobbies = _pickCommonHobbies(
      myHobbies,
      profile?.hobbies ?? const <Map<String, dynamic>>[],
    );

    // Dynamic font size: shorter messages render larger
    final msgLen = _pep.message.length;
    final msgSize = msgLen > 70
        ? 18.0
        : msgLen > 50
            ? 21.0
            : msgLen > 30
                ? 24.0
                : 28.0;

    return Stack(
      children: [
        // Background
        Positioned.fill(child: _buildBackground(bgIn)),

        // "We have a match" + partner name — anchored near top
        Positioned(
          top: 148,
          left: 28,
          right: 28,
          child: Opacity(
            opacity: titleOp,
            child: Transform.translate(
              offset: Offset(0, titleTy),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'We have a match',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: _cream,
                      height: 1.0,
                      letterSpacing: -1.4,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 32,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  if (name.isNotEmpty || age != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      '$name${age != null ? ', $age' : ''}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: _cream.withValues(alpha: 0.92),
                        height: 1.1,
                        letterSpacing: -0.48,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 22,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (commonHobbies.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final h in commonHobbies) _HobbyChip(label: h),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Center column: avatar + pep talk
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar — Y-axis spin + rise from below
              RepaintBoundary(
                child: Opacity(
                  opacity: avatarOp,
                  child: Transform.translate(
                    offset: Offset(0, avatarOffsetY),
                    child: SizedBox(
                      width: 188,
                      height: 188,
                      child: Stack(
                        children: [
                          // Back face (green disc, visible mid-spin)
                          if (!isFront)
                            Transform(
                              transform: _rotateY(spinRad + math.pi),
                              alignment: Alignment.center,
                              child: Container(
                                width: 188,
                                height: 188,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_greenDark, _greenLight],
                                  ),
                                ),
                              ),
                            ),
                          // Front face (photo or initial)
                          if (isFront)
                            Transform(
                              transform: _rotateY(spinRad),
                              alignment: Alignment.center,
                              child: _buildFrontFace(photoUrl, name),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Pep talk text
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: msgOp,
                      child: Transform.translate(
                        offset: Offset(0, msgTy),
                        child: Text(
                          _pep.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: msgSize,
                            fontWeight: FontWeight.w600,
                            color: _greenLight,
                            height: 1.3,
                            letterSpacing: -0.005 * msgSize,
                          ),
                        ),
                      ),
                    ),
                    if (_pep.note != null) ...[
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: noteOp,
                        child: Transform.translate(
                          offset: Offset(0, noteTy),
                          child: Text(
                            _pep.note!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: _cream.withValues(alpha: 0.42),
                              height: 1.5,
                              letterSpacing: 0.42,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: hintOp,
                      child: _StartRadarButton(
                        pulse: hintPulse,
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Picks up to 3 hobby names for the reveal card — shared hobbies first
  /// (matched by id), then the partner's remaining hobbies at random to fill.
  List<String> _pickCommonHobbies(
    List<Map<String, dynamic>> mine,
    List<Map<String, dynamic>> partner,
  ) {
    String? idOf(Map<String, dynamic> h) => (h['id'] ?? h['name']) as String?;
    String nameOf(Map<String, dynamic> h) =>
        ((h['name'] ?? h['id'] ?? '') as String).trim();

    final myIds = mine.map(idOf).whereType<String>().toSet();
    final shared = <String>[];
    final rest = <String>[];
    for (final h in partner) {
      final name = nameOf(h);
      if (name.isEmpty) continue;
      final id = idOf(h);
      if (id != null && myIds.contains(id)) {
        shared.add(name);
      } else {
        rest.add(name);
      }
    }
    rest.shuffle();
    return [...shared, ...rest].take(3).toList();
  }

  Widget _buildFrontFace(String? photoUrl, String name) {
    return Container(
      width: 188,
      height: 188,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenLight, _greenDark],
        ),
      ),
      child: ClipOval(
        child: Stack(
          children: [
            if (photoUrl != null)
              CachedNetworkImage(
                imageUrl: photoUrl,
                width: 188,
                height: 188,
                fit: BoxFit.cover,
              )
            else
              Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            // Inner highlight shimmer
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.5),
                    radius: 0.7,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(double bgIn) {
    return Stack(
      children: [
        // Base linear gradient
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgDeep, _bgMid, _bgBottom],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Green radial bloom — center
        Positioned.fill(
          child: Opacity(
            opacity: bgIn,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  // Alignment(0, -0.08) ≈ 50% horizontal, 46% vertical
                  center: Alignment(0, -0.08),
                  radius: 0.85,
                  colors: [
                    Color(0x8C2D9B6F), // rgba(45,155,111,0.55)
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Green glow — bottom edge
        Positioned.fill(
          child: Opacity(
            opacity: bgIn,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 0.65,
                  colors: [
                    Color(0x2E5BBF93), // rgba(91,191,147,0.18)
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single shared/partner hobby pill on the match reveal card.
class _HobbyChip extends StatelessWidget {
  final String label;
  const _HobbyChip({required this.label});

  static const _cream = TrembleTheme.backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _cream.withValues(alpha: 0.85),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// The explicit "Start radar" call-to-action that replaced the invisible
/// tap-anywhere gesture on the reveal. [pulse] drives a gentle breathing
/// opacity in sync with the scene animation.
class _StartRadarButton extends StatelessWidget {
  final double pulse;
  final VoidCallback onPressed;
  const _StartRadarButton({required this.pulse, required this.onPressed});

  static const _greenLight = Color(0xFF5BBF93);
  static const _greenDark = TrembleTheme.successGreen;
  static const _cream = TrembleTheme.backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: (0.85 + 0.15 * pulse).clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_greenLight, _greenDark],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: _greenDark.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar, size: 18, color: _cream),
              const SizedBox(width: 10),
              Text(
                'Start radar',
                style: GoogleFonts.instrumentSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _cream,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
