// mobile/lib/providers/plans_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/repositories/plans_repository.dart';

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(appDatabaseProvider));
});

final plansProvider = StreamProvider<List<PlanWithSubPlans>>((ref) {
  return ref.watch(plansRepositoryProvider).watchAll();
});
