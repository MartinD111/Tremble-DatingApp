import 'dart:ui';

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
    final surfaceColor = Colors.white.withValues(alpha: 0.82);
    final textPrimary = TrembleTheme.textColor;
    final dividerColor = const Color(0xFFD8D5CC).withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
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
                      color: const Color(0xFFB8B4A9).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isTasteOfPremium) ...[
                  _TasteOfPremiumBanner(isDark: isDark, lang: lang),
                  const SizedBox(height: 16),
                ],
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
                                  : t('coming_at', lang).replaceAll(
                                      '{time}', event.startsAt ?? ''),
                              style: TrembleTheme.uiFont(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: event.isActive
                                    ? TrembleTheme.azure
                                    : TrembleTheme.warmGray,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: effectiveIsPremium
                      ? _PeopleCountRow(
                          count: event.peopleCount,
                          isDark: isDark,
                          lang: lang,
                        )
                      : _LockedFeatureRow(
                          label: t('pulsing_here', lang)
                              .replaceAll('{count}', '??'),
                          sublabel: t('pro_feature_locked', lang),
                          isDark: isDark,
                        ),
                ),
                const SizedBox(height: 12),
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
                if (const String.fromEnvironment('FLAVOR',
                        defaultValue: 'dev') ==
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
          colors: [Color(0xFFF7FBFF), Color(0xFFE4F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9D7CF)),
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
                    color: TrembleTheme.textColor,
                  ),
                ),
                Text(
                  t('taste_of_premium_sub', lang),
                  style: TrembleTheme.uiFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: TrembleTheme.textColor.withValues(alpha: 0.68),
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
    final color = isActive ? TrembleTheme.azure : TrembleTheme.warmGray;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
        Icon(Icons.favorite_rounded, color: TrembleTheme.azure, size: 18),
        const SizedBox(width: 10),
        Text(
          t('pulsing_here', lang).replaceAll('{count}', '$count'),
          style: TrembleTheme.uiFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TrembleTheme.textColor,
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
        Icon(Icons.layers_rounded, color: TrembleTheme.azure, size: 18),
        const SizedBox(width: 10),
        Text(
          'Heatmap aktiven',
          style: TrembleTheme.uiFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TrembleTheme.textColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: TrembleTheme.azure.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(100),
            border:
                Border.all(color: TrembleTheme.azure.withValues(alpha: 0.18)),
          ),
          child: Text(
            'LIVE',
            style: TrembleTheme.uiFont(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TrembleTheme.azure,
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
    final borderColor = const Color(0xFFD9D7CF).withValues(alpha: 0.95);
    return Row(
      children: [
        Icon(Icons.lock_rounded,
            color: TrembleTheme.warmGray.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TrembleTheme.uiFont(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: TrembleTheme.warmGray.withValues(alpha: 0.72),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EFE8),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            sublabel,
            style: TrembleTheme.uiFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TrembleTheme.warmGray,
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded,
                color: Color(0xFF007AFF), size: 18),
            const SizedBox(width: 8),
            Text(
              t('share_event_invite', lang),
              style: TrembleTheme.uiFont(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFFD9D7CF).withValues(alpha: 0.95),
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
                color: TrembleTheme.textColor,
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
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFD9D7CF).withValues(alpha: 0.95)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report_rounded,
              color: Color(0xFF007AFF), size: 16),
          const SizedBox(width: 8),
          Text(
            'DEV: ${inGeofence ? 'In geofence' : 'Outside geofence'}',
            style: TrembleTheme.uiFont(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TrembleTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
