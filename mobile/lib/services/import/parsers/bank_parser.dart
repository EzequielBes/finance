import 'package:mobile/services/import/import_result.dart';

/// Interface para todos os parsers de extrato bancário.
abstract class BankParser {
  /// Nome legível do banco (e.g. 'Nubank', 'Itaú').
  String get bankName;

  /// Identificador do source (e.g. 'nubank_csv', 'itau_csv').
  String get importSource;

  /// Retorna true se este parser reconhece o conteúdo do arquivo.
  bool canParse(String content);

  /// Faz o parse do conteúdo e retorna [ImportResult].
  /// Nunca lança exceção — erros vão em [ImportResult.errors].
  ImportResult parse(String content);
}
