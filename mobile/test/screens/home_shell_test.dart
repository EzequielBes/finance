import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/providers/savings_analysis_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/repositories/income_repository.dart';
import 'package:mobile/repositories/plans_repository.dart';
import 'package:mobile/repositories/savings_analysis_repository.dart';
import 'package:mobile/repositories/transactions_repository.dart';
import 'package:mobile/screens/home_shell.dart';
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
        plansRepositoryProvider.overrideWithValue(PlansRepository(db)),
        dashboardRepositoryProvider.overrideWithValue(
          DashboardRepository(db, PlansRepository(db)),
        ),
        savingsAnalysisRepositoryProvider.overrideWithValue(
          SavingsAnalysisRepository(db),
        ),
      ],
      child: MaterialApp(
        home: SettingsScope(settings: AppSettings(), child: const HomeShell()),
      ),
    );
  }

  testWidgets('uses PageView instead of IndexedStack for navigation', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tapping a NavigationBar destination animates to that page', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Planos'));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 3.0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
