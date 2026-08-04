import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/category_icons.dart';
import 'package:mobile/widgets/category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemCount: categories.length,
          itemBuilder: (ctx, i) => _CategoryCard(
            item: categories[i],
            onTap: () => showCategoryFormSheet(context, ref, existing: categories[i].category),
          ),
        ),
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
    final percent = limit != null && limit > 0 ? (item.currentMonthUsage / limit * 100) : null;

    Color progressColor = AppColors.accentSuccess;
    if (percent != null) {
      if (percent > 100) {
        progressColor = AppColors.accentDanger;
      } else if (percent >= 80) {
        progressColor = AppColors.accentPrimary;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(categoryIconFor(category.icon), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        category.type.name == 'expense' ? 'Despesa' : 'Receita',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  limit != null
                      ? 'R\$${item.currentMonthUsage.toStringAsFixed(0)} / R\$${limit.toStringAsFixed(0)}'
                      : 'sem limite',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
                percent > 100 ? '${percent.toStringAsFixed(0)}% usado — acima do limite' : '${percent.toStringAsFixed(0)}% usado',
                style: TextStyle(fontSize: 11, color: progressColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
