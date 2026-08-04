import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/widgets/income_form_sheet.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  List<IncomeEntry> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(incomeRepositoryProvider);
    final result = await repo.watchList();
    setState(() => _items = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showIncomeFormSheet(context, ref);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final e = _items[i];
          return Dismissible(
            key: ValueKey(e.id),
            onDismissed: (_) async {
              await ref.read(incomeRepositoryProvider).remove(e.id);
              _load();
            },
            child: ListTile(
              title: Text(e.source),
              subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year}'),
              trailing: Text('R\$${e.amount.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }
}
