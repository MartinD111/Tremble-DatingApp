import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone edit bottom-sheet modal. Mirrors the onboarding PhoneStep UI:
// country dial-code prefix (with searchable picker) + national number input.
// Returns the combined "+<code><number>" string via [onSave].
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
  // ── Non-EU Europe ─────────────────────────────────────────────────────────
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
  // ── North America ─────────────────────────────────────────────────────────
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

_Country _defaultCountry() =>
    _kCountries.firstWhere((c) => c.dialCode == '+386' && c.name == 'Slovenia');

/// Splits an existing "+<code><number>" string into a country and the national
/// portion. Falls back to Slovenia if no match is found.
({_Country country, String number}) _splitPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return (country: _defaultCountry(), number: '');
  }
  final trimmed = raw.trim();
  final sorted = [..._kCountries]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final c in sorted) {
    if (trimmed.startsWith(c.dialCode)) {
      return (country: c, number: trimmed.substring(c.dialCode.length).trim());
    }
  }
  return (country: _defaultCountry(), number: trimmed);
}

Future<void> showPhoneEditModal({
  required BuildContext context,
  required String? currentPhone,
  required ValueChanged<String> onSave,
  String title = 'Phone number',
  String hint = 'Phone number',
  String saveLabel = 'Save',
  String cancelLabel = 'Cancel',
  String searchHint = 'Search country or code…',
  String countryPickerTitle = 'Select country',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PhoneEditSheet(
      currentPhone: currentPhone,
      title: title,
      hint: hint,
      saveLabel: saveLabel,
      cancelLabel: cancelLabel,
      searchHint: searchHint,
      countryPickerTitle: countryPickerTitle,
      onSave: (v) {
        onSave(v);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _PhoneEditSheet extends StatefulWidget {
  const _PhoneEditSheet({
    required this.currentPhone,
    required this.onSave,
    required this.title,
    required this.hint,
    required this.saveLabel,
    required this.cancelLabel,
    required this.searchHint,
    required this.countryPickerTitle,
  });

  final String? currentPhone;
  final ValueChanged<String> onSave;
  final String title;
  final String hint;
  final String saveLabel;
  final String cancelLabel;
  final String searchHint;
  final String countryPickerTitle;

  @override
  State<_PhoneEditSheet> createState() => _PhoneEditSheetState();
}

class _PhoneEditSheetState extends State<_PhoneEditSheet> {
  late _Country _selected;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final parsed = _splitPhone(widget.currentPhone);
    _selected = parsed.country;
    _phoneController = TextEditingController(text: parsed.number);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        isDark: isDark,
        title: widget.countryPickerTitle,
        searchHint: widget.searchHint,
      ),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final brandRose = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;

    final enabled = _phoneController.text.trim().length >= 7;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.phone,
                  size: 20, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Phone input with country prefix
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openCountryPicker,
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
                        Text(_selected.flag,
                            style: const TextStyle(fontSize: 20)),
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
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: GoogleFonts.instrumentSans(
                        color: textColor, fontSize: 17),
                    decoration: InputDecoration(
                      hintText: widget.hint,
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
          const SizedBox(height: 24),
          // Save / Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isDark ? Colors.white38 : Colors.black26),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.cancelLabel,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRose,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        brandRose.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: enabled
                      ? () => widget.onSave(
                          '${_selected.dialCode}${_phoneController.text.trim()}')
                      : null,
                  child: Text(widget.saveLabel,
                      style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.isDark,
    required this.title,
    required this.searchHint,
  });
  final bool isDark;
  final String title;
  final String searchHint;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.title,
                style: GoogleFonts.instrumentSans(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                style: GoogleFonts.instrumentSans(
                    color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
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
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  return ListTile(
                    leading:
                        Text(c.flag, style: const TextStyle(fontSize: 24)),
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
                          color: subColor, fontSize: 14),
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
