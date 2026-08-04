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
    // Day 1 of the current month is always <= today, so these fixture
    // dates are safe regardless of which day of the month the suite runs on.
    final monthStart = DateTime(now.year, now.month, 1);
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
        date: monthStart,
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
        date: monthStart,
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

  test('watchAll excludes future-dated transactions within the current month', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    // Only run when there's room for a "later this month" date after today.
    if (today.day >= lastDayOfMonth) {
      // Near/at month-end: no valid future-in-month date exists to test.
      return;
    }

    final futureDay = (today.day + 10) <= lastDayOfMonth ? today.day + 10 : lastDayOfMonth;
    final futureDate = DateTime(now.year, now.month, futureDay);

    final catId = await repo.create(
      name: 'Lazer',
      type: CategoryType.expense,
      color: '#c17a54',
      icon: 'tag',
    );
    // Transação de hoje, deve contar.
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Hoje',
        amount: 50.0,
        date: today,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // Transação futura, mesmo mês: NÃO deve contar (paridade com o backend,
    // que filtra Transaction.date <= today).
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Futura',
        amount: 500.0,
        date: futureDate,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final results = await repo.watchAll().first;
    final target = results.firstWhere((c) => c.category.id == catId);
    expect(target.currentMonthUsage, 50.0);
  });

  test('watchAll emits a new value when a transaction is inserted after subscription', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final catId = await repo.create(
      name: 'Transporte',
      type: CategoryType.expense,
      color: '#8a9bb0',
      icon: 'transactions',
    );

    final emissions = <double>[];
    final subscription = repo.watchAll().listen((results) {
      final target = results.firstWhere((c) => c.category.id == catId);
      emissions.add(target.currentMonthUsage);
    });

    // Let the initial emission(s) (usage = 0, no transactions yet) land.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, isNotEmpty);
    expect(emissions.last, 0.0);

    // Insert a transaction AFTER the stream is already subscribed — the
    // stream must react to this, not just to changes on the categories table.
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Ônibus',
        amount: 45.0,
        date: monthStart,
        type: TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.last, 45.0);
    await subscription.cancel();
  });

  test('update without monthlyLimit leaves existing monthlyLimit unchanged', () async {
    final catId = await repo.create(
      name: 'Lazer',
      type: CategoryType.expense,
      color: '#c17a54',
      icon: 'tag',
      monthlyLimit: 500.0,
    );

    await repo.update(catId, name: 'Novo nome');

    final updated = await (db.select(db.categories)..where((c) => c.id.equals(catId))).getSingle();
    expect(updated.name, 'Novo nome');
    expect(updated.monthlyLimit, 500.0);
  });
}
