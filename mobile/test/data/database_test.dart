import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts and reads a category', () async {
    final id = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Moradia',
        type: CategoryType.expense,
        color: '#c17a54',
        icon: 'bank',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final row = await (db.select(db.categories)..where((c) => c.id.equals(id))).getSingle();
    expect(row.name, 'Moradia');
    expect(row.type, CategoryType.expense);
  });

  test('inserts a transaction with installment group id', () async {
    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Compras',
        type: CategoryType.expense,
        color: '#7a9b7e',
        icon: 'wallet',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Notebook (1/3)',
        amount: 500.0,
        date: DateTime(2026, 1, 1),
        type: TransactionType.expense,
        installmentGroupId: const Value('abc-123'),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final rows = await db.select(db.transactions).get();
    expect(rows.length, 1);
    expect(rows.first.installmentGroupId, 'abc-123');
  });

  test('inserts an income entry', () async {
    await db.into(db.incomeEntries).insert(
      IncomeEntriesCompanion.insert(
        amount: 3000.0,
        date: DateTime(2026, 1, 5),
        source: 'Salário',
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      ),
    );
    final rows = await db.select(db.incomeEntries).get();
    expect(rows.length, 1);
    expect(rows.first.source, 'Salário');
  });
}
