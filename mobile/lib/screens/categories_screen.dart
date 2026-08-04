import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/categories_provider.dart';
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
          itemCount: categories.length,
          itemBuilder: (ctx, i) {
            final c = categories[i];
            return ListTile(
              title: Text(c.category.name),
              subtitle: c.category.monthlyLimit != null
                  ? Text('Uso: R\$${c.currentMonthUsage.toStringAsFixed(2)} / R\$${c.category.monthlyLimit!.toStringAsFixed(2)}')
                  : Text('Uso: R\$${c.currentMonthUsage.toStringAsFixed(2)}'),
              onTap: () => showCategoryFormSheet(context, ref, existing: c.category),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
