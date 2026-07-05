import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges native iOS BLE state restoration events to the existing
/// proximity write path.
///
/// When iOS restores a CBCentralManager scan after force-quit, the native
/// [BleRestoreBridge] emits {rssi, uuid} events via EventChannel. This
/// service listens and writes them to Firestore `proximity_events` so the
/// server-side `scanProximityPairs` picks them up.
///
/// Auth retry: Firebase Auth may not be rehydrated immediately after a cold
/// restore. Retries up to [_maxAuthRetries] times with [_authRetryDelay].
class BleRestoreService {
  static final BleRestoreService _instance = BleRestoreService._internal();
  factory BleRestoreService() => _instance;
  BleRestoreService._internal();

  static const _eventChannelName = 'app.tremble/ble/restore/events';

  static const int _maxAuthRetries = 3;
  static const Duration _authRetryDelay = Duration(seconds: 2);

  StreamSubscription<dynamic>? _eventSub;
  bool _initialized = false;

  /// Call once from [HomeScreen.initState]. Safe to call multiple times.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    const channel = EventChannel(_eventChannelName);
    _eventSub = channel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object error) {
        if (kDebugMode) debugPrint('[BleRestore] EventChannel error: $error');
      },
    );
    if (kDebugMode)
      debugPrint('[BleRestore] Initialized — listening for restore events');
  }

  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    _initialized = false;
  }

  Future<void> _onNativeEvent(dynamic event) async {
    if (event is! Map) return;

    final rssi = event['rssi'] as int?;
    final uuid = event['uuid'] as String?;
    if (rssi == null || uuid == null) return;

    if (kDebugMode)
      debugPrint('[BleRestore] Received restore event: uuid=$uuid rssi=$rssi');

    // Attempt to get the authenticated user, retrying if Auth hasn't rehydrated
    String? uid;
    for (int attempt = 0; attempt < _maxAuthRetries; attempt++) {
      uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) break;
      if (kDebugMode)
        debugPrint(
            '[BleRestore] Auth not ready, retry ${attempt + 1}/$_maxAuthRetries');
      await Future<void>.delayed(_authRetryDelay);
    }

    if (uid == null) {
      if (kDebugMode)
        debugPrint('[BleRestore] Auth not available after retries — skipping');
      return;
    }

    try {
      final proximityDoc = await FirebaseFirestore.instance
          .collection('proximity')
          .doc(uid)
          .get();
      final geohash = proximityDoc.data()?['geohash'] as String?;
      if (geohash == null || geohash.isEmpty) {
        if (kDebugMode)
          debugPrint('[BleRestore] No geohash for $uid — skipping');
        return;
      }

      await FirebaseFirestore.instance.collection('proximity_events').add({
        'fromUid': uid,
        'geohash': geohash,
        'rssi': rssi,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
      if (kDebugMode)
        debugPrint('[BleRestore] Proximity event written for $uid');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BleRestore] Proximity write failed: $e');
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }
}
