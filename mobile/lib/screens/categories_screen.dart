import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/category_icons.dart';
import 'package:mobile/widgets/category_form_sheet.dart';
import 'package:mobile/widgets/screen_header.dart';
import 'package:mobile/data/database.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: categoriesAsync.when(
        data: (categories) {
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
                  child: ScreenHeader(
                    title: 'Despesas',
                    subtitle: 'Limites e uso por categoria',
                    badge: '${expenses.length}',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                sliver: SliverList.list(
                  children: [
                    _ExpenseSummary(used: used, limits: limits),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
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

    Color progressColor = AppColors.accentSuccess;
    if (percent != null) {
      if (percent > 100) {
        progressColor = AppColors.accentDanger;
      } else if (percent >= 80) {
        progressColor = AppColors.accentPrimary;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        limit == null ? 'Sem limite definido' : 'Limite mensal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
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
                        color: AppColors.textSecondary,
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
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({required this.used, required this.limits});

  final double used;
  final double limits;

  @override
  Widget build(BuildContext context) {
    final percent = limits > 0 ? (used / limits * 100) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30261F), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GASTO NESTE MÊS',
            style: TextStyle(
              color: AppColors.textSecondary,
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
                    ? AppColors.accentDanger
                    : AppColors.accentPrimary,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${percent.toStringAsFixed(0)}% dos limites definidos',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
