import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/income_provider.dart';

Future<void> showIncomeFormSheet(
  BuildContext context,
  WidgetRef ref, {
  IncomeEntry? existing,
}) {
  final sourceController = TextEditingController(text: existing?.source ?? '');
  final amountController = TextEditingController(
    text: existing != null ? existing.amount.toStringAsFixed(2) : '',
  );
  var date = existing?.date ?? DateTime.now();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sourceController, decoration: const InputDecoration(labelText: 'Fonte')),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(incomeRepositoryProvider);
                final amount = double.tryParse(amountController.text) ?? 0;
                if (existing == null) {
                  await repo.create(amount: amount, date: date, source: sourceController.text);
                } else {
                  await repo.update(existing.id, amount: amount, date: date, source: sourceController.text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    ),
  );
}
