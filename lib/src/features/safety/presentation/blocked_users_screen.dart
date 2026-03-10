import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/translations.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/glass_card.dart';
import '../../auth/data/auth_repository.dart';
import '../data/safety_repository.dart';

/// Provider to fetch the list of blocked users for the current user.
final blockedUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  // 1. Fetch current user's document to get blockedUserIds
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
  if (!doc.exists) return [];

  final data = doc.data()!;
  final blockedIds = List<String>.from(data['blockedUserIds'] ?? []);

  if (blockedIds.isEmpty) return [];

  // 2. Fetch basic info for each blocked user
  // Firestore 'in' queries are limited to 10 items, so we'll fetch them individually 
  // or chunk them if needed. For a simple settings screen, individual gets or a single chunk is okay.
  // We'll just do individual gets concurrently for simplicity.
  final futures = blockedIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get());
  final snapshots = await Future.wait(futures);

  final List<Map<String, dynamic>> blockedUsers = [];
  for (var snap in snapshots) {
    if (snap.exists) {
      final userData = snap.data()!;
      final photoUrls = List<String>.from(userData['photoUrls'] ?? []);
      blockedUsers.add({
        'id': snap.id,
        'name': userData['name'] ?? 'Unknown User',
        'imageUrl': photoUrls.isNotEmpty ? photoUrls.first : 'https://via.placeholder.com/150',
      });
    }
  }

  return blockedUsers;
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'en';
    
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('blocked_users', lang),
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.userCheck, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    t('no_blocked_users', lang),
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                        backgroundImage: NetworkImage(blockedUser['imageUrl']),
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          blockedUser['name'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.pinkAccent,
                        ),
                        onPressed: () async {
                          // Unblock logic
                          final repo = ref.read(safetyRepositoryProvider);
                          try {
                            // Show loading indicator in place or block UI
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unblocking...')),
                            );
                            
                            await repo.unblockUser(blockedUser['id']);
                            
                            // Refresh the list
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
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
