import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/map/presentation/widgets/map_offline_card.dart';

// ---------------------------------------------------------------------------
// MapOfflineCard — the map's cold-offline state.
//
// Replaces the raw `Error loading map: <exception>` red text that airplane
// mode used to surface (tremble_map_screen.dart). Must show human copy and a
// working retry, so a transient host-lookup failure recovers on reconnect.
// ---------------------------------------------------------------------------

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('renders the localized title, subtitle, and retry label',
      (tester) async {
    await tester.pumpWidget(host(
      MapOfflineCard(
        title: 'Map unavailable',
        subtitle: 'Check your connection and try again.',
        retryLabel: 'Try again',
        onRetry: () {},
      ),
    ));

    expect(find.text('Map unavailable'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('invokes onRetry when the retry button is tapped',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(
      MapOfflineCard(
        title: 'Map unavailable',
        subtitle: 'Check your connection and try again.',
        retryLabel: 'Try again',
        onRetry: () => retries++,
      ),
    ));

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('does not overflow inside a small map-card slot', (tester) async {
    // The card lives inside a rounded, shadowed map container — not full
    // screen. Pump it into a tight box and assert no overflow was thrown.
    await tester.pumpWidget(host(
      SizedBox(
        width: 320,
        height: 220,
        child: MapOfflineCard(
          title: 'Map unavailable',
          subtitle: 'Check your connection and try again.',
          retryLabel: 'Try again',
          onRetry: () {},
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
