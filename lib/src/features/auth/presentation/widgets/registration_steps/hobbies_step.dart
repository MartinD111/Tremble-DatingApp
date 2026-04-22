import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

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
  });

  final List<String> selectedHobbies;
  final void Function(String hobby) onAddHobby;
  final void Function(String hobby) onRemoveHobby;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;
  final bool isModal;

  @override
  State<HobbiesStep> createState() => _HobbiesStepState();
}

class _HobbiesStepState extends State<HobbiesStep> {
  final Map<String, ExpansibleController> _tileControllers = {};

  static const Map<String, IconData> _catIcons = {
    'Active': LucideIcons.dumbbell,
    'Prosti čas': LucideIcons.coffee,
    'Umetnost': LucideIcons.palette,
    'Potovanja': LucideIcons.plane,
  };

  static const Map<String, List<String>> _cats = {
    'Active': [
      'Fitnes',
      'Pilates',
      'Sprehodi',
      'Tek',
      'Smučanje',
      'Snowboarding',
      'Plezanje',
      'Plavanje',
    ],
    'Prosti čas': [
      'Branje',
      'Kava',
      'Čaj',
      'Kuhanje',
      'Filmi',
      'Serije',
      'Videoigre',
      'Glasba',
    ],
    'Umetnost': [
      'Slikanje',
      'Fotografija',
      'Pisanje',
      'Muzeji',
      'Gledališče',
    ],
    'Potovanja': [
      'Roadtrips',
      'Camping',
      'City breaks',
      'Backpacking',
    ],
  };

  ExpansibleController _tileController(String key) {
    return _tileControllers.putIfAbsent(key, ExpansibleController.new);
  }

  void _showAddHobbyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        title: Text(widget.tr('add_hobby'),
            style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white : Colors.black)),
        content: TextField(
            controller: ctrl,
            style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white : Colors.black),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.tr('cancel'))),
          TextButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  widget.onAddHobby(ctrl.text);
                  Navigator.pop(ctx);
                }
              },
              child: Text(widget.tr('add'),
                  style: GoogleFonts.instrumentSans(
                      color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final predefinedHobbies = _cats.values.expand((e) => e).toSet();
    final customHobbies = widget.selectedHobbies
        .where((h) => !predefinedHobbies.contains(h))
        .toList();

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
                  subtitle:
                      '${widget.selectedHobbies.length} ${widget.tr('hobbies_selected').replaceAll('{count}', '')}',
                ),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customHobbies.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(widget.tr('my_hobbies_custom'),
                            style: GoogleFonts.instrumentSans(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: customHobbies.map((hobby) {
                          return FilterChip(
                            label: Text(
                              hobby,
                              style: GoogleFonts.instrumentSans(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: true,
                            onSelected: (_) => widget.onRemoveHobby(hobby),
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.05),
                            shape: StadiumBorder(
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.1)),
                            ),
                            checkmarkColor: Colors.black,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ..._cats.entries.map((e) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          expansionTileTheme: ExpansionTileThemeData(
                            iconColor: Theme.of(context).colorScheme.primary,
                            collapsedIconColor:
                                isDark ? Colors.white : Colors.black54,
                          ),
                        ),
                        child: ExpansionTile(
                          controller: _tileController(e.key),
                          expansionAnimationStyle: AnimationStyle(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              for (final key in _cats.keys) {
                                if (key != e.key) {
                                  _tileController(key).collapse();
                                }
                              }
                            }
                          },
                          title: Row(
                            children: [
                              if (_catIcons[e.key] != null)
                                Icon(
                                  _catIcons[e.key],
                                  size: 18,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              if (_catIcons[e.key] != null)
                                const SizedBox(width: 8),
                              Text(
                                '${e.key} (${e.value.where((h) => widget.selectedHobbies.contains(h)).length})',
                                style: GoogleFonts.instrumentSans(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...e.value.map((hobby) {
                                    final sel =
                                        widget.selectedHobbies.contains(hobby);
                                    return FilterChip(
                                      label: Text(
                                        hobby,
                                        style: GoogleFonts.instrumentSans(
                                          color: sel
                                              ? Colors.black
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                          fontWeight: sel
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      selected: sel,
                                      onSelected: (s) => s
                                          ? widget.onAddHobby(hobby)
                                          : widget.onRemoveHobby(hobby),
                                      selectedColor:
                                          Theme.of(context).colorScheme.primary,
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white12
                                              : Colors.black12,
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color: sel
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white24
                                                  : Colors.black26),
                                        ),
                                      ),
                                      checkmarkColor: Colors.black,
                                    );
                                  }),
                                  ActionChip(
                                    label: Text(widget.tr('add_own'),
                                        style: GoogleFonts.instrumentSans(
                                            color: Colors.black)),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    shape: const StadiumBorder(),
                                    onPressed: _showAddHobbyDialog,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }),
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
}
