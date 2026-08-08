import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/japanese_csv_parser.dart';

class MizuhoParser extends JapaneseCsvParser {
  const MizuhoParser();

  @override
  String get bankName => 'Mizuho';
  @override
  String get importSource => 'mizuho_csv';
  @override
  bool recognizes(String content) => content.contains('摘要,お支払金額,お預り金額');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['取引日', '摘要', 'お支払金額', 'お預り金額', '残高']);
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
