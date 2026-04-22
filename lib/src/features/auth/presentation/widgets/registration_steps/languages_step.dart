import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class LanguagesStep extends StatelessWidget {
  const LanguagesStep({
    super.key,
    required this.selectedLanguages,
    required this.showCustom,
    required this.customLanguageController,
    required this.onToggleLanguage,
    required this.onToggleCustom,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final List<String> selectedLanguages;
  final bool showCustom;
  final TextEditingController customLanguageController;
  final void Function(String lang) onToggleLanguage;
  final VoidCallback onToggleCustom;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  static const _opts = [
    'Angleščina',
    'Slovenščina',
    'Nemščina',
    'Italijanščina',
    'Hrvaščina',
    'Španščina',
    'Francoščina',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrembleBackButton(label: tr('back'), onPressed: onBack),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(tr('how_many_languages')),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                ..._opts.map((lang) {
                  final sel = selectedLanguages.contains(lang);
                  final flags = {
                    'Angleščina': '🇬🇧',
                    'Slovenščina': '🇸🇮',
                    'Nemščina': '🇩🇪',
                    'Italijanščina': '🇮🇹',
                    'Hrvaščina': '🇭🇷',
                    'Španščina': '🇪🇸',
                    'Francoščina': '🇫🇷',
                  };
                  return OptionPill(
                    label: lang,
                    selected: sel,
                    emoji: flags[lang],
                    onTap: () => onToggleLanguage(lang),
                  );
                }),
                OptionPill(
                  label: 'Custom',
                  selected: showCustom,
                  onTap: onToggleCustom,
                ),
                if (showCustom)
                  TextField(
                    controller: customLanguageController,
                    style: GoogleFonts.instrumentSans(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('write_answer'),
                      hintStyle: GoogleFonts.instrumentSans(
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ListenableBuilder(
              listenable: customLanguageController,
              builder: (_, __) => ContinueButton(
                enabled: selectedLanguages.isNotEmpty ||
                    (showCustom && customLanguageController.text.isNotEmpty),
                onTap: onContinue,
                label: tr('continue_btn'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
