import 'package:mobile/services/import/parsers/brazilian_csv_parser.dart';

abstract class JapaneseCsvParser extends BrazilianCsvParser {
  const JapaneseCsvParser();

  @override
  String get delimiter => ',';

  @override
  DateTime parseDate(String value) {
    final japanese = RegExp(
      r'^(\d{4})[./](\d{2})[./](\d{2})$',
    ).firstMatch(value.trim());
    if (japanese == null) return super.parseDate(value);
    return DateTime(
      int.parse(japanese.group(1)!),
      int.parse(japanese.group(2)!),
      int.parse(japanese.group(3)!),
    );
  }
}
