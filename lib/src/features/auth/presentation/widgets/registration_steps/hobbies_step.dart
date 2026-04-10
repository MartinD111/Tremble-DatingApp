import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class HobbiesStep extends StatefulWidget {
  const HobbiesStep({
    super.key,
    required this.selectedHobbies,
    required this.onAddHobby,
    required this.onRemoveHobby,
    required this.onBack,
    required this.onContinue,
    required this.tr,
  });

  final List<String> selectedHobbies;
  final void Function(String hobby) onAddHobby;
  final void Function(String hobby) onRemoveHobby;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String Function(String) tr;

  @override
  State<HobbiesStep> createState() => _HobbiesStepState();
}

class _HobbiesStepState extends State<HobbiesStep> {
  final Map<String, ExpansibleController> _tileControllers = {};

  static const Map<String, List<String>> _cats = {
    'Active 🏋️': [
      'Fitnes',
      'Pilates',
      'Sprehodi',
      'Tek',
      'Smučanje',
      'Snowboarding',
      'Plezanje',
      'Plavanje',
    ],
    'Prosti čas ☕': [
      'Branje',
      'Kava',
      'Čaj',
      'Kuhanje',
      'Filmi',
      'Serije',
      'Videoigre',
      'Glasba',
    ],
    'Umetnost 🎨': [
      'Slikanje',
      'Fotografija',
      'Pisanje',
      'Muzeji',
      'Gledališče',
    ],
    'Potovanja ✈️': [
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
                      color: const Color(0xFFF4436C)))),
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

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TrembleBackButton(
                label: widget.tr('back'), onPressed: widget.onBack),
            const SizedBox(height: 16),
            StepHeader(
              widget.tr('hobbies'),
              subtitle:
                  '${widget.selectedHobbies.length} ${widget.tr('hobbies_selected').replaceAll('{count}', '')}',
            ),
          ]),
        ),
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
                        selectedColor: const Color(0xFFF4436C),
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
                        iconColor: const Color(0xFFF4436C),
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
                      title: Text(
                          '${e.key} (${e.value.where((h) => widget.selectedHobbies.contains(h)).length})',
                          style: GoogleFonts.instrumentSans(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold)),
                      children: [
                        Wrap(
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
                                    fontWeight:
                                        sel ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                selected: sel,
                                onSelected: (s) => s
                                    ? widget.onAddHobby(hobby)
                                    : widget.onRemoveHobby(hobby),
                                selectedColor: const Color(0xFFF4436C),
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white12
                                    : Colors.black12,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: sel
                                        ? const Color(0xFFF4436C)
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
                              backgroundColor: const Color(0xFFF4436C),
                              shape: const StadiumBorder(),
                              onPressed: _showAddHobbyDialog,
                            ),
                          ],
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
            label: widget.tr('continue_btn'),
          ),
        ),
      ]),
    );
  }
}
