import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_input_formatter.dart';

void main() {
  test('formatCents accumulates digits as cents, BRL separators', () {
    expect(formatCents(1, AppCurrency.brl, DecimalSeparator.comma), '0,01');
    expect(formatCents(12, AppCurrency.brl, DecimalSeparator.comma), '0,12');
    expect(
      formatCents(1234, AppCurrency.brl, DecimalSeparator.comma),
      '12,34',
    );
    expect(
      formatCents(123456789, AppCurrency.brl, DecimalSeparator.comma),
      '1.234.567,89',
    );
  });

  test('formatCents JPY has no decimals', () {
    expect(formatCents(100, AppCurrency.jpy, DecimalSeparator.dot), '100');
  });

  test('formatCents USD uses comma grouping, dot decimal', () {
    expect(
      formatCents(1234500, AppCurrency.usd, DecimalSeparator.dot),
      '12,345.00',
    );
  });

  test('parseMoneyInput round-trips formatCents output', () {
    expect(
      parseMoneyInput('1.234.567,89', AppCurrency.brl, DecimalSeparator.comma),
      1234567.89,
    );
    expect(
      parseMoneyInput('12,345.00', AppCurrency.usd, DecimalSeparator.dot),
      12345.00,
    );
    expect(parseMoneyInput('', AppCurrency.brl, DecimalSeparator.comma), 0.0);
  });

  test('formatCents respects DecimalSeparator override', () {
    expect(
      formatCents(123456789, AppCurrency.brl, DecimalSeparator.dot),
      '1,234,567.89',
    );
  });

  test('parseMoneyInput respects DecimalSeparator override', () {
    expect(
      parseMoneyInput('1,234,567.89', AppCurrency.brl, DecimalSeparator.dot),
      1234567.89,
    );
  });
}
