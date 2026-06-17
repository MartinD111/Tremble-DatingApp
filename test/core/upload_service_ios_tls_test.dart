import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Regression guard — iOS TLS fix for Cloudflare R2 uploads.
//
// dart:io HttpClient uses Dart's own TLS stack. On iOS this causes
// SSLV3_ALERT_HANDSHAKE_FAILURE against Cloudflare R2's S3-compatible endpoint.
// The fix is to use package:http which delegates to NSURLSession on iOS
// (Apple's native Network.framework TLS stack).
//
// This test scans upload_service.dart source to ensure:
//   1. package:http is imported (the iOS-safe client is wired)
//   2. dart:io HttpClient is NOT instantiated (the broken client is gone)
//
// If either assertion fails, do NOT loosen it here — revert the regression
// that reintroduced dart:io HttpClient or removed package:http.
void main() {
  const String _sourcePath = 'lib/src/core/upload_service.dart';

  group(
      'UploadService — iOS TLS fix guard (package:http, not dart:io HttpClient)',
      () {
    late String source;

    setUpAll(() {
      // `flutter test` sets cwd to project root.
      source = File(_sourcePath).readAsStringSync();
    });

    test('package:http is imported in upload_service.dart', () {
      expect(
        source,
        contains("package:http/http.dart"),
        reason: 'upload_service.dart must import package:http/http.dart. '
            'dart:io HttpClient triggers SSLV3_ALERT_HANDSHAKE_FAILURE on iOS '
            'against Cloudflare R2. package:http uses NSURLSession on iOS.',
      );
    });

    test('dart:io HttpClient is NOT instantiated in upload_service.dart', () {
      // The import of dart:io for SocketException is fine (no parens follow).
      // What is forbidden is constructing HttpClient() — the Dart TLS client.
      expect(
        source,
        isNot(contains('HttpClient()')),
        reason: 'dart:io HttpClient() must not be used in upload_service.dart. '
            'It causes SSLV3_ALERT_HANDSHAKE_FAILURE on iOS when connecting to '
            'Cloudflare R2. Use package:http instead.',
      );
    });

    test('http.put is used for the R2 PUT request', () {
      expect(
        source,
        contains('http.put('),
        reason: 'upload_service.dart must use http.put() from package:http '
            'for the presigned R2 upload PUT request.',
      );
    });
  });
}
