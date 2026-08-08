import 'package:mobile/data/database.dart';

enum ParsedTransactionType { expense, income }

extension ParsedTransactionTypeX on ParsedTransactionType {
  TransactionType toTransactionType() => switch (this) {
        ParsedTransactionType.expense => TransactionType.expense,
        ParsedTransactionType.income => TransactionType.income,
      };
}

class ParsedTransaction {
  const ParsedTransaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.importSource,
    this.categoryId,
  });

  final String description;
  final double amount; // sempre positivo
  final DateTime date;
  final ParsedTransactionType type;
  final String importSource;
  final int? categoryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTransaction &&
          description == other.description &&
          amount == other.amount &&
          date == other.date &&
          type == other.type &&
          importSource == other.importSource;

  @override
  int get hashCode =>
      Object.hash(description, amount, date, type, importSource);
}

class ImportResult {
  const ImportResult({
    required this.transactions,
    required this.bankName,
    required this.importSource,
    this.errors = const [],
  });

  final List<ParsedTransaction> transactions;
  final String bankName;
  final String importSource;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
}
