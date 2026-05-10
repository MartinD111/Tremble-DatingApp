import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Prediction returned from the Places API (New) Autocomplete endpoint.
class PlacePrediction {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormat = json['structuredFormat'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['placeId'] as String? ?? '',
      description: json['text']?['text'] as String? ?? '',
      mainText: structuredFormat?['mainText']?['text'] as String?,
      secondaryText: structuredFormat?['secondaryText']?['text'] as String?,
    );
  }

  /// Human-readable label for UI display.
  String get displayName => mainText != null && secondaryText != null
      ? '$mainText, $secondaryText'
      : description;
}

/// Details returned from the Places API (New) Place Details endpoint.
class PlaceDetails {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const PlaceDetails({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/// Google Places API (New) autocomplete service with Session Token billing model.
///
/// Cost model (critical):
///   WITHOUT session tokens: $0.017 per Autocomplete request × N keystrokes
///   WITH session tokens: $0.017 flat per session (all keystrokes + 1 Place Details)
///   At 50k DAU: ~$5,100/mo vs ~$200–500/mo
///
/// Usage pattern:
///   1. Call [startSession] when the location field receives focus.
///   2. Call [autocomplete] / [gymAutocomplete] on each debounced keystroke.
///   3. Call [getPlaceDetails] when the user selects a result (ends the session).
///
/// The API key is injected via --dart-define=PLACES_KEY_DEV=AIza...
/// and is NEVER hardcoded in source.
class PlacesService {
  static const String _autocompleteEndpoint =
      'https://places.googleapis.com/v1/places:autocomplete';
  static const String _detailsEndpoint =
      'https://places.googleapis.com/v1/places';

  static const String _apiKey = String.fromEnvironment(
    String.fromEnvironment('FLAVOR', defaultValue: 'dev') == 'prod'
        ? 'PLACES_KEY_PROD'
        : 'PLACES_KEY_DEV',
    defaultValue: '',
  );

  final _uuid = const Uuid();
  String? _sessionToken;

  /// Start a new billing session. Call when the autocomplete field gets focus.
  void startSession() {
    _sessionToken = _uuid.v4();
    debugPrint('[PlacesService] New session started: $_sessionToken');
  }

  /// End the current billing session.
  void endSession() {
    debugPrint('[PlacesService] Session ended: $_sessionToken');
    _sessionToken = null;
  }

  /// Returns city autocomplete predictions for [input].
  /// Restricts to city-level results biased toward Slovenia/EU.
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    if (_apiKey.isEmpty) {
      debugPrint(
          '[PlacesService] ⚠️ No API key — pass --dart-define=PLACES_KEY_DEV=AIza...');
      return [];
    }

    _sessionToken ??= _uuid.v4();

    try {
      final response = await http
          .post(
            Uri.parse(_autocompleteEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
            },
            body: jsonEncode({
              'input': input.trim(),
              'sessionToken': _sessionToken,
              'includedPrimaryTypes': ['(cities)'],
              'locationBias': {
                'circle': {
                  'center': {'latitude': 46.1512, 'longitude': 14.9955},
                  'radius': 2000000.0,
                },
              },
              'languageCode': 'en',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
            '[PlacesService] API error ${response.statusCode}: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['suggestions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => s['placePrediction'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .map(PlacePrediction.fromJson)
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[PlacesService] Error: $e');
      return [];
    }
  }

  /// Returns gym/fitness place autocomplete predictions for [input].
  ///
  /// No type filter — searches all establishment types so users can find
  /// gyms by name regardless of how Google categorises them (gym, CrossFit,
  /// yoga studio, etc.). Session token billing applies (Rule #42).
  Future<List<PlacePrediction>> gymAutocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    if (_apiKey.isEmpty) {
      debugPrint('[PlacesService] ⚠️ No API key for gym autocomplete.');
      return [];
    }

    _sessionToken ??= _uuid.v4();

    try {
      final response = await http
          .post(
            Uri.parse(_autocompleteEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
            },
            body: jsonEncode({
              'input': input.trim(),
              'sessionToken': _sessionToken,
              'languageCode': 'en',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
            '[PlacesService] Gym autocomplete error ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['suggestions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => s['placePrediction'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .map(PlacePrediction.fromJson)
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[PlacesService] Gym autocomplete error: $e');
      return [];
    }
  }

  /// Fetches place details (name, address, lat, lng) for [placeId].
  ///
  /// Uses the active session token to link this request to the preceding
  /// autocomplete calls for billing consolidation (Rule #42).
  /// Automatically ends the session after the call.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) return null;

    final token = _sessionToken;

    try {
      final uri = Uri.parse('$_detailsEndpoint/$placeId').replace(
        queryParameters: token != null ? {'sessionToken': token} : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'displayName,formattedAddress,location',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
            '[PlacesService] Place details error ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final details = PlaceDetails(
        name: (data['displayName'] as Map<String, dynamic>?)?['text']
                as String? ??
            '',
        address: data['formattedAddress'] as String? ?? '',
        lat: (location['latitude'] as num?)?.toDouble() ?? 0.0,
        lng: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      );

      // End billing session after Place Details — starts fresh for next search.
      endSession();
      return details;
    } catch (e) {
      debugPrint('[PlacesService] Place details error: $e');
      endSession();
      return null;
    }
  }
}

/// Singleton provider for PlacesService.
/// Use `ref.read(placesServiceProvider)` in widgets and notifiers.
final placesServiceProvider = Provider<PlacesService>((ref) => PlacesService());
