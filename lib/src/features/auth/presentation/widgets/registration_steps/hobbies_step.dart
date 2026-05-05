import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import '../../../../../core/hobby_data.dart';

class HobbiesStep extends StatefulWidget {
  const HobbiesStep({
    super.key,
    required this.selectedHobbies,
    required this.onAddHobby,
    required this.onRemoveHobby,
    this.onBack,
    required this.onContinue,
    required this.tr,
    this.isModal = false,
    this.scrollController,
  });

  final List<Map<String, dynamic>> selectedHobbies;
  final void Function(Map<String, dynamic> hobby) onAddHobby;
  final void Function(Map<String, dynamic> hobby) onRemoveHobby;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;
  final bool isModal;
  final ScrollController? scrollController;

  @override
  State<HobbiesStep> createState() => _HobbiesStepState();
}

class _HobbiesStepState extends State<HobbiesStep> {
  String? _openCategory;
  final Map<String, GlobalKey> _categoryKeys = {};

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'hobby_cat_active':
        return LucideIcons.zap;
      case 'hobby_cat_leisure':
        return LucideIcons.coffee;
      case 'hobby_cat_art':
        return LucideIcons.palette;
      case 'hobby_cat_travel':
        return LucideIcons.map;
      default:
        return LucideIcons.sparkles;
    }
  }

  void _showAddHobbyDialog(String categoryKey, String categoryLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        title: Text('${widget.tr('hobby_other')} - $categoryLabel',
            style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: widget.tr('name'),
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
                style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: emojiCtrl,
                decoration: InputDecoration(
                  labelText: 'Emoji',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
                style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.tr('cancel'))),
          TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final newHobby = {
                    'name': nameCtrl.text.trim(),
                    'emoji': emojiCtrl.text.trim().isNotEmpty
                        ? emojiCtrl.text.trim()
                        : '✨',
                    'category': categoryKey,
                    'custom': true,
                  };
                  widget.onAddHobby(newHobby);
                  Navigator.pop(ctx);
                }
              },
              child: Text(widget.tr('add'),
                  style: GoogleFonts.instrumentSans(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  bool _isSelected(Map<String, dynamic> hobby) {
    return widget.selectedHobbies.any((h) => h['name'] == hobby['name']);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = HobbyData.groupedHobbies;

    final customHobbies =
        widget.selectedHobbies.where((h) => h['custom'] == true).toList();

    return Container(
      decoration: widget.isModal
          ? BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            )
          : null,
      child: SafeArea(
        child: Column(
          children: [
            if (widget.isModal) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Row(
                  children: [
                    TrembleBackButton(
                      label: widget.tr('back'),
                      onPressed:
                          widget.onBack ?? () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StepHeader(
                  widget.tr('hobbies'),
                  subtitle: widget.tr('hobbies_selected').replaceAll(
                      '{count}', widget.selectedHobbies.length.toString()),
                ),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...grouped.entries.map((e) {
                      final catKey = e.key;
                      final translatedName = widget.tr(catKey);
                      final isOpen = _openCategory == catKey;

                      // Merge predefined and custom hobbies for this category
                      final categoryHobbies = [...e.value];
                      categoryHobbies.addAll(
                          customHobbies.where((h) => h['category'] == catKey));

                      final selectedCount =
                          categoryHobbies.where((h) => _isSelected(h)).length;
                      final titleText = selectedCount > 0
                          ? '$translatedName ($selectedCount)'
                          : translatedName;

                      final containerKey =
                          _categoryKeys.putIfAbsent(catKey, () => GlobalKey());
                      return Container(
                        key: containerKey,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                final wasOpen = _openCategory == catKey;
                                setState(() {
                                  _openCategory = wasOpen ? null : catKey;
                                });
                                if (!wasOpen) {
                                  final key = _categoryKeys[catKey];
                                  if (key != null) {
                                    // Wait for AnimatedSize to finish (300ms) then scroll
                                    Future.delayed(
                                        const Duration(milliseconds: 320), () {
                                      final sc = widget.scrollController;
                                      final ctx = key.currentContext;
                                      if (sc == null ||
                                          !sc.hasClients ||
                                          ctx == null) return;
                                      final box =
                                          ctx.findRenderObject() as RenderBox?;
                                      if (box == null) return;
                                      final offset =
                                          box.localToGlobal(Offset.zero).dy;
                                      final scrollOffset = sc.offset +
                                          offset -
                                          MediaQuery.of(context).padding.top -
                                          16;
                                      sc.animateTo(
                                        scrollOffset.clamp(
                                            0.0, sc.position.maxScrollExtent),
                                        duration:
                                            const Duration(milliseconds: 350),
                                        curve: Curves.easeInOut,
                                      );
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Icon(_getCategoryIcon(catKey),
                                        size: 20,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(titleText,
                                          style: GoogleFonts.instrumentSans(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Icon(LucideIcons.chevronDown,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: isOpen
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children:
                                                categoryHobbies.map((hobby) {
                                              final sel = _isSelected(hobby);
                                              return _buildPill(
                                                  hobby, sel, isDark);
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 16),
                                          GestureDetector(
                                            onTap: () => _showAddHobbyDialog(
                                                catKey, translatedName),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.add,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                                  const SizedBox(width: 6),
                                                  Text(widget.tr('hobby_other'),
                                                      style: GoogleFonts
                                                          .instrumentSans(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(
                                      width: double.infinity, height: 0),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ContinueButton(
                enabled: true,
                onTap: widget.onContinue,
                label: widget.tr(widget.isModal ? 'save' : 'continue_btn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(Map<String, dynamic> hobby, bool selected, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (selected) {
          widget.onRemoveHobby(hobby);
        } else {
          widget.onAddHobby(hobby);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : (isDark ? Colors.white12 : Colors.black12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hobby['emoji'] as String,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              hobby['name'] as String,
              style: GoogleFonts.instrumentSans(
                color: selected
                    ? Colors.black
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
