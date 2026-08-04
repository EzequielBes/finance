// mobile/lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
