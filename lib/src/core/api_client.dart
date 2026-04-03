import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Centralized API client for calling Cloud Functions.
/// All backend communication goes through this service.
///
/// Provides:
/// - Automatic error mapping to typed exceptions
/// - Retry logic with exponential backoff
/// - Debug logging
class TrembleApiClient {
  static final TrembleApiClient _instance = TrembleApiClient._internal();
  factory TrembleApiClient() => _instance;
  TrembleApiClient._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Call a Cloud Function by name with optional data.
  ///
  /// [name] - The function name as exported in index.ts
  /// [data] - Optional request payload (Map<String, dynamic>)
  /// [timeout] - Request timeout (default 30s)
  /// [retries] - Number of retry attempts for transient errors (default 2)
  ///
  /// Returns the parsed response data.
  /// Throws [TrembleApiException] on failure.
  Future<Map<String, dynamic>> call(
    String name, {
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 30),
    int retries = 2,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        attempt++;

        if (kDebugMode) {
          debugPrint('[API] Calling $name (attempt $attempt)');
        }

        final callable = _functions.httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: timeout),
        );

        final result = await callable.call<Map<String, dynamic>>(data);
        return result.data;
      } on FirebaseFunctionsException catch (e) {
        if (kDebugMode) {
          debugPrint('[API] Error in $name: ${e.code} - ${e.message}');
        }

        // Don't retry non-transient errors
        if (!_isTransientError(e.code) || attempt > retries) {
          throw TrembleApiException.fromFirebase(e);
        }

        // Exponential backoff before retry
        final delayMs = 500 * (1 << (attempt - 1)); // 500, 1000, 2000...
        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e) {
        if (attempt > retries) {
          throw TrembleApiException(
            code: 'unknown',
            message: 'Unexpected error: $e',
          );
        }

        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Check if an error code represents a transient/retryable error.
  bool _isTransientError(String code) {
    return const {
      'unavailable',
      'deadline-exceeded',
      'resource-exhausted',
      'aborted',
      'internal',
    }.contains(code);
  }
}

/// Typed exception for API errors.
/// Maps Firebase Functions error codes to user-friendly messages.
class TrembleApiException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  TrembleApiException({
    required this.code,
    required this.message,
    this.details,
  });

  factory TrembleApiException.fromFirebase(FirebaseFunctionsException e) {
    return TrembleApiException(
      code: e.code,
      message: _userFriendlyMessage(e.code, e.message),
      details: e.details,
    );
  }

  static String _userFriendlyMessage(String code, String? serverMessage) {
    switch (code) {
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'permission-denied':
        return 'You don\'t have permission for this action.';
      case 'not-found':
        return serverMessage ?? 'The requested resource was not found.';
      case 'already-exists':
        return serverMessage ?? 'This already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment.';
      case 'invalid-argument':
        return serverMessage ?? 'Invalid input. Please check your data.';
      case 'failed-precondition':
        return serverMessage ?? 'This action cannot be performed right now.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return serverMessage ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'TrembleApiException($code): $message';
}
