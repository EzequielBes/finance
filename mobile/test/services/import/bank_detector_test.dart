import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/bank_detector.dart';

void main() {
  final cases = <(String, String)>[
    ('nubank_sample.csv', 'Nubank'),
    ('itau_sample.csv', 'Itaú'),
    ('bb_sample.csv', 'Banco do Brasil'),
    ('bradesco_sample.csv', 'Bradesco'),
    ('santander_sample.csv', 'Santander'),
    ('ufj_sample.csv', 'MUFG (UFJ)'),
    ('smbc_sample.csv', 'SMBC'),
    ('mizuho_sample.csv', 'Mizuho'),
    ('jppost_sample.csv', 'Japan Post Bank'),
    ('rakuten_sample.csv', 'Rakuten Bank'),
  ];

  group('BankDetector', () {
    for (final (fixture, bankName) in cases) {
      test('detects $bankName from its statement', () {
        final content = File(
          'test/services/import/fixtures/$fixture',
        ).readAsStringSync();

        final parser = const BankDetector().detect(content);

        expect(parser, isNotNull);
        expect(parser!.bankName, bankName);
      });
    }

    test('returns null when no bank recognizes the content', () {
      final parser = const BankDetector().detect(
        'date,description,amount\n2024-01-01,Unknown,10',
      );

      expect(parser, isNull);
    });
  });
}
