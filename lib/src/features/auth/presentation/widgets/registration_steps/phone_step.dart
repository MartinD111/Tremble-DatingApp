import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Country dial-code data
// ─────────────────────────────────────────────────────────────────────────────

class _Country {
  const _Country(this.flag, this.name, this.dialCode);
  final String flag;
  final String name;
  final String dialCode;
}

const _kCountries = [
  // ── EU ────────────────────────────────────────────────────────────────────
  _Country('🇦🇹', 'Austria', '+43'),
  _Country('🇧🇪', 'Belgium', '+32'),
  _Country('🇧🇬', 'Bulgaria', '+359'),
  _Country('🇭🇷', 'Croatia', '+385'),
  _Country('🇨🇾', 'Cyprus', '+357'),
  _Country('🇨🇿', 'Czech Republic', '+420'),
  _Country('🇩🇰', 'Denmark', '+45'),
  _Country('🇪🇪', 'Estonia', '+372'),
  _Country('🇫🇮', 'Finland', '+358'),
  _Country('🇫🇷', 'France', '+33'),
  _Country('🇩🇪', 'Germany', '+49'),
  _Country('🇬🇷', 'Greece', '+30'),
  _Country('🇭🇺', 'Hungary', '+36'),
  _Country('🇮🇪', 'Ireland', '+353'),
  _Country('🇮🇹', 'Italy', '+39'),
  _Country('🇱🇻', 'Latvia', '+371'),
  _Country('🇱🇹', 'Lithuania', '+370'),
  _Country('🇱🇺', 'Luxembourg', '+352'),
  _Country('🇲🇹', 'Malta', '+356'),
  _Country('🇳🇱', 'Netherlands', '+31'),
  _Country('🇵🇱', 'Poland', '+48'),
  _Country('🇵🇹', 'Portugal', '+351'),
  _Country('🇷🇴', 'Romania', '+40'),
  _Country('🇸🇰', 'Slovakia', '+421'),
  _Country('🇸🇮', 'Slovenia', '+386'),
  _Country('🇪🇸', 'Spain', '+34'),
  _Country('🇸🇪', 'Sweden', '+46'),
  // ── Non-EU Europe (common) ─────────────────────────────────────────────────
  _Country('🇨🇭', 'Switzerland', '+41'),
  _Country('🇳🇴', 'Norway', '+47'),
  _Country('🇮🇸', 'Iceland', '+354'),
  _Country('🇬🇧', 'United Kingdom', '+44'),
  _Country('🇷🇸', 'Serbia', '+381'),
  _Country('🇧🇦', 'Bosnia & Herzegovina', '+387'),
  _Country('🇲🇰', 'North Macedonia', '+389'),
  _Country('🇦🇱', 'Albania', '+355'),
  _Country('🇲🇪', 'Montenegro', '+382'),
  _Country('🇽🇰', 'Kosovo', '+383'),
  _Country('🇺🇦', 'Ukraine', '+380'),
  _Country('🇷🇺', 'Russia', '+7'),
  // ── North America ──────────────────────────────────────────────────────────
  _Country('🇺🇸', 'United States', '+1'),
  _Country('🇨🇦', 'Canada', '+1'),
  _Country('🇲🇽', 'Mexico', '+52'),
  // ── South America ─────────────────────────────────────────────────────────
  _Country('🇧🇷', 'Brazil', '+55'),
  _Country('🇦🇷', 'Argentina', '+54'),
  _Country('🇨🇱', 'Chile', '+56'),
  _Country('🇨🇴', 'Colombia', '+57'),
  _Country('🇵🇪', 'Peru', '+51'),
  _Country('🇻🇪', 'Venezuela', '+58'),
  _Country('🇪🇨', 'Ecuador', '+593'),
  _Country('🇧🇴', 'Bolivia', '+591'),
  _Country('🇵🇾', 'Paraguay', '+595'),
  _Country('🇺🇾', 'Uruguay', '+598'),
  _Country('🇬🇾', 'Guyana', '+592'),
  _Country('🇸🇷', 'Suriname', '+597'),
  // ── Oceania ───────────────────────────────────────────────────────────────
  _Country('🇦🇺', 'Australia', '+61'),
  _Country('🇳🇿', 'New Zealand', '+64'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Country picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<_Country?> _showCountryPicker(BuildContext context, bool isDark) {
  return showModalBottomSheet<_Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CountryPickerSheet(isDark: isDark),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.isDark});
  final bool isDark;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<_Country> _filtered = _kCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _kCountries
          : _kCountries
              .where((c) =>
                  c.name.toLowerCase().contains(lower) ||
                  c.dialCode.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1A1A18) : Colors.white;
    final borderColor =
        widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1);
    final hintColor = widget.isDark ? Colors.white38 : Colors.black38;
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final subColor = widget.isDark ? Colors.white54 : Colors.black54;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select country',
                style: GoogleFonts.instrumentSans(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                style: GoogleFonts.instrumentSans(
                    color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search country or code…',
                  hintStyle: GoogleFonts.instrumentSans(
                      color: hintColor, fontSize: 15),
                  prefixIcon:
                      Icon(LucideIcons.search, color: hintColor, size: 18),
                  filled: true,
                  fillColor: widget.isDark
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
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  return ListTile(
                    leading: Text(c.flag,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      c.name,
                      style: GoogleFonts.instrumentSans(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      c.dialCode,
                      style: GoogleFonts.instrumentSans(
                        color: subColor,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhoneStep
// ─────────────────────────────────────────────────────────────────────────────

class PhoneStep extends StatefulWidget {
  const PhoneStep({
    super.key,
    required this.phoneController,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.tr,
  });

  final TextEditingController phoneController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String Function(String) tr;

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  // Default to Slovenia (+386)
  _Country _selected =
      _kCountries.firstWhere((c) => c.dialCode == '+386' && c.name == 'Slovenia');

  void _openPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await _showCountryPicker(context, isDark);
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrembleBackButton(
                        onPressed: widget.onBack,
                        label: widget.tr('back')),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: Text(
                        widget.tr('skip'),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(
                  widget.tr('whats_your_phone'),
                  subtitle: widget.tr('phone_subtitle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Phone input with country prefix ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    // Country prefix button
                    GestureDetector(
                      onTap: _openPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selected.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selected.dialCode,
                              style: GoogleFonts.instrumentSans(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: iconColor, size: 18),
                          ],
                        ),
                      ),
                    ),

                    // Number input
                    Expanded(
                      child: TextField(
                        controller: widget.phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.instrumentSans(
                            color: textColor, fontSize: 17),
                        decoration: InputDecoration(
                          hintText: widget.tr('phone_label'),
                          hintStyle: GoogleFonts.instrumentSans(
                              color: hintColor, fontSize: 15),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: widget.phoneController.text.trim().length >= 7,
              onTap: widget.onNext,
              label: widget.tr('continue_btn'),
            ),
          ),
        ],
      ),
    );
  }
}
