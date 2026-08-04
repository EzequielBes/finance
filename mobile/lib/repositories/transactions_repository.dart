import 'package:drift/drift.dart';
import 'package:mobile/data/database.dart';
import 'package:uuid/uuid.dart';

class TransactionsRepository {
  TransactionsRepository(this.db);
  final AppDatabase db;
  static const _uuid = Uuid();

  Future<void> create({
    int? categoryId,
    required String description,
    required double amount,
    required DateTime date,
    required TransactionType type,
    bool isRecurring = false,
    RecurrencePeriod? recurrencePeriod,
    int? installmentsTotal,
  }) async {
    final now = DateTime.now();
    if (installmentsTotal != null && installmentsTotal > 1) {
      final groupId = _uuid.v4();
      for (var i = 1; i <= installmentsTotal; i++) {
        final installmentDate = DateTime(date.year, date.month + (i - 1), date.day);
        await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            categoryId: Value(categoryId),
            description: '$description ($i/$installmentsTotal)',
            amount: amount,
            date: installmentDate,
            type: type,
            installmentsTotal: Value(installmentsTotal),
            installmentsCurrent: Value(i),
            installmentGroupId: Value(groupId),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return;
    }
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        categoryId: Value(categoryId),
        description: description,
        amount: amount,
        date: date,
        type: type,
        isRecurring: Value(isRecurring),
        recurrencePeriod: Value(recurrencePeriod),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(
    int id, {
    String? description,
    double? amount,
    DateTime? date,
    Value<int?> categoryId = const Value.absent(),
  }) {
    return (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        description: description != null ? Value(description) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
        categoryId: categoryId,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> remove(int id) {
    return (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<({List<Transaction> items, int total})> watchList({
    int? month,
    int? year,
    int? categoryId,
    TransactionType? type,
    int page = 1,
    int perPage = 50,
  }) async {
    final query = db.select(db.transactions);
    if (year != null && month != null) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      query.where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end));
    } else if (year != null) {
      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      query.where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end));
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (type != null) {
      query.where((t) => t.type.equalsValue(type));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final all = await query.get();
    final total = all.length;
    final start = (page - 1) * perPage;
    final items = all.skip(start).take(perPage).toList();
    return (items: items, total: total);
  }

  Future<List<String>> getSuggestions(String query) async {
    final lowerQuery = query.toLowerCase();
    final rows = await (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)]))
        .get();
    final seen = <String>{};
    final result = <String>[];
    for (final row in rows) {
      if (!row.description.toLowerCase().contains(lowerQuery)) continue;
      if (seen.contains(row.description)) continue;
      seen.add(row.description);
      result.add(row.description);
      if (result.length == 5) break;
    }
    return result;
  }
}
