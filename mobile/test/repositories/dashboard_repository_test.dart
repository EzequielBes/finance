// mobile/test/repositories/dashboard_repository_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/repositories/plans_repository.dart';

void main() {
  late AppDatabase db;
  late DashboardRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = DashboardRepository(db, PlansRepository(db));
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

  test('getTimeline excludes transactions outside the window', () async {
    final now = DateTime.now();
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        description: 'Passada', amount: 50.0, date: now.subtract(const Duration(days: 5)),
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        description: 'Muito no futuro', amount: 50.0, date: DateTime(now.year, now.month + 8, now.day),
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    expect(events, isEmpty);
  });

  test('getTimeline includes a transaction inside the window with correct fields', () async {
    final now = DateTime.now();
    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );
    final futureDate = now.add(const Duration(days: 10));
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId), description: 'Cinema agendado', amount: 80.0, date: futureDate,
        type: TransactionType.expense, isRecurring: const Value(true), createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    expect(events.length, 1);
    final event = events.first as TransactionTimelineEvent;
    expect(event.title, 'Cinema agendado');
    expect(event.amount, 80.0);
    expect(event.categoryName, 'Lazer');
    expect(event.isRecurring, true);
  });

  test('getTimeline uses plan deadline when set, ignoring the simulated date', () async {
    final now = DateTime.now();
    final deadline = now.add(const Duration(days: 30));
    final planId = await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Viagem', targetAmount: 10000.0, monthlyContribution: 100.0,
        deadline: Value(deadline), color: '#c17a54', createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    expect(events.length, 1);
    final event = events.first as PlanMilestoneTimelineEvent;
    expect(event.id, planId);
    expect(event.planName, 'Viagem');
    expect(event.date.year, deadline.year);
    expect(event.date.month, deadline.month);
    expect(event.date.day, deadline.day);
  });

  test('getTimeline uses the simulated estimated date when plan has no deadline', () async {
    final now = DateTime.now();
    await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Notebook', targetAmount: 1000.0, currentSavings: const Value(0.0),
        monthlyContribution: 500.0, color: '#c17a54', createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    // remaining=1000, monthlyContribution=500 -> months=ceil(2)=2, dentro da janela de 6 meses.
    expect(events.length, 1);
    expect(events.first, isA<PlanMilestoneTimelineEvent>());
  });

  test('getTimeline excludes plans with status completed or cancelled', () async {
    final now = DateTime.now();
    await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Concluído', targetAmount: 100.0, currentSavings: const Value(100.0),
        monthlyContribution: 50.0, status: Value(PlanStatus.completed),
        color: '#c17a54', createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Cancelado', targetAmount: 100.0, monthlyContribution: 50.0,
        status: Value(PlanStatus.cancelled), color: '#c17a54', createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    expect(events, isEmpty);
  });

  test('getTimeline returns events sorted by date ascending, mixing both types', () async {
    final now = DateTime.now();
    final earlyDate = now.add(const Duration(days: 5));
    final lateDate = now.add(const Duration(days: 60));

    await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Plano tardio', targetAmount: 100.0, monthlyContribution: 100.0,
        deadline: Value(lateDate), color: '#c17a54', createdAt: now, updatedAt: now,
      ),
    );
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        description: 'Transação cedo', amount: 10.0, date: earlyDate,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );

    final events = await repo.getTimeline();

    expect(events.length, 2);
    expect(events[0].date.isBefore(events[1].date), true);
  });

  test('watchSummary emits a new value when a transaction is inserted after subscription', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final catId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
        createdAt: now, updatedAt: now,
      ),
    );

    final emissions = <double>[];
    final subscription = repo.watchSummary().listen((summary) {
      emissions.add(summary.totalExpense);
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, isNotEmpty);
    expect(emissions.last, 0.0);

    // Insert a transaction AFTER the stream is already subscribed — the
    // stream must react to this, not just to changes made before subscribing.
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(catId), description: 'Cinema', amount: 150.0, date: monthStart,
        type: TransactionType.expense, createdAt: now, updatedAt: now,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.last, 150.0);
    await subscription.cancel();
  });

  test('watchTimeline emits a new value when a plan is inserted after subscription', () async {
    final emissions = <int>[];
    final subscription = repo.watchTimeline().listen((events) {
      emissions.add(events.length);
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, isNotEmpty);
    expect(emissions.last, 0);

    final now = DateTime.now();
    await db.into(db.plans).insert(
      PlansCompanion.insert(
        name: 'Viagem', targetAmount: 10000.0, monthlyContribution: 100.0,
        deadline: Value(now.add(const Duration(days: 30))), color: '#c17a54',
        createdAt: now, updatedAt: now,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.last, 1);
    await subscription.cancel();
  });
}
