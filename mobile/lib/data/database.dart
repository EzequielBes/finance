import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum CategoryType { expense, income }

enum TransactionType { expense, income }

enum RecurrencePeriod { monthly, weekly, yearly }

enum PlanStatus { active, paused, cancelled, completed }

enum ContributionType { deposit, withdrawal }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<CategoryType>()();
  TextColumn get color => text()();
  TextColumn get icon => text()();
  RealColumn get monthlyLimit => real().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => textEnum<TransactionType>()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrencePeriod => textEnum<RecurrencePeriod>().nullable()();
  IntColumn get installmentsTotal => integer().nullable()();
  IntColumn get installmentsCurrent => integer().nullable()();
  TextColumn get installmentGroupId => text().nullable()();
  TextColumn get importSource => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class IncomeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrencePeriod => textEnum<RecurrencePeriod>().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentPlanId => integer().nullable().references(Plans, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get targetAmount => real()();
  RealColumn get currentSavings => real().withDefault(const Constant(0.0))();
  RealColumn get monthlyContribution => real()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get status =>
      textEnum<PlanStatus>().withDefault(Constant(PlanStatus.active.name))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get color => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class PlanContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(Plans, #id)();
  RealColumn get amount => real()();
  TextColumn get type => textEnum<ContributionType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [Categories, Transactions, IncomeEntries, Plans, PlanContributions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(plans);
        await m.createTable(planContributions);
      }
      if (from < 3) {
        await m.addColumn(transactions, transactions.importSource);
        await m.addColumn(categories, categories.isActive);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'analisador_financeiro.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
