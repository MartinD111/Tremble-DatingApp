import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/shared/ui/tremble_outage_screen.dart';

void main() {
  testWidgets('renders active and inactive status indicators', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TrembleOutageScreen(
          bluetoothStatus: const TrembleServiceStatus(
            label: 'Bluetooth',
            isActive: true,
          ),
          locationStatus: const TrembleServiceStatus(
            label: 'Location',
            isActive: false,
          ),
          networkStatus: const TrembleServiceStatus(
            label: 'Network',
            isActive: true,
          ),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('triggers retry when countdown expires', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TrembleOutageScreen(
          bluetoothStatus: const TrembleServiceStatus(
            label: 'Bluetooth',
            isActive: true,
          ),
          locationStatus: const TrembleServiceStatus(
            label: 'Location',
            isActive: true,
          ),
          networkStatus: const TrembleServiceStatus(
            label: 'Network',
            isActive: false,
          ),
          retryInterval: const Duration(seconds: 2),
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.text('Retrying in 2s...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(retryCount, 1);
  });
}
