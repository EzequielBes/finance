import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/plans_repository.dart';

abstract class TimelineEvent {
  DateTime get date;
}

class TransactionTimelineEvent extends TimelineEvent {
  TransactionTimelineEvent({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryName,
    required this.transactionType,
    required this.isRecurring,
    required this.installmentsTotal,
  });

  final int id;
  final String title;
  final double amount;
  @override
  final DateTime date;
  final String? categoryName;
  final TransactionType transactionType;
  final bool isRecurring;
  final int? installmentsTotal;
}

class PlanMilestoneTimelineEvent extends TimelineEvent {
  PlanMilestoneTimelineEvent({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.date,
    required this.planName,
    required this.status,
  });

  final int id;
  final String title;
  final double targetAmount;
  @override
  final DateTime date;
  final String planName;
  final PlanStatus status;
}

class CategoryExpenseSummary {
  CategoryExpenseSummary({
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
    required this.percent,
  });

  final String name;
  final String color;
  final String icon;
  final double total;
  final double percent;
}

class DashboardSummary {
  DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.savingsPercent,
    required this.byCategory,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double savingsPercent;
  final List<CategoryExpenseSummary> byCategory;
}

class DashboardRepository {
  DashboardRepository(this.db, this.plansRepository);
  final AppDatabase db;
  final PlansRepository plansRepository;

  Future<DashboardSummary> getSummary({int? month, int? year}) async {
    final now = DateTime.now();
    final refMonth = month ?? now.month;
    final refYear = year ?? now.year;
    final start = DateTime(refYear, refMonth, 1);
    final end = DateTime(refYear, refMonth + 1, 1);

    final incomeRows = await (db.select(db.incomeEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(start) & e.date.isSmallerThanValue(end)))
        .get();
    final totalIncome = incomeRows.fold<double>(0.0, (sum, e) => sum + e.amount);

    final expenseTxs = await (db.select(db.transactions)
          ..where((t) =>
              t.type.equalsValue(TransactionType.expense) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
    final totalExpense = expenseTxs.fold<double>(0.0, (sum, t) => sum + t.amount);

    final categories = await (db.select(db.categories)..where((c) => c.type.equalsValue(CategoryType.expense))).get();
    final categoriesById = {for (final c in categories) c.id: c};

    final totalsByCategory = <int, double>{};
    for (final t in expenseTxs) {
      if (t.categoryId == null) continue;
      totalsByCategory[t.categoryId!] = (totalsByCategory[t.categoryId!] ?? 0.0) + t.amount;
    }

    final byCategory = <CategoryExpenseSummary>[];
    totalsByCategory.forEach((catId, total) {
      final cat = categoriesById[catId];
      if (cat == null || total <= 0) return;
      byCategory.add(CategoryExpenseSummary(
        name: cat.name,
        color: cat.color,
        icon: cat.icon,
        total: total,
        percent: totalExpense > 0 ? (total / totalExpense * 100) : 0.0,
      ));
    });
    byCategory.sort((a, b) => b.total.compareTo(a.total));

    final balance = totalIncome - totalExpense;
    final savingsPercent = totalIncome > 0 ? (balance / totalIncome * 100) : 0.0;

    return DashboardSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      savingsPercent: savingsPercent,
      byCategory: byCategory,
    );
  }

  Future<List<TimelineEvent>> getTimeline({int monthsAhead = 6}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = DateTime(now.year, now.month + monthsAhead, now.day);
    final events = <TimelineEvent>[];

    final txs = await (db.select(db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(today) & t.date.isSmallerOrEqualValue(cutoff)))
        .get();
    final categories = await db.select(db.categories).get();
    final categoriesById = {for (final c in categories) c.id: c};

    for (final t in txs) {
      final categoryName = t.categoryId != null ? categoriesById[t.categoryId]?.name : null;
      events.add(TransactionTimelineEvent(
        id: t.id,
        title: t.description,
        amount: t.amount,
        date: t.date,
        categoryName: categoryName,
        transactionType: t.type,
        isRecurring: t.isRecurring,
        installmentsTotal: t.installmentsTotal,
      ));
    }

    final plans = await (db.select(db.plans)
          ..where((p) => p.status.equalsValue(PlanStatus.active) | p.status.equalsValue(PlanStatus.paused)))
        .get();
    for (final plan in plans) {
      final simulation = await plansRepository.simulate(
        targetAmount: plan.targetAmount,
        currentSavings: plan.currentSavings,
        monthlyContribution: plan.monthlyContribution,
        referenceDate: now,
      );
      final targetDate = plan.deadline ?? simulation.estimatedDate;
      if (targetDate == null) continue;
      if (targetDate.isBefore(today) || targetDate.isAfter(cutoff)) continue;
      events.add(PlanMilestoneTimelineEvent(
        id: plan.id,
        title: plan.name,
        targetAmount: plan.targetAmount,
        date: targetDate,
        planName: plan.name,
        status: plan.status,
      ));
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  // Dashboard summary/timeline are derived from transactions, income entries,
  // and plans — a plain watch on any single table would miss writes to the
  // others. Merging all relevant tables' watch streams ensures a write to
  // any of them triggers a recompute, matching the pattern already used by
  // CategoriesRepository.watchAll() and PlansRepository.watchAll().
  Stream<DashboardSummary> watchSummary({int? month, int? year}) {
    final transactionsChanged = db.select(db.transactions).watch().map((_) => null);
    final incomeChanged = db.select(db.incomeEntries).watch().map((_) => null);
    final categoriesChanged = db.select(db.categories).watch().map((_) => null);
    return StreamGroup.merge<void>([transactionsChanged, incomeChanged, categoriesChanged])
        .asyncMap((_) => getSummary(month: month, year: year));
  }

  Stream<List<TimelineEvent>> watchTimeline({int monthsAhead = 6}) {
    final transactionsChanged = db.select(db.transactions).watch().map((_) => null);
    final categoriesChanged = db.select(db.categories).watch().map((_) => null);
    final plansChanged = db.select(db.plans).watch().map((_) => null);
    return StreamGroup.merge<void>([transactionsChanged, categoriesChanged, plansChanged])
        .asyncMap((_) => getTimeline(monthsAhead: monthsAhead));
  }
}
