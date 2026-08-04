import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';

Future<void> showCategoryFormSheet(BuildContext context, WidgetRef ref, {Category? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  var type = existing?.type ?? CategoryType.expense;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome')),
              DropdownButton<CategoryType>(
                value: type,
                items: CategoryType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t == CategoryType.expense ? 'Despesa' : 'Receita')))
                    .toList(),
                onChanged: (v) => setState(() => type = v!),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(categoriesRepositoryProvider);
                  if (existing == null) {
                    await repo.create(name: nameController.text, type: type, color: '#c17a54', icon: 'tag');
                  } else {
                    await repo.update(existing.id, name: nameController.text);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
