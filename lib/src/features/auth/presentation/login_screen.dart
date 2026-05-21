import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/tremble_logo.dart';
import '../../../shared/ui/primary_button.dart';
import '../../../core/translations.dart';
import '../data/auth_repository.dart';
import 'radar_background.dart';

@immutable
class LoginLanguageOption {
  const LoginLanguageOption({
    required this.code,
    required this.flag,
    required this.label,
  });

  final String code;
  final String flag;
  final String label;
}

const loginLanguageOptions = [
  LoginLanguageOption(code: 'sl', flag: '🇸🇮', label: 'Slovenščina'),
  LoginLanguageOption(code: 'en', flag: '🇬🇧', label: 'English'),
  LoginLanguageOption(code: 'hr', flag: '🇭🇷', label: 'Hrvatski'),
  LoginLanguageOption(code: 'de', flag: '🇩🇪', label: 'Deutsch'),
  LoginLanguageOption(code: 'it', flag: '🇮🇹', label: 'Italiano'),
  LoginLanguageOption(code: 'fr', flag: '🇫🇷', label: 'Français'),
  LoginLanguageOption(code: 'hu', flag: '🇭🇺', label: 'Magyar'),
  LoginLanguageOption(code: 'sr', flag: '🇷🇸', label: 'Srpski'),
];

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LoginScreenStateful();
  }
}

class _LoginScreenStateful extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LoginScreenStateful> createState() =>
      _LoginScreenStatefulState();
}

