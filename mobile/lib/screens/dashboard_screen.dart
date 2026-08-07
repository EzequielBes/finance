// mobile/lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/plan_icons.dart';
import 'package:mobile/widgets/category_donut_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final timelineAsync = ref.watch(dashboardTimelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: summaryAsync.when(
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroCard(summary: summary),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Receita do mês', value: summary.totalIncome, color: AppColors.accentSuccess)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Total gasto', value: summary.totalExpense, color: AppColors.accentDanger)),
                ],
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: 'Economizado',
                value: null,
                displayText: '${summary.savingsPercent.toStringAsFixed(0)}%',
                subtitle: 'do total recebido',
                color: AppColors.accentSuccess,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gastos por categoria', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 14),
                    CategoryDonutChart(categories: summary.byCategory),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mapa financeiro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 12),
                    timelineAsync.when(
                      data: (events) => events.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Nenhum evento nos próximos 6 meses', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            )
                          : Column(children: events.map((e) => _TimelineRow(event: e)).toList()),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Erro: $e'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = summary.savingsPercent.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
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
                    color: AppColors.accentPrimary,
                  ),
                ),
                Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO DISPONÍVEL', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(
                  'R\$${summary.balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.color, this.value, this.displayText, this.subtitle});
  final String label;
  final double? value;
  final String? displayText;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            displayText ?? 'R\$${value!.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});
  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final isTransaction = event is TransactionTimelineEvent;
    final icon = isTransaction ? Icons.receipt_long_outlined : planSavingsIcon;
    final title = isTransaction ? (event as TransactionTimelineEvent).title : (event as PlanMilestoneTimelineEvent).title;
    final amount = isTransaction ? (event as TransactionTimelineEvent).amount : (event as PlanMilestoneTimelineEvent).targetAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${event.date.day}/${event.date.month}/${event.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('R\$${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
