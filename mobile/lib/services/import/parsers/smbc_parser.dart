import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/japanese_csv_parser.dart';

class SmbcParser extends JapaneseCsvParser {
  const SmbcParser();

  @override
  String get bankName => 'SMBC';
  @override
  String get importSource => 'smbc_csv';
  @override
  bool recognizes(String content) => content.contains('お引き出し金額,お預け入れ金額');
  @override
  bool isHeader(List<String> row) =>
      headerContains(row, const ['日付', '摘要', 'お引き出し金額', 'お預け入れ金額', '残高']);
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
