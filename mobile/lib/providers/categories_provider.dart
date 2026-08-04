// mobile/lib/providers/categories_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(appDatabaseProvider));
});

final categoriesProvider = StreamProvider<List<CategoryWithUsage>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});
