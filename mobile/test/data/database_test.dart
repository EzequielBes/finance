import 'dart:io';

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

  test('new categories default to isActive true', () async {
    final id = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer',
        type: CategoryType.expense,
        color: '#c17a54',
        icon: 'tag',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final row = await (db.select(db.categories)..where((c) => c.id.equals(id))).getSingle();
    expect(row.isActive, true);
  });

  test('schemaVersion is 3', () {
    expect(db.schemaVersion, 3);
  });

  test('v2 to v3 upgrade adds isActive column, preserving existing rows', () async {
    final directory = await Directory.systemTemp.createTemp('db_migration');
    final file = File('${directory.path}/v2.sqlite');
    addTearDown(() => directory.delete(recursive: true));

    // Build a v2 database by hand: the current `categories` table minus the
    // `is_active` column added in the v3 migration, matching how a real
    // user's on-disk schema would look before upgrading.
    final v2 = NativeDatabase(file);
    await v2.ensureOpen(_NoopUser());
    await v2.runCustom('''
      CREATE TABLE categories (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        monthly_limit REAL NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''', []);
    await v2.runCustom(
      'INSERT INTO categories (name, type, color, icon, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['Moradia', 'expense', '#c17a54', 'bank', 1735689600, 1735689600],
    );
    await v2.runCustom('PRAGMA user_version = 2', []);
    await v2.close();

    // Reopen through AppDatabase against the same file: this triggers the
    // real onUpgrade path exactly as it would for an upgrading user.
    final upgraded = AppDatabase(executor: NativeDatabase(file));
    addTearDown(upgraded.close);

    final rows = await upgraded.select(upgraded.categories).get();
    expect(rows.length, 1);
    expect(rows.first.name, 'Moradia');
    expect(rows.first.isActive, true);
  });
}

class _NoopUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
