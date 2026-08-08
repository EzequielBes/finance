import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/japanese_csv_parser.dart';

class RakutenParser extends JapaneseCsvParser {
  const RakutenParser();

  @override
  String get bankName => 'Rakuten Bank';
  @override
  String get importSource => 'rakuten_csv';
  @override
  bool recognizes(String content) => content.contains('入出金(円),残高(円),入出金先・内容');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['取引日', '入出金(円)', '残高(円)', '入出金先・内容']);
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
