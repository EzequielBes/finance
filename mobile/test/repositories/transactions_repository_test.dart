import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = TransactionsRepository(db);
  });

  tearDown(() async => db.close());

  test('create with installmentsTotal 3 generates 3 rows with shared group id and suffixes', () async {
    await repo.create(
      description: 'Notebook',
      amount: 300.0,
      date: DateTime(2026, 1, 10),
      type: TransactionType.expense,
      installmentsTotal: 3,
    );
    final rows = await db.select(db.transactions).get();
    expect(rows.length, 3);
    expect(rows[0].description, 'Notebook (1/3)');
    expect(rows[1].description, 'Notebook (2/3)');
    expect(rows[2].description, 'Notebook (3/3)');
    expect(rows[1].date, DateTime(2026, 2, 10));
    expect(rows[2].date, DateTime(2026, 3, 10));
    final groupIds = rows.map((r) => r.installmentGroupId).toSet();
    expect(groupIds.length, 1);
    expect(groupIds.first, isNotNull);
    expect(rows[0].installmentsCurrent, 1);
    expect(rows[2].installmentsCurrent, 3);
  });

  test('create without installments generates a single row', () async {
    await repo.create(
      description: 'Café',
      amount: 15.0,
      date: DateTime(2026, 1, 10),
      type: TransactionType.expense,
    );
    final rows = await db.select(db.transactions).get();
    expect(rows.length, 1);
    expect(rows.first.installmentGroupId, isNull);
  });

  test('watchList filters by month and year', () async {
    await repo.create(description: 'Jan', amount: 10, date: DateTime(2026, 1, 5), type: TransactionType.expense);
    await repo.create(description: 'Fev', amount: 20, date: DateTime(2026, 2, 5), type: TransactionType.expense);
    final result = await repo.watchList(month: 1, year: 2026);
    expect(result.total, 1);
    expect(result.items.first.description, 'Jan');
  });

  test('watchList filters by categoryId', () async {
    await repo.create(description: 'A', amount: 10, date: DateTime(2026, 1, 5), type: TransactionType.expense, categoryId: 1);
    await repo.create(description: 'B', amount: 10, date: DateTime(2026, 1, 6), type: TransactionType.expense, categoryId: 2);
    final result = await repo.watchList(categoryId: 1);
    expect(result.total, 1);
    expect(result.items.first.description, 'A');
  });

  test('getSuggestions returns at most 5 distinct descriptions, most recent first', () async {
    for (var i = 1; i <= 7; i++) {
      await repo.create(
        description: 'Mercado',
        amount: 50.0,
        date: DateTime(2026, 1, i),
        type: TransactionType.expense,
      );
    }
    await repo.create(description: 'Padaria', amount: 10.0, date: DateTime(2026, 1, 8), type: TransactionType.expense);
    final suggestions = await repo.getSuggestions('merc');
    expect(suggestions.length, 1);
    expect(suggestions.first, 'Mercado');
  });

  test('update without categoryId leaves existing categoryId unchanged', () async {
    await repo.create(
      description: 'Original',
      amount: 50.0,
      date: DateTime(2026, 1, 5),
      type: TransactionType.expense,
      categoryId: 7,
    );
    final created = (await db.select(db.transactions).get()).first;

    await repo.update(created.id, description: 'new desc');

    final updated = await (db.select(db.transactions)..where((t) => t.id.equals(created.id))).getSingle();
    expect(updated.description, 'new desc');
    expect(updated.categoryId, 7);
  });

  test('update with categoryId Value(null) explicitly clears the existing categoryId', () async {
    await repo.create(
      description: 'Original',
      amount: 50.0,
      date: DateTime(2026, 1, 5),
      type: TransactionType.expense,
      categoryId: 7,
    );
    final created = (await db.select(db.transactions).get()).first;

    await repo.update(created.id, categoryId: const Value(null));

    final updated = await (db.select(db.transactions)..where((t) => t.id.equals(created.id))).getSingle();
    expect(updated.categoryId, isNull);
  });

  test('remove deletes the transaction from the table', () async {
    await repo.create(
      description: 'To delete',
      amount: 20.0,
      date: DateTime(2026, 1, 5),
      type: TransactionType.expense,
    );
    final created = (await db.select(db.transactions).get()).first;

    await repo.remove(created.id);

    final rows = await db.select(db.transactions).get();
    expect(rows, isEmpty);
  });

  test('create with installments rolls over into the next year', () async {
    await repo.create(
      description: 'Ano novo',
      amount: 100.0,
      date: DateTime(2026, 11, 15),
      type: TransactionType.expense,
      installmentsTotal: 3,
    );
    final rows = await db.select(db.transactions).get();
    expect(rows.length, 3);
    expect(rows[0].date, DateTime(2026, 11, 15));
    expect(rows[1].date, DateTime(2026, 12, 15));
    expect(rows[2].date, DateTime(2027, 1, 15));
  });
}
