import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/gym/data/gym_repository.dart';

/// Plan 20260713-event-locations-firestore (PLAN_03_APP_CODE.md KORAK 3.5).
///
/// Verifies [TrembleEvent.fromMap] accepts BOTH:
///   1. `GeoPoint` — the canonical shape written by seed_events.ts.
///   2. `{lat, lng}` maps — legacy dev seeds from before the migration.
///
/// Missing/malformed `location` fields must not crash the render path — the
/// map screen filters events where `lat == null || lng == null` before
/// building markers, so returning null-lat/lng is the contract.
void main() {
  group('TrembleEvent.fromMap', () {
    test('parses a GeoPoint location (KORAK 3.5 canonical shape)', () {
      final event = TrembleEvent.fromMap('club_monokel', {
        'name': 'Klub Monokel',
        'active': true,
        'location': const GeoPoint(46.0514, 14.5058),
        'radiusMeters': 150,
        'locationLabel': 'Metelkova, Ljubljana',
      });

      expect(event.id, 'club_monokel');
      expect(event.name, 'Klub Monokel');
      expect(event.lat, closeTo(46.0514, 1e-6));
      expect(event.lng, closeTo(14.5058, 1e-6));
      expect(event.radiusMeters, 150);
      expect(event.locationLabel, 'Metelkova, Ljubljana');
    });

    test('parses a legacy {lat, lng} map location', () {
      final event = TrembleEvent.fromMap('labaratorij', {
        'name': 'Laboratorij',
        'location': {'lat': 46.054, 'lng': 14.512},
      });

      expect(event.lat, closeTo(46.054, 1e-6));
      expect(event.lng, closeTo(14.512, 1e-6));
      // defaults
      expect(event.radiusMeters, 500);
    });

    test('returns null lat/lng when location is missing', () {
      final event = TrembleEvent.fromMap('no_location', {
        'name': 'Some venue',
      });

      expect(event.lat, isNull);
      expect(event.lng, isNull);
      // Downstream markers filter these out — no crash on this path.
    });

    test('returns null lat/lng when location is a malformed map', () {
      final event = TrembleEvent.fromMap('bad_location', {
        'name': 'Broken venue',
        'location': {'x': 1, 'y': 2},
      });

      expect(event.lat, isNull);
      expect(event.lng, isNull);
    });

    test('falls back to "Event" when name is missing', () {
      final event = TrembleEvent.fromMap('anonymous', {
        'location': const GeoPoint(46.0, 14.5),
      });

      expect(event.name, 'Event');
    });
  });
}
