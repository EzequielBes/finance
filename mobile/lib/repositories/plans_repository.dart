import 'dart:async';
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';

class PlanSimulation {
  PlanSimulation({
    required this.monthsToGoal,
    required this.estimatedDate,
    required this.progressPercent,
    required this.remainingAmount,
  });

  final int? monthsToGoal;
  final DateTime? estimatedDate;
  final double progressPercent;
  final double remainingAmount;
}

class PlanWithSubPlans {
  PlanWithSubPlans({required this.plan, required this.subPlans});
  final Plan plan;
  final List<Plan> subPlans;
}

class PlansRepository {
  PlansRepository(this.db);
  final AppDatabase db;

  Future<int> create({
    int? parentPlanId,
    required String name,
    String? description,
    required double targetAmount,
    double currentSavings = 0.0,
    required double monthlyContribution,
    DateTime? deadline,
    required String color,
    String? notes,
  }) async {
    if (parentPlanId != null) {
      final parent = await (db.select(db.plans)..where((p) => p.id.equals(parentPlanId))).getSingle();
      if (parent.parentPlanId != null) {
        throw ArgumentError('Sub-planos não podem ter sub-planos (máx 1 nível)');
      }
    }
    final now = DateTime.now();
    return db.into(db.plans).insert(
      PlansCompanion.insert(
        parentPlanId: Value(parentPlanId),
        name: name,
        description: Value(description),
        targetAmount: targetAmount,
        currentSavings: Value(currentSavings),
        monthlyContribution: monthlyContribution,
        deadline: Value(deadline),
        color: color,
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(
    int id, {
    String? name,
    String? description,
    double? targetAmount,
    double? monthlyContribution,
    Value<DateTime?> deadline = const Value.absent(),
    String? color,
    PlanStatus? status,
  }) {
    return (db.update(db.plans)..where((p) => p.id.equals(id))).write(
      PlansCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        targetAmount: targetAmount != null ? Value(targetAmount) : const Value.absent(),
        monthlyContribution: monthlyContribution != null ? Value(monthlyContribution) : const Value.absent(),
        deadline: deadline,
        color: color != null ? Value(color) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> adjustSavings(int planId, double newAmount, {String notes = 'Ajuste manual'}) async {
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    final diff = newAmount - plan.currentSavings;
    if (diff == 0) return;
    await addContribution(
      planId: planId,
      amount: diff.abs(),
      type: diff > 0 ? ContributionType.deposit : ContributionType.withdrawal,
      date: DateTime.now(),
      notes: notes,
    );
  }

  Future<void> addContribution({
    required int planId,
    required double amount,
    required ContributionType type,
    required DateTime date,
    String? notes,
  }) async {
    final now = DateTime.now();
    await db.into(db.planContributions).insert(
      PlanContributionsCompanion.insert(
        planId: planId,
        amount: amount,
        type: type,
        date: date,
        notes: Value(notes),
        createdAt: now,
      ),
    );
    final plan = await (db.select(db.plans)..where((p) => p.id.equals(planId))).getSingle();
    final delta = type == ContributionType.deposit ? amount : -amount;
    final newSavings = (plan.currentSavings + delta).clamp(0.0, double.infinity);
    final newStatus = newSavings >= plan.targetAmount ? PlanStatus.completed : plan.status;
    await (db.update(db.plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        currentSavings: Value(newSavings),
        status: Value(newStatus),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> remove(int planId) async {
    final subPlans = await (db.select(db.plans)..where((p) => p.parentPlanId.equals(planId))).get();
    for (final sub in subPlans) {
      await (db.delete(db.planContributions)..where((c) => c.planId.equals(sub.id))).go();
      await (db.delete(db.plans)..where((p) => p.id.equals(sub.id))).go();
    }
    await (db.delete(db.planContributions)..where((c) => c.planId.equals(planId))).go();
    await (db.delete(db.plans)..where((p) => p.id.equals(planId))).go();
  }

  Future<void> reorder(List<int> planIdsInOrder) async {
    for (var i = 0; i < planIdsInOrder.length; i++) {
      await (db.update(db.plans)..where((p) => p.id.equals(planIdsInOrder[i]))).write(
        PlansCompanion(priority: Value(i + 1)),
      );
    }
  }

  Stream<List<PlanWithSubPlans>> watchAll() {
    final plansChanged = db.select(db.plans).watch().map((_) => null);
    final contributionsChanged = db.select(db.planContributions).watch().map((_) => null);
    return StreamGroup.merge<void>([plansChanged, contributionsChanged]).asyncMap((_) => _loadAll());
  }

  Future<List<PlanWithSubPlans>> _loadAll() async {
    final rootPlans = await (db.select(db.plans)
          ..where((p) => p.parentPlanId.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.priority)]))
        .get();
    final result = <PlanWithSubPlans>[];
    for (final plan in rootPlans) {
      final subPlans = await (db.select(db.plans)..where((p) => p.parentPlanId.equals(plan.id))).get();
      result.add(PlanWithSubPlans(plan: plan, subPlans: subPlans));
    }
    return result;
  }

  Future<PlanSimulation> simulate({
    required double targetAmount,
    required double currentSavings,
    required double monthlyContribution,
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final remaining = (targetAmount - currentSavings).clamp(0.0, double.infinity);
    final progress = targetAmount > 0 ? (currentSavings / targetAmount * 100).clamp(0.0, 100.0) : 100.0;

    if (remaining <= 0) {
      return PlanSimulation(monthsToGoal: 0, estimatedDate: now, progressPercent: 100.0, remainingAmount: 0.0);
    }
    if (monthlyContribution <= 0) {
      return PlanSimulation(
        monthsToGoal: null,
        estimatedDate: null,
        progressPercent: double.parse(progress.toStringAsFixed(2)),
        remainingAmount: double.parse(remaining.toStringAsFixed(2)),
      );
    }
    final months = (remaining / monthlyContribution).ceil();
    final estimated = DateTime(now.year, now.month + months, now.day);
    return PlanSimulation(
      monthsToGoal: months,
      estimatedDate: estimated,
      progressPercent: double.parse(progress.toStringAsFixed(2)),
      remainingAmount: double.parse(remaining.toStringAsFixed(2)),
    );
  }
}
