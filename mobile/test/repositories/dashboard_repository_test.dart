// mobile/test/repositories/dashboard_repository_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/dashboard_repository.dart';

void main() {
  late AppDatabase db;
  late DashboardRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = DashboardRepository(db);
  });

  tearDown(() async => db.close());

  test('getSummary computes income, expense, balance, savingsPercent for the current month', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    await db.into(db.incomeEntries).insert(
      IncomeEntriesCompanion.insert(
        amount: 2000.0, date: monthStart, source: 'Salário', createdAt: now, updatedAt: now,
      ),
    );

    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId), description: 'Cinema', amount: 200.0, date: monthStart,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );

    final summary = await repo.getSummary();

    expect(summary.totalIncome, 2000.0);
    expect(summary.totalExpense, 200.0);
    expect(summary.balance, 1800.0);
    expect(summary.savingsPercent, 90.0);
  });

  test('getSummary returns savingsPercent 0.0 when totalIncome is 0, no division by zero', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId), description: 'Cinema', amount: 100.0, date: monthStart,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );

    final summary = await repo.getSummary();

    expect(summary.totalIncome, 0.0);
    expect(summary.savingsPercent, 0.0);
  });

  test('getSummary byCategory includes only categories with expense > 0, sorted descending, percent relative to totalExpense', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final lazerId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );
    final comprasId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Compras', type: CategoryType.expense, color: '#7a9b7e', icon: 'wallet',
        createdAt: now, updatedAt: now,
      ),
    );
    // Categoria sem transação nenhuma não deve aparecer.
    await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Educação', type: CategoryType.expense, color: '#8a9bb0', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );

    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(lazerId), description: 'Cinema', amount: 300.0, date: monthStart,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(comprasId), description: 'Roupa', amount: 100.0, date: monthStart,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );

    final summary = await repo.getSummary();

    expect(summary.byCategory.length, 2);
    expect(summary.byCategory[0].name, 'Lazer');
    expect(summary.byCategory[0].total, 300.0);
    expect(summary.byCategory[0].percent, 75.0);
    expect(summary.byCategory[1].name, 'Compras');
    expect(summary.byCategory[1].percent, 25.0);
  });
}
