import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

class NubankParser extends BrazilianCsvParser {
  const NubankParser();

  @override
  String get bankName => 'Nubank';
  @override
  String get importSource => 'nubank_csv';
  @override
  String get delimiter => ',';
  @override
  bool recognizes(String content) =>
      content.contains('Identificador,Descrição');
  @override
  bool isHeader(List<String> row) => headerContains(row, const [
    'DATA',
    'VALOR',
    'IDENTIFICADOR',
    'DESCRIÇÃO',
  ]);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 4)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[3],
      date: row[0],
      signedAmount: parseAmount(row[1]),
    );
  }
}
