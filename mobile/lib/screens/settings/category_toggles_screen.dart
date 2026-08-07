// mobile/lib/screens/settings/category_toggles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/category_icons.dart';

class CategoryTogglesScreen extends ConsumerWidget {
  const CategoryTogglesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias ativas')),
      body: categoriesAsync.when(
        data: (categories) {
          final expenses = categories
              .where((c) => c.category.type == CategoryType.expense)
              .toList();
          final income = categories
              .where((c) => c.category.type == CategoryType.income)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _SectionLabel('Despesas'),
              for (final item in expenses)
                _CategoryToggleTile(item: item, ref: ref),
              const SizedBox(height: 16),
              const _SectionLabel('Receitas'),
              for (final item in income)
                _CategoryToggleTile(item: item, ref: ref),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CategoryToggleTile extends StatelessWidget {
  const _CategoryToggleTile({required this.item, required this.ref});

  final CategoryWithUsage item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final color = Color(int.parse('0xFF${category.color.substring(1)}'));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(categoryIconFor(category.icon), color: color, size: 16),
        ),
        title: Text(category.name),
        value: category.isActive,
        activeThumbColor: AppColors.accentPrimary,
        onChanged: (value) {
          ref
              .read(categoriesRepositoryProvider)
              .setActive(category.id, value);
        },
      ),
    );
  }
}
