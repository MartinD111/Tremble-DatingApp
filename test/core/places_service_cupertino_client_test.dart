// Regression tests for H9 — Places API HTTP calls routed through CupertinoClient on iOS.
//
// places_service.dart MUST:
//  1. Import cupertino_http and dart:io Platform
//  2. Provide _buildHttpClient() that returns CupertinoClient on iOS
//  3. Use _client.post / _client.get — NOT bare http.post / http.get
//  4. Expose dispose() that closes _client
//  5. Provider wires ref.onDispose(service.dispose)
//
// Source-text tests — cupertino_http / NSURLSession not available in unit context.
// These pin the structural contract so a future refactor cannot silently regress
// to the bare http.* calls that triggered SSLV3_ALERT_HANDSHAKE_FAILURE on iOS.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'lib/src/core/places_service.dart';

  late String source;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
  });

  group('PlacesService — CupertinoClient iOS TLS fix (H9)', () {
    test('imports cupertino_http', () {
      expect(
        source,
        contains("import 'package:cupertino_http/cupertino_http.dart';"),
        reason: 'CupertinoClient lives in cupertino_http',
      );
    });

    test('imports dart:io Platform', () {
      expect(
        source,
        contains("import 'dart:io' show Platform;"),
        reason: 'Platform.isIOS guard requires dart:io import',
      );
    });

    test('_buildHttpClient() function is present', () {
      expect(
        source,
        contains('_buildHttpClient()'),
        reason: 'Platform-aware factory must exist',
      );
    });

    test('_buildHttpClient returns CupertinoClient on iOS', () {
      expect(
        source,
        contains('CupertinoClient.fromSessionConfiguration(config)'),
        reason: 'iOS path must use CupertinoClient (NSURLSession)',
      );
    });

    test('_client field is declared on PlacesService', () {
      expect(
        source,
        contains('final http.Client _client = _buildHttpClient();'),
        reason: 'Service must hold a platform-aware client instance',
      );
    });

    test('no bare http.post calls remain', () {
      // Matches "http.post(" anywhere in source (excluding comments).
      final barePost = RegExp(r'(?<!_client)\bhttp\.post\(');
      expect(
        barePost.hasMatch(source),
        isFalse,
        reason: 'All post() calls must go through _client, not bare http.*',
      );
    });

    test('no bare http.get calls remain', () {
      final bareGet = RegExp(r'(?<!_client)\bhttp\.get\(');
      expect(
        bareGet.hasMatch(source),
        isFalse,
        reason: 'All get() calls must go through _client, not bare http.*',
      );
    });

    test('dispose() method exists on PlacesService', () {
      expect(
        source,
        contains('void dispose()'),
        reason: 'HTTP client must be closed when provider is disposed',
      );
    });

    test('dispose() closes the client', () {
      expect(
        source,
        contains('_client.close()'),
        reason: 'dispose() must call _client.close()',
      );
    });

    test('provider wires ref.onDispose', () {
      expect(
        source,
        contains('ref.onDispose(service.dispose)'),
        reason: 'Riverpod must close the client when the provider is disposed',
      );
    });

    test('_client.post used in autocomplete()', () {
      // autocomplete() is the city search — it must use _client
      final autocompleteSection = source.substring(
        source.indexOf('Future<List<PlacePrediction>> autocomplete('),
        source.indexOf('Future<List<PlacePrediction>> gymAutocomplete('),
      );
      expect(
        autocompleteSection,
        contains('_client'),
        reason: 'autocomplete() must route through _client',
      );
    });

    test('_client.post used in gymAutocomplete()', () {
      final gymSection = source.substring(
        source.indexOf('Future<List<PlacePrediction>> gymAutocomplete('),
        source.indexOf('Future<PlaceDetails?> getPlaceDetails('),
      );
      expect(
        gymSection,
        contains('_client'),
        reason: 'gymAutocomplete() must route through _client',
      );
    });

    test('_client.get used in getPlaceDetails()', () {
      final detailsSection = source.substring(
        source.indexOf('Future<PlaceDetails?> getPlaceDetails('),
      );
      expect(
        detailsSection,
        contains('_client'),
        reason: 'getPlaceDetails() must route through _client',
      );
    });
  });
}
