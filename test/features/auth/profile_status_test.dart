import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

void main() {
  group('ProfileStatus', () {
    test('loading is distinct from notFound and ready', () {
      const loading = ProfileStatus.loading();
      const notFound = ProfileStatus.notFound();
      const ready = ProfileStatus.ready(isOnboarded: false);

      expect(loading, isNot(equals(notFound)));
      expect(loading, isNot(equals(ready)));
      expect(notFound, isNot(equals(ready)));
    });

    test('ready copies isOnboarded correctly', () {
      const status = ProfileStatusReady(isOnboarded: true);
      expect(status.isOnboarded, isTrue);
    });

    test('ready(isOnboarded: false) != ready(isOnboarded: true)', () {
      const a = ProfileStatus.ready(isOnboarded: false);
      const b = ProfileStatus.ready(isOnboarded: true);
      expect(a, isNot(equals(b)));
    });

    test('map dispatches on loading', () {
      const ProfileStatus status = ProfileStatus.loading();
      final result = status.map(
        loading: (_) => 'loading',
        notFound: (_) => 'notFound',
        ready: (_) => 'ready',
      );
      expect(result, equals('loading'));
    });

    test('map dispatches on notFound', () {
      const ProfileStatus status = ProfileStatus.notFound();
      final result = status.map(
        loading: (_) => 'loading',
        notFound: (_) => 'notFound',
        ready: (_) => 'ready',
      );
      expect(result, equals('notFound'));
    });

    test('map dispatches on ready(isOnboarded: true)', () {
      const ProfileStatus status = ProfileStatus.ready(isOnboarded: true);
      final result = status.map(
        loading: (_) => 'loading',
        notFound: (_) => 'notFound',
        ready: (r) => 'ready:${r.isOnboarded}',
      );
      expect(result, equals('ready:true'));
    });
  });

  group('profileStatusProvider — stream transitions', () {
    test('starts in loading state before stream emits', () async {
      final sc = StreamController<ProfileStatus>.broadcast();
      final container = ProviderContainer(
        overrides: [
          profileStatusProvider.overrideWith((ref) => sc.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(sc.close);

      expect(container.read(profileStatusProvider).isLoading, isTrue);
    });

    test('emits notFound when stream produces notFound', () async {
      final sc = StreamController<ProfileStatus>.broadcast();
      final container = ProviderContainer(
        overrides: [
          profileStatusProvider.overrideWith((ref) => sc.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(sc.close);

      // Subscribe first so Riverpod opens a listener before the event is added.
      // Broadcast streams drop events with no listeners — subscribe, then emit.
      container.listen(profileStatusProvider, (_, __) {});
      sc.add(const ProfileStatus.notFound());
      await container.pump();

      expect(container.read(profileStatusProvider).value,
          equals(const ProfileStatus.notFound()));
    });

    test('emits ready(isOnboarded: false) when stream produces that value',
        () async {
      final sc = StreamController<ProfileStatus>.broadcast();
      final container = ProviderContainer(
        overrides: [
          profileStatusProvider.overrideWith((ref) => sc.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(sc.close);

      container.listen(profileStatusProvider, (_, __) {});
      sc.add(const ProfileStatus.ready(isOnboarded: false));
      await container.pump();

      final value = container.read(profileStatusProvider).value;
      expect(value, equals(const ProfileStatus.ready(isOnboarded: false)));
      expect((value! as ProfileStatusReady).isOnboarded, isFalse);
    });

    test('emits ready(isOnboarded: true) when stream produces that value',
        () async {
      final sc = StreamController<ProfileStatus>.broadcast();
      final container = ProviderContainer(
        overrides: [
          profileStatusProvider.overrideWith((ref) => sc.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(sc.close);

      container.listen(profileStatusProvider, (_, __) {});
      sc.add(const ProfileStatus.ready(isOnboarded: true));
      await container.pump();

      final value = container.read(profileStatusProvider).value;
      expect(value, equals(const ProfileStatus.ready(isOnboarded: true)));
      expect((value! as ProfileStatusReady).isOnboarded, isTrue);
    });

    test('transitions: loading → notFound → ready(true)', () async {
      final sc = StreamController<ProfileStatus>.broadcast();
      final container = ProviderContainer(
        overrides: [
          profileStatusProvider.overrideWith((ref) => sc.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(sc.close);

      // Subscribe before emitting to ensure no events are dropped.
      container.listen(profileStatusProvider, (_, __) {});

      // Phase 1: loading
      expect(container.read(profileStatusProvider).isLoading, isTrue);

      // Phase 2: notFound
      sc.add(const ProfileStatus.notFound());
      await container.pump();
      expect(container.read(profileStatusProvider).value,
          equals(const ProfileStatus.notFound()));

      // Phase 3: ready (CF trigger wrote the doc)
      sc.add(const ProfileStatus.ready(isOnboarded: true));
      await container.pump();
      expect(container.read(profileStatusProvider).value,
          equals(const ProfileStatus.ready(isOnboarded: true)));
    });
  });
}
