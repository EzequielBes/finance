import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/categories_provider.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/repositories/categories_repository.dart';
import 'package:mobile/screens/import_preview_screen.dart';
import 'package:mobile/services/import/parser_dispatcher.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/transaction_card.dart';
import 'package:mobile/widgets/transaction_form_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    this.embedded = false,
    this.selectedMonth,
  });

  final bool embedded;
  final DateTime? selectedMonth;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Transaction> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(transactionsRepositoryProvider);
    final result = await repo.watchList(
      month: widget.selectedMonth?.month,
      year: widget.selectedMonth?.year,
      type: TransactionType.expense,
    );
    if (!mounted) return;
    setState(
      () => _items = result.items
          .where((item) => item.type == TransactionType.expense)
          .toList(),
    );
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) _load();
  }

  List<TransactionGroup> _groupByInstallment(
    List<Transaction> items,
    Map<int, Category> categoriesById,
  ) {
    final grouped = <String, List<Transaction>>{};
    final ungrouped = <Transaction>[];
    for (final t in items) {
      final groupId = t.installmentGroupId;
      if (groupId != null) {
        grouped.putIfAbsent(groupId, () => []).add(t);
      } else {
        ungrouped.add(t);
      }
    }
    final groups = <TransactionGroup>[
      ...grouped.values.map(
        (list) => TransactionGroup(
          installments: list,
          category: list.first.categoryId != null
              ? categoriesById[list.first.categoryId]
              : null,
        ),
      ),
      ...ungrouped.map(
        (t) => TransactionGroup(
          installments: [t],
          category: t.categoryId != null ? categoriesById[t.categoryId] : null,
        ),
      ),
    ];
    groups.sort((a, b) => b.current.date.compareTo(a.current.date));
    return groups;
  }

  Future<void> _importStatement() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final content = await File(picked.files.single.path!).readAsString();
    final result = dispatchImport(content);

    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato não reconhecido')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImportPreviewScreen(result: result)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoriesById = <int, Category>{
      for (final c in categoriesAsync.value ?? const <CategoryWithUsage>[])
        c.category.id: c.category,
    };
    final groups = _groupByInstallment(_items, categoriesById);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Transações'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  tooltip: 'Importar extrato',
                  onPressed: _importStatement,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showTransactionFormSheet(context, ref);
          _load();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
        itemCount: groups.length,
        itemBuilder: (ctx, i) {
          final group = groups[i];
          return Slidable(
            key: ValueKey(group.current.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(transactionsRepositoryProvider)
                        .remove(group.current.id);
                    _load();
                  },
                  backgroundColor: AppColors.accentDanger,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Excluir',
                ),
              ],
            ),
            child: TransactionCard(
              group: group,
              onTapEdit: (transaction) async {
                await showTransactionFormSheet(
                  context,
                  ref,
                  existing: transaction,
                );
                _load();
              },
              onDelete: () async {
                await ref
                    .read(transactionsRepositoryProvider)
                    .remove(group.current.id);
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}
