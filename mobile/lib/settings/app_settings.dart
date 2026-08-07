import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum AppCurrency { brl, usd, eur, jpy }

class AppSettings extends ChangeNotifier {
  AppSettings({this._currency = AppCurrency.brl});
  AppSettings.forFile(this._file, {this._currency = AppCurrency.brl});

  AppCurrency _currency;
  File? _file;

  AppCurrency get currency => _currency;

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
      return AppSettings.forFile(file, currency: currency ?? AppCurrency.brl);
    } on Object {
      return AppSettings.forFile(file);
    }
  }

  Future<void> setCurrency(AppCurrency value) async {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
    final file = _file ??= File(
      '${(await getApplicationSupportDirectory()).path}/app_settings.json',
    );
    await file.writeAsString(jsonEncode({'currency': value.name}), flush: true);
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
