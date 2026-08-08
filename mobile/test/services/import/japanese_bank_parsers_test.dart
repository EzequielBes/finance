import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/bank_parser.dart';
import 'package:mobile/services/import/parsers/jp_post_parser.dart';
import 'package:mobile/services/import/parsers/mizuho_parser.dart';
import 'package:mobile/services/import/parsers/rakuten_parser.dart';
import 'package:mobile/services/import/parsers/smbc_parser.dart';
import 'package:mobile/services/import/parsers/ufj_parser.dart';

void main() {
  final cases =
      <
        ({
          String fixture,
          String bankName,
          String source,
          double firstExpense,
          double income,
          BankParser Function() factory,
        })
      >[
        (
          fixture: 'ufj_sample.csv',
          bankName: 'MUFG (UFJ)',
          source: 'ufj_csv',
          firstExpense: 15000,
          income: 250000,
          factory: UfjParser.new,
        ),
        (
          fixture: 'smbc_sample.csv',
          bankName: 'SMBC',
          source: 'smbc_csv',
          firstExpense: 15000,
          income: 250000,
          factory: SmbcParser.new,
        ),
        (
          fixture: 'mizuho_sample.csv',
          bankName: 'Mizuho',
          source: 'mizuho_csv',
          firstExpense: 15000,
          income: 250000,
          factory: MizuhoParser.new,
        ),
        (
          fixture: 'jppost_sample.csv',
          bankName: 'Japan Post Bank',
          source: 'jp_post_csv',
          firstExpense: 1500,
          income: 50000,
          factory: JpPostParser.new,
        ),
        (
          fixture: 'rakuten_sample.csv',
          bankName: 'Rakuten Bank',
          source: 'rakuten_csv',
          firstExpense: 15000,
          income: 250000,
          factory: RakutenParser.new,
        ),
      ];

  for (final parserCase in cases) {
    group(parserCase.bankName, () {
      final parser = parserCase.factory();
      final content = File(
        'test/services/import/fixtures/${parserCase.fixture}',
      ).readAsStringSync();

      test('recognizes and parses its statement', () {
        expect(parser.canParse(content), isTrue);

        final result = parser.parse(content);

        expect(result.bankName, parserCase.bankName);
        expect(result.importSource, parserCase.source);
        expect(result.errors, isEmpty);
        expect(result.transactions, hasLength(4));
        expect(result.transactions.first.amount, parserCase.firstExpense);
        expect(result.transactions.first.date, DateTime(2024, 1, 15));
        expect(result.transactions.first.type, ParsedTransactionType.expense);
        expect(result.transactions.first.importSource, parserCase.source);
        expect(
          result.transactions.any(
            (transaction) =>
                transaction.type == ParsedTransactionType.income &&
                transaction.amount == parserCase.income,
          ),
          isTrue,
        );
      });

      test('rejects an unrelated CSV', () {
        expect(
          parser.canParse('date,description,amount\n2024-01-01,x,1'),
          isFalse,
        );
      });

      test('reports invalid content without throwing', () {
        final result = parser.parse('invalid content');
        expect(result.transactions, isEmpty);
        expect(result.errors, isNotEmpty);
      });
    });
  }
}
