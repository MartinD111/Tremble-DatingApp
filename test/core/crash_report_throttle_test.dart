import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/crash_report_throttle.dart';

void main() {
  // Crashlytics records on the main thread and walks every thread in the
  // process (FIRCLSProcessRecordAllThreads). Tremble runs dozens of DartWorker
  // and gRPC threads, so each report is expensive. In 1.0.0+23 an offline map
  // produced one report per failed tile, forever, which saturated the main
  // thread and overflowed the stack inside the reporter itself.
  //
  // Filtering the known source is not enough — the next unfiltered storm would
  // do the same thing. This bounds reporting whatever the source.
  group('CrashReportThrottle', () {
    final t0 = DateTime.utc(2026, 7, 17, 9, 0, 0);

    test('allows reports up to the limit within the window', () {
      final throttle = CrashReportThrottle(
        maxReports: 3,
        window: const Duration(minutes: 1),
      );

      expect(throttle.allow(t0), isTrue);
      expect(throttle.allow(t0.add(const Duration(seconds: 1))), isTrue);
      expect(throttle.allow(t0.add(const Duration(seconds: 2))), isTrue);
    });

    test('blocks once the limit is reached within the window', () {
      final throttle = CrashReportThrottle(
        maxReports: 3,
        window: const Duration(minutes: 1),
      );
      for (var i = 0; i < 3; i++) {
        throttle.allow(t0.add(Duration(seconds: i)));
      }

      expect(throttle.allow(t0.add(const Duration(seconds: 3))), isFalse);
      expect(throttle.allow(t0.add(const Duration(seconds: 4))), isFalse);
    });

    test('the window slides — reporting resumes once old entries age out', () {
      final throttle = CrashReportThrottle(
        maxReports: 2,
        window: const Duration(minutes: 1),
      );
      throttle.allow(t0);
      throttle.allow(t0.add(const Duration(seconds: 1)));
      expect(throttle.allow(t0.add(const Duration(seconds: 2))), isFalse);

      // Both entries are now older than the window.
      expect(throttle.allow(t0.add(const Duration(seconds: 62))), isTrue);
    });

    test('a sustained storm costs a bounded number of reports', () {
      final throttle = CrashReportThrottle(
        maxReports: 8,
        window: const Duration(minutes: 1),
      );

      // One failed tile every 100ms for a solid minute — the offline map case.
      var permitted = 0;
      for (var ms = 0; ms < 60000; ms += 100) {
        if (throttle.allow(t0.add(Duration(milliseconds: ms)))) permitted++;
      }

      expect(permitted, 8);
    });

    test('does not retain unbounded history under a storm', () {
      final throttle = CrashReportThrottle(
        maxReports: 5,
        window: const Duration(minutes: 1),
      );
      for (var ms = 0; ms < 600000; ms += 50) {
        throttle.allow(t0.add(Duration(milliseconds: ms)));
      }

      // Whatever is retained must be bounded by the limit, not by how many
      // errors arrived — the throttle must not become its own memory leak.
      expect(throttle.debugRetainedCount, lessThanOrEqualTo(5));
    });
  });
}
