import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

class BancoDoBrasilParser extends BrazilianCsvParser {
  const BancoDoBrasilParser();
  @override
  String get bankName => 'Banco do Brasil';
  @override
  String get importSource => 'bb_csv';
  @override
  String get delimiter => ';';
  @override
  bool recognizes(String content) => content.contains('Banco do Brasil S.A.');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['DATA', 'HISTÓRICO', 'VALOR']);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 6)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[2],
      date: row[0],
      signedAmount: parseAmount(row[5]),
    );
  }
}
