import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';

void main() {
  test('gym mode enable action uses translations', () {
    expect(t('enable', 'en'), 'Enable');
    expect(t('enable', 'sl'), 'Omogoči');

    final source = File(
      'lib/src/features/gym/presentation/gym_mode_sheet.dart',
    ).readAsStringSync();

    expect(source, contains("t('enable', lang)"));
    expect(source, isNot(contains("Text('Omogoči')")));
    expect(source, isNot(contains('Text("Omogoči")')));
  });
}
