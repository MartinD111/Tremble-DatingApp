import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tremble/src/features/dashboard/application/precise_finder_controller.dart';
import 'package:tremble/src/features/dashboard/data/finder_repository.dart';

class _FinderCall {
  const _FinderCall({
    required this.matchId,
    required this.windowId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.optIn,
  });

  final String matchId;
  final String windowId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool optIn;
}

class _FakeFinderRepository implements FinderRepository {
  String windowId = 'wave-window-1';
  int windowReadCount = 0;
  final calls = <_FinderCall>[];
  final responses = <Future<FinderReading> Function()>[];

  @override
  Future<String> readWindowId(String matchId) async {
    windowReadCount++;
    return windowId;
  }

  @override
  Future<FinderReading> updateLocation({
    required String matchId,
    required String windowId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool optIn,
  }) {
    calls.add(
      _FinderCall(
        matchId: matchId,
        windowId: windowId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        optIn: optIn,
      ),
    );
    if (responses.isEmpty) {
      return Future.value(const FinderReading(partnerSharing: false));
    }
    return responses.removeAt(0)();
  }
}

class _FakeCallableClient implements FinderCallableClient {
  String? region;
  String? name;
  Map<String, dynamic>? data;
  Object response = <String, dynamic>{'partnerSharing': false};

  @override
  Future<Object?> call({
    required String region,
    required String name,
    required Map<String, dynamic> data,
  }) async {
    this.region = region;
    this.name = name;
    this.data = data;
    return response;
  }
}

class _FakeDelay {
  final durations = <Duration>[];
  final _completers = <Completer<void>>[];

  Future<void> call(Duration duration) {
    durations.add(duration);
    final completer = Completer<void>();
    _completers.add(completer);
    return completer.future;
  }

  void completeNext() => _completers.removeAt(0).complete();
}

