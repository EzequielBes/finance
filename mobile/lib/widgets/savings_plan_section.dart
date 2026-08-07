// mobile/lib/widgets/savings_plan_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/providers/savings_analysis_provider.dart';
import 'package:mobile/repositories/plans_repository.dart';
import 'package:mobile/repositories/savings_analysis_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/plan_icons.dart';

class SavingsPlanSection extends ConsumerStatefulWidget {
  const SavingsPlanSection({super.key, required this.plan, required this.simulation});
  final Plan plan;
  final PlanSimulation? simulation;

  @override
  ConsumerState<SavingsPlanSection> createState() => _SavingsPlanSectionState();
}

class _SavingsPlanSectionState extends ConsumerState<SavingsPlanSection> {
  bool _expanded = false;
  double _targetPercent = 20.0;
  List<SavingsCandidate> _allCandidates = [];
  final Map<int, SuggestedCut> _selectedCuts = {};
  PlanSimulation? _newSimulation;
  late final TextEditingController _targetPercentController;

  @override
  void initState() {
    super.initState();
    _targetPercentController = TextEditingController(text: _targetPercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _targetPercentController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    final repo = ref.read(savingsAnalysisRepositoryProvider);
    final candidates = await repo.getSavingsCandidates();
    if (mounted) setState(() => _allCandidates = candidates);
  }

  void _applySuggestion() {
    final repo = ref.read(savingsAnalysisRepositoryProvider);
    final suggestions = repo.suggestCuts(_allCandidates, _targetPercent);
    setState(() {
      _selectedCuts
        ..clear()
        ..addEntries(suggestions.map((s) => MapEntry(s.category.id, s)));
    });
    _recomputeSimulation();
  }

  double get _totalCut => _selectedCuts.values.fold(0.0, (sum, c) => sum + c.cutAmount);

  Future<void> _recomputeSimulation() async {
    final plansRepo = ref.read(plansRepositoryProvider);
    final result = await plansRepo.simulate(
      targetAmount: widget.plan.targetAmount,
      currentSavings: widget.plan.currentSavings,
      monthlyContribution: widget.plan.monthlyContribution + _totalCut,
    );
    if (mounted) setState(() => _newSimulation = result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded && _allCandidates.isEmpty) _loadCandidates();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(planSavingsIcon, size: 18, color: AppColors.accentPrimary),
                  const SizedBox(width: 8),
                  const Text('Plano de economia', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildExpandedContent(),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Defina quanto quer economizar no total, o sistema sugere como distribuir entre suas categorias.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Text('Economizar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _targetPercentController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (v) => _targetPercent = double.tryParse(v) ?? _targetPercent,
                ),
              ),
              const Text('%', style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: Icon(planSuggestIcon, size: 16),
                label: const Text('Sugerir'),
                onPressed: _allCandidates.isEmpty ? null : _applySuggestion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedCuts.isNotEmpty) ...[
          const Text('CATEGORIAS NO PLANO', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ..._selectedCuts.values.map((cut) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cut.category.name} — R\$${cut.cutAmount.toStringAsFixed(2)} (${cut.cutPercentOfCategory.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    IconButton(
                      icon: Icon(planRemoveIcon, size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() => _selectedCuts.remove(cut.category.id));
                        _recomputeSimulation();
                      },
                    ),
                  ],
                ),
              )),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Text('Total economizado', style: TextStyle(fontSize: 12.5)),
                const Spacer(),
                Text(
                  'R\$${_totalCut.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentSuccess),
                ),
              ],
            ),
          ),
          if (_newSimulation?.monthsToGoal != null && widget.simulation?.monthsToGoal != null)
            Row(
              children: [
                const Text('Novo prazo', style: TextStyle(fontSize: 12.5)),
                const Spacer(),
                Text(
                  '${_newSimulation!.monthsToGoal} meses',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhuma categoria no plano ainda. Toque "Sugerir" ou adicione manualmente.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
      ],
    );
  }
}
