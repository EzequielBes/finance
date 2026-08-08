import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/import_result.dart';

void main() {
  group('ParsedTransaction', () {
    test('creates from required fields', () {
      final tx = ParsedTransaction(
        description: 'Supermercado',
        amount: 150.00,
        date: DateTime(2024, 1, 15),
        type: ParsedTransactionType.expense,
        importSource: 'nubank_csv',
      );
      expect(tx.description, 'Supermercado');
      expect(tx.amount, 150.00);
      expect(tx.type, ParsedTransactionType.expense);
      expect(tx.importSource, 'nubank_csv');
    });

    test('equality is value-based', () {
      final a = ParsedTransaction(
        description: 'iFood',
        amount: 45.90,
        date: DateTime(2024, 1, 14),
        type: ParsedTransactionType.expense,
        importSource: 'nubank_csv',
      );
      final b = ParsedTransaction(
        description: 'iFood',
        amount: 45.90,
        date: DateTime(2024, 1, 14),
        type: ParsedTransactionType.expense,
        importSource: 'nubank_csv',
      );
      expect(a, equals(b));
    });
  });
}
