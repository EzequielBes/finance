import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';

class CategoryWithUsage {
  CategoryWithUsage(this.category, this.currentMonthUsage);
  final Category category;
  final double currentMonthUsage;
}

const _defaultCategories = [
  {'name': 'Moradia', 'type': CategoryType.expense, 'color': '#c17a54', 'icon': 'bank'},
  {'name': 'Alimentação', 'type': CategoryType.expense, 'color': '#7a9b7e', 'icon': 'tag'},
  {'name': 'Transporte', 'type': CategoryType.expense, 'color': '#8a9bb0', 'icon': 'transactions'},
  {'name': 'Saúde', 'type': CategoryType.expense, 'color': '#b8563a', 'icon': 'tag'},
  {'name': 'Lazer', 'type': CategoryType.expense, 'color': '#c17a54', 'icon': 'tag'},
  {'name': 'Compras', 'type': CategoryType.expense, 'color': '#7a9b7e', 'icon': 'wallet'},
  {'name': 'Educação', 'type': CategoryType.expense, 'color': '#8a9bb0', 'icon': 'tag'},
  {'name': 'Contas fixas', 'type': CategoryType.expense, 'color': '#b8563a', 'icon': 'bank'},
  {'name': 'Salário', 'type': CategoryType.income, 'color': '#7a9b7e', 'icon': 'trending-up'},
  {'name': 'Freelance', 'type': CategoryType.income, 'color': '#c17a54', 'icon': 'trending-up'},
  {'name': 'Outros rendimentos', 'type': CategoryType.income, 'color': '#8a9bb0', 'icon': 'trending-up'},
];

class CategoriesRepository {
  CategoriesRepository(this.db);
  final AppDatabase db;

  Future<void> seedDefaults() async {
    final existing = await db.select(db.categories).get();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    final now = DateTime.now();
    for (final def in _defaultCategories) {
      final name = def['name'] as String;
      if (existingNames.contains(name.toLowerCase())) continue;
      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          name: name,
          type: def['type'] as CategoryType,
          color: def['color'] as String,
          icon: def['icon'] as String,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<int> create({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
    double? monthlyLimit,
  }) {
    final now = DateTime.now();
    return db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: name,
        type: type,
        color: color,
        icon: icon,
        monthlyLimit: Value(monthlyLimit),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(
    int id, {
    String? name,
    String? color,
    String? icon,
    double? monthlyLimit,
  }) {
    return (db.update(db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        monthlyLimit: monthlyLimit != null ? Value(monthlyLimit) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<CategoryWithUsage>> watchAll() {
    // This stream must recompute whenever EITHER categories OR transactions
    // change — currentMonthUsage is derived from transactions, so a plain
    // `db.select(db.categories).watch()` (which only tracks the categories
    // table) would never react to a new/edited/deleted transaction. Merging
    // both tables' watch streams ensures a write to either triggers a
    // recompute of the combined result.
    final categoriesChanged = db.select(db.categories).watch().map((_) => null);
    final transactionsChanged = db.select(db.transactions).watch().map((_) => null);
    return StreamGroup.merge<void>([categoriesChanged, transactionsChanged])
        .asyncMap((_) => _computeUsage());
  }

  Future<List<CategoryWithUsage>> _computeUsage() async {
    final cats = await db.select(db.categories).get();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    // Exclusive upper bound = start of tomorrow, so the range covers
    // "month-to-date" (day 1 of this month through end of today),
    // matching the backend's `Transaction.date <= today` rule while
    // avoiding clock-time-of-day exclusion issues for same-day txs.
    final todayEnd = DateTime(now.year, now.month, now.day + 1);
    final result = <CategoryWithUsage>[];
    for (final cat in cats) {
      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.categoryId.equals(cat.id) &
                t.type.equalsValue(TransactionType.expense) &
                t.date.isBiggerOrEqualValue(monthStart) &
                t.date.isSmallerThanValue(todayEnd)))
          .get();
      final usage = txs.fold<double>(0.0, (sum, t) => sum + t.amount);
      result.add(CategoryWithUsage(cat, usage));
    }
    return result;
  }
}
