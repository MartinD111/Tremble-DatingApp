import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/crash_filter.dart';

void main() {
  group('CrashFilter', () {
    test('suppresses benign vector tile cancellation errors', () {
      final details = FlutterErrorDetails(
        exception: 'Cancelled',
        stack: StackTrace.fromString(
          'package:vector_map_tiles/src/raster/tile_loader.dart:72\n',
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
  });
}
