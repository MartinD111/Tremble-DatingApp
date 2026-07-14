import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

void main() {
  group('Consent step — explicit gender/lookingFor consent', () {
    final consentStep = File(
      'lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart',
    ).readAsStringSync();

    test('renders sexual-orientation consent tile via v1 narrow-purpose key',
        () {
      // Post-LEGAL-003 the orientation tile uses the long-form
      // narrow-purpose text; the legacy short-form key is preserved for
      // callers not yet migrated, but the widget references the v1 key.
      expect(
        consentStep,
        contains("widget.tr('consent_art9_orientation_v1')"),
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

    test(
        'select-all does NOT flip Art. 9 tiles (orientation/religion/ethnicity)',
        () {
      // Per LEGAL-003 step 4: Art. 9(2)(a) requires "specific" consent
      // per category. _toggleAll must therefore leave the three Art. 9
      // flags untouched and only sweep general-processing consents.
      final toggleAllBody = RegExp(
        r'void _toggleAll\(\)\s*\{(.*?)\n\s*\}',
        dotAll: true,
      ).firstMatch(consentStep)?.group(1);
      expect(toggleAllBody, isNotNull,
          reason: '_toggleAll() must exist to gate the select-all pill.');
      expect(toggleAllBody, isNot(contains('_consentReligion')),
          reason:
              'Select-all must not toggle religion — Art. 9 specific consent.');
      expect(toggleAllBody, isNot(contains('_consentEthnicity')),
          reason:
              'Select-all must not toggle ethnicity — Art. 9 specific consent.');
      expect(toggleAllBody, isNot(contains('_consentSexualOrientation')),
          reason:
              'Select-all must not toggle orientation — Art. 9 specific consent.');
    });

    test('Art. 9 tiles all link to the Privacy Policy anchor', () {
      // Each Art. 9 tile pairs the narrow-purpose text with a "Learn more"
      // deep-link to the PP anchor for that category.
      expect(consentStep, contains("consent_art9_orientation_v1"));
      expect(consentStep, contains("consent_art9_religion_v1"));
      expect(consentStep, contains("consent_art9_ethnicity_v1"));
      expect(consentStep, contains("art9-orientation"));
      expect(consentStep, contains("art9-religion"));
      expect(consentStep, contains("art9-ethnicity"));
    });

    test('EN + SL + HR v1 tiles carry the load-bearing narrow-purpose phrases',
        () {
      // The compliance defence rests on four phrases: "GDPR Article 9",
      // "never sold", "never shared with advertisers", "bilaterally
      // fail-closed". Every locale we ship for the primary launch (EN,
      // SL, HR) must carry the equivalent phrasing.
      const enPhrases = [
        'GDPR Article 9',
        'never sold',
        'never shared with advertisers',
        'bilaterally',
      ];
      const slPhrases = [
        '9. členu GDPR',
        'nikoli ne prodaja',
        'nikoli ne deli',
        'dvostransko',
      ];
      const hrPhrases = [
        'članku 9. GDPR',
        // "nikada se ne prodaje" (sg subject) vs "nikada se ne prodaju"
        // (plural — used when subject is "podaci"). Same for "ne
        // dijeli" vs "ne dijele". Assert on the shared prefix so both
        // grammatical forms qualify without pinning locale-specific
        // grammar.
        'nikada se ne proda',
        'nikada ne dije',
        'dvostrano',
      ];

      for (final key in [
        'consent_art9_orientation_v1',
        'consent_art9_religion_v1',
        'consent_art9_ethnicity_v1',
      ]) {
        final en = t(key, 'en');
        final sl = t(key, 'sl');
        final hr = t(key, 'hr');
        for (final p in enPhrases) {
          expect(en, contains(p),
              reason: 'EN $key must contain "$p" — got:\n$en');
        }
        for (final p in slPhrases) {
          expect(sl, contains(p),
              reason: 'SL $key must contain "$p" — got:\n$sl');
        }
        for (final p in hrPhrases) {
          expect(hr, contains(p),
              reason: 'HR $key must contain "$p" — got:\n$hr');
        }
      }
    });

    test('legacy short-form consent_sexual_orientation key stays parseable',
        () {
      // Legacy key preserved for any caller not yet migrated (backfill
      // modal still references orientation via the v1 key). Removing the
      // legacy key silently would risk a runtime tr() fallback to the
      // raw key string.
      expect(t('consent_sexual_orientation', 'en'), isNotEmpty);
      expect(t('consent_sexual_orientation', 'sl'), isNotEmpty);
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

    test(
        'fromFirestore parses version + timestamp for all three Art. 9 categories',
        () {
      // Per LEGAL-003 step 5, the client must be able to READ the
      // server-authoritative version + timestamp for orientation,
      // religion, and ethnicity so the settings withdrawal UI and the
      // backfill modal can decide whether to re-prompt on future
      // version bumps.
      final user = AuthUser.fromFirestore(
        'u1',
        const {
          'sexualOrientationConsent': true,
          'sexualOrientationConsentAt': '2026-07-14T12:00:00.000Z',
          'sexualOrientationConsentVersion': 'v1',
          'religionConsent': true,
          'religionConsentAt': '2026-07-14T12:00:00.000Z',
          'religionConsentVersion': 'v1',
          'ethnicityConsent': false,
          'ethnicityConsentAt': '2026-07-14T12:00:00.000Z',
          'ethnicityConsentVersion': 'v1',
        },
      );
      expect(user.sexualOrientationConsentVersion, 'v1');
      expect(user.religionConsentVersion, 'v1');
      expect(user.ethnicityConsentVersion, 'v1');
      expect(user.religionConsentAt, isNotNull);
      expect(user.ethnicityConsentAt, isNotNull);
    });

    test('version + timestamp fields default to null on unmigrated docs', () {
      const user = AuthUser(id: 'u1');
      expect(user.sexualOrientationConsentVersion, isNull);
      expect(user.religionConsentVersion, isNull);
      expect(user.ethnicityConsentVersion, isNull);
      expect(user.religionConsentAt, isNull);
      expect(user.ethnicityConsentAt, isNull);
    });

    test('copyWith preserves version + timestamp fields', () {
      final t = DateTime.utc(2026, 7, 14, 12);
      final u = AuthUser(
        id: 'u1',
        sexualOrientationConsent: true,
        sexualOrientationConsentVersion: 'v1',
        sexualOrientationConsentAt: t,
        religionConsent: true,
        religionConsentVersion: 'v1',
        religionConsentAt: t,
        ethnicityConsent: false,
        ethnicityConsentVersion: 'v1',
        ethnicityConsentAt: t,
      );
      final copy = u.copyWith(name: 'x');
      expect(copy.sexualOrientationConsentVersion, 'v1');
      expect(copy.religionConsentVersion, 'v1');
      expect(copy.ethnicityConsentVersion, 'v1');
      expect(copy.religionConsentAt, t);
      expect(copy.ethnicityConsentAt, t);
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
