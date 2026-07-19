import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/match/presentation/widgets/trembling_partner_card.dart';

MatchProfile _partner({
  String name = 'Nikolina',
  int age = 27,
  List<String> photoUrls = const [],
}) =>
    MatchProfile(
      id: 'p1',
      name: name,
      age: age,
      imageUrl: '',
      hobbies: const [],
      bio: '',
      photoUrls: photoUrls,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester
      .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
}

void main() {
  group('TremblingPartnerCard', () {
    testWidgets('renders partner name and age', (tester) async {
      await _pump(
        tester,
        TremblingPartnerCard(partner: _partner(), onTap: () {}),
      );

      expect(find.text('Nikolina, 27'), findsOneWidget);
    });

    testWidgets('renders name only when age is unknown (0)', (tester) async {
      await _pump(
        tester,
        TremblingPartnerCard(partner: _partner(age: 0), onTap: () {}),
      );

      expect(find.text('Nikolina'), findsOneWidget);
    });

    testWidgets('invokes onTap when the card is tapped', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        TremblingPartnerCard(partner: _partner(), onTap: () => tapped++),
      );

      await tester.tap(find.byType(TremblingPartnerCard));
      expect(tapped, 1);
    });

    testWidgets('shows a fallback avatar when there are no photos',
        (tester) async {
      await _pump(
        tester,
        TremblingPartnerCard(partner: _partner(), onTap: () {}),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
