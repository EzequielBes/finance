import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/category_icons.dart';
import 'package:mobile/widgets/category_form_sheet.dart';
import 'package:mobile/widgets/glass_card.dart';
import 'package:mobile/widgets/month_selector.dart';
import 'package:mobile/data/database.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<CategoryWithUsage>? _categories;
  Object? _error;
  StreamSubscription<List<CategoryWithUsage>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription?.cancel();
    final repo = ref.read(categoriesRepositoryProvider);
    _subscription = repo
        .watchAll(_month)
        .listen(
          (categories) {
            if (!mounted) return;
            setState(() {
              _categories = categories;
              _error = null;
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() => _error = e);
          },
        );
  }

  void _onMonthChanged(DateTime month) {
    setState(() => _month = month);
    _subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: _error != null
          ? Center(child: Text('Erro: $_error'))
          : categories == null
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final expenses = categories
                    .where(
                      (item) =>
                          item.category.type == CategoryType.expense &&
                          item.category.isActive,
                    )
                    .toList();
                final used = expenses.fold<double>(
                  0,
                  (sum, item) => sum + item.currentMonthUsage,
                );
                final limits = expenses.fold<double>(
                  0,
                  (sum, item) => sum + (item.category.monthlyLimit ?? 0),
                );
                return CustomScrollView(
                  slivers: [
                    SliverSafeArea(
                      bottom: false,
                      sliver: SliverToBoxAdapter(
                        child: MonthSelector(
                          month: _month,
                          onChanged: _onMonthChanged,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      sliver: SliverList.list(
                        children: [
                          _ExpenseSummary(
                            used: used,
                            limits: limits,
                            month: _month,
                          ),
                          for (final item in expenses)
                            _CategoryCard(
                              item: item,
                              onTap: () => showCategoryFormSheet(
                                context,
                                ref,
                                existing: item.category,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, required this.onTap});

  final CategoryWithUsage item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final color = Color(int.parse('0xFF${category.color.substring(1)}'));
    final limit = category.monthlyLimit;
    final percent = limit != null && limit > 0
        ? (item.currentMonthUsage / limit * 100)
        : null;

    Color progressColor = LiquidGlassColors.positive;
    if (percent != null) {
      if (percent > 100) {
        progressColor = LiquidGlassColors.negative;
      } else if (percent >= 80) {
        progressColor = LiquidGlassColors.accentPrimary;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: GlassCard(
          intensity: GlassIntensity.opaque,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(
                      categoryIconFor(category.icon),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: LiquidGlassColors.textPrimary,
                          ),
                        ),
                        Text(
                          limit == null
                              ? 'Sem limite definido'
                              : 'Limite mensal',
                          style: const TextStyle(
                            fontSize: 11,
                            color: LiquidGlassColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        limit != null
                            ? '${formatMoney(item.currentMonthUsage, SettingsScope.of(context).currency, SettingsScope.of(context).decimalSeparator)} / ${formatMoney(limit, SettingsScope.of(context).currency, SettingsScope.of(context).decimalSeparator)}'
                            : 'sem limite',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: LiquidGlassColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (percent != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: progressColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  percent > 100
                      ? '${percent.toStringAsFixed(0)}% usado — acima do limite'
                      : '${percent.toStringAsFixed(0)}% usado',
                  style: TextStyle(fontSize: 11, color: progressColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({
    required this.used,
    required this.limits,
    required this.month,
  });

  final double used;
  final double limits;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final percent = limits > 0 ? (used / limits * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GASTO EM ${formatMonth(month)}',
              style: const TextStyle(
                color: LiquidGlassColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formatMoney(
                used,
                SettingsScope.of(context).currency,
                SettingsScope.of(context).decimalSeparator,
              ),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            if (limits > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (percent / 100).clamp(0, 1),
                  minHeight: 7,
                  color: percent > 90
                      ? LiquidGlassColors.negative
                      : LiquidGlassColors.accentPrimary,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${percent.toStringAsFixed(0)}% dos limites definidos',
                style: const TextStyle(
                  color: LiquidGlassColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
