import 'package:flutter/foundation.dart';

class CrashFilter {
  const CrashFilter._();

  static bool shouldSuppressFlutterError(FlutterErrorDetails details) {
    final exceptionText = details.exceptionAsString();
    final stackText = details.stack?.toString() ?? '';

    final isCancellation = exceptionText == 'Cancelled' ||
        exceptionText.contains('CancellationException');

    // Match both debug builds (full package URI present) and release/AOT
    // builds (Dart strips package URIs; only the bare filename survives).
    final isVectorTileStack = stackText.contains('package:vector_map_tiles/') ||
        stackText.contains('vector_map_tiles') ||
        stackText.contains('future_tile_provider.dart') ||
        stackText.contains('_FutureImageProvider');

    return isCancellation && isVectorTileStack;
  }
}
