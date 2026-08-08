import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/bank_parser.dart';

abstract class BrazilianCsvParser implements BankParser {
  const BrazilianCsvParser();

  String get delimiter;
  bool recognizes(String content);
  bool isHeader(List<String> row);
  ParsedTransaction? parseRow(List<String> row);

  @override
  bool canParse(String content) {
    try {
      return recognizes(content) && _rows(content).any(isHeader);
    } on Object {
      return false;
    }
  }

  @override
  ImportResult parse(String content) {
    final transactions = <ParsedTransaction>[];
    final errors = <String>[];

    try {
      final rows = _rows(content);
      final headerIndex = rows.indexWhere(isHeader);
      if (!recognizes(content) || headerIndex < 0) {
        errors.add('Arquivo não reconhecido como extrato do $bankName.');
      } else {
        for (var index = headerIndex + 1; index < rows.length; index++) {
          final row = rows[index];
          if (row.every((cell) => cell.trim().isEmpty)) {
            continue;
          }
          try {
            final transaction = parseRow(row);
            if (transaction != null) transactions.add(transaction);
          } on Object catch (error) {
            errors.add('Linha ${index + 1}: $error');
          }
        }
        if (transactions.isEmpty && errors.isEmpty) {
          errors.add('Nenhuma transação válida encontrada.');
        }
      }
    } on Object catch (error) {
      errors.add('Falha ao ler o arquivo: $error');
    }

    return ImportResult(
      transactions: transactions,
      bankName: bankName,
      importSource: importSource,
      errors: errors,
    );
  }

  List<List<String>> _rows(String content) =>
      const CsvToListConverter(
            shouldParseNumbers: false,
            allowInvalid: true,
            convertEmptyTo: '',
          )
          .convert(content, fieldDelimiter: delimiter, eol: '\n')
          .map((row) => row.map((cell) => cell.toString().trim()).toList())
          .toList();

  ParsedTransaction transaction({
    required String description,
    required String date,
    required double signedAmount,
  }) {
    if (description.trim().isEmpty) {
      throw const FormatException('descrição vazia');
    }
    if (signedAmount == 0) throw const FormatException('valor zerado');
    return ParsedTransaction(
      description: description.trim(),
      amount: signedAmount.abs(),
      date: parseDate(date),
      type: signedAmount < 0
          ? ParsedTransactionType.expense
          : ParsedTransactionType.income,
      importSource: importSource,
    );
  }

  DateTime parseDate(String value) {
    final text = value.trim();
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    final br = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (br == null) throw FormatException('data inválida: $value');
    return DateTime(
      int.parse(br.group(3)!),
      int.parse(br.group(2)!),
      int.parse(br.group(1)!),
    );
  }

  double parseAmount(String value) {
    var text = value.trim().replaceAll(RegExp(r'\s|R\$'), '');
    if (text.isEmpty) throw const FormatException('valor vazio');
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.parse(text);
  }

  double creditDebit(String credit, String debit) {
    if (credit.trim().isNotEmpty) return parseAmount(credit);
    if (debit.trim().isNotEmpty) return -parseAmount(debit).abs();
    throw const FormatException('crédito e débito vazios');
  }

  bool headerContains(List<String> row, Iterable<String> fields) {
    final normalized = row.map((cell) => cell.toUpperCase()).toSet();
    return fields.every(normalized.contains);
  }

  bool hasColumns(List<String> row, int count) =>
      row.length >= math.max(count, 1);
}
