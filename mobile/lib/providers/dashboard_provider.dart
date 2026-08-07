// mobile/lib/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/database_provider.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(appDatabaseProvider), ref.watch(plansRepositoryProvider));
});

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchSummary();
});

final dashboardTimelineProvider = StreamProvider<List<TimelineEvent>>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchTimeline();
});
