// mobile/lib/screens/plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/screens/plan_detail_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/plan_icons.dart';
import 'package:mobile/widgets/plan_form_sheet.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPlanFormSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text('Nenhum plano criado ainda', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: plans.length,
            onReorder: (oldIndex, newIndex) async {
              final ids = plans.map((p) => p.plan.id).toList();
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await ref.read(plansRepositoryProvider).reorder(ids);
            },
            itemBuilder: (ctx, i) {
              final item = plans[i];
              final color = Color(int.parse('0xFF${item.plan.color.substring(1)}'));
              final percent = item.plan.targetAmount > 0
                  ? (item.plan.currentSavings / item.plan.targetAmount * 100).clamp(0.0, 100.0)
                  : 0.0;
              return Container(
                key: ValueKey(item.plan.id),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(planDragHandleIcon, color: AppColors.textSecondary),
                  title: Text(
                    item.plan.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'R\$${item.plan.currentSavings.toStringAsFixed(0)} / R\$${item.plan.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: item.plan.id)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
