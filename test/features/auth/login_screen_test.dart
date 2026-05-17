import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/presentation/login_screen.dart';

void main() {
  test('login language row exposes the compact plan order', () {
    expect(
      loginLanguageOptions.map((language) => language.code),
      ['sl', 'en', 'hr', 'de', 'it', 'fr', 'hu', 'sr'],
    );
  });
}
