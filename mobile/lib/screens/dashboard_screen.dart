import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/widgets/payment_map.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final timelineAsync = ref.watch(dashboardTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_monthName(DateTime.now())),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => _showCurrencySettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FinancialHealthCard(summary: summary),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Receitas',
                      value: summary.totalIncome,
                      color: AppColors.accentSuccess,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      label: 'Despesas',
                      value: summary.totalExpense,
                      color: AppColors.accentDanger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _SectionHeader(
                title: 'Rota de pagamentos',
                subtitle: 'Próximos pagamentos deste mês',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: timelineAsync.when(
                  data: (events) {
                    final now = DateTime.now();
                    final payments = events
                        .whereType<TransactionTimelineEvent>()
                        .where(
                          (event) =>
                              event.transactionType ==
                                  TransactionType.expense &&
                              event.date.year == now.year &&
                              event.date.month == now.month,
                        )
                        .toList();
                    return PaymentMap(events: payments);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Text('Não foi possível carregar os pagamentos: $e'),
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

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final spentPercent = summary.totalIncome > 0
        ? summary.totalExpense / summary.totalIncome * 100
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF30261F), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAÚDE FINANCEIRA',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(142),
                      painter: _SpendingDonutPainter(
                        categories: summary.byCategory,
                        totalIncome: summary.totalIncome,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.totalIncome > 0
                              ? '${spentPercent.toStringAsFixed(0)}%'
                              : '--',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          summary.totalIncome > 0 ? 'gasto' : 'sem renda',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo disponível',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(
                          summary.balance,
                          SettingsScope.of(context).currency,
                        ),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      spentPercent <= 70
                          ? 'Seus gastos estão sob controle.'
                          : spentPercent <= 90
                          ? 'Atenção ao restante do mês.'
                          : 'Você está perto do limite mensal.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.byCategory.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 10),
            for (final category in summary.byCategory.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('0xFF${category.color.substring(1)}'),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 155),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_percentageOfIncome(category.total, summary.totalIncome)} · ${formatMoney(category.total, SettingsScope.of(context).currency)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              formatMoney(value, SettingsScope.of(context).currency),
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingDonutPainter extends CustomPainter {
  const _SpendingDonutPainter({
    required this.categories,
    required this.totalIncome,
  });

  final List<CategoryExpenseSummary> categories;
  final double totalIncome;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide / 2 - 8,
    );
    const width = 14.0;
    final background = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawArc(rect, 0, math.pi * 2, false, background);
    if (totalIncome <= 0) return;

    var start = -math.pi / 2;
    for (final category in categories) {
      final remaining = math.pi * 1.5 - start;
      if (remaining <= 0) break;
      final sweep = math.min(
        (category.total / totalIncome).clamp(0.0, 1.0) * math.pi * 2,
        remaining,
      );
      final paint = Paint()
        ..color = Color(int.parse('0xFF${category.color.substring(1)}'))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingDonutPainter oldDelegate) =>
      oldDelegate.categories != categories ||
      oldDelegate.totalIncome != totalIncome;
}

String _monthName(DateTime date) =>
    '${const ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'][date.month - 1]} ${date.year}';

String _percentageOfIncome(double value, double income) {
  if (income <= 0 || value <= 0) return '0%';
  final percent = value / income * 100;
  return percent < 1
      ? '${percent.toStringAsFixed(1)}%'
      : '${percent.toStringAsFixed(0)}%';
}

Future<void> _showCurrencySettings(BuildContext context) {
  final settings = SettingsScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Moeda do aplicativo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Altera a unidade exibida. Os valores não são convertidos por cotação.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final currency in AppCurrency.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(currencyLabel(currency)),
                leading: CircleAvatar(
                  backgroundColor: AppColors.bgInput,
                  child: Text(
                    currencySymbol(currency),
                    style: const TextStyle(
                      color: AppColors.accentPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                trailing: settings.currency == currency
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.accentPrimary,
                      )
                    : null,
                onTap: () async {
                  await settings.setCurrency(currency);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
