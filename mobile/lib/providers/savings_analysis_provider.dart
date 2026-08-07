// mobile/lib/providers/savings_analysis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/repositories/savings_analysis_repository.dart';

final savingsAnalysisRepositoryProvider = Provider<SavingsAnalysisRepository>((
  ref,
) {
  return SavingsAnalysisRepository(ref.watch(appDatabaseProvider));
});
