// mobile/lib/screens/plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/screens/plan_detail_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/plan_icons.dart';
import 'package:mobile/widgets/plan_form_sheet.dart';
import 'package:mobile/widgets/screen_header.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPlanFormSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return SafeArea(
              child: Column(
                children: [
                  const ScreenHeader(
                    title: 'Planos',
                    subtitle: 'Metas que dão direção ao seu dinheiro',
                    badge: '0',
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Nenhum plano criado ainda',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final saved = plans.fold<double>(
            0,
            (sum, item) => sum + item.plan.currentSavings,
          );
          final target = plans.fold<double>(
            0,
            (sum, item) => sum + item.plan.targetAmount,
          );
          return SafeArea(
            child: Column(
              children: [
                ScreenHeader(
                  title: 'Planos',
                  subtitle: 'Metas que dão direção ao seu dinheiro',
                  badge: '${plans.length}',
                ),
                _PlansSummary(
                  saved: saved,
                  target: target,
                  count: plans.length,
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 88),
                    itemCount: plans.length,
                    onReorderItem: (oldIndex, newIndex) async {
                      final ids = plans.map((p) => p.plan.id).toList();
                      final moved = ids.removeAt(oldIndex);
                      ids.insert(newIndex, moved);
                      await ref.read(plansRepositoryProvider).reorder(ids);
                    },
                    itemBuilder: (ctx, i) {
                      final item = plans[i];
                      final color = Color(
                        int.parse('0xFF${item.plan.color.substring(1)}'),
                      );
                      final percent = item.plan.targetAmount > 0
                          ? (item.plan.currentSavings /
                                    item.plan.targetAmount *
                                    100)
                                .clamp(0.0, 100.0)
                          : 0.0;
                      return Container(
                        key: ValueKey(item.plan.id),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border(
                            left: BorderSide(color: color, width: 3),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlanDetailScreen(planId: item.plan.id),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.plan.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.plan.deadline == null
                                              ? 'Sem prazo definido'
                                              : 'Meta até ${formatMonthYear(item.plan.deadline!, SettingsScope.of(context).dateFormat)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        planDragHandleIcon,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${formatMoney(item.plan.currentSavings, SettingsScope.of(context).currency)} guardados',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.accentSuccess,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'meta ${formatMoney(item.plan.targetAmount, SettingsScope.of(context).currency)}',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: percent / 100,
                                  minHeight: 7,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${percent.toStringAsFixed(0)}% concluído',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Aporte ${formatMoney(item.plan.monthlyContribution, SettingsScope.of(context).currency)}/mês',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _PlansSummary extends StatelessWidget {
  const _PlansSummary({
    required this.saved,
    required this.target,
    required this.count,
  });

  final double saved;
  final double target;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30261F), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL GUARDADO',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(saved, SettingsScope.of(context).currency),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count ${count == 1 ? 'plano' : 'planos'}',
                style: const TextStyle(
                  color: AppColors.accentPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Meta total ${formatMoney(target, SettingsScope.of(context).currency)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
