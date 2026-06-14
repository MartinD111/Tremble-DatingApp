import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:tremble/src/core/places_service.dart';
import 'package:tremble/src/features/gym/presentation/gym_search_widget.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    return null;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.denied;
  }
}

class ThrowingPlacesService extends PlacesService {
  var gymAutocompleteCalls = 0;

  @override
  void startSession() {
    // no-op
  }

  @override
  Future<List<PlacePrediction>> gymAutocomplete(
    String input, {
    double? latitude,
    double? longitude,
  }) {
    gymAutocompleteCalls += 1;
    throw Exception('places unavailable');
  }
}

Future<void> _pumpGymSearch(
  WidgetTester tester, {
  required PlacesService placesService,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        placesServiceProvider.overrideWithValue(placesService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: GymSearchWidget(
            selectedGyms: const [],
            onAdd: (_) async => true,
            onRemove: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows unavailable snackbar when gym autocomplete throws',
      (tester) async {
    final originalGeolocator = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = FakeGeolocatorPlatform();
    addTearDown(() => GeolocatorPlatform.instance = originalGeolocator);

    final placesService = ThrowingPlacesService();
    await _pumpGymSearch(
      tester,
      placesService: placesService,
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Fitinn');
    await tester.pump();
    final textField = tester.widget<TextField>(find.byType(TextField));
    textField.onSubmitted?.call('Fitinn');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(placesService.gymAutocompleteCalls, 1);
    expect(find.text('Gym search unavailable. Check connection.'), findsOne);
    expect(
        find.text('No gyms found nearby. Try another gym name.'), findsNothing);
  });
}
