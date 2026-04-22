import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/translations.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class EmailLocationStep extends StatefulWidget {
  const EmailLocationStep({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.locationController,
    required this.isRegistering,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController locationController;
  final bool isRegistering;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  @override
  State<EmailLocationStep> createState() => _EmailLocationStepState();
}

class _EmailLocationStepState extends State<EmailLocationStep> {
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.red;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasDigit && _hasSpecialChar;

  void _updatePasswordStrength(String pw) {
    _hasMinLength = pw.length >= 8;
    _hasUppercase = pw.contains(RegExp(r'[A-Z]'));
    _hasDigit = pw.contains(RegExp(r'[0-9]'));
    _hasSpecialChar =
        pw.contains(RegExp(r'[!@#%^&*()_+\-=\[\]{};:,.<>?/\\|`~]'));
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;
    if (pw.length >= 12) score++;
    if (pw.length >= 16) score++;
    if (pw.contains(RegExp(r'[a-z]'))) score++;
    double strength = math.min(score / 5.0, 1.0);
    if (pw.isEmpty) strength = 0.0;
    String label;
    Color color;
    if (strength == 0) {
      label = '';
      color = Colors.red;
    } else if (strength < 0.3) {
      label = widget.tr('very_weak');
      color = Colors.red;
    } else if (strength < 0.5) {
      label = widget.tr('weak');
      color = Colors.orange;
    } else if (strength < 0.7) {
      label = widget.tr('medium');
      color = Colors.amber;
    } else if (strength < 0.9) {
      label = widget.tr('strong');
      color = const Color(0xFF2D9B6F);
    } else {
      label = widget.tr('very_strong');
      color = const Color(0xFF2D9B6F);
    }
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType? keyboard,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      readOnly: readOnly,
      style: GoogleFonts.instrumentSans(color: textColor, fontSize: 17),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        prefixIcon:
            icon != null ? Icon(icon, color: iconColor, size: 20) : null,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  Widget _passwordInputField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: widget.passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.instrumentSans(color: textColor, fontSize: 17),
      onChanged: _updatePasswordStrength,
      decoration: InputDecoration(
        labelText: widget.tr('password'),
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        prefixIcon: Icon(LucideIcons.lock, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
              color: iconColor, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _confirmPasswordInputField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: TextStyle(color: textColor, fontSize: 17),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: widget.tr('confirm_password'),
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(LucideIcons.lock, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
              _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
              color: iconColor,
              size: 20),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
    );
  }

  Widget _passwordStrengthBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? Colors.white12 : Colors.black12;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _passwordStrength),
      duration: const Duration(milliseconds: 400),
      builder: (ctx, val, _) => Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
              )),
        ),
        const SizedBox(height: 4),
        Align(
            alignment: Alignment.centerRight,
            child: Text(_passwordStrengthLabel,
                style: TextStyle(
                    color: _passwordStrengthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _pwReq(String text, bool met) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unmetIconColor = isDark ? Colors.white30 : Colors.black26;
    final unmetTextColor = isDark ? Colors.white38 : Colors.black45;
    final successColor = isDark ? Colors.greenAccent : const Color(0xFF2D9B6F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(met ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 14, color: met ? successColor : unmetIconColor),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: met ? successColor : unmetTextColor,
                decoration: met ? TextDecoration.lineThrough : null,
                decorationColor: successColor.withValues(alpha: 0.5))),
      ]),
    );
  }

  Widget _locationAutocomplete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return Autocomplete<String>(
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const Iterable<String>.empty();
        return locationSuggestions
            .where((c) => c.toLowerCase().contains(tv.text.toLowerCase()));
      },
      onSelected: (s) => setState(() => widget.locationController.text = s),
      fieldViewBuilder: (ctx, ctrl, fn, _) {
        if (widget.locationController.text.isNotEmpty && ctrl.text.isEmpty) {
          ctrl.text = widget.locationController.text;
        }
        return TextField(
          controller: ctrl,
          focusNode: fn,
          style: TextStyle(color: textColor, fontSize: 17),
          onChanged: (v) {
            widget.locationController.text = v;
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: widget.tr('from_where'),
            labelStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(LucideIcons.mapPin, color: iconColor, size: 20),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: borderFocusColor, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180, maxWidth: 340),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: opts.length,
              itemBuilder: (ctx, i) {
                final o = opts.elementAt(i);
                return ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.mapPin,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black54),
                    title: Text(o, style: TextStyle(color: textColor)),
                    onTap: () => onSel(o));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPill() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.diamond,
                      color: Theme.of(context).colorScheme.primary, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    widget.tr('premium_free_notice'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget
                        .tr('current_users_count')
                        .replaceAll('{count}', '4.832'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.diamond,
                  color: Theme.of(context).colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.tr('premium_account_activated'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAlreadyLoggedIn = currentUser != null;
    final isSocialUser = currentUser?.providerData.any((p) =>
            p.providerId == 'google.com' || p.providerId == 'apple.com') ??
        false;
    final hasPassword =
        currentUser?.providerData.any((p) => p.providerId == 'password') ??
            false;
    // A user with a password provider but an unverified email is mid-registration
    // (stale partial session). They must enter a new password — treat them the
    // same as a brand-new user for the purposes of this step.
    final isVerifiedPasswordUser =
        hasPassword && (currentUser?.emailVerified ?? false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TrembleBackButton(
                    label: widget.tr('back'), onPressed: widget.onBack),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            StepHeader(widget.tr('basic_info')),
            const SizedBox(height: 32),
            if (isAlreadyLoggedIn &&
                (isSocialUser || isVerifiedPasswordUser) &&
                widget.emailController.text.isNotEmpty)
              _inputField(widget.tr('email'), widget.emailController,
                  icon: LucideIcons.mail,
                  keyboard: TextInputType.emailAddress,
                  readOnly: true)
            else
              _inputField(widget.tr('email'), widget.emailController,
                  icon: LucideIcons.mail,
                  keyboard: TextInputType.emailAddress,
                  readOnly: false),
            const SizedBox(height: 20),
            _locationAutocomplete(),
            if (!isVerifiedPasswordUser && !isSocialUser) ...[
              const SizedBox(height: 20),
              _passwordInputField(),
              const SizedBox(height: 20),
              _confirmPasswordInputField(),
              if (widget.passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _passwordStrengthBar(),
                const SizedBox(height: 8),
                _pwReq(widget.tr('pw_min_length'), _hasMinLength),
                _pwReq(widget.tr('pw_uppercase'), _hasUppercase),
                _pwReq(widget.tr('pw_digit'), _hasDigit),
                _pwReq(widget.tr('pw_special'), _hasSpecialChar),
                _pwReq(
                    widget.tr('confirm_password'),
                    widget.passwordController.text ==
                            _confirmPasswordController.text &&
                        _confirmPasswordController.text.isNotEmpty),
              ],
            ],
            const SizedBox(height: 32),
            _buildPremiumPill(),
            const SizedBox(height: 32),
            widget.isRegistering
                ? Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary))
                : ContinueButton(
                    enabled: widget.emailController.text.isNotEmpty &&
                        ((isAlreadyLoggedIn &&
                                (isSocialUser || isVerifiedPasswordUser)) ||
                            (_isPasswordValid &&
                                widget.passwordController.text ==
                                    _confirmPasswordController.text)),
                    onTap: widget.onContinue,
                    label: widget.tr('continue_btn'),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
