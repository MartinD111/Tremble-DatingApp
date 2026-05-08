import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/translations.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../data/safety_repository.dart';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.id).get();
  if (!doc.exists) return [];

  final data = doc.data()!;
  final blockedIds = List<String>.from(data['blockedUserIds'] ?? []);
  if (blockedIds.isEmpty) return [];

  final futures = blockedIds.map(
      (id) => FirebaseFirestore.instance.collection('users').doc(id).get());
  final snapshots = await Future.wait(futures);

  final List<Map<String, dynamic>> blockedUsers = [];
  for (var snap in snapshots) {
    if (snap.exists) {
      final userData = snap.data()!;
      final photoUrls = List<String>.from(userData['photoUrls'] ?? []);
      blockedUsers.add({
        'id': snap.id,
        'name': userData['name'] ?? 'Unknown User',
        'imageUrl': photoUrls.isNotEmpty
            ? photoUrls.first
            : 'https://via.placeholder.com/150',
      });
    }
  }
  return blockedUsers;
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.userCheck,
                          size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        t('no_blocked_users', lang),
                        style: GoogleFonts.instrumentSans(
                            color: Colors.white54, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 80,
                    16,
                    40),
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
                              foregroundColor: const Color(0xFFF4436C),
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
                                  SnackBar(content: Text('Error: $e')),
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
              child: CircularProgressIndicator(color: Color(0xFFF4436C)),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error',
                  style: const TextStyle(color: Colors.red)),
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
