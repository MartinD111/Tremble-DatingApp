import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/shared/ui/form_factor.dart';

void main() {
  group('classifyFormFactor', () {
    test('standard phones are NOT adapted (regression guard)', () {
      // iPhone SE — the smallest mainstream phone. Must stay standard so the
      // existing layout is untouched on normal devices.
      expect(classifyFormFactor(const Size(320, 568)), FormFactor.standard);
      // iPhone 14 / Pixel-class.
      expect(classifyFormFactor(const Size(390, 844)), FormFactor.standard);
      // Large phone.
      expect(classifyFormFactor(const Size(430, 932)), FormFactor.standard);
    });

    test('flip cover screen (small near-square) is compact', () {
      // Galaxy Z Flip Flex Window, roughly 360x387 dp.
      expect(classifyFormFactor(const Size(360, 387)), FormFactor.compact);
      // Even smaller cover surface.
      expect(classifyFormFactor(const Size(300, 300)), FormFactor.compact);
    });

    test('Fold inner screen / tablet is expanded', () {
      // Z Fold inner ≈ 670 dp shortest side.
      expect(classifyFormFactor(const Size(670, 830)), FormFactor.expanded);
      // Landscape tablet — shortest side still >= 600.
      expect(classifyFormFactor(const Size(1024, 768)), FormFactor.expanded);
    });

    test('expanded takes priority for a large but short landscape surface', () {
      expect(classifyFormFactor(const Size(900, 600)), FormFactor.expanded);
    });

    test('a short but wide surface is NOT misread as compact', () {
      // Wide enough to exceed the compact width cap → stays standard.
      expect(classifyFormFactor(const Size(560, 460)), FormFactor.standard);
    });
  });

  group('formFactorOf', () {
    Future<FormFactor> resolve(WidgetTester tester, Size size) async {
      late FormFactor result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              result = formFactorOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('reads size from MediaQuery', (tester) async {
      expect(await resolve(tester, const Size(360, 387)), FormFactor.compact);
      expect(await resolve(tester, const Size(390, 844)), FormFactor.standard);
      expect(await resolve(tester, const Size(670, 830)), FormFactor.expanded);
    });
  });
}
