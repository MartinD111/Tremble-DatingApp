import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Regression guard — iOS TLS fix for Cloudflare R2 uploads.
//
// `package:http` on iOS does NOT use NSURLSession by default — it wraps
// `dart:io HttpClient`, whose TLS stack triggers SSLV3_ALERT_HANDSHAKE_FAILURE
// against Cloudflare R2's S3-compatible endpoint.
//
// The correct fix is to route the iOS upload through `cupertino_http`'s
// `CupertinoClient`, which delegates to NSURLSession / Network.framework.
//
// This test scans upload_service.dart to ensure:
//   1. `dart:io HttpClient` is NOT instantiated.
//   2. `package:cupertino_http` is imported.
//   3. `CupertinoClient` is constructed.
//   4. The PUT is dispatched through the platform client (`client.put(`),
//      not the top-level `http.put(` (which would bypass CupertinoClient).
//
// If any assertion fails, do NOT loosen it here — revert the regression that
// reintroduced the broken client or dropped cupertino_http.
void main() {
  const String _sourcePath = 'lib/src/core/upload_service.dart';

  group('UploadService — iOS TLS fix guard (cupertino_http / NSURLSession)',
      () {
    late String source;

    setUpAll(() {
      // `flutter test` sets cwd to project root.
      source = File(_sourcePath).readAsStringSync();
    });

    test('dart:io HttpClient is NOT instantiated in upload_service.dart', () {
      expect(
        source,
        isNot(contains('HttpClient()')),
        reason: 'dart:io HttpClient() must not be used in upload_service.dart. '
            'It causes SSLV3_ALERT_HANDSHAKE_FAILURE on iOS when connecting to '
            'Cloudflare R2. Use cupertino_http CupertinoClient instead.',
      );
    });

    test('package:cupertino_http is imported in upload_service.dart', () {
      expect(
        source,
        contains('package:cupertino_http/cupertino_http.dart'),
        reason: 'upload_service.dart must import cupertino_http. '
            'package:http alone wraps dart:io HttpClient on iOS, which fails '
            'TLS handshake against Cloudflare R2.',
      );
    });

    test('CupertinoClient is constructed in upload_service.dart', () {
      expect(
        source,
        contains('CupertinoClient.fromSessionConfiguration('),
        reason: 'upload_service.dart must construct a CupertinoClient on iOS '
            'so the PUT routes through NSURLSession / Network.framework.',
      );
    });

    test('R2 PUT goes through the platform client, not top-level http.put', () {
      expect(
        source,
        contains('client.put('),
        reason: 'The R2 PUT must be dispatched through the platform client '
            '(client.put), so iOS uses CupertinoClient.',
      );
      expect(
        source,
        isNot(contains('http.put(')),
        reason: 'Top-level http.put() bypasses CupertinoClient on iOS and '
            'falls back to dart:io HttpClient — the broken path.',
      );
    });
  });
}
