import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';

void main() {
  test('formats supported currencies with their decimal conventions', () {
    expect(
      formatMoney(75800, AppCurrency.brl, DecimalSeparator.comma),
      'R\$ 75.800,00',
    );
    expect(
      formatMoney(75800, AppCurrency.usd, DecimalSeparator.dot),
      'US\$ 75,800.00',
    );
    expect(
      formatMoney(75800, AppCurrency.eur, DecimalSeparator.comma),
      '€ 75.800,00',
    );
    expect(
      formatMoney(75800.6, AppCurrency.jpy, DecimalSeparator.dot),
      '¥ 75,801',
    );
  });

  test('decimal separator overrides currency default grouping', () {
    expect(
      formatMoney(75800, AppCurrency.brl, DecimalSeparator.dot),
      'R\$ 75,800.00',
    );
  });

  test('persists the selected currency between settings instances', () async {
    final directory = await Directory.systemTemp.createTemp(
      'financial_settings',
    );
    final file = File('${directory.path}/settings.json');
    addTearDown(() => directory.delete(recursive: true));

    final settings = await AppSettings.fromFile(file);
    await settings.setCurrency(AppCurrency.jpy);
    final restored = await AppSettings.fromFile(file);

    expect(restored.currency, AppCurrency.jpy);
  });

  test('persists date format and decimal separator between settings instances', () async {
    final directory = await Directory.systemTemp.createTemp(
      'financial_settings_2',
    );
    final file = File('${directory.path}/settings.json');
    addTearDown(() => directory.delete(recursive: true));

    final settings = await AppSettings.fromFile(file);
    expect(settings.dateFormat, AppDateFormat.dmy);
    expect(settings.decimalSeparator, DecimalSeparator.comma);

    await settings.setDateFormat(AppDateFormat.ymd);
    await settings.setDecimalSeparator(DecimalSeparator.dot);
    final restored = await AppSettings.fromFile(file);

    expect(restored.dateFormat, AppDateFormat.ymd);
    expect(restored.decimalSeparator, DecimalSeparator.dot);
  });
}