class _CancelFailingStream extends Stream<Position> {
  @override
  StreamSubscription<Position> listen(
    void Function(Position event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _CancelFailingSubscription();
  }
}

class _CancelFailingSubscription implements StreamSubscription<Position> {
  @override
  Future<void> cancel() async => throw Exception('cancel failed');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Position _position({
  double latitude = 45.548,
  double longitude = 13.73,
  double accuracy = 8,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.utc(2026, 7, 22),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

({
  ProviderContainer container,
  _FakeFinderRepository repository,
  StreamController<Position> positions,
  List<LocationSettings> settings,
  _FakeDelay delay,
  void Function(DateTime value) setNow,
  int Function() cancellationCount,
}) _harness() {
  final repository = _FakeFinderRepository();
  var cancellations = 0;
  final positions = StreamController<Position>.broadcast(
    sync: true,
    onCancel: () => cancellations++,
  );
  final settings = <LocationSettings>[];
  final delay = _FakeDelay();
  var now = DateTime.utc(2026, 7, 22, 12);

  final container = ProviderContainer(
    overrides: [
      finderRepositoryProvider.overrideWithValue(repository),
      finderLocationStreamProvider.overrideWithValue((locationSettings) {
        settings.add(locationSettings);
        return positions.stream;
      }),
      finderClockProvider.overrideWithValue(() => now),
      finderDelayProvider.overrideWithValue(delay.call),
    ],
  );

  return (
    container: container,
    repository: repository,
    positions: positions,
    settings: settings,
    delay: delay,
    setNow: (value) => now = value,
    cancellationCount: () => cancellations,
  );
}

void main() {
  group('FirebaseFinderRepository', () {
    test('uses europe-west1 and sends the complete callable payload', () async {
      final client = _FakeCallableClient()
        ..response = <String, dynamic>{
          'partnerSharing': true,
          'bearing': 91,
          'distanceM': 24.5,
        };
      final repository = FirebaseFinderRepository(
        callableClient: client,
        windowIdReader: (_) async => 'wave-window-1',
      );

      final reading = await repository.updateLocation(
        matchId: 'match-1',
        windowId: 'wave-window-1',
        latitude: 45.548,
        longitude: 13.73,
        accuracy: 7.5,
        optIn: true,
      );

      expect(client.region, 'europe-west1');
      expect(client.name, 'updateFinderLocation');
      expect(client.data, <String, dynamic>{
        'matchId': 'match-1',
        'windowId': 'wave-window-1',
        'lat': 45.548,
        'lng': 13.73,
        'accuracy': 7.5,
        'optIn': true,
      });
      expect(reading.partnerSharing, isTrue);
      expect(reading.bearing, 91);
      expect(reading.distanceM, 24.5);
    });

    test('reads and validates notificationOwnerWaveId from the match once',
        () async {
      var reads = 0;
      final repository = FirebaseFinderRepository(
        callableClient: _FakeCallableClient(),
        windowIdReader: (matchId) async {
          reads++;
          expect(matchId, 'match-1');
          return 'wave-window_1';
        },
      );

      expect(await repository.readWindowId('match-1'), 'wave-window_1');
      expect(reads, 1);
    });

    test('rejects unexpected response keys including raw coordinates',
        () async {
      final client = _FakeCallableClient()
        ..response = <String, dynamic>{
          'partnerSharing': true,
          'bearing': 91,
          'distanceM': 24,
          'lat': 45.548,
        };
      final repository = FirebaseFinderRepository(
        callableClient: client,
        windowIdReader: (_) async => 'wave-window-1',
      );

      await expectLater(
        repository.updateLocation(
          matchId: 'match-1',
          windowId: 'wave-window-1',
          latitude: 45.548,
          longitude: 13.73,
          accuracy: 8,
          optIn: true,
        ),
        throwsFormatException,
      );
    });

    test('requires finite bearing and distance for a precise response',
        () async {
      final client = _FakeCallableClient()
        ..response = <String, dynamic>{
          'partnerSharing': true,
          'bearing': double.nan,
          'distanceM': 24,
        };
      final repository = FirebaseFinderRepository(
        callableClient: client,
        windowIdReader: (_) async => 'wave-window-1',
      );

      await expectLater(
        repository.updateLocation(
          matchId: 'match-1',
          windowId: 'wave-window-1',
          latitude: 45.548,
          longitude: 13.73,
          accuracy: 8,
          optIn: true,
        ),
        throwsFormatException,
      );
    });

    test('rejects impossible distances but accepts the Earth-scale boundary',
        () async {
      final client = _FakeCallableClient();
      final repository = FirebaseFinderRepository(
        callableClient: client,
        windowIdReader: (_) async => 'wave-window-1',
      );

      Future<FinderReading> updateWithDistance(double distanceM) {
        client.response = <String, dynamic>{
          'partnerSharing': true,
          'bearing': 180,
          'distanceM': distanceM,
        };
        return repository.updateLocation(
          matchId: 'match-1',
          windowId: 'wave-window-1',
          latitude: 45.548,
          longitude: 13.73,
          accuracy: 8,
          optIn: true,
        );
      }

      for (final distance in <double>[
        -1,
        double.infinity,
        double.nan,
        20100000.001,
      ]) {
        await expectLater(updateWithDistance(distance), throwsFormatException);
      }

      final boundary = await updateWithDistance(20100000);
      expect(boundary.distanceM, 20100000);
      expect(boundary.hasPreciseData, isTrue);
    });

    test('rejects bearing 360', () async {
      final client = _FakeCallableClient()
        ..response = <String, dynamic>{
          'partnerSharing': true,
          'bearing': 360,
          'distanceM': 24,
        };
      final repository = FirebaseFinderRepository(
        callableClient: client,
        windowIdReader: (_) async => 'wave-window-1',
      );

      await expectLater(
        repository.updateLocation(
          matchId: 'match-1',
          windowId: 'wave-window-1',
          latitude: 45.548,
          longitude: 13.73,
          accuracy: 8,
          optIn: true,
        ),
        throwsFormatException,
      );
    });
  });

  group('PreciseFinderController', () {
    test('starts idle then opens a high-accuracy foreground stream on tap',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.idle,
      );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');

      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.waiting,
      );
      expect(harness.settings, hasLength(1));
      expect(harness.settings.single.accuracy, LocationAccuracy.high);
      expect(harness.settings.single.distanceFilter, greaterThan(0));
    });

    test('captures one window token and sends the first sample immediately',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      harness.repository.responses.add(
        () async => const FinderReading(
          partnerSharing: false,
          reason: 'partner_not_opted',
        ),
      );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      await _flushAsync();

      expect(harness.repository.windowReadCount, 1);
      expect(harness.repository.calls, hasLength(1));
      expect(harness.repository.calls.single.windowId, 'wave-window-1');
      expect(harness.repository.calls.single.optIn, isTrue);
      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.waiting,
      );

      harness.repository.windowId = 'wave-window-restarted';
      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.positions.add(_position(latitude: 45.549));
      await _flushAsync();

      expect(harness.repository.windowReadCount, 1);
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.windowId, 'wave-window-1');
    });

