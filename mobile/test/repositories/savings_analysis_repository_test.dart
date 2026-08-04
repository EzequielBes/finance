import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/savings_analysis_repository.dart';

void main() {
  test('isEssentialCategory matches case-insensitively, trimmed', () {
    expect(isEssentialCategory('Moradia'), isTrue);
    expect(isEssentialCategory('  saúde  '), isTrue);
    expect(isEssentialCategory('Contas Fixas'), isTrue);
    expect(isEssentialCategory('Lazer'), isFalse);
  });

  group('SavingsAnalysisRepository with database', () {
    late AppDatabase db;
    late SavingsAnalysisRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = SavingsAnalysisRepository(db);
    });

    tearDown(() async => db.close());

    test('getCategoryReference prefers monthlyLimit over historical average', () async {
      final now = DateTime.now();
      final catId = await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
          monthlyLimit: const Value(300.0), createdAt: now, updatedAt: now,
        ),
      );
      final category = await (db.select(db.categories)..where((c) => c.id.equals(catId))).getSingle();
      final reference = await repo.getCategoryReference(category);
      expect(reference, 300.0);
    });

    test('getCategoryReference falls back to 3-month average when no limit set', () async {
      final now = DateTime.now();
      final catId = await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag',
          createdAt: now, updatedAt: now,
        ),
      );
      final category = await (db.select(db.categories)..where((c) => c.id.equals(catId))).getSingle();
      final oneMonthAgo = DateTime(now.year, now.month - 1, 15);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 15);
      for (final d in [oneMonthAgo, twoMonthsAgo]) {
        await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            categoryId: Value(catId), description: 'Gasto', amount: 100.0, date: d,
            type: TransactionType.expense, createdAt: now, updatedAt: now,
          ),
        );
      }
      final reference = await repo.getCategoryReference(category);
      expect(reference, greaterThan(0));
    });
  });

  group('suggestCuts (pure function)', () {
    test('distributes proportionally to weight and sums exactly to target', () {
      final now = DateTime.now();
      final categories = [
        Category(id: 1, name: 'Lazer', type: CategoryType.expense, color: '#c17a54', icon: 'tag', monthlyLimit: null, createdAt: now, updatedAt: now),
        Category(id: 2, name: 'Compras', type: CategoryType.expense, color: '#7a9b7e', icon: 'wallet', monthlyLimit: null, createdAt: now, updatedAt: now),
        Category(id: 3, name: 'Educação', type: CategoryType.expense, color: '#8a9bb0', icon: 'tag', monthlyLimit: null, createdAt: now, updatedAt: now),
      ];
      final candidates = [
        SavingsCandidate(category: categories[0], currentMonthAmount: 400.0, reference: 300.0), // over limit, weight 1.33
        SavingsCandidate(category: categories[1], currentMonthAmount: 300.0, reference: 500.0), // weight 0.6
        SavingsCandidate(category: categories[2], currentMonthAmount: 100.0, reference: 200.0), // weight 0.5
      ];
      // Total de todas não-essenciais (aqui as 3 mesmas) = 800; meta 20% = R$160.
      final result = SavingsAnalysisRepository(AppDatabase(executor: NativeDatabase.memory()))
          .suggestCuts(candidates, 20.0);

      final totalCut = result.fold<double>(0.0, (sum, c) => sum + c.cutAmount);
      expect(totalCut, closeTo(160.0, 0.01));
      // Categoria com maior peso (Lazer, 1.33) recebe o maior corte em valor absoluto.
      final lazerCut = result.firstWhere((c) => c.category.id == 1).cutAmount;
      final comprasCut = result.firstWhere((c) => c.category.id == 2).cutAmount;
      expect(lazerCut, greaterThan(comprasCut));
    });

    test('excludes categories with zero reference from suggestion', () {
      final now = DateTime.now();
      final cat = Category(id: 1, name: 'Nova', type: CategoryType.expense, color: '#c17a54', icon: 'tag', monthlyLimit: null, createdAt: now, updatedAt: now);
      final candidates = [
        SavingsCandidate(category: cat, currentMonthAmount: 50.0, reference: 0.0),
      ];
      final result = SavingsAnalysisRepository(AppDatabase(executor: NativeDatabase.memory()))
          .suggestCuts(candidates, 20.0);
      expect(result, isEmpty);
    });
  });
}
