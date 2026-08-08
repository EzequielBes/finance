// mobile/test/services/import/parser_dispatcher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/import/parser_dispatcher.dart';

void main() {
  test('dispatches Nubank CSV to the correct parser', () {
    const content = 'Data,Valor,Identificador,Descrição\n'
        '2024-01-15,-150.00,tx001,Supermercado Extra\n';
    final result = dispatchImport(content);
    expect(result, isNotNull);
    expect(result!.bankName, 'Nubank');
    expect(result.transactions.length, 1);
  });

  test('dispatches Santander CSV to the correct parser', () {
    const content = 'Data;Descrição;Valor;Saldo\n'
        '15/01/2024;COMPRA SUPERMERCADO EXTRA;-150,00;4850,00\n';
    final result = dispatchImport(content);
    expect(result, isNotNull);
    expect(result!.bankName, 'Santander');
  });

  test('returns null when no parser recognizes the content', () {
    const content = 'coluna_aleatoria,outra_coluna\nvalor1,valor2\n';
    final result = dispatchImport(content);
    expect(result, isNull);
  });
}
