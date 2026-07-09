import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

void main() {
  group('Consent step — explicit gender/lookingFor consent', () {
    final consentStep = File(
      'lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart',
    ).readAsStringSync();

    test('renders sexual-orientation consent tile via translation key', () {
      expect(
        consentStep,
        contains("widget.tr('consent_sexual_orientation')"),
      );
    });

    test('sexual-orientation consent is part of the blocking gate', () {
      // _consentGiven must AND-in the new field so Continue is disabled
      // until the user checks the box.
      final gate = RegExp(
        r'bool get _consentGiven\s*=>[^;]*_consentSexualOrientation',
        dotAll: true,
      );
      expect(gate.hasMatch(consentStep), isTrue,
          reason:
              '_consentGiven must include _consentSexualOrientation so registration is blocked without it.');
    });

    test('onComplete forwards the new consent value to the parent', () {
      // The callback signature must include sexualOrientationConsent so the
      // parent registration flow can persist it.
      expect(consentStep, contains('sexualOrientationConsent'));
      expect(consentStep, contains('_consentSexualOrientation'));
    });

    test('EN + SL translations match the exact spec wording', () {
      expect(
        t('consent_sexual_orientation', 'en'),
        'I explicitly consent to the processing of my gender and matching '
        'preferences solely for the purpose of finding matches.',
      );
      expect(
        t('consent_sexual_orientation', 'sl'),
        'Izrecno soglašam z obdelavo mojega spola in preferenc za ujemanje '
        'izključno za namen iskanja ujemanj.',
      );
    });
  });

  group('Consent step — strict 18+ age confirmation', () {
    final consentStep = File(
      'lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart',
    ).readAsStringSync();

    test('age tile uses the strict 18+ translation key', () {
      expect(consentStep, contains("widget.tr('consent_age_18')"));
    });

    test('old "age of majority"-style copy is removed from the widget', () {
      expect(
        consentStep,
        isNot(contains('18 years of age or older')),
        reason:
            'Copy must be the explicit "I am at least 18 years old." string, not the prior legalese.',
      );
      expect(consentStep, isNot(contains('age of majority')));
      expect(consentStep, isNot(contains('legal age')));
    });

    test('EN + SL translations for consent_age_18 are exact', () {
      expect(t('consent_age_18', 'en'), 'I am at least 18 years old.');
      expect(t('consent_age_18', 'sl'), 'Star sem najmanj 18 let.');
    });
  });

  group('AuthUser — sexualOrientationConsent GDPR wiring', () {
    test('field is nullable-safe by default', () {
      const user = AuthUser(id: 'u1');
      expect(user.sexualOrientationConsent, isNull);
      expect(user.sexualOrientationConsentAt, isNull);
    });

    test('toApiPayload omits the field when null', () {
      const user = AuthUser(id: 'u1');
      final payload = user.toApiPayload();
      expect(payload.containsKey('sexualOrientationConsent'), isFalse);
    });

    test('toApiPayload includes the field when set true', () {
      const user = AuthUser(id: 'u1', sexualOrientationConsent: true);
      final payload = user.toApiPayload();
      expect(payload['sexualOrientationConsent'], isTrue);
    });

    test('copyWith preserves the consent value', () {
      const original = AuthUser(id: 'u1', sexualOrientationConsent: true);
      final copy = original.copyWith(name: 'x');
      expect(copy.sexualOrientationConsent, isTrue);
    });

    test('fromFirestore parses the consent field and timestamp', () {
      final user = AuthUser.fromFirestore(
        'u1',
        const {
          'sexualOrientationConsent': true,
          'sexualOrientationConsentAt': '2026-07-09T00:00:00.000Z',
        },
      );
      expect(user.sexualOrientationConsent, isTrue);
      expect(user.sexualOrientationConsentAt, isNotNull);
    });
  });

  group('GDPR pipeline — server-side wiring', () {
    test('completeOnboarding schema requires sexualOrientationConsent === true',
        () {
      final schema =
          File('functions/src/modules/auth/auth.schema.ts').readAsStringSync();
      expect(
        schema,
        contains('sexualOrientationConsent: z.boolean().refine'),
        reason:
            'Server must reject onboarding without explicit consent for gender/matching-preference processing.',
      );
    });

    test('completeOnboarding writes the consent field + timestamp', () {
      final fn = File('functions/src/modules/auth/auth.functions.ts')
          .readAsStringSync();
      expect(
        fn,
        contains('sexualOrientationConsent: data.sexualOrientationConsent'),
      );
      expect(
        fn,
        contains('sexualOrientationConsentAt: FieldValue.serverTimestamp()'),
      );
    });
  });
}
