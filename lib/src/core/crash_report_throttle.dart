import 'dart:collection';

/// Bounds how many errors may be handed to the crash reporters per window.
///
/// Crashlytics records on the main thread and walks every thread in the process
/// (`FIRCLSProcessRecordAllThreads`). Tremble runs dozens of DartWorker and gRPC
/// threads, so a single report is expensive and a sustained stream of them
/// stalls the main thread — in 1.0.0+23 that ended in a stack overflow raised
/// from inside the reporter, with the app's own error handler as the cause.
///
/// [CrashFilter] removes the source we know about. This bounds the blast radius
/// of the ones we do not: reporting a storm's first few errors identifies it
/// just as well as reporting ten thousand, at a fraction of the cost.
class CrashReportThrottle {
  CrashReportThrottle({
    this.maxReports = 8,
    this.window = const Duration(minutes: 1),
  });

  /// Reports permitted per [window].
  final int maxReports;

  /// Sliding window over which [maxReports] is counted.
  final Duration window;

  /// Timestamps of permitted reports, oldest first. Bounded by [maxReports]:
  /// blocked reports are never recorded, so a storm cannot grow this queue.
  final Queue<DateTime> _permitted = Queue<DateTime>();

  /// Whether a report at [now] may be forwarded to the reporters.
  bool allow(DateTime now) {
    final cutoff = now.subtract(window);
    while (_permitted.isNotEmpty && !_permitted.first.isAfter(cutoff)) {
      _permitted.removeFirst();
    }

    if (_permitted.length >= maxReports) return false;

    _permitted.addLast(now);
    return true;
  }

  /// Entries currently retained. Exposed so a test can prove the throttle does
  /// not become its own leak under a sustained storm.
  int get debugRetainedCount => _permitted.length;
}
