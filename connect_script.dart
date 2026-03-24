import 'dart:io';

void main() {
  final file = File('lib/src/features/auth/presentation/registration_flow.dart');
  var content = file.readAsStringSync();

  final regexPol = RegExp(r'_continueButton\(enabled: true, onTap: \(\) => _nextPage\(\)\),(?:\s*)const SizedBox\(height: 16\),(?:\s*)\],(?:\s*)\),(?:\s*)\),(?:\s*)\}(?:\s*)// ══════════════════════════════════════════════════════(?:\s*)// PAGE 6 – EXERCISE');
  
  final polDst = '''_continueButton(
              enabled: true,
              onTap: () {
                _showPartnerRangeModal(
                  title: tr('political_affiliation'),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  labels: [tr('politics_left'), tr('politics_right')],
                  onSave: (val) {
                    if (val == null) {
                      setState(() => _partnerPoliticalAffiliationPreference = null);
                    } else {
                      setState(() => _partnerPoliticalAffiliationPreference = '\${val.start.toInt()}-\${val.end.toInt()}');
                    }
                  },
                );
              }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 6 – EXERCISE''';

  content = content.replaceFirst(regexPol, polDst);

  final regexInt = RegExp(r'_continueButton\(enabled: true, onTap: \(\) => _nextPage\(\)\),(?:\s*)const SizedBox\(height: 16\),(?:\s*)\],(?:\s*)\),(?:\s*)\),(?:\s*)\}(?:\s*)Widget _buildPageSleep\(\)');

  final intDst = '''_continueButton(
              enabled: true,
              onTap: () {
                _showPartnerRangeModal(
                  title: tr('introversion'),
                  min: 0,
                  max: 1,
                  divisions: 0,
                  labels: [tr('introvert'), tr('extrovert')],
                  onSave: (val) {
                    if (val == null) {
                      setState(() => _partnerIntrovertPreference = null);
                    } else {
                      setState(() => _partnerIntrovertPreference = '\${val.start}-\${val.end}');
                    }
                  },
                );
              }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildPageSleep()''';

  content = content.replaceFirst(regexInt, intDst);

  file.writeAsStringSync(content);
}
