import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

class BradescoParser extends BrazilianCsvParser {
  const BradescoParser();
  @override
  String get bankName => 'Bradesco';
  @override
  String get importSource => 'bradesco_csv';
  @override
  String get delimiter => ';';
  @override
  bool recognizes(String content) =>
      content.contains('Extrato de Conta Corrente') &&
      content.contains('Agência:');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['DATA', 'DESCRIÇÃO', 'DOCUMENTO', 'VALOR']);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 4)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[1],
      date: row[0],
      signedAmount: parseAmount(row[3]),
    );
  }
}
