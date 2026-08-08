import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  const ImportPreviewScreen({required this.result, super.key});

  final ImportResult result;

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  bool _importing = false;

  Future<void> _confirmImport() async {
    setState(() => _importing = true);
    final transactionsRepo = ref.read(transactionsRepositoryProvider);
    final incomeRepo = ref.read(incomeRepositoryProvider);
    final expenseItems = widget.result.transactions
        .where((tx) => tx.type == ParsedTransactionType.expense)
        .toList();
    final incomeItems = widget.result.transactions
        .where((tx) => tx.type == ParsedTransactionType.income)
        .toList();
    try {
      final expenseResult = await transactionsRepo.bulkImport(expenseItems);
      final incomeResult = await incomeRepo.bulkImport(incomeItems);
      if (!mounted) return;
      final inserted = expenseResult.inserted + incomeResult.inserted;
      final skipped = expenseResult.skipped + incomeResult.skipped;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$inserted importadas, $skipped já existiam')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsScope.of(context).currency;
    final decimalSeparator = SettingsScope.of(context).decimalSeparator;
    final transactions = widget.result.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview da Importação')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '${widget.result.bankName} · ${transactions.length} transações encontradas',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (widget.result.hasErrors)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final error in widget.result.errors)
                    Text(
                      error,
                      style: const TextStyle(
                        color: AppColors.accentWarning,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              itemCount: transactions.length,
              itemBuilder: (ctx, i) {
                final tx = transactions[i];
                final isExpense = tx.type == ParsedTransactionType.expense;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tx.description),
                  subtitle: Text(formatShortDate(tx.date)),
                  trailing: Text(
                    '${isExpense ? '−' : '+'} ${formatMoney(tx.amount, currency, decimalSeparator)}',
                    style: TextStyle(
                      color: isExpense
                          ? AppColors.accentDanger
                          : AppColors.accentSuccess,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: transactions.isEmpty || _importing
                ? null
                : _confirmImport,
            child: Text('Importar ${transactions.length} transações'),
          ),
        ),
      ),
    );
  }
}
