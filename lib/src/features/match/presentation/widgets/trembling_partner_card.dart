import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../matches/data/match_repository.dart';

/// Always-visible partner identity shown at the TOP of the trembling window
/// (the active mutual-wave radar search). A circle photo with the partner's
/// name + age underneath, so the user can re-check who they matched with while
/// the radar guides them together.
///
/// Pure + presentational: the free-vs-premium tap gate is owned by the caller
/// (via [onTap]) so this widget stays trivially testable and free of provider
/// dependencies. Identity is sourced from [MatchProfile] (the getMatches path),
/// never getPublicProfile — see BLOCKER-POSTMATCH-PHOTO.
class TremblingPartnerCard extends StatelessWidget {
  final MatchProfile partner;
  final VoidCallback onTap;

  /// Accent ring color. Defaults to the theme primary.
  final Color? accent;

  const TremblingPartnerCard({
    super.key,
    required this.partner,
    required this.onTap,
    this.accent,
  });

  static const double _avatarSize = 72;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ring = accent ?? colorScheme.primary;
    final photoUrl = partner.photoUrls.isNotEmpty
        ? partner.photoUrls.first
        : partner.imageUrl;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ring.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => _fallbackAvatar(colorScheme),
                    )
                  : _fallbackAvatar(colorScheme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            partner.age > 0 ? '${partner.name}, ${partner.age}' : partner.name,
            style: GoogleFonts.instrumentSans(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(ColorScheme colorScheme) => Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.person,
          size: _avatarSize * 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
      );
}
