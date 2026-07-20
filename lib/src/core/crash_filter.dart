import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Decides which `FlutterError`s are benign enough to keep out of Crashlytics
/// and Sentry.
///
/// This is not cosmetic. Crashlytics records on the main thread and walks every
/// thread in the process, and Tremble runs dozens of DartWorker and gRPC
/// threads. One report is expensive; a *stream* of them is fatal. In 1.0.0+23
/// an unreachable tile host produced one report per failed tile until the main
/// thread stalled and the stack overflowed inside the reporter itself.
///
/// The tile pipeline fails constantly by design — tiles are cancelled whenever
/// the camera moves, and every one of them fails when the device is offline.
/// None of it is actionable, so none of it is worth reporting.
class CrashFilter {
  const CrashFilter._();

  /// Frames belonging to the vector tile pipeline.
  ///
  /// Release builds strip package URIs, so only the bare filename survives —
  /// which is why matching on `package:vector_map_tiles/` passed in debug and
  /// silently missed every production stack. Each bare filename below was taken
  /// from a real 1.0.0+23 Crashlytics report. Prefer adding a frame here over
  /// broadening the exception match.
  static const List<String> _tilePipelineFrames = <String>[
    'vector_map_tiles',
    'future_tile_provider.dart',
    '_FutureImageProvider',
    'tile_loader.dart',
    'vector_tile_loading_cache.dart',
    'caches_tile_provider.dart',
    'concurrency_executor.dart',
    'isolate_executor.dart',
    'pool_executor.dart',
    // The package's own filename really is misspelled.
    'immdediate_executor.dart',
  ];

  static bool shouldSuppressFlutterError(FlutterErrorDetails details) {
    return _isBenignTileFailure(
      exceptionText: details.exceptionAsString(),
      stackText: details.stack?.toString() ?? '',
    );
  }

  /// Sentry `beforeSend` guard for the same tile-pipeline noise.
  ///
  /// These `Cancelled` failures escape [FlutterError.onError] and reach Sentry
  /// through `PlatformDispatcher.onError` / the isolate error listener, which
  /// capture unfiltered — so they flooded prod Sentry as errors
  /// (TREMBLE-FUNCTIONS-13/14/15) despite the [FlutterError] filter above.
  /// Returning `null` from `beforeSend` for these events drops them. Release
  /// builds minify the exception type (e.g. `fL`), so match on the value text
  /// (`Cancelled`) plus a tile-pipeline stack frame, never on the type.
  static bool shouldSuppressSentryEvent(SentryEvent event) {
    final exceptions = event.exceptions;
    if (exceptions == null || exceptions.isEmpty) return false;

    for (final exception in exceptions) {
      final exceptionText = '${exception.type ?? ''}: ${exception.value ?? ''}';
      final stackText = exception.stackTrace?.frames
              .map((f) =>
                  '${f.fileName ?? ''} ${f.function ?? ''} ${f.package ?? ''} ${f.absPath ?? ''}')
              .join('\n') ??
          '';
      if (_isBenignTileFailure(
        exceptionText: exceptionText,
        stackText: stackText,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Shared predicate: a benign tile-pipeline cancellation or network failure.
  /// Gated behind a tile-pipeline stack frame so real defects on any other
  /// stack still report.
  static bool _isBenignTileFailure({
    required String exceptionText,
    required String stackText,
  }) {
    final isFromTilePipeline =
        _tilePipelineFrames.any((frame) => stackText.contains(frame));
    if (!isFromTilePipeline) return false;

    // A tile is cancelled every time the camera moves. `.contains` (not `==`)
    // so a minified/prefixed value like "fL: Cancelled" still matches.
    final isCancellation = exceptionText.contains('Cancelled') ||
        exceptionText.contains('CancellationException');

    // Offline / bad network: DNS for the tile host fails, so tiles in flight
    // throw rather than cancel.
    final isNetworkFailure = exceptionText.contains('SocketException') ||
        exceptionText.contains('ClientException') ||
        exceptionText.contains('Failed host lookup') ||
        exceptionText.contains('HttpException');

    // Anything else on this stack is a real defect and must still report.
    return isCancellation || isNetworkFailure;
  }
}
