import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class ConsentStep extends StatefulWidget {
  const ConsentStep({
    super.key,
    required this.onBack,
    required this.onComplete,
    required this.tr,
    this.photoUploadError,
  });

  final VoidCallback onBack;
  final void Function(
    bool religionConsent,
    bool ethnicityConsent,
    bool sexualOrientationConsent,
  ) onComplete;
  final String Function(String) tr;
  final String? photoUploadError;

  @override
  State<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<ConsentStep> {
  bool _consentTerms = false;
  bool _consentPrivacy = false;
  bool _consentDataProcessing = false;
  bool _consentAge = false;
  bool _consentLocation = false;
  bool _consentReligion = false;
  bool _consentEthnicity = false;
  // GDPR Art. 9 — explicit consent for processing gender + matching
  // preferences (sexual orientation is inferrable). Blocks registration.
  bool _consentSexualOrientation = false;

  bool get _consentGiven =>
      _consentTerms &&
      _consentPrivacy &&
      _consentDataProcessing &&
      _consentAge &&
      _consentLocation &&
      _consentSexualOrientation;

  void _toggleAll() {
    // Select-all covers ONLY the general-processing consents. GDPR Art. 9
    // special-category tiles (orientation, religion, ethnicity) must be
    // toggled individually — a select-all shortcut is incompatible with
    // "specific" consent per Art. 9(2)(a). The orientation tile remains
    // in `_consentGiven` because it is required to complete registration;
    // it just isn't in the select-all sweep.
    final newVal = !_consentGiven;
    setState(() {
      _consentTerms = newVal;
      _consentPrivacy = newVal;
      _consentDataProcessing = newVal;
      _consentAge = newVal;
      _consentLocation = newVal;
    });
  }

  /// Builds a rich span for an Art. 9 tile: the narrow-purpose consent body
  /// followed by a "Learn more" link that deep-links to the corresponding
  /// Privacy Policy anchor. The anchor resolves to the PP root when the
  /// section is not yet published (LEGAL-001 lane), so the link never
  /// dangles.
  InlineSpan _art9TileSpan({
    required String body,
    required String anchor,
    required TextStyle bodyStyle,
  }) {
    return TextSpan(
      style: bodyStyle,
      children: [
        TextSpan(text: body),
        const TextSpan(text: ' '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://trembledating.com/privacy#$anchor'),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              widget.tr('consent_art9_learn_more'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _consentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required InlineSpan richText,
    Key? key,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      key: key,
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value
                      ? Theme.of(context).colorScheme.primary
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
          Row(
            children: [
              TrembleBackButton(
                  label: widget.tr('back'), onPressed: widget.onBack),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          StepHeader(
            'Privacy and GDPR',
            subtitle: widget.tr('consent_subtitle'),
          ),
          const SizedBox(height: 24),
          OptionPill(
            label: widget.tr('select_all'),
            selected: _consentGiven,
            onTap: _toggleAll,
            icon: Icons.done_all,
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentTerms,
            onChanged: (v) => setState(() => _consentTerms = v),
            richText: TextSpan(
              style: bodyStyle,
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://trembledating.com/tos'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text('Terms of Service',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
                    onTap: () => launchUrl(
                      Uri.parse('https://trembledating.com/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text('Privacy Policy',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
                        'I explicitly consent to the processing of my profile data '
                        '(interests, preferences) for the purpose of matchmaking. '
                        'I understand this data is protected by Google Cloud infrastructure-level encryption at rest, never sold, and I can withdraw consent '
                        'at any time from Settings.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            key: const Key('art9-religion-tile'),
            value: _consentReligion,
            onChanged: (v) => setState(() => _consentReligion = v),
            richText: _art9TileSpan(
              body: widget.tr('consent_art9_religion_v1'),
              anchor: 'art9-religion',
              bodyStyle: bodyStyle,
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            key: const Key('art9-ethnicity-tile'),
            value: _consentEthnicity,
            onChanged: (v) => setState(() => _consentEthnicity = v),
            richText: _art9TileSpan(
              body: widget.tr('consent_art9_ethnicity_v1'),
              anchor: 'art9-ethnicity',
              bodyStyle: bodyStyle,
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            key: const Key('art9-orientation-tile'),
            value: _consentSexualOrientation,
            onChanged: (v) => setState(() => _consentSexualOrientation = v),
            richText: _art9TileSpan(
              body: widget.tr('consent_art9_orientation_v1'),
              anchor: 'art9-orientation',
              bodyStyle: bodyStyle,
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentAge,
            onChanged: (v) => setState(() => _consentAge = v),
            richText: TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: widget.tr('consent_age_18')),
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
                Icon(Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 20),
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
          if (widget.photoUploadError != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.photoUploadError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          ContinueButton(
            enabled: _consentGiven,
            onTap: () => widget.onComplete(
              _consentReligion,
              _consentEthnicity,
              _consentSexualOrientation,
            ),
            label: 'Continue',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
