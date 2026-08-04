import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/categories_repository.dart';

void main() {
  late AppDatabase db;
  late CategoriesRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = CategoriesRepository(db);
  });

  tearDown(() async => db.close());

  test('seedDefaults inserts 11 default categories', () async {
    await repo.seedDefaults();
    final rows = await db.select(db.categories).get();
    expect(rows.length, 11);
  });

  test('seedDefaults is idempotent (case-insensitive by name)', () async {
    await repo.seedDefaults();
    await repo.seedDefaults();
    final rows = await db.select(db.categories).get();
    expect(rows.length, 11);
  });

  test('watchAll computes currentMonthUsage summing expense transactions this month', () async {
    final now = DateTime.now();
    final catId = await repo.create(
      name: 'Alimentação',
      type: CategoryType.expense,
      color: '#7a9b7e',
      icon: 'tag',
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Mercado',
        amount: 150.0,
        date: DateTime(now.year, now.month, 5),
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Restaurante',
        amount: 80.0,
        date: DateTime(now.year, now.month, 10),
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // transação de mês anterior não deve contar
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Antiga',
        amount: 999.0,
        date: DateTime(now.year, now.month - 1, 1),
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final results = await repo.watchAll().first;
    final target = results.firstWhere((c) => c.category.id == catId);
    expect(target.currentMonthUsage, 230.0);
  });
}
