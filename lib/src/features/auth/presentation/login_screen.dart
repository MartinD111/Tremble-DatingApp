import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Local state for text fields provided by hooks or just use StatefulWidget if needed.
    // Since this is ConsumerWidget, we can't use setState easily without converting.
    // Let's convert to ConsumerStatefulWidget to handle text controllers.
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    String tr(String key) => t(key, lang);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom + 24;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A18),
      body: SafeArea(
        child: RadarBackground(
          backgroundColor: const Color(0xFF1A1A18),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    30,
                    24,
                    30,
                    bottomPadding + mediaQuery.viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TrembleLogo(size: 140),
                      const SizedBox(height: 20),
                      Text("Tremble",
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              )),

                      const SizedBox(height: 8),
                      Text(tr('onb1_title'),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    letterSpacing: 0.5,
                                  )),
                      const SizedBox(height: 18),
                      _LoginLanguageRow(
                        currentCode: lang,
                        onChanged: (code) {
                          ref
                              .read(appLanguageProvider.notifier)
                              .setLanguage(code);
                        },
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

                      // Forgot password link
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
                            Expanded(
                              child: _SocialSignInButton(
                                icon: 'G',
                                text: tr('continue_with_google'),
                                iconColor: const Color(0xFF4285F4),
                                backgroundColor:
                                    const Color(0xFF1E1E1E).withValues(
                                  alpha: 0.86,
                                ),
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
                            Expanded(
                              child: _SocialSignInButton(
                                icon: '',
                                text: tr('continue_with_apple'),
                                iconColor: Colors.black,
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

                      // Are you new Pill
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginLanguageRow extends StatelessWidget {
  const _LoginLanguageRow({
    required this.currentCode,
    required this.onChanged,
  });

  final String currentCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final language in loginLanguageOptions)
          Tooltip(
            message: language.label,
            child: Semantics(
              button: true,
              selected: language.code == currentCode,
              label: language.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(language.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: language.code == currentCode
                        ? colorScheme.primary.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: language.code == currentCode
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.18),
                      width: language.code == currentCode ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 18, height: 1),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String icon;
  final String text;
  final Color iconColor;
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
              Text(
                icon,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  height: 1,
                ),
              ),
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
