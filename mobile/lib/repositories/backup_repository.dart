// mobile/lib/repositories/backup_repository.dart
import 'package:mobile/data/database.dart';

class BackupVersionMismatch implements Exception {
  BackupVersionMismatch(this.foundVersion, this.currentVersion);
  final int foundVersion;
  final int currentVersion;

  @override
  String toString() =>
      'Backup schema version $foundVersion is newer than app schema $currentVersion';
}

class BackupRepository {
  BackupRepository(this.db);
  final AppDatabase db;

  Future<Map<String, dynamic>> buildExportJson() async {
    final categories = await db.select(db.categories).get();
    final transactions = await db.select(db.transactions).get();
    final incomeEntries = await db.select(db.incomeEntries).get();
    final plans = await db.select(db.plans).get();
    final planContributions = await db.select(db.planContributions).get();

    return {
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'incomeEntries': incomeEntries.map((i) => i.toJson()).toList(),
      'plans': plans.map((p) => p.toJson()).toList(),
      'planContributions': planContributions.map((p) => p.toJson()).toList(),
    };
  }

  Future<void> restoreFromJson(Map<String, dynamic> json) async {
    final foundVersion = json['schemaVersion'] as int;
    if (foundVersion > db.schemaVersion) {
      throw BackupVersionMismatch(foundVersion, db.schemaVersion);
    }

    await db.transaction(() async {
      await db.delete(db.planContributions).go();
      await db.delete(db.plans).go();
      await db.delete(db.transactions).go();
      await db.delete(db.incomeEntries).go();
      await db.delete(db.categories).go();

      for (final row in (json['categories'] as List)) {
        await db
            .into(db.categories)
            .insert(Category.fromJson(row as Map<String, dynamic>).toCompanion(true));
      }
      for (final row in (json['transactions'] as List)) {
        await db
            .into(db.transactions)
            .insert(Transaction.fromJson(row as Map<String, dynamic>).toCompanion(true));
      }
      for (final row in (json['incomeEntries'] as List)) {
        await db
            .into(db.incomeEntries)
            .insert(IncomeEntry.fromJson(row as Map<String, dynamic>).toCompanion(true));
      }

      // Two-pass insertion: sub-plans reference their parent via parentPlanId
      // (FK, checked at statement time in SQLite/drift, not deferred). Row
      // order in the exported JSON reflects export-time SELECT order, which
      // has no guaranteed parent-before-child ordering, so a naive single
      // pass can insert a child before its parent and fail. Insert
      // top-level plans first, then sub-plans.
      final planRows = (json['plans'] as List)
          .map((row) => Plan.fromJson(row as Map<String, dynamic>))
          .toList();
      for (final plan in planRows.where((p) => p.parentPlanId == null)) {
        await db.into(db.plans).insert(plan.toCompanion(true));
      }
      for (final plan in planRows.where((p) => p.parentPlanId != null)) {
        await db.into(db.plans).insert(plan.toCompanion(true));
      }

      for (final row in (json['planContributions'] as List)) {
        await db
            .into(db.planContributions)
            .insert(
              PlanContribution.fromJson(
                row as Map<String, dynamic>,
              ).toCompanion(true),
            );
      }
    });
  }
}
