import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/places_service.dart';
import '../domain/selected_gym.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymSearchWidget
//
// Reusable component used in both the onboarding GymStep and the Settings
// "My Gyms" section. Handles autocomplete search via PlacesService, displays
// selected gym tiles, and enforces the 3-gym cap through [onAdd]'s return value.
// ─────────────────────────────────────────────────────────────────────────────

class GymSearchWidget extends ConsumerStatefulWidget {
  const GymSearchWidget({
    super.key,
    required this.selectedGyms,
    required this.onAdd,
    required this.onRemove,
    this.onSearchFocused,
    this.focusNode,
  });

  /// Current selection (read-only; owned by parent state).
  final List<SelectedGym> selectedGyms;

  /// Called when the user picks a gym. Returns true on success, false when
  /// the 3-gym limit is already reached.
  final Future<bool> Function(SelectedGym gym) onAdd;

  /// Called when the user removes a selected gym.
  final void Function(String placeId) onRemove;

  /// Called when the search field gains focus — used to scroll it into view.
  final VoidCallback? onSearchFocused;

  /// Optional external focus node. If provided, the widget uses this instead
  /// of its internal one — allows the parent to programmatically focus the field.
  final FocusNode? focusNode;

  @override
  ConsumerState<GymSearchWidget> createState() => _GymSearchWidgetState();
}

class _GymSearchWidgetState extends ConsumerState<GymSearchWidget> {
  static const _brandRose = Color(0xFFF4436C);
  static const _debounceMs = 300;

  final _searchController = TextEditingController();
  final _internalFocus = FocusNode();
  late final PlacesService _places;
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;

  FocusNode get _searchFocus => widget.focusNode ?? _internalFocus;

  @override
  void initState() {
    super.initState();
    _places = ref.read(placesServiceProvider);
    _places.startSession();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        widget.onSearchFocused?.call();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _internalFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () async {
      setState(() => _isSearching = true);
      final results = await _places.gymAutocomplete(value);
      if (mounted)
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    final details = await _places.getPlaceDetails(prediction.placeId);
    if (details == null) return;

    final gym = SelectedGym(
      placeId: prediction.placeId,
      name: details.name.isNotEmpty ? details.name : prediction.displayName,
      address: details.address,
      lat: details.lat,
      lng: details.lng,
    );

    final added = await widget.onAdd(gym);

    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Max 3 gyms reached',
            style: GoogleFonts.instrumentSans(),
          ),
          backgroundColor: _brandRose,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Reset search field and restart session for the next search.
    _searchController.clear();
    setState(() => _predictions = []);
    _places.startSession();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search field ─────────────────────────────────────────────────
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          style: GoogleFonts.instrumentSans(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search for your gym...',
            hintStyle: GoogleFonts.instrumentSans(
              color: hintColor,
              fontSize: 15,
            ),
            prefixIcon: Icon(LucideIcons.search, color: hintColor, size: 18),
            suffixIcon: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _brandRose,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        // ── Predictions ──────────────────────────────────────────────────
        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1C) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: borderColor,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, i) {
                final p = _predictions[i];
                return ListTile(
                  dense: true,
                  leading:
                      Icon(LucideIcons.dumbbell, color: _brandRose, size: 18),
                  title: Text(
                    p.mainText ?? p.description,
                    style: GoogleFonts.instrumentSans(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: p.secondaryText != null
                      ? Text(
                          p.secondaryText!,
                          style: GoogleFonts.instrumentSans(
                            color: hintColor,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  onTap: () => _selectPrediction(p),
                );
              },
            ),
          ),
        ],

        // ── Selected gyms ────────────────────────────────────────────────
        if (widget.selectedGyms.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...widget.selectedGyms.map(
            (gym) => _GymTile(
              gym: gym,
              onRemove: () => widget.onRemove(gym.placeId),
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GymTile — a single selected gym row with remove icon.
// ─────────────────────────────────────────────────────────────────────────────

class _GymTile extends StatelessWidget {
  const _GymTile({
    required this.gym,
    required this.onRemove,
    required this.isDark,
  });

  final SelectedGym gym;
  final VoidCallback onRemove;
  final bool isDark;

  static const _brandRose = Color(0xFFF4436C);

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _brandRose.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _brandRose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(LucideIcons.dumbbell, color: _brandRose, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: GoogleFonts.instrumentSans(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (gym.address.isNotEmpty)
                  Text(
                    gym.address,
                    style: GoogleFonts.instrumentSans(
                      color: subColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.x,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
