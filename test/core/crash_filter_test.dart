import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/crash_filter.dart';

void main() {
  group('CrashFilter', () {
    test('suppresses benign vector tile cancellation — debug build stack', () {
      final details = FlutterErrorDetails(
        exception: 'Cancelled',
        stack: StackTrace.fromString(
          'package:vector_map_tiles/src/raster/tile_loader.dart:72\n',
        ),
      );

      expect(CrashFilter.shouldSuppressFlutterError(details), isTrue);
    });

    test('suppresses benign vector tile cancellation — AOT/release build stack',
        () {
      // In release builds Dart strips package URIs; only the bare filename
      // survives. This mirrors the exact Crashlytics stack trace that was
      // slipping through the old filter.
      final details = FlutterErrorDetails(
        exception: 'Cancelled',
        stack: StackTrace.fromString(
          'at _FutureImageProvider._load.<fn>(future_tile_provider.dart:67)\n',
        ),
      );

      expect(CrashFilter.shouldSuppressFlutterError(details), isTrue);
    });

    test('does not suppress unrelated cancelled errors', () {
      final details = FlutterErrorDetails(
        exception: 'Cancelled',
        stack: StackTrace.fromString(
          'package:tremble/src/features/auth/data/auth_repository.dart:10\n',
        ),
      );

      expect(CrashFilter.shouldSuppressFlutterError(details), isFalse);
    });

    // ── Production frames, 1.0.0+23 ────────────────────────────────────────
    // Every frame below is copied from a real Crashlytics report. The previous
    // filter matched none of them: it looked for `vector_map_tiles`,
    // `future_tile_provider.dart`, and `_FutureImageProvider`, but AOT strips
    // package URIs and the tile pipeline's real frames carry different
    // filenames. Each unsuppressed error became a main-thread
    // `recordFlutterFatalError`, and the resulting storm hung the app.
    group('real 1.0.0+23 release frames', () {
      const productionFrames = <String, String>{
        'tile_loader': 'TileLoader._renderTile + 72 (tile_loader.dart:72)',
        'isolate_executor':
            'IsolateExecutor.submit + 69 (isolate_executor.dart:69)',
        'vector_tile_loading_cache': 'VectorTileLoadingCache._loadTile + 102 '
            '(vector_tile_loading_cache.dart:102)',
        'caches_tile_provider':
            'CachesTileProvider._retrieve + 64 (caches_tile_provider.dart:64)',
        'concurrency_executor':
            'ConcurrencyExecutor._startJob + 74 (concurrency_executor.dart:74)',
        'pool_executor': 'PoolExecutor.submit + 38 (pool_executor.dart:38)',
        // The package really does misspell this filename.
        'immediate_executor':
            'ImmediateExecutor.submit + 17 (immdediate_executor.dart:17)',
      };

      productionFrames.forEach((name, frame) {
        test('suppresses Cancelled originating in $name', () {
          final details = FlutterErrorDetails(
            exception: 'Cancelled',
            stack: StackTrace.fromString('$frame\n'),
          );

          expect(CrashFilter.shouldSuppressFlutterError(details), isTrue);
        });
      });
    });

    // The offline trigger: DNS for the tile host fails, so every tile in flight
    // throws a network error rather than a cancellation. The old filter only
    // recognised 'Cancelled', so airplane mode reported one fatal per tile.
    group('offline tile fetch failures', () {
      test('suppresses failed host lookup from the tile pipeline', () {
        final details = FlutterErrorDetails(
          exception:
              "ClientException with SocketException: Failed host lookup: "
              "'maps.trembledating.com' (OS Error: nodename nor servname "
              "provided, or not known, errno = 8), "
              "uri=https://maps.trembledating.com/planet.pmtiles",
          stack: StackTrace.fromString(
            'TileLoader._renderTile + 72 (tile_loader.dart:72)\n',
          ),
        );

        expect(CrashFilter.shouldSuppressFlutterError(details), isTrue);
      });

      test('suppresses a bare SocketException from the tile pipeline', () {
        final details = FlutterErrorDetails(
          exception: 'SocketException: Connection failed',
          stack: StackTrace.fromString(
            'VectorTileLoadingCache.retrieve + 43 '
            '(vector_tile_loading_cache.dart:43)\n',
          ),
        );

        expect(CrashFilter.shouldSuppressFlutterError(details), isTrue);
      });

      test('does NOT suppress a network failure outside the tile pipeline', () {
        // A failed upload or callable is a real signal and must still report.
        final details = FlutterErrorDetails(
          exception: 'SocketException: Failed host lookup: '
              "'europe-west1-am---dating-app.cloudfunctions.net'",
          stack: StackTrace.fromString(
            'WaveRepository.sendWave + 20 (wave_repository.dart:20)\n',
          ),
        );

        expect(CrashFilter.shouldSuppressFlutterError(details), isFalse);
      });
    });

    test('does not suppress a genuine error sharing the tile pipeline stack',
        () {
      // Only cancellations and network failures are benign. A real defect in
      // the tile pipeline must still surface.
      final details = FlutterErrorDetails(
        exception: 'RangeError (index): Invalid value: Not in inclusive range',
        stack: StackTrace.fromString(
          'TileLoader._renderTile + 72 (tile_loader.dart:72)\n',
        ),
      );

      expect(CrashFilter.shouldSuppressFlutterError(details), isFalse);
    });
  });
}
