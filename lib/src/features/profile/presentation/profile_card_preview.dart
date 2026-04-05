import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../shared/ui/tremble_back_button.dart';

class ProfileCardPreview extends ConsumerStatefulWidget {
  const ProfileCardPreview({super.key});

  @override
  ConsumerState<ProfileCardPreview> createState() => _ProfileCardPreviewState();
}

class _ProfileCardPreviewState extends ConsumerState<ProfileCardPreview> {
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    if (user == null) {
      return const GradientScaffold(
          child: Center(
              child: Text('No user', style: TextStyle(color: Colors.white))));
    }

    final hasPhotos = user.photoUrls.isNotEmpty;
    final photoCount = user.photoUrls.length;

    return GradientScaffold(
      child: CustomScrollView(
        slivers: [
          // App bar with edit button
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: const SizedBox.shrink(),
            title: Text(t('my_card', user.appLanguage),
                style: GoogleFonts.instrumentSans(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.pencil, color: Colors.white),
                tooltip: t('edit_profile', user.appLanguage),
                onPressed: () => context.push('/edit-profile'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TrembleBackButton(
                  onPressed: () => context.pop(),
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          // Main photo gallery
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Photo gallery with PageView
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 360,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasPhotos)
                            PageView.builder(
                              controller: _photoPageController,
                              itemCount: photoCount,
                              onPageChanged: (i) =>
                                  setState(() => _currentPhotoPage = i),
                              itemBuilder: (context, index) {
                                final url = user.photoUrls[index];
                                return url.startsWith('http')
                                    ? Image.network(url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[900]))
                                    : Image.file(File(url),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[900]));
                              },
                            )
                          else
                            Container(
                              color: Colors.white10,
                              child: const Center(
                                child: Icon(Icons.person,
                                    size: 80, color: Colors.white24),
                              ),
                            ),
                          // Dot indicators
                          if (photoCount > 1)
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(photoCount, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: _currentPhotoPage == i ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentPhotoPage == i
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name + Age
                  Text(
                    '${user.name ?? 'Guest'}, ${user.age ?? '?'}',
                    style: GoogleFonts.instrumentSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Job / Occupation Overlay
                  if (user.occupation?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.briefcase,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(user.occupation ?? '',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 15)),
                      ],
                    ),
                  ],

                  // Height Overlay
                  if (user.height != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.ruler,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text('${user.height} cm',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 15)),
                      ],
                    ),
                  ],

                  // Location
                  if ((user.location?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.mapPin,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(user.location ?? '',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 15)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info badges
                  _buildInfoBadges(user),

                  const SizedBox(height: 24),

                  // Hobbies
                  if (user.hobbies.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t('hobbies', user.appLanguage),
                          style: GoogleFonts.instrumentSans(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.hobbies.map((h) {
                        return Chip(
                          label: Text(h,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          side: const BorderSide(color: Colors.white24),
                          shape: const StadiumBorder(),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Lifestyle
                  _buildLifestyleSection(user),

                  const SizedBox(height: 24),

                  // Looking for
                  if (user.lookingFor.isNotEmpty) ...[
                    _buildSection(
                        t('looking_for', user.appLanguage),
                        user.isPremium
                            ? user.lookingFor
                            : user.lookingFor
                                .where((item) =>
                                    item == 'Dolgoročno razmerje' ||
                                    item == 'Long-term relationship' ||
                                    item == 'Prijateljstvo' ||
                                    item == 'Friendship')
                                .toList()),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadges(AuthUser user) {
    final badges = <Widget>[];

    if (user.height != null) {
      badges.add(_badge(LucideIcons.ruler, '${user.height} cm'));
    }
    if (user.gender != null) {
      badges.add(_badge(
          user.gender == 'Moški' ? LucideIcons.user : LucideIcons.user,
          user.gender!));
    }
    if (user.occupation != null) {
      badges.add(_badge(LucideIcons.briefcase, user.occupation!));
    }
    if (user.isSmoker == true) {
      badges.add(_badge(LucideIcons.cigarette, t('smoker', user.appLanguage)));
    }
    if (user.politicalAffiliation != null &&
        user.politicalAffiliation != 'politics_dont_care' &&
        user.politicalAffiliation != 'politics_undisclosed') {
      badges.add(_badge(
          LucideIcons.flag, t(user.politicalAffiliation!, user.appLanguage)));
    }
    if (user.religion != null) {
      badges
          .add(_badge(LucideIcons.heart, t(user.religion!, user.appLanguage)));
    }
    if (user.hairColor != null) {
      badges.add(
          _badge(LucideIcons.scissors, t(user.hairColor!, user.appLanguage)));
    }
    if (user.ethnicity != null) {
      badges.add(_badge(LucideIcons.users,
          t('ethnicity_${user.ethnicity}', user.appLanguage)));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.start,
      children: badges,
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(AuthUser user) {
    final items = <Widget>[];

    if (user.exerciseHabit != null) {
      items.add(_lifestyleItem(
          LucideIcons.dumbbell, 'Telovadba', user.exerciseHabit!));
    }
    if (user.drinkingHabit != null) {
      items.add(
          _lifestyleItem(LucideIcons.wine, 'Alkohol', user.drinkingHabit!));
    }
    if (user.sleepSchedule != null) {
      items.add(_lifestyleItem(
          user.sleepSchedule == 'Nočna ptica'
              ? LucideIcons.moon
              : LucideIcons.sun,
          'Spanje',
          user.sleepSchedule!));
    }
    if (user.petPreference != null) {
      items.add(_lifestyleItem(
          LucideIcons.dog, t('pets', user.appLanguage), user.petPreference!));
    }
    if (user.childrenPreference != null) {
      items.add(_lifestyleItem(LucideIcons.baby,
          t('children', user.appLanguage), user.childrenPreference!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('lifestyle', user.appLanguage),
              style: GoogleFonts.instrumentSans(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _lifestyleItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.instrumentSans(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Chip(
                      label: Text(item,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.white24),
                      shape: const StadiumBorder(),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
