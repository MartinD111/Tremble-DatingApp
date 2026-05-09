import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme.dart';
import '../../../core/translations.dart';

/// Data model for an event displayed on the map.
class TrembleEventData {
  final String id;
  final String name;
  final bool isActive;
  final String? startsAt;
  final int peopleCount;
  final String? locationLabel;

  const TrembleEventData({
    required this.id,
    required this.name,
    required this.isActive,
    this.startsAt,
    required this.peopleCount,
    this.locationLabel,
  });
}

/// Bottom sheet shown when a user taps an event marker on the map.
///
/// Free tier: event name + time + share button. People count and heatmap hidden.
/// Pro tier / Taste of Premium: all of the above + people count + heatmap indicator.
class EventPinSheet extends StatelessWidget {
  final TrembleEventData event;
  final bool effectiveIsPremium;
  final bool isTasteOfPremium;
  final bool isDark;
  final String lang;

  const EventPinSheet({
    super.key,
    required this.event,
    required this.effectiveIsPremium,
    required this.isTasteOfPremium,
    required this.isDark,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : TrembleTheme.textColor;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Taste of Premium banner ──────────────────────────────
            if (isTasteOfPremium) ...[
              _TasteOfPremiumBanner(isDark: isDark, lang: lang),
              const SizedBox(height: 16),
            ],

            // ── Event header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EventStatusDot(isActive: event.isActive),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: TrembleTheme.displayFont(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.isActive
                              ? t('active_now', lang)
                              : t('coming_at', lang)
                                  .replaceAll('{time}', event.startsAt ?? ''),
                          style: TrembleTheme.uiFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: event.isActive
                                ? TrembleTheme.rose
                                : TrembleTheme.accentYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 16),

            // ── People count row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: effectiveIsPremium
                  ? _PeopleCountRow(
                      count: event.peopleCount,
                      isDark: isDark,
                      lang: lang,
                    )
                  : _LockedFeatureRow(
                      label:
                          t('pulsing_here', lang).replaceAll('{count}', '??'),
                      sublabel: t('pro_feature_locked', lang),
                      isDark: isDark,
                    ),
            ),

            const SizedBox(height: 12),

            // ── Heatmap indicator ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: effectiveIsPremium
                  ? _HeatmapActiveRow(isDark: isDark, lang: lang)
                  : _LockedFeatureRow(
                      label: 'Heatmap',
                      sublabel: t('heatmap_locked', lang),
                      isDark: isDark,
                    ),
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 16),

            // ── Action buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ShareButton(event: event, isDark: isDark, lang: lang),
                  if (!effectiveIsPremium && event.isActive) ...[
                    const SizedBox(height: 10),
                    _UnlockButton(isDark: isDark, lang: lang),
                  ],
                ],
              ),
            ),

            // ── Dev-only: geofence simulation ────────────────────────
            if (const String.fromEnvironment('FLAVOR', defaultValue: 'dev') ==
                'dev') ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DevGeofenceControls(
                  event: event,
                  inGeofence: isTasteOfPremium,
                  isDark: isDark,
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TasteOfPremiumBanner extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _TasteOfPremiumBanner({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5C842), Color(0xFFFFAA30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('taste_of_premium', lang),
                  style: TrembleTheme.uiFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  t('taste_of_premium_sub', lang),
                  style: TrembleTheme.uiFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1A1A18).withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventStatusDot extends StatelessWidget {
  final bool isActive;
  const _EventStatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? TrembleTheme.rose : TrembleTheme.accentYellow;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Icon(
          isActive ? Icons.bolt_rounded : Icons.schedule_rounded,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}

class _PeopleCountRow extends StatelessWidget {
  final int count;
  final bool isDark;
  final String lang;

  const _PeopleCountRow(
      {required this.count, required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.favorite_rounded, color: TrembleTheme.rose, size: 18),
        const SizedBox(width: 10),
        Text(
          t('pulsing_here', lang).replaceAll('{count}', '$count'),
          style: TrembleTheme.uiFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : TrembleTheme.textColor,
          ),
        ),
      ],
    );
  }
}

class _HeatmapActiveRow extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _HeatmapActiveRow({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.layers_rounded, color: TrembleTheme.rose, size: 18),
        const SizedBox(width: 10),
        Text(
          'Heatmap aktiven',
          style: TrembleTheme.uiFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : TrembleTheme.textColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: TrembleTheme.rose.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'LIVE',
            style: TrembleTheme.uiFont(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TrembleTheme.rose,
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedFeatureRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isDark;

  const _LockedFeatureRow(
      {required this.label, required this.sublabel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock_rounded,
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.25),
            size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TrembleTheme.uiFont(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: TrembleTheme.accentYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: TrembleTheme.accentYellow.withValues(alpha: 0.4)),
          ),
          child: Text(
            sublabel,
            style: TrembleTheme.uiFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TrembleTheme.accentYellow,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final TrembleEventData event;
  final bool isDark;
  final String lang;

  const _ShareButton(
      {required this.event, required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final box = context.findRenderObject() as RenderBox?;
        final location = event.locationLabel ?? event.name;
        final text = t('event_share_text', lang)
            .replaceAll('{name}', event.name)
            .replaceAll('{location}', location);
        Share.share(
          text,
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: TrembleTheme.rose,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              t('share_event_invite', lang),
              style: TrembleTheme.uiFont(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _UnlockButton({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Paywall is blocked (BLOCKER-003). Button is a no-op placeholder.
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: TrembleTheme.accentYellow, size: 18),
            const SizedBox(width: 8),
            Text(
              t('upgrade_to_pro', lang),
              style: TrembleTheme.uiFont(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TrembleTheme.accentYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dev-only widget — simulates entering/exiting an event geofence.
/// Rendered only when FLAVOR=dev.
class _DevGeofenceControls extends StatelessWidget {
  final TrembleEventData event;
  final bool inGeofence;
  final bool isDark;

  const _DevGeofenceControls(
      {required this.event, required this.inGeofence, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.yellow.withValues(alpha: 0.08)
            : Colors.yellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report_rounded, color: Colors.yellow, size: 16),
          const SizedBox(width: 8),
          Text(
            'DEV: ${inGeofence ? 'In geofence' : 'Outside geofence'}',
            style: TrembleTheme.uiFont(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
