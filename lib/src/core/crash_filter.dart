import 'package:flutter/foundation.dart';

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
    final exceptionText = details.exceptionAsString();
    final stackText = details.stack?.toString() ?? '';

    final isFromTilePipeline =
        _tilePipelineFrames.any((frame) => stackText.contains(frame));
    if (!isFromTilePipeline) return false;

    // A tile is cancelled every time the camera moves.
    final isCancellation = exceptionText == 'Cancelled' ||
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
