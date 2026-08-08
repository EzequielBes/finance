import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/income_repository.dart';
import 'package:mobile/services/import/import_result.dart';

void main() {
  late AppDatabase db;
  late IncomeRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = IncomeRepository(db);
  });

  tearDown(() async => db.close());

  test('create and watchList filters by month/year', () async {
    await repo.create(amount: 3000, date: DateTime(2026, 1, 5), source: 'Salário');
    await repo.create(amount: 500, date: DateTime(2026, 2, 5), source: 'Freelance');
    final jan = await repo.watchList(month: 1, year: 2026);
    expect(jan.length, 1);
    expect(jan.first.source, 'Salário');
  });

  test('bulkImport inserts new income entries and returns counts', () async {
    final result = await repo.bulkImport([
      ParsedTransaction(
        description: 'Salário Janeiro',
        amount: 3000.0,
        date: DateTime(2026, 1, 5),
        type: ParsedTransactionType.income,
        importSource: 'nubank_csv',
      ),
    ]);
    expect(result.inserted, 1);
    expect(result.skipped, 0);
    final rows = await repo.watchList();
    expect(rows.length, 1);
    expect(rows.first.source, 'Salário Janeiro');
  });

  test('bulkImport skips an entry that already exists within a 1-day window', () async {
    await repo.create(amount: 3000.0, date: DateTime(2026, 1, 5), source: 'Salário Janeiro');

    final result = await repo.bulkImport([
      ParsedTransaction(
        description: 'Salário Janeiro',
        amount: 3000.0,
        date: DateTime(2026, 1, 6),
        type: ParsedTransactionType.income,
        importSource: 'nubank_csv',
      ),
    ]);

    expect(result.inserted, 0);
    expect(result.skipped, 1);
  });

  test('remove deletes entry', () async {
    await repo.create(amount: 100, date: DateTime(2026, 1, 1), source: 'Extra');
    final all = await repo.watchList();
    await repo.remove(all.first.id);
    final afterRemove = await repo.watchList();
    expect(afterRemove.length, 0);
  });

  test('getSummary computes average of last 3 months and total this month', () async {
    final now = DateTime.now();
    await repo.create(amount: 100, date: now, source: 'A');
    await repo.create(amount: 200, date: now.subtract(const Duration(days: 35)), source: 'B');
    await repo.create(amount: 300, date: now.subtract(const Duration(days: 65)), source: 'C');
    await repo.create(amount: 999, date: now.subtract(const Duration(days: 200)), source: 'Old');

    final summary = await repo.getSummary();
    expect(summary.totalThisMonth, 100);
    expect(summary.averageLast3Months, closeTo(200.0, 0.01));
  });

  test('update without notes leaves existing notes unchanged', () async {
    await repo.create(
      amount: 1000,
      date: DateTime(2026, 1, 5),
      source: 'Salário',
      notes: 'Pagamento mensal',
    );
    final created = (await repo.watchList()).first;

    await repo.update(created.id, amount: 999);

    final updated = (await repo.watchList()).first;
    expect(updated.amount, 999);
    expect(updated.notes, 'Pagamento mensal');
  });
}