    test('serializes requests and coalesces in-flight samples in order',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final first = Completer<FinderReading>();
      final second = Completer<FinderReading>();
      harness.repository.responses
        ..add(() => first.future)
        ..add(() => second.future);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position(latitude: 45.548));
      expect(harness.repository.calls, hasLength(1));

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.positions
        ..add(_position(latitude: 45.549))
        ..add(_position(latitude: 45.55));
      expect(
        harness.repository.calls,
        hasLength(1),
        reason: 'a second callable must not overlap the first',
      );

      first.complete(
        const FinderReading(
          partnerSharing: true,
          bearing: 45,
          distanceM: 18,
        ),
      );
      await _flushAsync();

      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.latitude, 45.55);
      second.complete(
        const FinderReading(
          partnerSharing: false,
          reason: 'partner_not_opted',
        ),
      );
      await _flushAsync();
      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.waiting,
      );
    });

    test('throttles samples until the injectable three-second cadence',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position(latitude: 45.548));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(1));

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 2, 999));
      harness.positions.add(_position(latitude: 45.549));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(1));

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.positions.add(_position(latitude: 45.55));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(2));
    });

    test('sends the latest pending sample at the trailing cadence edge',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position(latitude: 45.548));
      await _flushAsync();

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 2));
      harness.positions.add(_position(latitude: 45.55));
      expect(harness.repository.calls, hasLength(1));
      expect(harness.delay.durations, <Duration>[const Duration(seconds: 3)]);

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.delay.completeNext();
      await _flushAsync();

      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.latitude, 45.55);
    });

    test('heartbeats the latest fix every three seconds while stationary',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position(latitude: 45.548));
      await _flushAsync();

      expect(harness.repository.calls, hasLength(1));
      expect(harness.delay.durations, <Duration>[const Duration(seconds: 3)]);

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.delay.completeNext();
      await _flushAsync();

      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.latitude, 45.548);
      expect(harness.repository.calls.last.longitude, 13.73);
    });

    test('maps valid sharing to active and stale or poor GPS to fallback',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      harness.repository.responses
        ..add(
          () async => const FinderReading(
            partnerSharing: true,
            bearing: 271,
            distanceM: 16,
          ),
        )
        ..add(
          () async => const FinderReading(
            partnerSharing: false,
            reason: 'partner_stale',
          ),
        )
        ..add(
          () async => const FinderReading(
            partnerSharing: false,
            reason: 'poor_accuracy',
          ),
        );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      await _flushAsync();

      var state = harness.container.read(preciseFinderControllerProvider);
      expect(state.status, FinderStatus.active);
      expect(state.reading?.bearing, 271);
      expect(state.reading?.distanceM, 16);

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.positions.add(_position(latitude: 45.549));
      await _flushAsync();
      state = harness.container.read(preciseFinderControllerProvider);
      expect(state.status, FinderStatus.fallback);
      expect(state.reading?.reason, 'partner_stale');

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 6));
      harness.positions.add(_position(latitude: 45.55));
      await _flushAsync();
      state = harness.container.read(preciseFinderControllerProvider);
      expect(state.status, FinderStatus.fallback);
      expect(state.reading?.reason, 'poor_accuracy');
    });

    test('maps location and callable failures to honest fallback', () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      harness.repository.responses.add(
        () => Future<FinderReading>.error(Exception('callable unavailable')),
      );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      await _flushAsync();
      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'callable'),
      );

      harness.positions.addError(Exception('location unavailable'));
      await _flushAsync();
      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );
    });

    test('maps an ended location stream to honest fallback', () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      await harness.positions.close();
      await _flushAsync();

      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );
    });

    test('a response arriving after a location error cannot reactivate finder',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final inFlight = Completer<FinderReading>();
      harness.repository.responses
        ..add(() => inFlight.future)
        ..add(
          () async => const FinderReading(
            partnerSharing: true,
            bearing: 90,
            distanceM: 2,
          ),
        );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      harness.positions.addError(Exception('GPS unavailable'));
      await _flushAsync();

      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );

      inFlight.complete(
        const FinderReading(
          partnerSharing: true,
          bearing: 180,
          distanceM: 3,
        ),
      );
      await _flushAsync();

      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );
      expect(harness.delay.durations, isEmpty);
      expect(harness.repository.calls, hasLength(1));

      harness.setNow(DateTime.utc(2026, 7, 22, 12, 0, 3));
      harness.positions.add(_position(latitude: 45.549));
      await _flushAsync();

      expect(harness.repository.calls, hasLength(2));
      expect(
        harness.container.read(preciseFinderControllerProvider),
        const FinderState.active(
          FinderReading(
            partnerSharing: true,
            bearing: 90,
            distanceM: 2,
          ),
        ),
      );
    });

    test('a response arriving after location stream done cannot reactivate',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final inFlight = Completer<FinderReading>();
      harness.repository.responses.add(() => inFlight.future);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      await harness.positions.close();
      await _flushAsync();

      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );

      inFlight.complete(
        const FinderReading(
          partnerSharing: true,
          bearing: 180,
          distanceM: 3,
        ),
      );
      await _flushAsync();

      expect(
        harness.container.read(preciseFinderControllerProvider),
        FinderState.fallback(reason: 'location'),
      );
      expect(harness.delay.durations, isEmpty);
      expect(harness.repository.calls, hasLength(1));
    });

    test('window_over stops, revokes, and never exposes precise data',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      harness.repository.responses.add(
        () async => const FinderReading(
          partnerSharing: false,
          reason: 'window_over',
        ),
      );

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      await _flushAsync();
      await _flushAsync();

      final state = harness.container.read(preciseFinderControllerProvider);
      expect(state.status, FinderStatus.stopped);
      expect(state.reading?.bearing, isNull);
      expect(state.reading?.distanceM, isNull);
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.optIn, isFalse);
      expect(harness.repository.calls.last.windowId, 'wave-window-1');
    });

    test('stop cancels first, waits for a late request, then revokes once',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final inFlight = Completer<FinderReading>();
      final revocation = Completer<FinderReading>();
      harness.repository.responses
        ..add(() => inFlight.future)
        ..add(() => revocation.future);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      expect(harness.repository.calls, hasLength(1));

      final notifier =
          harness.container.read(preciseFinderControllerProvider.notifier);
      final firstStop = notifier.stop();
      final repeatedStop = notifier.stop();
      harness.positions.add(_position(latitude: 45.56));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(1));

      inFlight.complete(
        const FinderReading(
          partnerSharing: true,
          bearing: 180,
          distanceM: 3,
        ),
      );
      await _flushAsync();
      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        isNot(FinderStatus.active),
        reason: 'a late response must not reactivate a stopped session',
      );
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.optIn, isFalse);
      expect(harness.repository.calls.last.windowId, 'wave-window-1');

      revocation.complete(const FinderReading(partnerSharing: false));
      await Future.wait([firstStop, repeatedStop]);
      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.stopped,
      );
      expect(harness.cancellationCount(), 1);
      expect(harness.repository.calls, hasLength(2));
    });

    test('a rapid restart waits until the previous revocation completes',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final inFlight = Completer<FinderReading>();
      final revocation = Completer<FinderReading>();
      harness.repository.responses
        ..add(() => inFlight.future)
        ..add(() => revocation.future);

      final notifier =
          harness.container.read(preciseFinderControllerProvider.notifier);
      await notifier.optInAndStart('match-1');
      harness.positions.add(_position());
      final stop = notifier.stop();
      harness.repository.windowId = 'wave-window-2';
      final restart = notifier.optInAndStart('match-1');
      await _flushAsync();

      expect(
        harness.repository.windowReadCount,
        1,
        reason: 'the new session must not start while old cleanup is pending',
      );

      inFlight.complete(const FinderReading(partnerSharing: false));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.windowId, 'wave-window-1');
      expect(harness.repository.calls.last.optIn, isFalse);

      revocation.complete(const FinderReading(partnerSharing: false));
      await Future.wait([stop, restart]);
      expect(harness.repository.windowReadCount, 2);
      expect(harness.settings, hasLength(2));

      harness.positions.add(_position(latitude: 45.56));
      await _flushAsync();
      expect(harness.repository.calls.last.windowId, 'wave-window-2');
      expect(harness.repository.calls.last.optIn, isTrue);
    });

    test('stop cancels an activation queued behind an existing cleanup',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final revocation = Completer<FinderReading>();
      harness.repository.responses
        ..add(() async => const FinderReading(partnerSharing: false))
        ..add(() => revocation.future);

      final notifier =
          harness.container.read(preciseFinderControllerProvider.notifier);
      await notifier.optInAndStart('match-1');
      harness.positions.add(_position());
      await _flushAsync();

      final firstStop = notifier.stop();
      await _flushAsync();
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.optIn, isFalse);

      harness.repository.windowId = 'wave-window-2';
      final queuedActivation = notifier.optInAndStart('match-1');
      final repeatedStop = notifier.stop();
      revocation.complete(const FinderReading(partnerSharing: false));
      await Future.wait([firstStop, repeatedStop, queuedActivation]);
      await _flushAsync();

      expect(
        harness.repository.windowReadCount,
        1,
        reason: 'stop must invalidate activation queued behind old cleanup',
      );
      expect(harness.settings, hasLength(1));
      expect(harness.repository.calls, hasLength(2));
      expect(
        harness.container.read(preciseFinderControllerProvider).status,
        FinderStatus.stopped,
      );
    });

    test('stream cancellation failure still revokes and exposes stopped',
        () async {
      final repository = _FakeFinderRepository();
      final container = ProviderContainer(
        overrides: [
          finderRepositoryProvider.overrideWithValue(repository),
          finderLocationStreamProvider.overrideWithValue(
            (_) => _CancelFailingStream(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(keepAlive.close);
      final notifier = container.read(preciseFinderControllerProvider.notifier);

      await notifier.optInAndStart('match-1');
      await notifier.stop();

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.optIn, isFalse);
      expect(
        container.read(preciseFinderControllerProvider).status,
        FinderStatus.stopped,
      );
    });

    test('autoDispose still revokes after an in-flight request settles',
        () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final keepAlive = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      final inFlight = Completer<FinderReading>();
      harness.repository.responses.add(() => inFlight.future);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      expect(harness.repository.calls, hasLength(1));

      keepAlive.close();
      await _flushAsync();
      inFlight.complete(
        const FinderReading(
          partnerSharing: true,
          bearing: 180,
          distanceM: 4,
        ),
      );
      await _flushAsync();

      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.optIn, isFalse);
      expect(harness.repository.calls.last.windowId, 'wave-window-1');
    });

    test('a recreated provider waits for autoDispose revocation', () async {
      final harness = _harness();
      addTearDown(harness.container.dispose);
      addTearDown(harness.positions.close);
      final oldListener = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      final inFlight = Completer<FinderReading>();
      final revocation = Completer<FinderReading>();
      harness.repository.responses
        ..add(() => inFlight.future)
        ..add(() => revocation.future);

      await harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      harness.positions.add(_position());
      oldListener.close();
      await _flushAsync();

      final newListener = harness.container.listen(
        preciseFinderControllerProvider,
        (_, __) {},
      );
      addTearDown(newListener.close);
      harness.repository.windowId = 'wave-window-2';
      final restart = harness.container
          .read(preciseFinderControllerProvider.notifier)
          .optInAndStart('match-1');
      await _flushAsync();
      expect(harness.repository.windowReadCount, 1);

      inFlight.complete(const FinderReading(partnerSharing: false));
      await _flushAsync();
      expect(harness.repository.calls, hasLength(2));
      expect(harness.repository.calls.last.optIn, isFalse);
      expect(harness.repository.calls.last.windowId, 'wave-window-1');
      expect(harness.repository.windowReadCount, 1);

      revocation.complete(const FinderReading(partnerSharing: false));
      await restart;
      expect(harness.repository.windowReadCount, 2);
      expect(harness.settings, hasLength(2));
    });

    test('state and readings contain only derived finder data', () {
      const reading = FinderReading(
        partnerSharing: true,
        bearing: 180,
        distanceM: 12,
      );
      const state = FinderState.active(reading);

      expect(state.reading, reading);
      expect(state.reading?.bearing, 180);
      expect(state.reading?.distanceM, 12);
      expect(state.toString(), isNot(contains('45.548')));
      expect(reading.toString(), isNot(contains('13.73')));
    });
  });
}
