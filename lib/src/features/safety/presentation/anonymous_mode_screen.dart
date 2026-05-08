import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/translations.dart';
import '../../../core/theme.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/contact_service.dart';

class AnonymousModeScreen extends ConsumerStatefulWidget {
  const AnonymousModeScreen({super.key});

  @override
  ConsumerState<AnonymousModeScreen> createState() =>
      _AnonymousModeScreenState();
}

class _AnonymousModeScreenState extends ConsumerState<AnonymousModeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);
  bool _isProcessing = false;
  int? _hiddenCount;

  String _t(String key) {
    final user = ref.read(authStateProvider);
    return t(key, user?.appLanguage ?? 'en');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final opacity =
          (1.0 - (_scrollController.offset / 60)).clamp(0.0, 1.0);
      if (_titleOpacity.value != opacity) _titleOpacity.value = opacity;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12;
    final topPad = MediaQuery.of(context).padding.top;

    return GradientScaffold(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24, topPad + 80, 24, 40),
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
                    child: const Icon(LucideIcons.shieldOff,
                        color: TrembleTheme.rose, size: 28),
                  ),
                ),
                const SizedBox(height: 24),

                _InfoBlock(
                  icon: LucideIcons.eyeOff,
                  title: 'What Anonymous Mode does',
                  body:
                      'When enabled, Tremble scans your contacts locally on your device and ensures that people in your address book cannot discover your profile — and you cannot discover theirs.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),

                _InfoBlock(
                  icon: LucideIcons.lock,
                  title: 'Your contacts stay on your device',
                  body:
                      'Phone numbers are hashed (SHA-256) locally before any data leaves your device. The actual phone numbers are never uploaded to our servers — only the fingerprints are used for matching.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),

                _InfoBlock(
                  icon: LucideIcons.server,
                  title: 'No storage, no logs',
                  body:
                      'Tremble does not store, log, or retain your contact list. The matching happens ephemerally in a Cloud Function — the list is discarded immediately after the check. We have no way to reconstruct who your contacts are.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),
                const SizedBox(height: 12),

                _InfoBlock(
                  icon: LucideIcons.userX,
                  title: 'Mutual — they cannot find you either',
                  body:
                      'If someone in your contacts has also enabled Anonymous Mode, neither of you will appear in the other\'s radar results. The protection is always bidirectional.',
                  textColor: textColor,
                  subColor: subColor,
                  cardBg: cardBg,
                ),

                Divider(color: dividerColor, height: 40),

                if (_hiddenCount != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _t('anonymity_active').replaceAll(
                                '{count}', _hiddenCount.toString()),
                            style: GoogleFonts.instrumentSans(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrembleTheme.rose,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);
                            try {
                              final count =
                                  await ContactService.secureAndSyncContacts(
                                      '+386');
                              setState(() {
                                _hiddenCount = count;
                                _isProcessing = false;
                              });
                            } catch (e) {
                              setState(() => _isProcessing = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed: ${e.toString()}')),
                                );
                              }
                            }
                          },
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _t('anonymity_grant_permission'),
                            style: GoogleFonts.instrumentSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, _) => TrembleHeader(
              title: 'Anonymous\nMode',
              titleOpacity: opacity,
              buttonsOpacity: opacity,
            ),
          ),
        ],
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
