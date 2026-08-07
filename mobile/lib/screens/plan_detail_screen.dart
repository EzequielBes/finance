// mobile/lib/screens/plan_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/repositories/plans_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
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

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen>
    with SingleTickerProviderStateMixin {
  double? _simulatedContribution;
  PlanSimulation? _simulation;
  double? _simulatedCurrentSavings;
  Timer? _debounce;
  TabController? _tabController;
  bool _hasSubPlans = false;

  Future<void> _runSimulation(Plan plan, double contribution) async {
    final repo = ref.read(plansRepositoryProvider);
    final result = await repo.simulate(
      targetAmount: plan.targetAmount,
      currentSavings: plan.currentSavings,
      monthlyContribution: contribution,
    );
    if (mounted) setState(() => _simulation = result);
  }

  void _ensureTabController(bool hasSubPlans) {
    if (_tabController != null && _hasSubPlans == hasSubPlans) return;
    _tabController?.dispose();
    _hasSubPlans = hasSubPlans;
    _tabController = TabController(length: hasSubPlans ? 2 : 1, vsync: this)
      ..addListener(() {
        if (!_tabController!.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    return plansAsync.when(
      data: (plans) {
        Plan? plan;
        List<Plan> subPlans = const [];
        for (final p in plans) {
          if (p.plan.id == widget.planId) {
            plan = p.plan;
            subPlans = p.subPlans;
          }
          for (final sub in p.subPlans) {
            if (sub.id == widget.planId) plan = sub;
          }
        }
        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('Plano não encontrado')),
          );
        }
        _ensureTabController(subPlans.isNotEmpty);
        _simulatedContribution ??= plan.monthlyContribution;
        if (_simulation == null ||
            _simulatedCurrentSavings != plan.currentSavings) {
          _simulatedCurrentSavings = plan.currentSavings;
          _runSimulation(plan, _simulatedContribution!);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            actions: [
              IconButton(
                icon: Icon(planEditIcon),
                onPressed: () =>
                    showPlanFormSheet(context, ref, existing: plan),
              ),
            ],
            bottom: _hasSubPlans
                ? TabBar(
                    controller: _tabController,
                    tabs: [
                      const Tab(text: 'Visão geral'),
                      Tab(text: 'Sub-planos (${subPlans.length})'),
                    ],
                  )
                : null,
          ),
          floatingActionButton:
              _hasSubPlans && (_tabController?.index ?? 0) == 1
              ? FloatingActionButton(
                  onPressed: () => showPlanFormSheet(
                    context,
                    ref,
                    defaultParentPlanId: plan!.id,
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          body: _hasSubPlans
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(
                      plan: plan,
                      simulation: _simulation,
                      simulatedContribution: _simulatedContribution!,
                      onContributionChanged: (v) {
                        setState(() => _simulatedContribution = v);
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () => _runSimulation(plan!, v),
                        );
                      },
                    ),
                    _SubPlansTab(subPlans: subPlans),
                  ],
                )
              : _OverviewTab(
                  plan: plan,
                  simulation: _simulation,
                  simulatedContribution: _simulatedContribution!,
                  onContributionChanged: (v) {
                    setState(() => _simulatedContribution = v);
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 400),
                      () => _runSimulation(plan!, v),
                    );
                  },
                ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.plan,
    required this.simulation,
    required this.simulatedContribution,
    required this.onContributionChanged,
  });

  final Plan plan;
  final PlanSimulation? simulation;
  final double simulatedContribution;
  final ValueChanged<double> onContributionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse('0xFF${plan.color.substring(1)}'));
    final percent = plan.targetAmount > 0
        ? (plan.currentSavings / plan.targetAmount * 100).clamp(0.0, 100.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
            ),
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
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      label: 'Guardado',
                      value: formatMoney(
                        plan.currentSavings,
                        SettingsScope.of(context).currency,
                      ),
                      color: AppColors.accentSuccess,
                    ),
                    _Stat(
                      label: 'Meta',
                      value: formatMoney(
                        plan.targetAmount,
                        SettingsScope.of(context).currency,
                      ),
                    ),
                    if (simulation?.monthsToGoal != null)
                      _Stat(
                        label: 'Faltam',
                        value: '${simulation!.monthsToGoal} meses',
                      ),
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
                  onPressed: () => showPlanContributionSheet(
                    context,
                    ref,
                    planId: plan.id,
                    type: ContributionType.deposit,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(planWithdrawIcon, color: AppColors.accentDanger),
                  label: const Text('Retirar'),
                  onPressed: () => showPlanContributionSheet(
                    context,
                    ref,
                    planId: plan.id,
                    type: ContributionType.withdrawal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      planSimulatorIcon,
                      size: 18,
                      color: AppColors.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Simulador interativo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Contribuição mensal: ${formatMoney(simulatedContribution, SettingsScope.of(context).currency)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Slider(
                  value: simulatedContribution,
                  min: 50,
                  max: plan.targetAmount,
                  onChanged: onContributionChanged,
                ),
                if (simulation != null)
                  Row(
                    children: [
                      _Stat(
                        label: 'Prazo',
                        value: simulation!.monthsToGoal != null
                            ? '${simulation!.monthsToGoal} meses'
                            : 'Indefinido',
                      ),
                      if (simulation!.estimatedDate != null) ...[
                        const SizedBox(width: 24),
                        _Stat(
                          label: 'Data estimada',
                          value: formatMonthYear(simulation!.estimatedDate!),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SavingsPlanSection(plan: plan, simulation: simulation),
        ],
      ),
    );
  }
}

class _SubPlansTab extends StatelessWidget {
  const _SubPlansTab({required this.subPlans});
  final List<Plan> subPlans;

  @override
  Widget build(BuildContext context) {
    if (subPlans.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum sub-plano ainda',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: subPlans.length,
      itemBuilder: (ctx, i) {
        final sub = subPlans[i];
        final color = Color(int.parse('0xFF${sub.color.substring(1)}'));
        final percent = sub.targetAmount > 0
            ? (sub.currentSavings / sub.targetAmount * 100).clamp(0.0, 100.0)
            : 0.0;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              sub.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatMoney(sub.currentSavings, SettingsScope.of(context).currency)} / ${formatMoney(sub.targetAmount, SettingsScope.of(context).currency)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: color,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanDetailScreen(planId: sub.id),
              ),
            ),
          ),
        );
      },
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
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
