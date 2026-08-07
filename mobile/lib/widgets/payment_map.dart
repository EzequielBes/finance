import 'package:flutter/material.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';

double paymentGapHeight(int days, int largestGap) {
  if (days <= 0) return 12;
  if (largestGap <= 1) return 22;
  return (18 + (days / largestGap) * 54).clamp(18, 72);
}

class PaymentMap extends StatefulWidget {
  const PaymentMap({super.key, required this.events, this.now});

  final List<TransactionTimelineEvent> events;
  final DateTime? now;

  @override
  State<PaymentMap> createState() => _PaymentMapState();
}

class _PaymentMapState extends State<PaymentMap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final today = widget.now ?? DateTime.now();
    final events = [...widget.events]..sort((a, b) => a.date.compareTo(b.date));
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'Nenhum pagamento previsto para este mês.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final visible = _expanded ? events : events.take(5).toList();
    final gaps = <int>[];
    var previous = DateTime(today.year, today.month, today.day);
    for (final event in visible) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      gaps.add(date.difference(previous).inDays.clamp(0, 31));
      previous = date;
    }
    final largestGap = gaps.fold<int>(
      1,
      (largest, gap) => gap > largest ? gap : largest,
    );

    return Column(
      children: [
        const _TodayMarker(),
        for (var i = 0; i < visible.length; i++)
          _PaymentMarker(
            event: visible[i],
            gapDays: gaps[i],
            largestGap: largestGap,
          ),
        if (events.length > 5)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _expanded
                  ? 'Mostrar só os próximos'
                  : 'Ver todos os ${events.length} pagamentos',
            ),
          ),
      ],
    );
  }
}

class _TodayMarker extends StatelessWidget {
  const _TodayMarker();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 34, child: Center(child: _MapDot(active: true))),
        SizedBox(width: 10),
        Text(
          'Hoje',
          style: TextStyle(
            color: AppColors.accentPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentMarker extends StatelessWidget {
  const _PaymentMarker({
    required this.event,
    required this.gapDays,
    required this.largestGap,
  });

  final TransactionTimelineEvent event;
  final int gapDays;
  final int largestGap;

  @override
  Widget build(BuildContext context) {
    final gapHeight = paymentGapHeight(gapDays, largestGap);
    return Column(
      children: [
        SizedBox(
          height: gapHeight,
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(width: 1, color: AppColors.border),
                    ),
                    if (gapDays >= 4)
                      const Text(
                        '···',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                          height: 0.7,
                        ),
                      ),
                    Expanded(
                      child: Container(width: 1, color: AppColors.border),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                gapDays == 0
                    ? 'mesmo dia'
                    : gapDays == 1
                    ? 'amanhã'
                    : 'em $gapDays dias',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 34, child: Center(child: _MapDot())),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${event.date.day}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _month(event.date.month),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              event.categoryName ?? 'Pagamento programado',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(
                          event.amount,
                          SettingsScope.of(context).currency,
                        ),
                        style: const TextStyle(
                          color: AppColors.accentDanger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _month(int month) => const [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ][month - 1];
}

class _MapDot extends StatelessWidget {
  const _MapDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 13 : 11,
      height: active ? 13 : 11,
      decoration: BoxDecoration(
        color: active ? AppColors.accentPrimary : AppColors.bgCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentPrimary, width: 2),
      ),
    );
  }
}
