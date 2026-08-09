// mobile/lib/widgets/plan_contribution_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/plans_provider.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/money_input_formatter.dart';
import 'package:mobile/widgets/glass_card.dart';

Future<void> showPlanContributionSheet(
  BuildContext context,
  WidgetRef ref, {
  required int planId,
  required ContributionType type,
}) {
  final currency = SettingsScope.of(context).currency;
  final decimalSeparator = SettingsScope.of(context).decimalSeparator;
  final amountController = TextEditingController();
  final isDeposit = type == ContributionType.deposit;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: GlassCard(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LiquidGlassRadius.card),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDeposit ? 'Depositar' : 'Retirar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: LiquidGlassColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  MoneyInputFormatter(currency, decimalSeparator),
                ],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: '${currencySymbol(currency)} ',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDeposit
                      ? LiquidGlassColors.positive
                      : LiquidGlassColors.negative,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final amount = parseMoneyInput(
                    amountController.text,
                    currency,
                    decimalSeparator,
                  );
                  if (amount > 0) {
                    await ref
                        .read(plansRepositoryProvider)
                        .addContribution(
                          planId: planId,
                          amount: amount,
                          type: type,
                          date: DateTime.now(),
                        );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  isDeposit ? 'Confirmar depósito' : 'Confirmar retirada',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
