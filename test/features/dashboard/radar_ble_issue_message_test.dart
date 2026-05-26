import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/features/dashboard/presentation/home_screen.dart';

void main() {
  testWidgets('renders bluetooth off state with open settings action',
      (tester) async {
    var openedSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadarBleIssueMessage(
            issue: RadarBleIssue.bluetoothOff,
            onOpenSettings: () => openedSettings = true,
            onGrantPermission: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('Bluetooth is off. Tremble needs it to detect people nearby.'),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Open Settings'));
    expect(openedSettings, isTrue);
  });

  testWidgets('renders permission denied state with grant permission action',
      (tester) async {
    var requestedPermission = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadarBleIssueMessage(
            issue: RadarBleIssue.permissionDenied,
            onOpenSettings: () {},
            onGrantPermission: () => requestedPermission = true,
          ),
        ),
      ),
    );

    expect(find.text('Bluetooth permission required.'), findsOneWidget);
    expect(find.text('Grant Permission'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Grant Permission'));
    expect(requestedPermission, isTrue);
  });
}
