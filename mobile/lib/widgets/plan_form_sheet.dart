// mobile/lib/widgets/plan_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/money_input_formatter.dart';

const _planColorPalette = ['#c17a54', '#7a9b7e', '#8a9bb0', '#b8563a'];

Future<void> showPlanFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Plan? existing,
  int? defaultParentPlanId,
}) {
  final currency = SettingsScope.of(context).currency;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final descController = TextEditingController(
    text: existing?.description ?? '',
  );
  final targetController = TextEditingController(
    text: existing != null
        ? formatCents((existing.targetAmount * 100).round(), currency)
        : '',
  );
  final contributionController = TextEditingController(
    text: existing != null
        ? formatCents((existing.monthlyContribution * 100).round(), currency)
        : '',
  );
  var selectedColor = existing?.color ?? _planColorPalette.first;
  var parentPlanId = existing?.parentPlanId ?? defaultParentPlanId;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Consumer(
      builder: (ctx, consumerRef, _) {
        final plansAsync = consumerRef.watch(plansProvider);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final rootPlans = (plansAsync.value ?? [])
                    .map((p) => p.plan)
                    .where((p) => existing == null || p.id != existing.id)
                    .toList();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do plano',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MoneyInputFormatter(currency)],
                        decoration: InputDecoration(
                          labelText: 'Valor alvo',
                          prefixText: '${currencySymbol(currency)} ',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contributionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MoneyInputFormatter(currency)],
                        decoration: InputDecoration(
                          labelText: 'Contribuição mensal',
                          prefixText: '${currencySymbol(currency)} ',
                        ),
                      ),
                      if (existing == null) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          initialValue: parentPlanId,
                          decoration: const InputDecoration(
                            labelText: 'Plano pai (opcional)',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Nenhum (plano raiz)'),
                            ),
                            ...rootPlans
                                .where((p) => p.parentPlanId == null)
                                .map(
                                  (p) => DropdownMenuItem<int?>(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                ),
                          ],
                          onChanged: (v) => setState(() => parentPlanId = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: _planColorPalette.map((hex) {
                          final selected = hex == selectedColor;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedColor = hex),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse('0xFF${hex.substring(1)}'),
                                  ),
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: AppColors.textPrimary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final repo = ref.read(plansRepositoryProvider);
                          final target = parseMoneyInput(
                            targetController.text,
                            currency,
                          );
                          final contribution = parseMoneyInput(
                            contributionController.text,
                            currency,
                          );
                          if (existing == null) {
                            await repo.create(
                              parentPlanId: parentPlanId,
                              name: nameController.text,
                              description: descController.text.isEmpty
                                  ? null
                                  : descController.text,
                              targetAmount: target,
                              monthlyContribution: contribution,
                              color: selectedColor,
                            );
                          } else {
                            await repo.update(
                              existing.id,
                              name: nameController.text,
                              description: descController.text.isEmpty
                                  ? null
                                  : descController.text,
                              targetAmount: target,
                              monthlyContribution: contribution,
                              color: selectedColor,
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
