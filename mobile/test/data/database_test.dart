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

  test('inserts a plan and a contribution', () async {
    final planId = await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Viagem Japão',
        targetAmount: 10000.0,
        monthlyContribution: 3000.0,
        color: '#c17a54',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await db.into(db.planContributions).insert(
      PlanContributionsCompanion.insert(
        planId: planId,
        amount: 500.0,
        type: ContributionType.deposit,
        date: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5),
      ),
    );
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    expect(plan.name, 'Viagem Japão');
    expect(plan.currentSavings, 0.0);
    final contributions = await db.select(db.planContributions).get();
    expect(contributions.length, 1);
    expect(contributions.first.type, ContributionType.deposit);
  });

  test('sub-plan references parent plan', () async {
    final parentId = await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Pai',
        targetAmount: 10000.0,
        monthlyContribution: 1000.0,
        color: '#c17a54',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final subId = await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Sub',
        parentPlanId: Value(parentId),
        targetAmount: 2000.0,
        monthlyContribution: 200.0,
        color: '#7a9b7e',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final sub = await (db.select(db.plans)..where((p) => p.id.equals(subId))).getSingle();
    expect(sub.parentPlanId, parentId);
  });
}
