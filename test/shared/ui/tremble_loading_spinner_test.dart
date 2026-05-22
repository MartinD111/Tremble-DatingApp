import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/shared/ui/tremble_loading_spinner.dart';

void main() {
  testWidgets('simple style does not display message text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrembleLoadingSpinner(
            style: LoadingStyle.simple,
            messages: ['Scanning for nearby matches...'],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Scanning for nearby matches...'), findsNothing);
  });

  testWidgets('dynamic style transitions through messages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrembleLoadingSpinner(
            style: LoadingStyle.dynamic,
            messages: ['Scanning', 'Connecting'],
            duration: Duration(milliseconds: 500),
          ),
        ),
      ),
    );

    expect(find.text('Scanning'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Connecting'), findsOneWidget);
  });
}
