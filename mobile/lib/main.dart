import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/screens/home_shell.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AnalisadorFinanceiroApp()));
}

class AnalisadorFinanceiroApp extends ConsumerWidget {
  const AnalisadorFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appDatabaseProvider, (previous, next) {});
    ref.read(categoriesRepositoryProvider).seedDefaults();
    return MaterialApp(
      title: 'AnalisadorFinanceiro',
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
