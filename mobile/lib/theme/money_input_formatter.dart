import 'package:flutter/services.dart';
import 'package:mobile/settings/app_settings.dart';

/// Formats money input like a calculator: digits accumulate from the right
/// as cents (e.g. typing "1234" shows "12,34"). Mirrors [formatMoney]'s
/// separators so what's typed matches what's displayed.
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter(this.currency, this.decimalSeparator);

  final AppCurrency currency;
  final DecimalSeparator decimalSeparator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final cents = int.parse(digits);
    final text = formatCents(cents, currency, decimalSeparator);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatCents(int cents, AppCurrency currency, DecimalSeparator decimalSeparator) {
  final decimals = currency == AppCurrency.jpy ? 0 : 2;
  final decimalChar = decimalSeparator == DecimalSeparator.comma ? ',' : '.';
  final groupChar = decimalSeparator == DecimalSeparator.comma ? '.' : ',';
  final divisor = decimals == 0 ? 1 : 100;
  final whole = (cents / divisor).floor();
  final wholeDigits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < wholeDigits.length; i++) {
    if (i > 0 && (wholeDigits.length - i) % 3 == 0) {
      grouped.write(groupChar);
    }
    grouped.write(wholeDigits[i]);
  }
  if (decimals == 0) return grouped.toString();
  final fraction = (cents % divisor).toString().padLeft(decimals, '0');
  return '$grouped$decimalChar$fraction';
}

/// Parses text produced by [MoneyInputFormatter] back into a double.
double parseMoneyInput(String text, AppCurrency currency, DecimalSeparator decimalSeparator) {
  if (text.isEmpty) return 0;
  final decimalChar = decimalSeparator == DecimalSeparator.comma ? ',' : '.';
  final groupChar = decimalSeparator == DecimalSeparator.comma ? '.' : ',';
  final normalized = text.replaceAll(groupChar, '').replaceAll(decimalChar, '.');
  return double.tryParse(normalized) ?? 0;
}
