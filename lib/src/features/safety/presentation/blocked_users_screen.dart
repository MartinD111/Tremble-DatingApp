import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/translations.dart';
import '../../../core/theme.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../shared/ui/warmth_empty_state.dart';
import '../../auth/data/auth_repository.dart';
import '../data/safety_repository.dart';

/// Fallback avatar used when a blocked user has no photo. Kept as a null-safe
/// default so the tile's [NetworkImage] never receives a null URL.
const _kBlockedAvatarFallback = 'https://via.placeholder.com/150';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  // Cross-user reads are denied by Firestore rules (self-only), so the list is
  // sourced from the `getBlockedUsers` callable (Admin SDK) instead of a direct
  // client fan-out over `blockedUserIds`. See BUG-BLOCKED-USERS-LIST.
  final repo = ref.watch(safetyRepositoryProvider);
  final blocked = await repo.getBlockedUsers();

  return blocked
      .map((b) => {
            'id': b['id'],
            'name': b['name'] ?? 'Unknown User',
            'imageUrl': (b['imageUrl'] as String?) ?? _kBlockedAvatarFallback,
          })
      .toList(growable: false);
});

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final opacity = (1.0 - (_scrollController.offset / 60)).clamp(0.0, 1.0);
      if (_titleOpacity.value != opacity) _titleOpacity.value = opacity;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'en';
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return GradientScaffold(
      child: Stack(
        children: [
          blockedUsersAsync.when(
            data: (blockedUsers) {
              if (blockedUsers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: WarmthEmptyState(
                      title: t('no_blocked_users', lang),
                      subtitle: t('no_blocked_users_sub', lang),
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.of(context).padding.top + 80, 16, 40),
                itemCount: blockedUsers.length,
                itemBuilder: (context, index) {
                  final blockedUser = blockedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                NetworkImage(blockedUser['imageUrl']),
                            backgroundColor: Colors.white12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              blockedUser['name'],
                              style: GoogleFonts.instrumentSans(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: TrembleTheme.rose,
                            ),
                            onPressed: () async {
                              final repo = ref.read(safetyRepositoryProvider);
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Unblocking...')),
                                );
                                await repo.unblockUser(blockedUser['id']);
                                ref.invalidate(blockedUsersProvider);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Uporabnika ni bilo mogoče odblokirati. Povezava ali dovoljenje ni uspelo. Poskusi znova.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(t('unblock', lang)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Blokiranih uporabnikov ni bilo mogoče naložiti. Preveri povezavo in poskusi znova.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, _) => TrembleHeader(
              title: t('blocked_users', user?.appLanguage ?? 'en'),
              titleOpacity: opacity,
              buttonsOpacity: opacity,
            ),
          ),
        ],
      ),
    );
  }
}
