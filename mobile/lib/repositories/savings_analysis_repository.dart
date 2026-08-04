import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';

const _essentialCategoryNames = {'moradia', 'saúde', 'contas fixas'};

bool isEssentialCategory(String name) {
  return _essentialCategoryNames.contains(name.trim().toLowerCase());
}

class SavingsCandidate {
  SavingsCandidate({required this.category, required this.currentMonthAmount, required this.reference});
  final Category category;
  final double currentMonthAmount;
  final double reference;
}

class SuggestedCut {
  SuggestedCut({required this.category, required this.cutAmount, required this.cutPercentOfCategory});
  final Category category;
  final double cutAmount;
  final double cutPercentOfCategory;
}

class SavingsAnalysisRepository {
  SavingsAnalysisRepository(this.db);
  final AppDatabase db;

  Future<double> getCategoryReference(Category category) async {
    if (category.monthlyLimit != null && category.monthlyLimit! > 0) {
      return category.monthlyLimit!;
    }
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final threeMonthsBackStart = DateTime(now.year, now.month - 3, 1);
    final txs = await (db.select(db.transactions)
          ..where((t) =>
              t.categoryId.equals(category.id) &
              t.type.equalsValue(TransactionType.expense) &
              t.date.isBiggerOrEqualValue(threeMonthsBackStart) &
              t.date.isSmallerThanValue(currentMonthStart)))
        .get();
    if (txs.isEmpty) return 0.0;
    final monthTotals = <String, double>{};
    for (final t in txs) {
      final key = '${t.date.year}-${t.date.month}';
      monthTotals[key] = (monthTotals[key] ?? 0.0) + t.amount;
    }
    final total = monthTotals.values.fold<double>(0.0, (sum, v) => sum + v);
    return total / monthTotals.length;
  }

  Future<List<SavingsCandidate>> getSavingsCandidates() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final categories = await (db.select(db.categories)..where((c) => c.type.equalsValue(CategoryType.expense))).get();
    final result = <SavingsCandidate>[];
    for (final cat in categories) {
      if (isEssentialCategory(cat.name)) continue;
      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.categoryId.equals(cat.id) &
                t.type.equalsValue(TransactionType.expense) &
                t.date.isBiggerOrEqualValue(monthStart) &
                t.date.isSmallerThanValue(monthEnd)))
          .get();
      final currentAmount = txs.fold<double>(0.0, (sum, t) => sum + t.amount);
      if (currentAmount <= 0) continue;
      final reference = await getCategoryReference(cat);
      result.add(SavingsCandidate(category: cat, currentMonthAmount: currentAmount, reference: reference));
    }
    return result;
  }

  List<SuggestedCut> suggestCuts(List<SavingsCandidate> allCandidates, double targetPercent) {
    final withHistory = allCandidates.where((c) => c.reference > 0).toList();
    if (withHistory.isEmpty) return [];

    final totalReference = allCandidates.fold<double>(0.0, (sum, c) => sum + c.currentMonthAmount);
    final targetReais = targetPercent / 100 * totalReference;

    final weights = {
      for (final c in withHistory) c.category.id: c.currentMonthAmount / c.reference,
    };
    final totalWeight = weights.values.fold<double>(0.0, (sum, w) => sum + w);
    if (totalWeight <= 0) return [];

    return withHistory.map((c) {
      final weight = weights[c.category.id]!;
      final cutAmount = targetReais * (weight / totalWeight);
      final cutPercent = c.currentMonthAmount > 0 ? cutAmount / c.currentMonthAmount * 100 : 0.0;
      return SuggestedCut(category: c.category, cutAmount: cutAmount, cutPercentOfCategory: cutPercent);
    }).toList();
  }
}
