import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/money_input_formatter.dart';

Future<void> showTransactionFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Transaction? existing,
}) {
  final descController = TextEditingController(
    text: existing?.description ?? '',
  );
  final currency = SettingsScope.of(context).currency;
  final amountController = TextEditingController(
    text: existing != null
        ? formatCents((existing.amount * 100).round(), currency)
        : '',
  );
  var date = existing?.date ?? DateTime.now();
  var type = existing?.type ?? TransactionType.expense;
  var categoryId = existing?.categoryId;
  var installments = 1;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Consumer(
      builder: (ctx, consumerRef, _) {
        final categoriesAsync = consumerRef.watch(categoriesProvider);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final categories = categoriesAsync.value ?? [];
                final filteredCategories = categories
                    .where(
                      (c) =>
                          c.category.type ==
                          (type == TransactionType.expense
                              ? CategoryType.expense
                              : CategoryType.income),
                    )
                    .toList();
                if (categoryId != null &&
                    !filteredCategories.any(
                      (c) => c.category.id == categoryId,
                    )) {
                  categoryId = null;
                }
                final isExpense = type == TransactionType.expense;
                final amount = parseMoneyInput(amountController.text, currency);
                final perInstallment = installments > 0
                    ? amount / installments
                    : amount;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TypeToggle(
                        isExpense: isExpense,
                        onChanged: (expense) => setState(() {
                          type = expense
                              ? TransactionType.expense
                              : TransactionType.income;
                        }),
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel('Descrição'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel('Valor'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MoneyInputFormatter(currency)],
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '${currencySymbol(currency)} ',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel('Categoria'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: categoryId,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sem categoria'),
                          ),
                          ...filteredCategories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.category.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          '0xFF${c.category.color.substring(1)}',
                                        ),
                                      ),
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
                      const SizedBox(height: 20),
                      _FieldLabel('Data'),
                      const SizedBox(height: 8),
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
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(formatFullDate(date)),
                        ),
                      ),
                      if (existing == null) ...[
                        const SizedBox(height: 20),
                        _InstallmentsCard(
                          installments: installments,
                          perInstallment: perInstallment,
                          onChanged: (v) => setState(() => installments = v),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final repo = ref.read(transactionsRepositoryProvider);
                          final savedAmount = parseMoneyInput(
                            amountController.text,
                            currency,
                          );
                          if (existing == null) {
                            await repo.create(
                              description: descController.text,
                              amount: savedAmount,
                              date: date,
                              type: type,
                              categoryId: categoryId,
                              installmentsTotal: installments > 1
                                  ? installments
                                  : null,
                            );
                          } else {
                            await repo.update(
                              existing.id,
                              description: descController.text,
                              amount: savedAmount,
                              date: date,
                              categoryId: Value(categoryId),
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
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

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.isExpense, required this.onChanged});

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isExpense
                      ? AppColors.accentDanger
                      : AppColors.accentSuccess,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ToggleOption(
                  label: 'Despesa',
                  icon: Icons.arrow_downward,
                  active: isExpense,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _ToggleOption(
                  label: 'Receita',
                  icon: Icons.arrow_upward,
                  active: !isExpense,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.bgPrimary : AppColors.textSecondary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: active
                        ? AppColors.bgPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallmentsCard extends StatelessWidget {
  const _InstallmentsCard({
    required this.installments,
    required this.perInstallment,
    required this.onChanged,
  });

  final int installments;
  final double perInstallment;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$installments',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentPrimary,
                ),
              ),
              const Text(
                'x',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (installments > 1)
                Text(
                  'de ${formatMoney(perInstallment, SettingsScope.of(context).currency)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPrimary,
              inactiveTrackColor: AppColors.accentPrimary.withValues(
                alpha: 0.2,
              ),
              thumbColor: AppColors.accentPrimary,
              overlayColor: AppColors.accentPrimary.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            ),
            child: Slider(
              value: installments.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '1x',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '24x',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
