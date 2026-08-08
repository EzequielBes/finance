import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/japanese_csv_parser.dart';

class UfjParser extends JapaneseCsvParser {
  const UfjParser();

  @override
  String get bankName => 'MUFG (UFJ)';
  @override
  String get importSource => 'ufj_csv';
  @override
  bool recognizes(String content) => content.contains('支払金額,預かり金額,差引残高');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['取引日', '摘要', '支払金額', '預かり金額', '差引残高']);
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
