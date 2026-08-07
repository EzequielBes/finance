import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum AppCurrency { brl, usd, eur, jpy }

enum AppDateFormat { dmy, mdy, ymd }

enum DecimalSeparator { comma, dot }

class AppSettings extends ChangeNotifier {
  AppSettings({
    AppCurrency currency = AppCurrency.brl,
    AppDateFormat dateFormat = AppDateFormat.dmy,
    DecimalSeparator decimalSeparator = DecimalSeparator.comma,
  }) : _currency = currency,
       _dateFormat = dateFormat,
       _decimalSeparator = decimalSeparator;

  AppSettings.forFile(
    this._file, {
    AppCurrency currency = AppCurrency.brl,
    AppDateFormat dateFormat = AppDateFormat.dmy,
    DecimalSeparator decimalSeparator = DecimalSeparator.comma,
  }) : _currency = currency,
       _dateFormat = dateFormat,
       _decimalSeparator = decimalSeparator;

  AppCurrency _currency;
  AppDateFormat _dateFormat;
  DecimalSeparator _decimalSeparator;
  File? _file;

  AppCurrency get currency => _currency;
  AppDateFormat get dateFormat => _dateFormat;
  DecimalSeparator get decimalSeparator => _decimalSeparator;

  static Future<AppSettings> load() async {
    final directory = await getApplicationSupportDirectory();
    return fromFile(File('${directory.path}/app_settings.json'));
  }

  static Future<AppSettings> fromFile(File file) async {
    if (!await file.exists()) return AppSettings.forFile(file);
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final currency = AppCurrency.values
          .where((value) => value.name == json['currency'])
          .firstOrNull;
      final dateFormat = AppDateFormat.values
          .where((value) => value.name == json['dateFormat'])
          .firstOrNull;
      final decimalSeparator = DecimalSeparator.values
          .where((value) => value.name == json['decimalSeparator'])
          .firstOrNull;
      return AppSettings.forFile(
        file,
        currency: currency ?? AppCurrency.brl,
        dateFormat: dateFormat ?? AppDateFormat.dmy,
        decimalSeparator: decimalSeparator ?? DecimalSeparator.comma,
      );
    } on Object {
      return AppSettings.forFile(file);
    }
  }

  Future<void> setCurrency(AppCurrency value) async {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setDateFormat(AppDateFormat value) async {
    if (_dateFormat == value) return;
    _dateFormat = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setDecimalSeparator(DecimalSeparator value) async {
    if (_decimalSeparator == value) return;
    _decimalSeparator = value;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final file = _file ??= File(
      '${(await getApplicationSupportDirectory()).path}/app_settings.json',
    );
    await file.writeAsString(
      jsonEncode({
        'currency': _currency.name,
        'dateFormat': _dateFormat.name,
        'decimalSeparator': _decimalSeparator.name,
      }),
      flush: true,
    );
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
