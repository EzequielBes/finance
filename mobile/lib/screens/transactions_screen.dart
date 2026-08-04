import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/transactions_provider.dart';
import 'package:mobile/widgets/transaction_form_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

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
    final result = await repo.watchList();
    setState(() => _items = result.items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transações')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showTransactionFormSheet(context, ref);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final t = _items[i];
          return Dismissible(
            key: ValueKey(t.id),
            onDismissed: (_) async {
              await ref.read(transactionsRepositoryProvider).remove(t.id);
              _load();
            },
            child: ListTile(
              title: Text(t.description),
              subtitle: Text('${t.date.day}/${t.date.month}/${t.date.year}'),
              trailing: Text(
                'R\$${t.amount.toStringAsFixed(2)}',
                style: TextStyle(color: t.type == TransactionType.expense ? Colors.redAccent : Colors.greenAccent),
              ),
            ),
          );
        },
      ),
    );
  }
}
