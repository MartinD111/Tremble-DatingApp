import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DRUM PICKER
// A scroll-wheel date/value picker used by BirthdayStep and HeightStep.
// ─────────────────────────────────────────────────────────────────────────────
class DrumPicker extends StatefulWidget {
  const DrumPicker({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.looping = false,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool looping;

  @override
  State<DrumPicker> createState() => _DrumPickerState();
}

class _DrumPickerState extends State<DrumPicker> {
  late FixedExtentScrollController _ctrl;

  // Tracks the last index we reported via onChanged (from user scroll).
  // didUpdateWidget uses this to distinguish user-initiated changes (skip
  // jumpToItem — the scroll controller is already there) from programmatic
  // external changes like a month switch resetting the day column (jump needed).
  int _lastReported = 0;

  @override
  void initState() {
    super.initState();
    _lastReported = widget.selectedIndex;
    _ctrl = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(DrumPicker old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && _ctrl.hasClients) {
      // Only jump when the change was NOT triggered by the user scrolling this
      // column. If it was user-initiated, the scroll controller already sits at
      // the correct position — jumping would cancel the in-flight fling and
      // produce the step-by-step behaviour reported in the bug.
      if (widget.selectedIndex != _lastReported) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_ctrl.hasClients) _ctrl.jumpToItem(widget.selectedIndex);
        });
      }
      _lastReported = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Colors.black87;
    final inactiveColor = isDark ? Colors.white38 : Colors.black26;

    return ListWheelScrollView.useDelegate(
      controller: _ctrl,
      itemExtent: 44,
      perspective: 0.004,
      diameterRatio: 1.8,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        final reported = widget.looping ? i % widget.items.length : i;
        _lastReported = reported;
        widget.onChanged(reported);
      },
      childDelegate: widget.looping
          ? ListWheelChildLoopingListDelegate(
              children: List.generate(widget.items.length, (i) {
                final selected =
                    i == (widget.selectedIndex % widget.items.length);
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.instrumentSans(
                      fontSize: selected ? 20 : 16,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? activeColor : inactiveColor,
                    ),
                    child: Text(widget.items[i]),
                  ),
                );
              }),
            )
          : ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (ctx, i) {
                final selected = i == widget.selectedIndex;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.instrumentSans(
                      fontSize: selected ? 20 : 16,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? activeColor : inactiveColor,
                    ),
                    child: Text(widget.items[i]),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTINUE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class ContinueButton extends StatelessWidget {
  const ContinueButton({
    super.key,
    required this.enabled,
    required this.onTap,
    this.label,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label ?? 'Naprej',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? Colors.black
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black38),
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTION PILL
// ─────────────────────────────────────────────────────────────────────────────
class OptionPill extends StatelessWidget {
  const OptionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.emoji,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.white38 : Colors.black26),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ??
                    (selected
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black54)),
                size: 20,
              ),
              const SizedBox(width: 12),
            ] else if (emoji != null) ...[
              Text(
                emoji!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xDDFFFFFF) : Colors.black87),
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP HEADER
// ─────────────────────────────────────────────────────────────────────────────
class StepHeader extends StatelessWidget {
  const StepHeader(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive font size: smaller on mobile, larger on tablet
    final titleFontSize = screenWidth < 400 ? 28.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.instrumentSans(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCROLLABLE FORM PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ScrollableFormPage extends StatelessWidget {
  const ScrollableFormPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
  }
}
