import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tremble/src/core/api_client.dart';
import 'package:tremble/src/core/upload_service.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/core/consent_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/auth/presentation/registration_flow.dart';
import 'package:tremble/src/features/auth/presentation/widgets/registration_steps/photos_step.dart';
import 'package:tremble/src/features/auth/presentation/widgets/registration_steps/consent_step.dart';
import 'package:tremble/src/features/auth/presentation/widgets/registration_steps/step_shared.dart';
import 'package:tremble/src/features/gym/data/gym_repository.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import 'package:tremble/src/features/dashboard/data/run_club_repository.dart';

import 'package:image_picker/image_picker.dart';
import 'package:tremble/src/features/gym/domain/selected_gym.dart';

class MockUser implements User {
  @override
  final String uid = 'me';

  @override
  final String? email = 'me@example.com';

  @override
  final String? displayName = 'Sarah Smith';

  @override
  final bool emailVerified = true;

  @override
  List<UserInfo> get providerData => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirebaseAuth implements FirebaseAuth {
  @override
  final User? currentUser = MockUser();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class FakeAuthRepository implements AuthRepository {
  Future<void> Function(AuthUser user)? onCompleteOnboarding;
  Future<void> Function(List<SelectedGym> gyms)? onUpdateSelectedGyms;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  Future<void> completeOnboarding(AuthUser user) async {
    if (onCompleteOnboarding != null) {
      await onCompleteOnboarding!(user);
    }
  }

  @override
  Future<void> markOnboardedDirectly(AuthUser user) async {
    // no-op
  }

  @override
  Future<void> updateSelectedGyms(String uid, List<SelectedGym> gyms) async {
    if (onUpdateSelectedGyms != null) {
      await onUpdateSelectedGyms!(gyms);
    }
  }

  @override
  Future<void> updateRegistrationDraft(
      String uid, Map<String, dynamic> data) async {
    // no-op
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthUser? initial, AuthRepository repo) : super(repo) {
    state = initial;
  }
}

class MockUploadService implements UploadService {
  Future<String> Function(String path,
          {void Function(int bytes, int total)? onProgress})?
      uploadPhotoFromPathHandler;

  @override
  Future<String> uploadPhoto(XFile file,
      {void Function(int bytes, int total)? onProgress}) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPhotoFromPath(
    String path, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    if (uploadPhotoFromPathHandler != null) {
      return uploadPhotoFromPathHandler!(path, onProgress: onProgress);
    }
    return 'https://example.com/mock_photo.png';
  }
}

class MockGdprConsentNotifier extends GdprConsentNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> grantConsent() async {
    state = const AsyncValue.data(true);
  }

  @override
  Future<void> resetConsent() async {
    state = const AsyncValue.data(false);
  }
}

class FakeGymRepository implements GymRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWaveRepository implements WaveRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRunClubRepository implements RunClubRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

File _createSmallPhotoFixture(String prefix) {
  final tempDir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() => tempDir.deleteSync(recursive: true));
  return File('${tempDir.path}/photo.jpg')
    ..writeAsBytesSync(List<int>.filled(32 * 1024, 1));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var i = 0; i < 20; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 10));
  }
  fail('condition was not met before timeout');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registration photo upload preparation', () {
    test('skips compression for files under 200KB', () async {
      final tempDir = Directory.systemTemp.createTempSync('photo-prep-small-');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final photo = File('${tempDir.path}/small.jpg')
        ..writeAsBytesSync(List<int>.filled(199 * 1024, 1));

      final prepared = await prepareRegistrationPhotoForUpload(
        photo,
        tempDirectoryProvider: () async {
          fail('small photos should not request a temp directory');
        },
        readImageSize: (_) async {
          fail('small photos should not read dimensions');
        },
        compressor: (
          sourcePath,
          targetPath, {
          required minWidth,
          required minHeight,
          required quality,
        }) async {
          fail('small photos should not be compressed');
        },
      );

      expect(prepared.path, photo.path);
    });

    test('compresses large photos to a temp JPEG with 1200px longest side',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('photo-prep-large-');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final photo = File('${tempDir.path}/large.png')
        ..writeAsBytesSync(List<int>.filled(201 * 1024, 1));

      String? capturedSourcePath;
      String? capturedTargetPath;
      int? capturedMinWidth;
      int? capturedMinHeight;
      int? capturedQuality;

      final prepared = await prepareRegistrationPhotoForUpload(
        photo,
        tempDirectoryProvider: () async => tempDir,
        readImageSize: (_) async => const Size(4000, 2000),
        compressor: (
          sourcePath,
          targetPath, {
          required minWidth,
          required minHeight,
          required quality,
        }) async {
          capturedSourcePath = sourcePath;
          capturedTargetPath = targetPath;
          capturedMinWidth = minWidth;
          capturedMinHeight = minHeight;
          capturedQuality = quality;
          return XFile(targetPath);
        },
      );

      expect(capturedSourcePath, photo.path);
      expect(capturedTargetPath, endsWith('.jpg'));
      expect(capturedMinWidth, 1200);
      expect(capturedMinHeight, 600);
      expect(capturedQuality, 85);
      expect(prepared.path, capturedTargetPath);
    });
  });

  group('mapUploadError unit tests', () {
    test('translates TrembleApiException invalid-argument code', () {
      final error =
          TrembleApiException(code: 'invalid-argument', message: 'error');
      final resultEn = mapUploadError(error, 'en');
      final resultSl = mapUploadError(error, 'sl');

      expect(resultEn, contains(t('photo_upload_error_format', 'en')));
      expect(resultSl, contains(t('photo_upload_error_format', 'sl')));
    });

    test('translates TrembleApiException internal code', () {
      final error = TrembleApiException(code: 'internal', message: 'error');
      final resultEn = mapUploadError(error, 'en');
      expect(resultEn, contains(t('photo_upload_error_interrupted', 'en')));
    });

    test('translates TrembleApiException unavailable code', () {
      final error = TrembleApiException(code: 'unavailable', message: 'error');
      final resultEn = mapUploadError(error, 'en');
      expect(resultEn, contains(t('photo_upload_error_network', 'en')));
    });

    test('translates unknown TrembleApiException code to generic', () {
      final error = TrembleApiException(code: 'unknown-code', message: 'error');
      final resultEn = mapUploadError(error, 'en');
      expect(resultEn, contains(t('photo_upload_error_generic', 'en')));
    });

    test('translates generic exceptions to generic error', () {
      final error = Exception('generic error');
      final resultEn = mapUploadError(error, 'en');
      expect(resultEn, contains(t('photo_upload_error_generic', 'en')));
    });
  });

  group('RegistrationFlow Widget Tests - Photo Upload', () {
    late FakeAuthRepository fakeAuthRepo;
    late MockUploadService mockUploadService;
    late MockAuthNotifier authNotifier;

    final initialUser = AuthUser(
      id: 'me',
      email: 'me@example.com',
      name: 'Sarah',
      onboardingCheckpoint:
          26, // Start at PhotosStep page (index 26 on iOS/macOS)
      isEmailVerified: true,
    );

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      mockUploadService = MockUploadService();
      authNotifier = MockAuthNotifier(initialUser, fakeAuthRepo);
    });

    List<Override> getOverrides() => [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          authStateProvider.overrideWith((ref) => authNotifier),
          uploadServiceProvider.overrideWithValue(mockUploadService),
          gdprConsentProvider.overrideWith(MockGdprConsentNotifier.new),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          firestoreProvider.overrideWithValue(MockFirestore()),
          gymRepositoryProvider.overrideWithValue(FakeGymRepository()),
          waveRepositoryProvider.overrideWithValue(FakeWaveRepository()),
          runClubRepositoryProvider.overrideWithValue(FakeRunClubRepository()),
          appLanguageProvider.overrideWith(() => AppLanguageNotifier('en')),
        ];

    Widget makeTestableWidget() {
      return ProviderScope(
        overrides: getOverrides(),
        child: const MaterialApp(
          home: Scaffold(
            body: RegistrationFlow(),
          ),
        ),
      );
    }

    testWidgets('Progress bar appears during upload and disappears on success',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final uploadCompleter = Completer<String>();
      var uploadStarted = false;
      mockUploadService.uploadPhotoFromPathHandler = (path, {onProgress}) {
        uploadStarted = true;
        return uploadCompleter.future;
      };

      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      // Ensure we are on PhotosStep
      expect(find.byType(PhotosStep), findsOneWidget);

      // Mutate photos list to add a photo
      final PhotosStep photosStep = tester.widget(find.byType(PhotosStep));
      photosStep.photos[0] = _createSmallPhotoFixture('upload-progress-');

      // Trigger completeRegistration directly on the state
      final state = tester.state(find.byType(RegistrationFlow)) as dynamic;
      state.completeRegistration();

      // Let the build update
      await tester.pump();

      // Finder for the upload progress indicator only (descendant of the overlay with text)
      final uploadProgressFinder = find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.minHeight == 4,
      );

      // Verify progress overlay is visible and shows progress bar
      expect(uploadProgressFinder, findsOneWidget);
      expect(find.text('Nalaganje slike...'), findsOneWidget);

      await _pumpUntil(tester, () => uploadStarted);

      // Complete the upload
      uploadCompleter.complete('https://example.com/uploaded.png');
      await tester.pumpAndSettle();

      // Verify progress overlay has disappeared
      expect(uploadProgressFinder, findsNothing);
    });

    testWidgets('Progress bar shows progress updates correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final uploadCompleter = Completer<String>();
      void Function(int, int)? progressCallback;
      mockUploadService.uploadPhotoFromPathHandler = (path, {onProgress}) {
        progressCallback = onProgress;
        return uploadCompleter.future;
      };

      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      final PhotosStep photosStep = tester.widget(find.byType(PhotosStep));
      photosStep.photos[0] = _createSmallPhotoFixture('upload-progress-value-');

      final state = tester.state(find.byType(RegistrationFlow)) as dynamic;
      state.completeRegistration();
      await tester.pump();

      final uploadProgressFinder = find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.minHeight == 4,
      );

      await _pumpUntil(tester, () => progressCallback != null);

      // Trigger progress updates
      progressCallback?.call(50, 100);
      await tester.pump();

      final indicator1 =
          tester.widget<LinearProgressIndicator>(uploadProgressFinder);
      expect(indicator1.value, equals(0.5));

      progressCallback?.call(100, 100);
      await tester.pump();

      final indicator2 =
          tester.widget<LinearProgressIndicator>(uploadProgressFinder);
      expect(indicator2.value, equals(1.0));

      uploadCompleter.complete('https://example.com/uploaded.png');
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Inline error appears on upload failure, and retry resets error state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Setup error response
      var uploadAttempted = false;
      mockUploadService.uploadPhotoFromPathHandler =
          (path, {onProgress}) async {
        uploadAttempted = true;
        throw TrembleApiException(
            code: 'unavailable', message: 'No internet connection');
      };

      await tester.pumpWidget(makeTestableWidget());
      await tester.pumpAndSettle();

      // Put photo in the list
      final PhotosStep photosStep = tester.widget(find.byType(PhotosStep));
      photosStep.photos[0] = _createSmallPhotoFixture('upload-error-');

      // Navigate from PhotosStep to GymStep, then to ConsentStep
      // Tap "Continue" on PhotosStep
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // GymStep is active. Tap "Continue"
      expect(find.text('Your Gyms'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // ConsentStep is active.
      expect(find.byType(ConsentStep), findsOneWidget);

      // Select all checkboxes using the OptionPill
      await tester.tap(find.byType(OptionPill));
      await tester.pumpAndSettle();

      // Tap "Continue" on ConsentStep (triggers completeRegistration)
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await _pumpUntil(tester, () => uploadAttempted);
      await tester.pumpAndSettle();

      // Verify inline error message is shown (from t('photo_upload_error_network', 'en'))
      final expectedError = t('photo_upload_error_network', 'en');
      expect(find.text(expectedError), findsOneWidget);

      final uploadProgressFinder = find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.minHeight == 4,
      );

      // Verify overlay is gone (since it failed)
      expect(uploadProgressFinder, findsNothing);

      // Now set the mock upload service to succeed for retry
      final retryCompleter = Completer<String>();
      mockUploadService.uploadPhotoFromPathHandler = (path, {onProgress}) {
        return retryCompleter.future;
      };

      // Tap "Continue" again to retry
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Verify that the error message is cleared and progress indicator is back
      expect(find.text(expectedError), findsNothing);
      expect(uploadProgressFinder, findsOneWidget);

      // Cleanup
      retryCompleter.complete('https://example.com/success.png');
      await tester.pumpAndSettle();
    });
  });
}
