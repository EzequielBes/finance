import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/bank_parser.dart';
import 'package:mobile/services/import/parsers/bb_parser.dart';
import 'package:mobile/services/import/parsers/bradesco_parser.dart';
import 'package:mobile/services/import/parsers/itau_parser.dart';
import 'package:mobile/services/import/parsers/nubank_parser.dart';
import 'package:mobile/services/import/parsers/santander_parser.dart';

void main() {
  final cases =
      <
        ({
          String fixture,
          String bankName,
          String source,
          BankParserFactory factory,
        })
      >[
        (
          fixture: 'nubank_sample.csv',
          bankName: 'Nubank',
          source: 'nubank_csv',
          factory: NubankParser.new,
        ),
        (
          fixture: 'itau_sample.csv',
          bankName: 'Itaú',
          source: 'itau_csv',
          factory: ItauParser.new,
        ),
        (
          fixture: 'bradesco_sample.csv',
          bankName: 'Bradesco',
          source: 'bradesco_csv',
          factory: BradescoParser.new,
        ),
        (
          fixture: 'santander_sample.csv',
          bankName: 'Santander',
          source: 'santander_csv',
          factory: SantanderParser.new,
        ),
        (
          fixture: 'bb_sample.csv',
          bankName: 'Banco do Brasil',
          source: 'bb_csv',
          factory: BancoDoBrasilParser.new,
        ),
      ];

  for (final parserCase in cases) {
    group(parserCase.bankName, () {
      final parser = parserCase.factory();
      final content = File(
        'test/services/import/fixtures/${parserCase.fixture}',
      ).readAsStringSync();

      test('recognizes and parses its CSV fixture', () {
        expect(parser.canParse(content), isTrue);
        expect(parser.bankName, parserCase.bankName);
        expect(parser.importSource, parserCase.source);

        final result = parser.parse(content);

        expect(result.hasErrors, isFalse);
        expect(
          result.transactions,
          hasLength(parserCase.source == 'nubank_csv' ? 5 : 4),
        );
        expect(
          result.transactions.first.description.toUpperCase(),
          contains('SUPERMERCADO'),
        );
        expect(result.transactions.first.amount, 150);
        expect(result.transactions.first.date, DateTime(2024, 1, 15));
        expect(result.transactions.first.type, ParsedTransactionType.expense);
        expect(result.transactions.first.importSource, parserCase.source);
        expect(
          result.transactions.any(
            (transaction) =>
                transaction.type == ParsedTransactionType.income &&
                transaction.amount == 5000,
          ),
          isTrue,
        );
      });

      test('does not recognize unrelated content', () {
        expect(parser.canParse('foo,bar\n1,2'), isFalse);
      });

      test('reports malformed rows instead of throwing', () {
        final result = parser.parse('invalid content');
        expect(result.transactions, isEmpty);
        expect(result.errors, isNotEmpty);
      });
    });
  }

  group('CRLF and BOM normalization', () {
    test('BancoDoBrasilParser handles CRLF line endings', () {
      final content = File(
        'test/services/import/fixtures/bb_sample.csv',
      ).readAsStringSync().replaceAll('\n', '\r\n');
      final parser = BancoDoBrasilParser();

      expect(parser.canParse(content), isTrue);
      final result = parser.parse(content);
      expect(result.hasErrors, isFalse);
      expect(result.transactions, hasLength(4));
    });

    test('SantanderParser handles a leading UTF-8 BOM', () {
      final content =
          '﻿${File('test/services/import/fixtures/santander_sample.csv').readAsStringSync()}';
      final parser = SantanderParser();

      expect(parser.canParse(content), isTrue);
    });
  });
}

typedef BankParserFactory = BankParser Function();
