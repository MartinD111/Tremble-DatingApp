import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PreferencePillRow — unified row widget for enum-style preferences.
//
// Layout: [icon] [label] [spacer] [value pill] [edit circle]
//
// - values: list of raw stored values (e.g. ['christianity'])
// - formatter: maps raw value → human-readable label
// - onTap: called when the value pill is tapped (show selected info)
// - onEdit: called when the edit circle is tapped (open edit modal)
// - isPremium: if true, shows a lock icon next to the label
// ─────────────────────────────────────────────────────────────────────────────

class PreferencePillRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String?> values; // nullable: null = not set
  final String Function(String) formatter;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final bool isPremium;

  const PreferencePillRow({
    super.key,
    required this.icon,
    required this.label,
    required this.values,
    required this.formatter,
    required this.onEdit,
    this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final pillBg =
        isDark ? const Color(0xFF2A2A28) : Colors.black.withValues(alpha: 0.06);
    final pillBorder = isDark
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
        : Colors.black12;
    final iconColor = isDark ? Colors.white70 : Colors.black45;
    final editIconColor = isDark ? Colors.white54 : Colors.black38;

    final nonNull = values.whereType<String>().toList();
    final String displayLabel;
    if (nonNull.isEmpty) {
      displayLabel = '—';
    } else if (nonNull.length == 1) {
      displayLabel = formatter(nonNull.first);
    } else {
      displayLabel = 'Selected ${nonNull.length}';
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
        if (isPremium) ...[
          const SizedBox(width: 6),
          const Icon(LucideIcons.lock, size: 13, color: Colors.amber),
        ],
        const Spacer(),
        // Value pill — max 140px wide, ellipsis on overflow
        GestureDetector(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: pillBorder),
              ),
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subColor, fontSize: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Edit circle
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pillBg,
              border: Border.all(color: pillBorder),
            ),
            child: Icon(
              LucideIcons.pencil,
              size: 14,
              color: editIconColor,
            ),
          ),
        ),
      ],
    );
  }
}
