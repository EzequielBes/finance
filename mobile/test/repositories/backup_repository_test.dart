import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/backup_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('export then restore round-trips all tables losslessly', () async {
    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Moradia',
        type: CategoryType.expense,
        color: '#c17a54',
        icon: 'bank',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId),
        description: 'Aluguel',
        amount: 1500.0,
        date: DateTime(2026, 1, 5),
        type: TransactionType.expense,
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      ),
    );
    await db.into(db.incomeEntries).insert(
      IncomeEntriesCompanion.insert(
        amount: 3000.0,
        date: DateTime(2026, 1, 1),
        source: 'Salário',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    final planId = await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Viagem',
        targetAmount: 5000.0,
        monthlyContribution: 500.0,
        color: '#7a9b7e',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await db.into(db.planContributions).insert(
      PlanContributionsCompanion.insert(
        planId: planId,
        amount: 500.0,
        type: ContributionType.deposit,
        date: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 10),
      ),
    );

    final repo = BackupRepository(db);
    final json = await repo.buildExportJson();

    expect(json['schemaVersion'], db.schemaVersion);
    expect((json['categories'] as List).length, 1);
    expect((json['transactions'] as List).length, 1);
    expect((json['incomeEntries'] as List).length, 1);
    expect((json['plans'] as List).length, 1);
    expect((json['planContributions'] as List).length, 1);

    // Clear the database, then restore from the exported JSON.
    await db.delete(db.planContributions).go();
    await db.delete(db.plans).go();
    await db.delete(db.incomeEntries).go();
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();

    await repo.restoreFromJson(json);

    final categories = await db.select(db.categories).get();
    final transactions = await db.select(db.transactions).get();
    final income = await db.select(db.incomeEntries).get();
    final plans = await db.select(db.plans).get();
    final contributions = await db.select(db.planContributions).get();

    expect(categories.length, 1);
    expect(categories.first.name, 'Moradia');
    expect(transactions.length, 1);
    expect(transactions.first.description, 'Aluguel');
    expect(income.length, 1);
    expect(income.first.source, 'Salário');
    expect(plans.length, 1);
    expect(plans.first.name, 'Viagem');
    expect(contributions.length, 1);
    expect(contributions.first.amount, 500.0);
  });

  test('restoreFromJson rejects a schemaVersion newer than current', () async {
    final repo = BackupRepository(db);
    final futureJson = {
      'schemaVersion': db.schemaVersion + 1,
      'categories': [],
      'transactions': [],
      'incomeEntries': [],
      'plans': [],
      'planContributions': [],
    };

    expect(
      () => repo.restoreFromJson(futureJson),
      throwsA(isA<BackupVersionMismatch>()),
    );
  });
}
