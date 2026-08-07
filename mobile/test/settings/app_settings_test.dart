import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';

void main() {
  test('formats supported currencies with their decimal conventions', () {
    expect(formatMoney(75800, AppCurrency.brl), 'R\$ 75.800,00');
    expect(formatMoney(75800, AppCurrency.usd), 'US\$ 75,800.00');
    expect(formatMoney(75800, AppCurrency.eur), '€ 75.800,00');
    expect(formatMoney(75800.6, AppCurrency.jpy), '¥ 75,801');
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
}
