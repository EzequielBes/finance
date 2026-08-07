import 'package:flutter/services.dart';
import 'package:mobile/settings/app_settings.dart';

/// Formats money input like a calculator: digits accumulate from the right
/// as cents (e.g. typing "1234" shows "12,34"). Mirrors [formatMoney]'s
/// separators per currency so what's typed matches what's displayed.
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter(this.currency);

  final AppCurrency currency;

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
    final text = formatCents(cents, currency);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatCents(int cents, AppCurrency currency) {
  final decimals = currency == AppCurrency.jpy ? 0 : 2;
  final decimalSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => ',',
    AppCurrency.usd || AppCurrency.jpy => '.',
  };
  final groupSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => '.',
    AppCurrency.usd || AppCurrency.jpy => ',',
  };
  final divisor = decimals == 0 ? 1 : 100;
  final whole = (cents / divisor).floor();
  final wholeDigits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < wholeDigits.length; i++) {
    if (i > 0 && (wholeDigits.length - i) % 3 == 0) {
      grouped.write(groupSeparator);
    }
    grouped.write(wholeDigits[i]);
  }
  if (decimals == 0) return grouped.toString();
  final fraction = (cents % divisor).toString().padLeft(decimals, '0');
  return '$grouped$decimalSeparator$fraction';
}

/// Parses text produced by [MoneyInputFormatter] back into a double.
double parseMoneyInput(String text, AppCurrency currency) {
  if (text.isEmpty) return 0;
  final decimalSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => ',',
    AppCurrency.usd || AppCurrency.jpy => '.',
  };
  final groupSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => '.',
    AppCurrency.usd || AppCurrency.jpy => ',',
  };
  final normalized = text
      .replaceAll(groupSeparator, '')
      .replaceAll(decimalSeparator, '.');
  return double.tryParse(normalized) ?? 0;
}
