// Regression tests for H6 — profileStatusProvider non-autoDispose leak fix.
//
// profileStatusProvider MUST be a StreamProvider.autoDispose so the open
// Firestore listener is cancelled when no consumer is watching it.
//
// Tests operate on the source text (permission_handler / Firestore not
// available in unit-test context). They pin the structural contract so a
// future refactor cannot silently regress to the non-autoDispose form.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'lib/src/features/auth/data/auth_repository.dart';

  late String source;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
  });

  group('profileStatusProvider — autoDispose StreamProvider', () {
    test('is declared as StreamProvider.autoDispose', () {
      expect(
        source,
        contains('StreamProvider.autoDispose<ProfileStatus>'),
        reason:
            'Firestore listener must auto-cancel when no consumer is watching',
      );
    });

    test('old non-autoDispose form is absent', () {
      // Must not contain the bare StreamProvider<ProfileStatus> declaration.
      // Note: profileExistsProvider uses StreamProvider<bool> — that must not
      // be flagged, so we search for the profileStatusProvider declaration line.
      final nonAutoDisposePattern =
          RegExp(r'profileStatusProvider\s*=\s*StreamProvider<ProfileStatus>');
      expect(
        nonAutoDisposePattern.hasMatch(source),
        isFalse,
        reason:
            'Non-autoDispose form leaks a Firestore listener across navigation',
      );
    });

    test('profileStatusProvider still watches authStateProvider', () {
      expect(
        source,
        contains('ref.watch(authStateProvider)'),
        reason: 'Provider must re-run when auth state changes',
      );
    });

    test('profileStatusProvider returns notFound when authState is null', () {
      expect(
        source,
        contains('Stream.value(const ProfileStatus.notFound())'),
        reason: 'Signed-out path must emit notFound immediately',
      );
    });

    test('no keepAlive() call on profileStatusProvider', () {
      // autoDispose + keepAlive() would negate the fix.
      // Check the provider body (roughly between profileStatusProvider and the
      // next top-level final declaration).
      final providerStart = source.indexOf('profileStatusProvider');
      final providerEnd = source.indexOf('\nfinal ', providerStart + 1);
      final providerBody = providerEnd != -1
          ? source.substring(providerStart, providerEnd)
          : source.substring(providerStart);
      expect(
        providerBody.contains('keepAlive()'),
        isFalse,
        reason: 'keepAlive() would negate the autoDispose leak fix',
      );
    });
  });
}
