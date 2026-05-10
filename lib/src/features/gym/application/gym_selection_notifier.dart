import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/selected_gym.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymSelectionNotifier — manages the user's personal gym list (max 3).
//
// State is derived from authStateProvider so it stays in sync with Firestore
// on reload. Mutations write through to AuthNotifier.updateSelectedGyms which
// does an optimistic local update + async Firestore write.
// ─────────────────────────────────────────────────────────────────────────────

class GymSelectionNotifier extends Notifier<List<SelectedGym>> {
  static const int maxGyms = 3;

  @override
  List<SelectedGym> build() {
    return ref.watch(authStateProvider)?.selectedGyms ?? const [];
  }

  /// Returns true if the gym was added, false if the limit is already reached.
  Future<bool> addGym(SelectedGym gym) async {
    if (state.length >= maxGyms) return false;
    if (state.any((g) => g.placeId == gym.placeId))
      return true; // already there
    final updated = [...state, gym];
    await _persist(updated);
    return true;
  }

  Future<void> removeGym(String placeId) async {
    final updated = state.where((g) => g.placeId != placeId).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<SelectedGym> gyms) async {
    await ref.read(authStateProvider.notifier).updateSelectedGyms(gyms);
  }
}

final gymSelectionProvider =
    NotifierProvider<GymSelectionNotifier, List<SelectedGym>>(
  GymSelectionNotifier.new,
);
