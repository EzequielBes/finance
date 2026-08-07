// mobile/lib/screens/plan_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/repositories/plans_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/plan_icons.dart';
import 'package:mobile/widgets/plan_contribution_sheet.dart';
import 'package:mobile/widgets/plan_form_sheet.dart';
import 'package:mobile/widgets/savings_plan_section.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final int planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  double? _simulatedContribution;
  PlanSimulation? _simulation;
  Timer? _debounce;

  Future<void> _runSimulation(Plan plan, double contribution) async {
    final repo = ref.read(plansRepositoryProvider);
    final result = await repo.simulate(
      targetAmount: plan.targetAmount,
      currentSavings: plan.currentSavings,
      monthlyContribution: contribution,
    );
    if (mounted) setState(() => _simulation = result);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    return plansAsync.when(
      data: (plans) {
        Plan? plan;
        for (final p in plans) {
          if (p.plan.id == widget.planId) plan = p.plan;
          for (final sub in p.subPlans) {
            if (sub.id == widget.planId) plan = sub;
          }
        }
        if (plan == null) {
          return const Scaffold(body: Center(child: Text('Plano não encontrado')));
        }
        final color = Color(int.parse('0xFF${plan.color.substring(1)}'));
        final percent = plan.targetAmount > 0 ? (plan.currentSavings / plan.targetAmount * 100).clamp(0.0, 100.0) : 0.0;
        _simulatedContribution ??= plan.monthlyContribution;
        if (_simulation == null) {
          _runSimulation(plan, _simulatedContribution!);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            actions: [
              IconButton(
                icon: Icon(planEditIcon),
                onPressed: () => showPlanFormSheet(context, ref, existing: plan),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: percent / 100),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (ctx, value, _) => CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                color: color,
                              ),
                            ),
                            Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'Guardado', value: 'R\$${plan.currentSavings.toStringAsFixed(0)}', color: AppColors.accentSuccess),
                          _Stat(label: 'Meta', value: 'R\$${plan.targetAmount.toStringAsFixed(0)}'),
                          if (_simulation?.monthsToGoal != null)
                            _Stat(label: 'Faltam', value: '${_simulation!.monthsToGoal} meses'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(planDepositIcon, color: AppColors.accentSuccess),
                        label: const Text('Depositar'),
                        onPressed: () => showPlanContributionSheet(context, ref, planId: plan!.id, type: ContributionType.deposit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(planWithdrawIcon, color: AppColors.accentDanger),
                        label: const Text('Retirar'),
                        onPressed: () => showPlanContributionSheet(context, ref, planId: plan!.id, type: ContributionType.withdrawal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(planSimulatorIcon, size: 18, color: AppColors.accentPrimary), const SizedBox(width: 8), const Text('Simulador interativo', style: TextStyle(fontWeight: FontWeight.w600))]),
                      const SizedBox(height: 14),
                      Text('Contribuição mensal: R\$${_simulatedContribution!.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary)),
                      Slider(
                        value: _simulatedContribution!,
                        min: 50,
                        max: plan.targetAmount,
                        onChanged: (v) {
                          setState(() => _simulatedContribution = v);
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 400), () => _runSimulation(plan!, v));
                        },
                      ),
                      if (_simulation != null)
                        Row(
                          children: [
                            _Stat(label: 'Prazo', value: _simulation!.monthsToGoal != null ? '${_simulation!.monthsToGoal} meses' : 'Indefinido'),
                            if (_simulation!.estimatedDate != null) ...[
                              const SizedBox(width: 24),
                              _Stat(label: 'Data estimada', value: '${_simulation!.estimatedDate!.month}/${_simulation!.estimatedDate!.year}'),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SavingsPlanSection(plan: plan, simulation: _simulation),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
