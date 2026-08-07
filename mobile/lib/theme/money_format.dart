import 'package:mobile/settings/app_settings.dart';

String formatMoney(double value, AppCurrency currency) {
  final decimals = currency == AppCurrency.jpy ? 0 : 2;
  final decimalSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => ',',
    AppCurrency.usd || AppCurrency.jpy => '.',
  };
  final groupSeparator = switch (currency) {
    AppCurrency.brl || AppCurrency.eur => '.',
    AppCurrency.usd || AppCurrency.jpy => ',',
  };
  final symbol = currencySymbol(currency);
  final absolute = value.abs().toStringAsFixed(decimals).split('.');
  final digits = absolute.first;
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(groupSeparator);
    grouped.write(digits[i]);
  }
  final fraction = decimals == 0 ? '' : '$decimalSeparator${absolute.last}';
  return '${value < 0 ? '-' : ''}$symbol ${grouped.toString()}$fraction';
}

String currencyLabel(AppCurrency currency) => switch (currency) {
  AppCurrency.brl => 'Real brasileiro (BRL)',
  AppCurrency.usd => 'Dólar americano (USD)',
  AppCurrency.eur => 'Euro (EUR)',
  AppCurrency.jpy => 'Iene japonês (JPY)',
};

String currencySymbol(AppCurrency currency) => switch (currency) {
  AppCurrency.brl => 'R\$',
  AppCurrency.usd => 'US\$',
  AppCurrency.eur => '€',
  AppCurrency.jpy => '¥',
};
