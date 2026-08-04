import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';

Future<void> showTransactionFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Transaction? existing,
}) {
  final descController = TextEditingController(text: existing?.description ?? '');
  final amountController = TextEditingController(
    text: existing != null ? existing.amount.toStringAsFixed(2) : '',
  );
  var date = existing?.date ?? DateTime.now();
  var type = existing?.type ?? TransactionType.expense;
  var categoryId = existing?.categoryId;
  var installments = 1;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, consumerRef, _) {
        final categoriesAsync = consumerRef.watch(categoriesProvider);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final categories = categoriesAsync.value ?? [];
                final filteredCategories = categories
                    .where((c) => c.category.type == (type == TransactionType.expense ? CategoryType.expense : CategoryType.income))
                    .toList();
                if (categoryId != null && !filteredCategories.any((c) => c.category.id == categoryId)) {
                  categoryId = null;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(value: TransactionType.expense, label: Text('Despesa')),
                        ButtonSegment(value: TransactionType.income, label: Text('Receita')),
                      ],
                      selected: {type},
                      onSelectionChanged: (selection) => setState(() => type = selection.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição')),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Valor'),
                    ),
                    DropdownButtonFormField<int?>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Sem categoria')),
                        ...filteredCategories.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.category.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${c.category.color.substring(1)}')),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(c.category.name),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => categoryId = v),
                    ),
                    if (existing == null) ...[
                      Row(
                        children: [
                          const Text('Parcelas:'),
                          Expanded(
                            child: Slider(
                              value: installments.toDouble(),
                              min: 1,
                              max: 24,
                              divisions: 23,
                              label: '$installments',
                              onChanged: (v) => setState(() => installments = v.toInt()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    ElevatedButton(
                      onPressed: () async {
                        final repo = ref.read(transactionsRepositoryProvider);
                        final amount = double.tryParse(amountController.text) ?? 0;
                        if (existing == null) {
                          await repo.create(
                            description: descController.text,
                            amount: amount,
                            date: date,
                            type: type,
                            categoryId: categoryId,
                            installmentsTotal: installments > 1 ? installments : null,
                          );
                        } else {
                          await repo.update(
                            existing.id,
                            description: descController.text,
                            amount: amount,
                            date: date,
                            categoryId: categoryId,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ),
  );
}
