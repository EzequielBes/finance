import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/money_input_formatter.dart';

Future<void> showIncomeFormSheet(
  BuildContext context,
  WidgetRef ref, {
  IncomeEntry? existing,
}) {
  final currency = SettingsScope.of(context).currency;
  final sourceController = TextEditingController(text: existing?.source ?? '');
  final amountController = TextEditingController(
    text: existing != null
        ? formatCents((existing.amount * 100).round(), currency)
        : '',
  );
  var date = existing?.date ?? DateTime.now();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                existing == null ? 'Nova receita' : 'Editar receita',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Fonte da receita',
                  hintText: 'Ex.: Salário',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter(currency)],
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: '${currencySymbol(currency)} ',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    formatFullDate(date, SettingsScope.of(ctx).dateFormat),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(incomeRepositoryProvider);
                  final amount = parseMoneyInput(
                    amountController.text,
                    currency,
                  );
                  if (existing == null) {
                    await repo.create(
                      amount: amount,
                      date: date,
                      source: sourceController.text,
                    );
                  } else {
                    await repo.update(
                      existing.id,
                      amount: amount,
                      date: date,
                      source: sourceController.text,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  existing == null ? 'Adicionar receita' : 'Salvar alterações',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
