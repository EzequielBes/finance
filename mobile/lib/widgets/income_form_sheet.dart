import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/income_provider.dart';

Future<void> showIncomeFormSheet(BuildContext context, WidgetRef ref) {
  final sourceController = TextEditingController();
  final amountController = TextEditingController();
  var date = DateTime.now();

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
                await repo.create(
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: date,
                  source: sourceController.text,
                );
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
