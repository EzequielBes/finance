import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';

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
  DashboardRepository(this.db);
  final AppDatabase db;

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
}
