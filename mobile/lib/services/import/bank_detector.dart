import 'package:mobile/services/import/parsers/bank_parser.dart';
import 'package:mobile/services/import/parsers/bb_parser.dart';
import 'package:mobile/services/import/parsers/bradesco_parser.dart';
import 'package:mobile/services/import/parsers/itau_parser.dart';
import 'package:mobile/services/import/parsers/jp_post_parser.dart';
import 'package:mobile/services/import/parsers/mizuho_parser.dart';
import 'package:mobile/services/import/parsers/nubank_parser.dart';
import 'package:mobile/services/import/parsers/rakuten_parser.dart';
import 'package:mobile/services/import/parsers/santander_parser.dart';
import 'package:mobile/services/import/parsers/smbc_parser.dart';
import 'package:mobile/services/import/parsers/ufj_parser.dart';

const List<BankParser> defaultBankParsers = [
  NubankParser(),
  ItauParser(),
  BancoDoBrasilParser(),
  BradescoParser(),
  SantanderParser(),
  UfjParser(),
  SmbcParser(),
  MizuhoParser(),
  JpPostParser(),
  RakutenParser(),
];

class BankDetector {
  const BankDetector({this.parsers = defaultBankParsers});

  final List<BankParser> parsers;

  BankParser? detect(String content) {
    for (final parser in parsers) {
      if (parser.canParse(content)) return parser;
    }
    return null;
  }
}
