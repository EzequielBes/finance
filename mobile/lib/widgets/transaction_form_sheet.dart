import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/transactions_provider.dart';

Future<void> showTransactionFormSheet(BuildContext context, WidgetRef ref) {
  final descController = TextEditingController();
  final amountController = TextEditingController();
  var date = DateTime.now();
  var type = TransactionType.expense;
  var installments = 1;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição')),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
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
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(transactionsRepositoryProvider);
                  await repo.create(
                    description: descController.text,
                    amount: double.tryParse(amountController.text) ?? 0,
                    date: date,
                    type: type,
                    installmentsTotal: installments > 1 ? installments : null,
                  );
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
