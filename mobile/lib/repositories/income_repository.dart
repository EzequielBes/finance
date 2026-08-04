import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';

class IncomeSummary {
  IncomeSummary(this.averageLast3Months, this.totalThisMonth);
  final double averageLast3Months;
  final double totalThisMonth;
}

class IncomeRepository {
  IncomeRepository(this.db);
  final AppDatabase db;

  Future<void> create({
    required double amount,
    required DateTime date,
    required String source,
    bool isRecurring = false,
    RecurrencePeriod? recurrencePeriod,
    String? notes,
  }) {
    final now = DateTime.now();
    return db.into(db.incomeEntries).insert(
      IncomeEntriesCompanion.insert(
        amount: amount,
        date: date,
        source: source,
        isRecurring: Value(isRecurring),
        recurrencePeriod: Value(recurrencePeriod),
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(
    int id, {
    double? amount,
    DateTime? date,
    String? source,
    String? notes,
  }) {
    return (db.update(db.incomeEntries)..where((e) => e.id.equals(id))).write(
      IncomeEntriesCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
        source: source != null ? Value(source) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> remove(int id) {
    return (db.delete(db.incomeEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<List<IncomeEntry>> watchList({int? month, int? year}) async {
    final query = db.select(db.incomeEntries);
    if (year != null && month != null) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      query.where((e) => e.date.isBiggerOrEqualValue(start) & e.date.isSmallerThanValue(end));
    } else if (year != null) {
      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      query.where((e) => e.date.isBiggerOrEqualValue(start) & e.date.isSmallerThanValue(end));
    }
    query.orderBy([(e) => OrderingTerm.desc(e.date)]);
    return query.get();
  }

  Future<IncomeSummary> getSummary() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final thisMonthRows = await (db.select(db.incomeEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(monthStart) & e.date.isSmallerOrEqualValue(now)))
        .get();
    final totalThisMonth = thisMonthRows.fold<double>(0.0, (sum, e) => sum + e.amount);

    final last3MonthsRows = await (db.select(db.incomeEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(threeMonthsAgo) & e.date.isSmallerOrEqualValue(now)))
        .get();
    final average = last3MonthsRows.isEmpty
        ? 0.0
        : last3MonthsRows.fold<double>(0.0, (sum, e) => sum + e.amount) / last3MonthsRows.length;

    return IncomeSummary(average, totalThisMonth);
  }
}
