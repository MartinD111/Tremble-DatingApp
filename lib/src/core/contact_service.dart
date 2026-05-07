import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service responsible for handling local contact fetching,
/// normalizing, hashing, and syncing with the backend for Anonymity Mode.
class ContactService {
  /// Entry point to process contacts and block matching users.
  /// Returns the number of new users blocked.
  static Future<int> secureAndSyncContacts(String countryCode) async {
    // 1. Request permission
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      throw Exception('Contact permission denied');
    }

    // 2. Fetch contacts
    final contacts =
        await FlutterContacts.getAll(properties: {ContactProperty.phone});
    if (contacts.isEmpty) return 0;

    // 3. Extract raw phone numbers
    final List<String> rawPhones = [];
    for (var contact in contacts) {
      for (var phone in contact.phones) {
        rawPhones.add(phone.number);
      }
    }

    if (rawPhones.isEmpty) return 0;

    // 4. Normalize and Hash in background isolate
    final List<String> hashedPhones = await compute(
      _processContactsWorker,
      _WorkerParams(rawPhones, countryCode),
    );

    // 5. Send to backend for Zero-Data comparison
    final callable =
        FirebaseFunctions.instance.httpsCallable('onContactAnonymityCheck');
    final response = await callable.call({
      'hashedContacts': hashedPhones,
    });

    final int blockedCount = response.data['matchesFound'] as int? ?? 0;
    return blockedCount;
  }
}

/// Parameters for the background worker
class _WorkerParams {
  final List<String> phones;
  final String defaultCountryCode;

  _WorkerParams(this.phones, this.defaultCountryCode);
}

/// Background worker function to prevent UI jank
List<String> _processContactsWorker(_WorkerParams params) {
  final Set<String> hashes = {};

  for (String phone in params.phones) {
    // Basic normalization: remove all non-digits except '+'
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Replace leading '00' with '+'
    if (normalized.startsWith('00')) {
      normalized = '+' + normalized.substring(2);
    }

    // If it doesn't start with '+', assume it's a local number and prepend default country code
    // Assuming defaultCountryCode is like '+386'
    if (!normalized.startsWith('+')) {
      // If it starts with '0', remove the '0' (common in many European countries for local calls)
      if (normalized.startsWith('0')) {
        normalized = params.defaultCountryCode + normalized.substring(1);
      } else {
        normalized = params.defaultCountryCode + normalized;
      }
    }

    // Hash the normalized string using SHA-256
    if (normalized.length >= 8) {
      // Basic sanity check for valid length
      final bytes = utf8.encode(normalized);
      final digest = sha256.convert(bytes);
      hashes.add(digest.toString());
    }
  }

  return hashes.toList();
}
