import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

class ItauParser extends BrazilianCsvParser {
  const ItauParser();
  @override
  String get bankName => 'Itaú';
  @override
  String get importSource => 'itau_csv';
  @override
  String get delimiter => ';';
  @override
  bool recognizes(String content) => content.contains('Crédito;Débito;Saldo');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['DATA', 'HISTÓRICO', 'CRÉDITO', 'DÉBITO']);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 5)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[1],
      date: row[0],
      signedAmount: creditDebit(row[3], row[4]),
    );
  }
}
