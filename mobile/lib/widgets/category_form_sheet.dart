import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/category_icons.dart';

const _colorPalette = ['#c17a54', '#7a9b7e', '#8a9bb0', '#b8563a'];

Future<void> showCategoryFormSheet(BuildContext context, WidgetRef ref, {Category? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final limitController = TextEditingController(
    text: existing?.monthlyLimit != null ? existing!.monthlyLimit!.toStringAsFixed(2) : '',
  );
  var type = existing?.type ?? CategoryType.expense;
  var selectedColor = existing?.color ?? _colorPalette.first;
  var selectedIcon = existing?.icon ?? availableIconKeys().first;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel('Nome'),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Tipo'),
                const SizedBox(height: 8),
                DropdownButtonFormField<CategoryType>(
                  initialValue: type,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  items: CategoryType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t == CategoryType.expense ? 'Despesa' : 'Receita')))
                      .toList(),
                  // CategoriesRepository.update() has no `type` parameter, so type is
                  // immutable after creation. Keep the dropdown read-only (onChanged: null)
                  // when editing so it never visually suggests a change that won't be
                  // saved — and so the monthly-limit visibility guard below, which reads
                  // this same `type` variable, can't diverge from what actually persists.
                  onChanged: existing == null ? (v) => setState(() => type = v!) : null,
                ),
                if (type == CategoryType.expense) ...[
                  const SizedBox(height: 20),
                  _FieldLabel('Limite mensal (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _FieldLabel('Cor'),
                const SizedBox(height: 8),
                Row(
                  children: _colorPalette.map((hex) {
                    final selected = hex == selectedColor;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedColor = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xFF${hex.substring(1)}')),
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Ícone'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: availableIconKeys().map((key) {
                    final selected = key == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.bgInput,
                          borderRadius: BorderRadius.circular(10),
                          border: selected ? Border.all(color: AppColors.accentPrimary, width: 1.5) : null,
                        ),
                        child: Icon(
                          categoryIconFor(key),
                          color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final repo = ref.read(categoriesRepositoryProvider);
                    final limitText = limitController.text.trim();
                    final limitValue = type == CategoryType.expense && limitText.isNotEmpty
                        ? double.tryParse(limitText)
                        : null;
                    if (existing == null) {
                      await repo.create(
                        name: nameController.text,
                        type: type,
                        color: selectedColor,
                        icon: selectedIcon,
                        monthlyLimit: limitValue,
                      );
                    } else {
                      await repo.update(
                        existing.id,
                        name: nameController.text,
                        color: selectedColor,
                        icon: selectedIcon,
                        monthlyLimit: Value(limitValue),
                      );
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
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}
