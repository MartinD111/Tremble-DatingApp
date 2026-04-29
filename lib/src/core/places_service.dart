import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    // Places API (New) autocomplete response structure
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

/// Google Places API (New) autocomplete service with Session Token billing model.
///
/// Cost model (critical):
///   WITHOUT session tokens: $0.017 per Autocomplete request × N keystrokes
///   WITH session tokens: $0.017 flat per session (all keystrokes + 1 Place Details)
///   At 50k DAU: ~$5,100/mo vs ~$200–500/mo
///
/// Usage pattern:
///   1. Call [startSession] when the location field receives focus.
///   2. Call [autocomplete] on each debounced keystroke.
///   3. Call [endSession] when the user selects a result.
///
/// The API key is injected via --dart-define=PLACES_KEY_DEV=AIza...
/// and is NEVER hardcoded in source.
class PlacesService {
  static const String _endpoint =
      'https://places.googleapis.com/v1/places:autocomplete';

  // API key injected via --dart-define at build time.
  // In production (--flavor prod) use PLACES_KEY_PROD.
  static const String _apiKey = String.fromEnvironment(
    'PLACES_KEY_DEV',
    defaultValue: '',
  );

  final _uuid = const Uuid();
  String? _sessionToken;

  /// Start a new billing session. Call when the autocomplete field gets focus.
  void startSession() {
    _sessionToken = _uuid.v4();
    debugPrint('[PlacesService] New session started: $_sessionToken');
  }

  /// End the current billing session. Call after the user selects a result.
  /// A new session token is auto-generated for the next interaction.
  void endSession() {
    debugPrint('[PlacesService] Session ended: $_sessionToken');
    _sessionToken = null;
  }

  /// Returns autocomplete predictions for [input].
  ///
  /// Requires [startSession] to have been called first.
  /// Falls back to empty list on any error — never throws to the UI.
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];

    if (_apiKey.isEmpty) {
      debugPrint(
        '[PlacesService] ⚠️ No API key — '
        'pass --dart-define=PLACES_KEY_DEV=AIza... to flutter run.',
      );
      return [];
    }

    // Ensure session token exists (defensive — startSession should have been called)
    _sessionToken ??= _uuid.v4();

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
            },
            body: jsonEncode({
              'input': input.trim(),
              'sessionToken': _sessionToken,
              // Restrict to city-level results for home city selection
              'includedPrimaryTypes': ['(cities)'],
              // Bias toward Slovenia/EU but don't restrict globally
              'locationBias': {
                'circle': {
                  'center': {'latitude': 46.1512, 'longitude': 14.9955},
                  'radius': 2000000.0, // 2000 km — covers all of Europe
                },
              },
              'languageCode': 'en',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          '[PlacesService] API error ${response.statusCode}: ${response.body}',
        );
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => s['placePrediction'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .map(PlacePrediction.fromJson)
          .where((p) => p.placeId.isNotEmpty)
          .toList();

      return suggestions;
    } catch (e) {
      debugPrint('[PlacesService] Error: $e');
      return [];
    }
  }
}
