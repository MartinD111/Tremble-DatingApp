import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/safety/data/safety_repository.dart';
import 'package:tremble/src/features/safety/presentation/blocked_users_screen.dart';

/// Minimal auth repo — the provider only needs a seeded auth state, not a live
/// stream.
class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SeededAuthNotifier extends AuthNotifier {
  _SeededAuthNotifier(AuthUser? initial, AuthRepository repo) : super(repo) {
    state = initial;
  }
}

/// Fake that returns whatever the `getBlockedUsers` callable would return,
/// so the provider's mapping is exercised without hitting Firestore.
class _FakeSafetyRepo implements SafetyRepository {
  _FakeSafetyRepo(this._blocked);
  final List<Map<String, dynamic>> _blocked;
  int getCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    getCalls++;
    return _blocked;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
      'blockedUsersProvider returns empty and skips the callable when signed out',
      () async {
    final repo = _FakeSafetyRepo([]);
    final container = ProviderContainer(overrides: [
      authStateProvider
          .overrideWith((ref) => _SeededAuthNotifier(null, _FakeAuthRepo())),
      safetyRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final result = await container.read(blockedUsersProvider.future);

    expect(result, isEmpty);
    expect(repo.getCalls, 0);
  });

  test(
      'blockedUsersProvider maps callable results and fills a fallback avatar '
      'when imageUrl is null', () async {
    final repo = _FakeSafetyRepo([
      {'id': 'a', 'name': 'Martin', 'imageUrl': 'https://cdn.test/m.jpg'},
      {'id': 'b', 'name': 'Nika', 'imageUrl': null},
    ]);
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(
          (ref) => _SeededAuthNotifier(AuthUser(id: 'u1'), _FakeAuthRepo())),
      safetyRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final result = await container.read(blockedUsersProvider.future);

    expect(repo.getCalls, 1);
    expect(result, hasLength(2));
    expect(result[0],
        {'id': 'a', 'name': 'Martin', 'imageUrl': 'https://cdn.test/m.jpg'});
    // Null imageUrl must never reach the tile's NetworkImage — it is replaced
    // by the fallback avatar URL.
    expect(result[1]['imageUrl'], isNotNull);
    expect(result[1]['name'], 'Nika');
  });
}
