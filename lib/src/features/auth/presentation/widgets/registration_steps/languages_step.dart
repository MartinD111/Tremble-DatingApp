import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class LanguagesStep extends StatefulWidget {
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
    'lang_english',
    'lang_german',
    'lang_french',
    'lang_spanish',
    'lang_italian',
    'lang_portuguese',
    'lang_dutch',
    'lang_polish',
    'lang_czech',
    'lang_slovak',
    'lang_hungarian',
    'lang_romanian',
    'lang_bulgarian',
    'lang_greek',
    'lang_swedish',
    'lang_norwegian',
    'lang_danish',
    'lang_finnish',
    'lang_estonian',
    'lang_latvian',
    'lang_lithuanian',
    'lang_slovenian',
    'lang_croatian',
    'lang_serbian',
    'lang_bosnian',
    'lang_montenegrin',
    'lang_albanian',
    'lang_macedonian',
    'lang_ukrainian',
    'lang_russian',
    'lang_turkish',
    'lang_arabic',
    'lang_chinese',
    'lang_japanese',
    'lang_korean',
    'lang_hindi',
  ];

  static const _langFlags = {
    'lang_english': '🇬🇧',
    'lang_german': '🇩🇪',
    'lang_french': '🇫🇷',
    'lang_spanish': '🇪🇸',
    'lang_italian': '🇮🇹',
    'lang_portuguese': '🇵🇹',
    'lang_dutch': '🇳🇱',
    'lang_polish': '🇵🇱',
    'lang_czech': '🇨🇿',
    'lang_slovak': '🇸🇰',
    'lang_hungarian': '🇭🇺',
    'lang_romanian': '🇷🇴',
    'lang_bulgarian': '🇧🇬',
    'lang_greek': '🇬🇷',
    'lang_swedish': '🇸🇪',
    'lang_norwegian': '🇳🇴',
    'lang_danish': '🇩🇰',
    'lang_finnish': '🇫🇮',
    'lang_estonian': '🇪🇪',
    'lang_latvian': '🇱🇻',
    'lang_lithuanian': '🇱🇹',
    'lang_slovenian': '🇸🇮',
    'lang_croatian': '🇭🇷',
    'lang_serbian': '🇷🇸',
    'lang_bosnian': '🇧🇦',
    'lang_montenegrin': '🇲🇪',
    'lang_albanian': '🇦🇱',
    'lang_macedonian': '🇲🇰',
    'lang_ukrainian': '🇺🇦',
    'lang_russian': '🇷🇺',
    'lang_turkish': '🇹🇷',
    'lang_arabic': '🇸🇦',
    'lang_chinese': '🇨🇳',
    'lang_japanese': '🇯🇵',
    'lang_korean': '🇰🇷',
    'lang_hindi': '🇮🇳',
  };

  @override
  State<LanguagesStep> createState() => _LanguagesStepState();
}

class _LanguagesStepState extends State<LanguagesStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    final filtered = (_query.isEmpty
            ? List<String>.from(LanguagesStep._opts)
            : LanguagesStep._opts.where((lang) {
                final name = widget.tr(lang).toLowerCase();
                return name.contains(_query.toLowerCase());
              }).toList())
      ..sort((a, b) => widget.tr(a).compareTo(widget.tr(b)));

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
                    TrembleBackButton(
                        label: widget.tr('back'), onPressed: widget.onBack),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader('How many languages do you speak? (${widget.selectedLanguages.length}/5)'),
                const SizedBox(height: 16),
                // ── Search field ───────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search language…',
                    hintStyle: GoogleFonts.instrumentSans(
                        color: hintColor, fontSize: 15),
                    prefixIcon:
                        Icon(LucideIcons.search, color: hintColor, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x,
                                color: hintColor, size: 16),
                            onPressed: () => setState(() {
                              _query = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No languages found',
                        style: GoogleFonts.instrumentSans(
                          color: hintColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((lang) {
                    final sel = widget.selectedLanguages.contains(lang);
                    final atLimit = widget.selectedLanguages.length >= 5;
                    final disabled = !sel && atLimit;
                    return OptionPill(
                      label: widget.tr(lang),
                      selected: sel,
                      emoji: LanguagesStep._langFlags[lang],
                      onTap: disabled ? () {} : () => widget.onToggleLanguage(lang),
                    );
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: widget.selectedLanguages.isNotEmpty,
              onTap: widget.onContinue,
              label: widget.tr('continue_btn'),
            ),
          ),
        ],
      ),
    );
  }
}
