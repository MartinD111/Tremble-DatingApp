import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/primary_button.dart';
import '../data/auth_repository.dart';
import 'radar_background.dart';

/// Forgot Password flow (real Firebase):
/// 1. User enters email → Firebase sends reset link
/// 2. Confirmation shown — user clicks link in their email → resets on Firebase page
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  /// 0 = enter email, 1 = email sent confirmation
  int _step = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        setState(() => _step = 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RadarBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildEmailSentStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final textHint = isDark ? Colors.white70 : Colors.black45;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      key: const ValueKey('email_step'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.keyRound, size: 60, color: textPrimary),
        const SizedBox(height: 20),
        Text("Forgot Password",
            style: GoogleFonts.instrumentSans(
                fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 10),
        Text("Enter your email to receive a reset link",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.instrumentSans(fontSize: 15, color: textSecondary)),
        const SizedBox(height: 40),

        // Email Field
        TextField(
          controller: _emailController,
          style: TextStyle(color: textPrimary),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: textHint),
            prefixIcon: Icon(LucideIcons.mail, color: textHint),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderFocusColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: fillColor,
          ),
        ),
        const SizedBox(height: 25),

        if (_isLoading)
          CircularProgressIndicator(color: textPrimary)
        else
          PrimaryButton(
            text: "Send Reset Email",
            onPressed: _sendResetEmail,
          ),

        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.pop(),
          child: Text("Back to Login", style: TextStyle(color: textSecondary)),
        ),
      ],
    );
  }

  Widget _buildEmailSentStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final textBody = isDark ? Colors.white70 : Colors.black54;
    final infoBoxBg = isDark
        ? Colors.blue.withValues(alpha: 0.15)
        : Colors.blue.withValues(alpha: 0.08);
    final infoBoxBorder = isDark
        ? Colors.blue.withValues(alpha: 0.3)
        : Colors.blue.withValues(alpha: 0.4);

    return Column(
      key: const ValueKey('sent_step'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: const Icon(LucideIcons.mailCheck,
                  size: 70, color: Colors.greenAccent),
            );
          },
        ),
        const SizedBox(height: 25),
        Text("Email Sent!",
            style: GoogleFonts.instrumentSans(
                fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 12),
        Text("Check your inbox for ${_emailController.text}",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 15)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: infoBoxBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: infoBoxBorder),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info,
                  color: Colors.lightBlueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text("Click the link in the email to continue…",
                    style: GoogleFonts.instrumentSans(
                        color: textBody, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        TextButton(
          onPressed: () => context.pop(),
          child: Text('Back to Login',
              style: TextStyle(color: textSecondary, fontSize: 15)),
        ),
      ],
    );
  }
}
