import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ContactService routes anonymity check through TrembleApiClient', () {
    final source = File('lib/src/core/contact_service.dart').readAsStringSync();

    expect(source, contains("import 'api_client.dart';"));
    expect(source, contains("'onContactAnonymityCheck'"));
    expect(source, contains('TrembleApiException'));
    expect(source,
        isNot(contains('package:cloud_functions/cloud_functions.dart')));
    expect(source, isNot(contains('FirebaseFunctions.instance')));
    expect(source, isNot(contains("httpsCallable('onContactAnonymityCheck')")));
  });
}
