import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.categories});
  final List<CategoryExpenseSummary> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Sem gastos este mês',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(painter: _DonutPainter(categories: categories)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.take(6).map((c) {
              final color = Color(int.parse('0xFF${c.color.substring(1)}'));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${c.name} · ${formatMoney(c.total, SettingsScope.of(context).currency)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.categories});
  final List<CategoryExpenseSummary> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    var startAngle = -math.pi / 2;
    for (final cat in categories) {
      final sweepAngle = (cat.percent / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = Color(int.parse('0xFF${cat.color.substring(1)}'))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories;
}
