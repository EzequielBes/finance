import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

class SantanderParser extends BrazilianCsvParser {
  const SantanderParser();
  @override
  String get bankName => 'Santander';
  @override
  String get importSource => 'santander_csv';
  @override
  String get delimiter => ';';
  @override
  bool recognizes(String content) =>
      content.startsWith('Data;Descrição;Valor;Saldo');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['DATA', 'DESCRIÇÃO', 'VALOR', 'SALDO']);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 4)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[1],
      date: row[0],
      signedAmount: parseAmount(row[2]),
    );
  }
}
