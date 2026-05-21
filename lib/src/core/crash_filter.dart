import 'package:flutter/foundation.dart';

class CrashFilter {
  const CrashFilter._();

  static bool shouldSuppressFlutterError(FlutterErrorDetails details) {
    final exceptionText = details.exceptionAsString();
    final stackText = details.stack?.toString() ?? '';

    final isCancellation = exceptionText == 'Cancelled' ||
        exceptionText.contains('CancellationException');
    final isVectorTileStack =
        stackText.contains('package:vector_map_tiles/src/raster/');

    return isCancellation && isVectorTileStack;
  }
}
