import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/screens/home_shell.dart';
import 'package:mobile/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(categoriesRepositoryProvider).seedDefaults();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AnalisadorFinanceiroApp(),
    ),
  );
}

class AnalisadorFinanceiroApp extends ConsumerWidget {
  const AnalisadorFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AnalisadorFinanceiro',
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
