import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme.dart';
import '../../../../shared/ui/primary_button.dart';

/// Cold-offline state for the map card.
///
/// Airplane mode makes `mapInitProvider` fail its `PmTilesVectorTileProvider`
/// host lookup, which used to surface as raw red `Error loading map: <e>` text.
/// This is the human-facing replacement: an offline icon, a short line, and a
/// retry that re-runs init (the caller wires `onRetry` to
/// `ref.invalidate(mapInitProvider)`), so a transient failure recovers on
/// reconnect.
///
/// Sized to fit inside the rounded, shadowed map container — not a full-screen
/// Scaffold like [TrembleOutageScreen]. Content is centered and scrollable so
/// it never overflows a short map slot.
class MapOfflineCard extends StatelessWidget {
  const MapOfflineCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TrembleTheme.rose.withValues(alpha: 0.14),
              ),
              child: const Icon(
                LucideIcons.cloudOff,
                color: TrembleTheme.rose,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                color: Colors.white.withValues(alpha: 0.68),
                height: 1.3,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: retryLabel,
              onPressed: onRetry,
              width: 160,
              height: 44,
              icon: LucideIcons.refreshCw,
            ),
          ],
        ),
      ),
    );
  }
}
