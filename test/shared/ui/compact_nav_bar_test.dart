import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/shared/ui/liquid_nav_bar.dart';

List<LiquidNavItem> _items() => [
      LiquidNavItem(icon: Icons.radar, label: 'Radar'),
      LiquidNavItem(icon: Icons.map, label: 'Map'),
      LiquidNavItem(icon: Icons.people, label: 'People'),
      LiquidNavItem(icon: Icons.settings, label: 'Settings'),
    ];

CompactNavBar _bar(int index, {void Function(int)? onTap}) => CompactNavBar(
      currentIndex: index,
      items: _items(),
      onTap: onTap ?? (_) {},
    );

void main() {
  group('neighborIndex', () {
    test('shows the RIGHT neighbor normally', () {
      expect(_bar(0).neighborIndex(), 1);
      expect(_bar(1).neighborIndex(), 2);
      expect(_bar(2).neighborIndex(), 3);
    });

    test('shows the LEFT neighbor when on the LAST item (Settings)', () {
      expect(_bar(3).neighborIndex(), 2);
    });

    test('returns null for a degenerate single-item bar', () {
      final bar = CompactNavBar(
        currentIndex: 0,
        items: [LiquidNavItem(icon: Icons.radar, label: 'Radar')],
        onTap: (_) {},
      );
      expect(bar.neighborIndex(), isNull);
    });
  });

  group('rendering', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester
        .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

    testWidgets('renders exactly the selected item + one neighbor', (t) async {
      await pump(t, _bar(0));
      // Selected (Radar) renders its label; neighbor (Map) renders icon only.
      expect(find.text('Radar'), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      // The far destinations are NOT shown on a compact bar.
      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('tapping the neighbor navigates to it', (t) async {
      int? tapped;
      await pump(t, _bar(1, onTap: (i) => tapped = i));
      // From index 1, neighbor is index 2 (People).
      await t.tap(find.byIcon(Icons.people));
      expect(tapped, 2);
    });

    testWidgets('on last item, tapping neighbor goes left', (t) async {
      int? tapped;
      await pump(t, _bar(3, onTap: (i) => tapped = i));
      // From Settings (3), neighbor is People (2).
      await t.tap(find.byIcon(Icons.people));
      expect(tapped, 2);
    });
  });
}
