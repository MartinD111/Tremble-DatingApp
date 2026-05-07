import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'safe_zone_model.dart';

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>((ref) {
  return SafeZoneRepository();
});

/// Manages local safe zones and syncs obfuscated geohashes to the server.
/// Adheres strictly to the Zero-Data philosophy:
/// - Exact lat/lng coordinates NEVER leave the device.
/// - Only a list of blocked Geohash strings is synced to Firestore.
class SafeZoneRepository {
  static const String _prefKey = 'local_safe_zones';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<SafeZone>> getSafeZones() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> zonesJson = prefs.getStringList(_prefKey) ?? [];
    return zonesJson.map((z) => SafeZone.fromJson(z)).toList();
  }

  Future<void> addSafeZone(SafeZone zone) async {
    final zones = await getSafeZones();
    zones.add(zone);
    await _saveLocalAndSync(zones);
  }

  Future<void> removeSafeZone(String id) async {
    final zones = await getSafeZones();
    zones.removeWhere((z) => z.id == id);
    await _saveLocalAndSync(zones);
  }

  Future<void> _saveLocalAndSync(List<SafeZone> zones) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = zones.map((z) => z.toJson()).toList();
    await prefs.setStringList(_prefKey, jsonList);

    // Sync obfuscated geohashes to server
    await _syncBlockedGeohashes(zones);
  }

  Future<void> _syncBlockedGeohashes(List<SafeZone> zones) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final Set<String> blockedGeohashes = {};
    for (final zone in zones) {
      // Precision 6 is ~1.2km x 600m. Center + 8 neighbors provides a large enough
      // blanket to cover small radiuses (e.g. 500m) with 0 exact-location leakage.
      final geoHash = GeoHash.fromDecimalDegrees(zone.longitude, zone.latitude,
          precision: 6);
      blockedGeohashes.add(geoHash.geohash);
      blockedGeohashes.addAll(geoHash.neighbors.values);
    }

    try {
      await _firestore.collection('users').doc(uid).set(
        {'blockedGeohashes': blockedGeohashes.toList()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Fail silently, zero-data fallback handles client side filtering anyway.
    }
  }
}
