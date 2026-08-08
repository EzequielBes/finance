import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/japanese_csv_parser.dart';

class JpPostParser extends JapaneseCsvParser {
  const JpPostParser();

  @override
  String get bankName => 'Japan Post Bank';
  @override
  String get importSource => 'jp_post_csv';
  @override
  bool recognizes(String content) => content.contains('お取引内容,お支払金額,お受取金額');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['取引日', 'お取引内容', 'お支払金額', 'お受取金額', '残高']);
  @override
  ParsedTransaction? parseRow(List<String> row) {
    if (!hasColumns(row, 5)) {
      throw const FormatException('colunas insuficientes');
    }
    return transaction(
      description: row[1],
      date: row[0],
      signedAmount: creditDebit(row[3], row[2]),
    );
  }
}
