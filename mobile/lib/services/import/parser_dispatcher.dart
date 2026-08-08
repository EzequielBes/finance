import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/services/import/parsers/bank_parser.dart';
import 'package:mobile/services/import/parsers/bb_parser.dart';
import 'package:mobile/services/import/parsers/bradesco_parser.dart';
import 'package:mobile/services/import/parsers/itau_parser.dart';
import 'package:mobile/services/import/parsers/nubank_parser.dart';
import 'package:mobile/services/import/parsers/santander_parser.dart';

const List<BankParser> _parsers = [
  NubankParser(),
  ItauParser(),
  BancoDoBrasilParser(),
  BradescoParser(),
  SantanderParser(),
];

/// Tenta cada parser conhecido em ordem; retorna o resultado do primeiro
/// que reconhecer o conteúdo, ou null se nenhum reconhecer.
ImportResult? dispatchImport(String content) {
  for (final parser in _parsers) {
    if (parser.canParse(content)) return parser.parse(content);
  }
  return null;
}
