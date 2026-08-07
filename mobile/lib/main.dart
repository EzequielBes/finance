import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/screens/home_shell.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final settings = await AppSettings.load();
  await container.read(categoriesRepositoryProvider).seedDefaults();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: AnalisadorFinanceiroApp(settings: settings),
    ),
  );
}

class AnalisadorFinanceiroApp extends ConsumerWidget {
  AnalisadorFinanceiroApp({super.key, AppSettings? settings})
    : settings = settings ?? AppSettings();

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsScope(
      settings: settings,
      child: MaterialApp(
        title: 'AnalisadorFinanceiro',
        theme: buildAppTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
