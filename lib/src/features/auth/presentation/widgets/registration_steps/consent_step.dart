import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class ConsentStep extends StatefulWidget {
  const ConsentStep({
    super.key,
    required this.onBack,
    required this.onComplete,
    required this.tr,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;
  final String Function(String) tr;

  @override
  State<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<ConsentStep> {
  bool _consentTerms = false;
  bool _consentPrivacy = false;
  bool _consentDataProcessing = false;
  bool _consentLocation = false;

  bool get _consentGiven =>
      _consentTerms &&
      _consentPrivacy &&
      _consentDataProcessing &&
      _consentLocation;

  void _toggleAll() {
    final newVal = !_consentGiven;
    setState(() {
      _consentTerms = newVal;
      _consentPrivacy = newVal;
      _consentDataProcessing = newVal;
      _consentLocation = newVal;
    });
  }

  Widget _consentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required InlineSpan richText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? kBrandRose : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value
                      ? kBrandRose
                      : (isDark ? Colors.white38 : Colors.black38),
                  width: 2),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: RichText(text: richText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontSize: 14,
      height: 1.5,
    );

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrembleBackButton(label: widget.tr('back'), onPressed: widget.onBack),
          const SizedBox(height: 24),
          StepHeader(
            'Privacy and GDPR',
            subtitle: widget.tr('consent_subtitle'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _toggleAll,
              icon: Icon(
                _consentGiven ? Icons.check_box : Icons.check_box_outline_blank,
                color: kBrandRose,
              ),
              label: Text(
                'Izberi Vse',
                style: GoogleFonts.instrumentSans(
                  color: kBrandRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _consentTile(
            value: _consentTerms,
            onChanged: (v) => setState(() => _consentTerms = v),
            richText: TextSpan(
              style: bodyStyle,
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Terms of Service',
                        style: TextStyle(
                            color: kBrandRose,
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ),
                const TextSpan(text: ' of Tremble.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentPrivacy,
            onChanged: (v) => setState(() => _consentPrivacy = v),
            richText: TextSpan(
              style: bodyStyle,
              children: [
                const TextSpan(text: 'I have read and accept the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Privacy Policy',
                        style: TextStyle(
                            color: kBrandRose,
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ),
                const TextSpan(text: ', including GDPR data processing.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentDataProcessing,
            onChanged: (v) => setState(() => _consentDataProcessing = v),
            richText: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(
                    text:
                        'I explicitly consent to the processing of my sensitive personal data '
                        '(interests, preferences, religion, ethnicity) for the purpose of matchmaking. '
                        'I understand this data is encrypted, never sold, and I can withdraw consent '
                        'at any time from Settings.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentLocation,
            onChanged: (v) => setState(() => _consentLocation = v),
            richText: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(
                    text:
                        'I consent to live location tracking for the Radar feature. '
                        'Only an approximate grid position (~38m accuracy) is stored — '
                        'never my exact coordinates. Location data auto-deletes after 2 hours of inactivity. '
                        'I can disable Radar at any time from Settings.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: kBrandRose, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is stored securely, never sold to third parties, '
                    'and can be exported or deleted at any time from Settings.',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: _consentGiven,
            onTap: widget.onComplete,
            label: 'Continue',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
