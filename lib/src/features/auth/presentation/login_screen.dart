import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/primary_button.dart';
import '../../../core/translations.dart';
import '../data/auth_repository.dart';
import 'radar_background.dart';

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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    String tr(String key) => t(key, lang);

    return Scaffold(
      body: RadarBackground(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.heartPulse,
                        size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    Text("Tremble",
                        style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),

                    const SizedBox(height: 8),
                    Text(tr('onb1_title'), // Using a translation for subtitle
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.white60,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 50),

                    // Email Input
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: tr('email'),
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(LucideIcons.mail, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Password Input
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: tr('password'),
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(LucideIcons.lock, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
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
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Premium Free Notice Pill
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E2E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.diamond,
                                    color: Color(0xFF00D9A6), size: 40),
                                const SizedBox(height: 16),
                                Text(
                                  tr('premium_free_notice'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr('current_users_count')
                                      .replaceAll('{count}', '4.832'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF00D9A6),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D9A6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00D9A6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: const Color(0xFF00D9A6)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.diamond,
                                color: Color(0xFF00D9A6), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Premium račun aktiviran',
                              style: TextStyle(
                                  color: Color(0xFF00D9A6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      PrimaryButton(
                          text: tr('login'),
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(authStateProvider.notifier).login(
                                  _emailController.text,
                                  _passwordController.text);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Login failed: $e")),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }),

                    const SizedBox(height: 16),
                    // Are you new Pill
                    GestureDetector(
                      onTap: () => context.push('/onboarding'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Center(
                          child: Text(
                            tr('are_you_new'),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Language selector pill at the bottom
                    GestureDetector(
                      onTap: () {
                        _showLanguagePicker(context, lang, ref);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              availableLanguages.firstWhere(
                                  (l) => l['code'] == lang,
                                  orElse: () =>
                                      availableLanguages.first)['label']!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.white70, size: 18),
                          ],
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
    );
  }

  void _showLanguagePicker(
      BuildContext context, String currentLang, WidgetRef ref) {
    String tr(String key) => t(key, currentLang);
    final isSlovenian = currentLang == 'sl';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateB) {
            String searchQuery = "";
            final filteredLangs = availableLanguages.where((l) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final enName = l['englishName']?.toLowerCase() ?? '';
              final natName = l['nativeName']?.toLowerCase() ?? '';
              final trName = tr(l['translationKey'] ?? '').toLowerCase();
              return enName.contains(q) ||
                  natName.contains(q) ||
                  trName.contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSlovenian ? 'Izberi jezik' : 'Select Language',
                      style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) => setStateB(() => searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isSlovenian ? "Išči..." : "Search...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(LucideIcons.search,
                            color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredLangs.length,
                        itemBuilder: (context, index) {
                          final l = filteredLangs[index];
                          final isSelected = l['code'] == currentLang;
                          return InkWell(
                            onTap: () {
                              ref.read(appLanguageProvider.notifier).state =
                                  l['code']!;
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00D9A6)
                                        .withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00D9A6)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    l['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF00D9A6), size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