class _LoginScreenStatefulState extends ConsumerState<_LoginScreenStateful> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _authErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Napačno geslo ali e-pošta.';
        case 'user-not-found':
          return 'Uporabnik s tem e-poštnim naslovom ne obstaja.';
        case 'invalid-email':
          return 'E-poštni naslov ni veljavne oblike.';
        case 'user-disabled':
          return 'Ta račun je bil onemogočen.';
        case 'too-many-requests':
          return 'Preveč poskusov. Počakaj trenutek in poskusi znova.';
        case 'network-request-failed':
          return 'Ni internetne povezave.';
        default:
          return 'Prijava ni uspela. Poskusi znova.';
      }
    }
    return 'Prijava ni uspela. Poskusi znova.';
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLanguageSheet(String currentCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LanguageSheet(
        currentCode: currentCode,
        onChanged: (code) {
          ref.read(appLanguageProvider.notifier).setLanguage(code);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    String tr(String key) => t(key, lang);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom + 24;
    final currentFlag = loginLanguageOptions
        .firstWhere((o) => o.code == lang,
            orElse: () => loginLanguageOptions.first)
        .flag;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A18),
      body: SafeArea(
        child: RadarBackground(
          backgroundColor: const Color(0xFF1A1A18),
          child: Stack(
            children: [
              // ── Main scrollable content ────────────────────────────────────
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    30,
                    56, // leave room for top-right button
                    30,
                    bottomPadding + mediaQuery.viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TrembleLogo(size: 140),
                      const SizedBox(height: 20),
                      Text(
                        'Tremble',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('onb1_title'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 34),

                      // Email Input
                      TextField(
                        controller: _emailController,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: tr('email'),
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7)),
                          prefixIcon: Icon(LucideIcons.mail,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: tr('password'),
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7)),
                          prefixIcon: Icon(LucideIcons.lock,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Forgot password
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: Text(
                            tr('forgot_password'),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary)
                      else
                        PrimaryButton(
                          text: tr('login'),
                          onPressed: () => _runAuthAction(
                            () => ref.read(authStateProvider.notifier).login(
                                  _emailController.text,
                                  _passwordController.text,
                                ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (!_isLoading) ...[
                        Row(
                          children: [
                            // Google
                            Expanded(
                              child: _SocialSignInButton(
                                icon: const _GoogleIcon(),
                                text: tr('continue_with_google'),
                                backgroundColor: const Color(0xFF1E1E1E)
                                    .withValues(alpha: 0.86),
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSurface,
                                borderColor: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.28),
                                onTap: () => _runAuthAction(
                                  () => ref
                                      .read(authStateProvider.notifier)
                                      .signInWithGoogle(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Apple
                            Expanded(
                              child: _SocialSignInButton(
                                icon: const _AppleIcon(),
                                text: tr('continue_with_apple'),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                borderColor: Colors.white,
                                onTap: () => _runAuthAction(
                                  () => ref
                                      .read(authStateProvider.notifier)
                                      .signInWithApple(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Are you new pill
                      GestureDetector(
                        onTap: () async {
                          if (FirebaseAuth.instance.currentUser != null) {
                            await FirebaseAuth.instance.signOut();
                          }
                          if (context.mounted) context.push('/onboarding');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Text(
                              tr('are_you_new'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Language button — top-right corner ────────────────────────
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => _showLanguageSheet(lang),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentFlag,
                            style: const TextStyle(fontSize: 20, height: 1)),
                        const SizedBox(width: 6),
                        Icon(LucideIcons.chevronDown,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.currentCode,
    required this.onChanged,
  });

  final String currentCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xE6181818),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Language',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...loginLanguageOptions.map((lang) {
                final isSelected = lang.code == currentCode;
                return GestureDetector(
                  onTap: () => onChanged(lang.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF4436C).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF4436C)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag,
                            style: const TextStyle(fontSize: 22, height: 1)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lang.label,
                            style: GoogleFonts.instrumentSans(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFFF4436C), size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google G icon — multicolor segments
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    const strokeW = 3.8;
    final rect =
        Rect.fromCircle(center: Offset(cx, cy), radius: r - strokeW / 2);

    void arc(Color color, double startDeg, double sweepDeg) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt;
      final startRad = startDeg * 3.14159265 / 180;
      final sweepRad = sweepDeg * 3.14159265 / 180;
      canvas.drawArc(rect, startRad, sweepRad, false, paint);
    }

    // Google colors: Blue, Red, Yellow, Green — roughly quartered
    arc(const Color(0xFF4285F4), -10, 100); // Blue (top-right → bottom)
    arc(const Color(0xFFEA4335), 90, 100); // Red (bottom → left)
    arc(const Color(0xFFFBBC05), 190, 90); // Yellow (left → top-left)
    arc(const Color(0xFF34A853), 280, 80); // Green (top-left → top-right)

    // Horizontal bar for the G cutout
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r - strokeW / 2, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter old) => false;
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _ApplePainter()),
    );
  }
}

class _ApplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Apple logo drawn as a simple path scaled to the bounding box.
    // Shape: round body with a bite taken from the right, and a leaf on top.
    final path = Path();

    // Body — approximate Apple logo outline
    final body = Path();
    // Left lobe
    body.moveTo(w * 0.50, h * 0.28);
    body.cubicTo(w * 0.50, h * 0.18, w * 0.36, h * 0.12, w * 0.26, h * 0.18);
    body.cubicTo(w * 0.14, h * 0.25, w * 0.10, h * 0.42, w * 0.13, h * 0.57);
    body.cubicTo(w * 0.17, h * 0.74, w * 0.28, h * 0.92, w * 0.40, h * 0.92);
    body.cubicTo(w * 0.47, h * 0.92, w * 0.50, h * 0.88, w * 0.50, h * 0.88);
    // Right lobe
    body.cubicTo(w * 0.50, h * 0.88, w * 0.53, h * 0.92, w * 0.60, h * 0.92);
    body.cubicTo(w * 0.72, h * 0.92, w * 0.83, h * 0.74, w * 0.87, h * 0.57);
    body.cubicTo(w * 0.90, h * 0.42, w * 0.86, h * 0.25, w * 0.74, h * 0.18);
    body.cubicTo(w * 0.64, h * 0.12, w * 0.50, h * 0.18, w * 0.50, h * 0.28);
    body.close();

    // Leaf (stem going up-right)
    final leaf = Path();
    leaf.moveTo(w * 0.50, h * 0.28);
    leaf.cubicTo(w * 0.50, h * 0.18, w * 0.58, h * 0.06, w * 0.68, h * 0.04);
    leaf.cubicTo(w * 0.68, h * 0.04, w * 0.62, h * 0.16, w * 0.50, h * 0.28);
    leaf.close();

    path.addPath(body, Offset.zero);
    path.addPath(leaf, Offset.zero);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ApplePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Social sign-in button — icon is now a Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final Widget icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 9),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foregroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
