import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/bank_import_service.dart';
import 'package:mobile/services/import/import_result.dart';

void main() {
  group('BankImportService', () {
    test('detects and parses a statement asynchronously', () async {
      final content = File(
        'test/services/import/fixtures/nubank_sample.csv',
      ).readAsStringSync();

      final result = await const BankImportService().parse(content);

      expect(result, isNotNull);
      expect(result!.bankName, 'Nubank');
      expect(result.transactions, hasLength(5));
      expect(result.transactions.first.amount, 150);
      expect(result.transactions.first.type, ParsedTransactionType.expense);
    });

    test('parses a Japanese statement through the same service', () async {
      final content = File(
        'test/services/import/fixtures/smbc_sample.csv',
      ).readAsStringSync();

      final result = await const BankImportService().parse(content);

      expect(result, isNotNull);
      expect(result!.bankName, 'SMBC');
      expect(result.transactions, hasLength(4));
    });

    test('returns null asynchronously for an unknown format', () async {
      final future = const BankImportService().parse('not,a,bank');

      expect(future, isA<Future<ImportResult?>>());
      expect(await future, isNull);
    });
  });
}
