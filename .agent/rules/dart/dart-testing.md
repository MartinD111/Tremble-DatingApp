---
paths:
  - "**/*.dart"
  - "**/test/**"
---
# Dart/Flutter Testing

> This file extends common/testing.md with Flutter and Firebase specific content.

## Test Types

| Type | Tool | When to use |
|------|------|-------------|
| Unit | `flutter_test` | Services, repositories, use cases, pure functions |
| Widget | `flutter_test` + `WidgetTester` | UI components, screens |
| Integration | `integration_test` | Full user flows on real device/emulator |
| Firebase | `fake_cloud_firestore` + `firebase_auth_mocks` | Firestore logic without real backend |

## Unit Tests

Test business logic in isolation — mock all external dependencies:

```dart
// CORRECT: Use mockito or mocktail for dependencies
@GenerateMocks([BleService, FirebaseFirestore])
void main() {
  late RadarService sut;
  late MockBleService mockBle;

  setUp(() {
    mockBle = MockBleService();
    sut = RadarService(bleService: mockBle);
  });

  test('startScan emits nearby users within range', () async {
    when(mockBle.scanResults).thenAnswer(
      (_) => Stream.fromIterable([fakeScanResult(rssi: -65)])
    );

    final results = await sut.getNearbyUsers().first;

    expect(results, isNotEmpty);
    expect(results.first.signalStrength, equals(SignalStrength.close));
  });

  test('startScan filters users beyond 30m (rssi < -85)', () async {
    when(mockBle.scanResults).thenAnswer(
      (_) => Stream.fromIterable([fakeScanResult(rssi: -90)])
    );

    final results = await sut.getNearbyUsers().first;

    expect(results, isEmpty);
  });
}
```

## Widget Tests

Test widget rendering and interactions without a real device:

```dart
testWidgets('RadarScreen shows empty state when no nearby users', (tester) async {
  // Arrange: override provider with empty state
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        nearbyUsersProvider.overrideWith((_) async => []),
      ],
      child: const MaterialApp(home: RadarScreen()),
    ),
  );
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Nihče ni v bližini'), findsOneWidget);
  expect(find.byType(UserRadarCard), findsNothing);
});

testWidgets('Greeting button is disabled after sending', (tester) async {
  await tester.pumpWidget(buildTestApp());
  await tester.pump();

  final button = find.byKey(const Key('send_greeting_btn'));
  await tester.tap(button);
  await tester.pump();

  expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
});
```

## Firebase Mocking

Use `fake_cloud_firestore` instead of a real Firestore connection in tests:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth fakeAuth;
  late UserRepository sut;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-uid-123', email: 'test@test.com')
    );
    sut = UserRepository(firestore: fakeFirestore, auth: fakeAuth);
  });

  test('updateProfile writes to correct document path', () async {
    await sut.updateProfile(bio: 'Hello world');

    final doc = await fakeFirestore
        .collection('users')
        .doc('test-uid-123')
        .get();

    expect(doc.data()?['bio'], equals('Hello world'));
  });
}
```

## Test File Structure

Mirror source structure in `test/` folder:

```
test/
  features/
    radar/
      data/
        radar_repository_test.dart
      domain/
        radar_use_case_test.dart
      presentation/
        radar_screen_test.dart
  core/
    services/
      ble_service_test.dart
      location_service_test.dart
```

## Running Tests

```bash
# All unit + widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Single file
flutter test test/features/radar/data/radar_repository_test.dart

# Integration tests (requires device/emulator)
flutter test integration_test/app_test.dart
```

## Coverage Targets

| Layer | Target |
|-------|--------|
| Services (BLE, location) | 80%+ |
| Repositories (Firestore) | 80%+ |
| Use cases / domain logic | 90%+ |
| Widgets / screens | 60%+ |
| Generated code | Exclude |

## Test Helpers

Create shared helpers in `test/helpers/`:

```dart
// test/helpers/test_providers.dart
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      ...overrides,
      // Default overrides for all tests
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
    ],
  );
}

// test/helpers/fake_data.dart
ScanResult fakeScanResult({int rssi = -70, String? deviceId}) {
  return ScanResult(
    device: BluetoothDevice(remoteId: DeviceIdentifier(deviceId ?? 'AA:BB:CC:DD:EE:FF')),
    rssi: rssi,
    advertisementData: AdvertisementData.empty,
    timeStamp: DateTime.now(),
  );
}
```
