import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/repositories/income_repository.dart';
import 'package:mobile/repositories/transactions_repository.dart';
import 'package:mobile/screens/movements_screen.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Widget buildApp() {
    final db = AppDatabase(executor: NativeDatabase.memory());
    return ProviderScope(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(
          TransactionsRepository(db),
        ),
        incomeRepositoryProvider.overrideWithValue(IncomeRepository(db)),
        categoriesRepositoryProvider.overrideWithValue(
          CategoriesRepository(db),
        ),
      ],
      child: MaterialApp(
        home: SettingsScope(
          settings: AppSettings(),
          child: const MovementsScreen(),
        ),
      ),
    );
  }

  testWidgets('does not expose a TabBarView (no internal horizontal swipe)', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsNothing);
    expect(find.byType(IndexedStack), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tapping the Receitas tab switches to the income view', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receitas'));
    await tester.pumpAndSettle();

    final indexedStack = tester.widget<IndexedStack>(
      find.byType(IndexedStack).first,
    );
    expect(indexedStack.index, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
