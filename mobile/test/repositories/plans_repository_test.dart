import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/plans_repository.dart';

void main() {
  late AppDatabase db;
  late PlansRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = PlansRepository(db);
  });

  tearDown(() async => db.close());

  test('create rejects a sub-plan whose parent is already a sub-plan', () async {
    final grandparentId = await repo.create(
      name: 'Pai', targetAmount: 10000, monthlyContribution: 1000, color: '#c17a54',
    );
    final parentId = await repo.create(
      name: 'Filho', parentPlanId: grandparentId, targetAmount: 5000, monthlyContribution: 500, color: '#7a9b7e',
    );
    expect(
      () => repo.create(
        name: 'Neto', parentPlanId: parentId, targetAmount: 1000, monthlyContribution: 100, color: '#8a9bb0',
      ),
      throwsArgumentError,
    );
  });

  test('addContribution with deposit increases currentSavings', () async {
    final planId = await repo.create(
      name: 'Meta', targetAmount: 1000, monthlyContribution: 200, color: '#c17a54',
    );
    await repo.addContribution(planId: planId, amount: 300, type: ContributionType.deposit, date: DateTime(2026, 1, 1));
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    expect(plan.currentSavings, 300.0);
  });

  test('addContribution with withdrawal decreases currentSavings and never goes negative', () async {
    final planId = await repo.create(
      name: 'Meta', targetAmount: 1000, monthlyContribution: 200, color: '#c17a54', currentSavings: 100,
    );
    await repo.addContribution(planId: planId, amount: 500, type: ContributionType.withdrawal, date: DateTime(2026, 1, 1));
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    expect(plan.currentSavings, 0.0);
  });

  test('addContribution marks plan completed when currentSavings reaches targetAmount', () async {
    final planId = await repo.create(
      name: 'Meta', targetAmount: 1000, monthlyContribution: 200, color: '#c17a54', currentSavings: 800,
    );
    await repo.addContribution(planId: planId, amount: 200, type: ContributionType.deposit, date: DateTime(2026, 1, 1));
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    expect(plan.status, PlanStatus.completed);
  });

  test('adjustSavings creates an automatic deposit contribution for a positive difference', () async {
    final planId = await repo.create(
      name: 'Meta', targetAmount: 1000, monthlyContribution: 200, color: '#c17a54', currentSavings: 100,
    );
    await repo.adjustSavings(planId, 400);
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    expect(plan.currentSavings, 400.0);
    final contributions = await (db.select(db.planContributions)..where((c) => c.planId.equals(planId))).get();
    expect(contributions.length, 1);
    expect(contributions.first.type, ContributionType.deposit);
    expect(contributions.first.amount, 300.0);
    expect(contributions.first.notes, 'Ajuste manual');
  });

  test('adjustSavings creates an automatic withdrawal contribution for a negative difference', () async {
    final planId = await repo.create(
      name: 'Meta', targetAmount: 1000, monthlyContribution: 200, color: '#c17a54', currentSavings: 400,
    );
    await repo.adjustSavings(planId, 100);
    final contributions = await (db.select(db.planContributions)..where((c) => c.planId.equals(planId))).get();
    expect(contributions.first.type, ContributionType.withdrawal);
    expect(contributions.first.amount, 300.0);
  });

  test('remove deletes plan, its sub-plans, and their contributions', () async {
    final parentId = await repo.create(name: 'Pai', targetAmount: 1000, monthlyContribution: 100, color: '#c17a54');
    final subId = await repo.create(name: 'Sub', parentPlanId: parentId, targetAmount: 500, monthlyContribution: 50, color: '#7a9b7e');
    await repo.addContribution(planId: subId, amount: 50, type: ContributionType.deposit, date: DateTime(2026, 1, 1));

    await repo.remove(parentId);

    final remainingPlans = await db.select(db.plans).get();
    expect(remainingPlans, isEmpty);
    final remainingContributions = await db.select(db.planContributions).get();
    expect(remainingContributions, isEmpty);
  });

  test('reorder updates priority according to list position', () async {
    final id1 = await repo.create(name: 'A', targetAmount: 100, monthlyContribution: 10, color: '#c17a54');
    final id2 = await repo.create(name: 'B', targetAmount: 100, monthlyContribution: 10, color: '#7a9b7e');
    final id3 = await repo.create(name: 'C', targetAmount: 100, monthlyContribution: 10, color: '#8a9bb0');

    await repo.reorder([id3, id1, id2]);

    final planC = await (db.select(db.plans)..where((p) => p.id.equals(id3))).getSingle();
    final planA = await (db.select(db.plans)..where((p) => p.id.equals(id1))).getSingle();
    final planB = await (db.select(db.plans)..where((p) => p.id.equals(id2))).getSingle();
    expect(planC.priority, 1);
    expect(planA.priority, 2);
    expect(planB.priority, 3);
  });

  group('simulate', () {
    test('returns completed immediately when target already reached', () async {
      final result = await repo.simulate(
        targetAmount: 1000, currentSavings: 1000, monthlyContribution: 100, referenceDate: DateTime(2026, 1, 1),
      );
      expect(result.monthsToGoal, 0);
      expect(result.progressPercent, 100.0);
      expect(result.remainingAmount, 0.0);
    });

    test('returns null months when monthlyContribution is zero or negative', () async {
      final result = await repo.simulate(
        targetAmount: 1000, currentSavings: 200, monthlyContribution: 0, referenceDate: DateTime(2026, 1, 1),
      );
      expect(result.monthsToGoal, isNull);
      expect(result.estimatedDate, isNull);
      expect(result.remainingAmount, 800.0);
    });

    test('computes months and estimated date for a normal case', () async {
      final result = await repo.simulate(
        targetAmount: 1000, currentSavings: 100, monthlyContribution: 300, referenceDate: DateTime(2026, 1, 1),
      );
      expect(result.monthsToGoal, 3); // ceil(900 / 300) = 3
      expect(result.estimatedDate, DateTime(2026, 4, 1));
      expect(result.progressPercent, 10.0);
    });
  });
}
