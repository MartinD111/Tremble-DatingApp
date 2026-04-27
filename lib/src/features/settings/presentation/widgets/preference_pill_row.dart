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
  final IconData? Function(String)? iconMapper;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final bool isPremium;

  const PreferencePillRow({
    super.key,
    required this.icon,
    required this.label,
    required this.values,
    required this.formatter,
    this.iconMapper,
    required this.onEdit,
    this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54;
    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black45;

    final nonNull = values.whereType<String>().toList();
    
    Widget buildPillContent() {
      if (nonNull.isEmpty) {
        return Text('—', style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600));
      }
      
      if (nonNull.length == 1) {
        final val = nonNull.first;
        final pillIcon = iconMapper?.call(val);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pillIcon != null) ...[
              Icon(pillIcon, size: 14, color: subColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                formatter(val),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      }
      
      return Text(
        'Izbrano: ${nonNull.length}',
        style: TextStyle(
          color: subColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.lock, size: 13, color: Colors.amber),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right-side group: Pill + Edit
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: pillBorder),
                  ),
                  child: buildPillContent(),
                ),
              ),
              const SizedBox(width: 10),
              // Edit circle
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
