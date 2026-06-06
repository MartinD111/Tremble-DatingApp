import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/ui/tremble_logo.dart';
import '../../../shared/ui/primary_button.dart';
import '../../../core/translations.dart';
import '../data/auth_repository.dart';
import 'radar_background.dart';
import '../../../core/theme.dart';

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
    final bottomPadding = mediaQuery.padding.bottom + 32;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFlag = loginLanguageOptions
        .firstWhere((o) => o.code == lang,
            orElse: () => loginLanguageOptions.first)
        .flag;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: RadarBackground(
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
                                backgroundColor: isDark
                                    ? const Color(0xFF2A2A2C)
                                    : const Color(0xFFF1F3F4),
                                foregroundColor: isDark
                                    ? Colors.white
                                    : TrembleTheme.textColor,
                                borderColor: isDark
                                    ? Colors.white24
                                    : const Color(0xFFD0D0D0),
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
                                icon: const _AppleIcon(color: Colors.black),
                                text: tr('continue_with_apple'),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                borderColor: isDark
                                    ? Colors.white
                                    : const Color(0xFFCCCCCC),
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
                            color: isDark
                                ? const Color(0xFF2A2A2E)
                                : const Color(0xFFE8E8E4),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : const Color(0xFFCCCCC8),
                            ),
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
                      const SizedBox(height: 8),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.12),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
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
                          ? TrembleTheme.rose.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? TrembleTheme.rose
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
                              color: TrembleTheme.rose, size: 20),
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
// Google G icon — official 4-colour SVG mark
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apple logo icon — official monochrome SVG path
// ─────────────────────────────────────────────────────────────────────────────

class _AppleIcon extends StatelessWidget {
  const _AppleIcon({required this.color});

  final Color color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="black" d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social sign-in button
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
