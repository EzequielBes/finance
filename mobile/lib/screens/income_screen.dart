import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/theme/app_theme.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final e = _items[i];
          return Slidable(
            key: ValueKey(e.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    await ref.read(incomeRepositoryProvider).remove(e.id);
                    _load();
                  },
                  backgroundColor: AppColors.accentDanger,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Excluir',
                ),
              ],
            ),
            child: _IncomeCard(
              entry: e,
              onTapEdit: () async {
                await showIncomeFormSheet(context, ref, existing: e);
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class _IncomeCard extends StatefulWidget {
  const _IncomeCard({required this.entry, required this.onTapEdit});

  final IncomeEntry entry;
  final VoidCallback onTapEdit;

  @override
  State<_IncomeCard> createState() => _IncomeCardState();
}

class _IncomeCardState extends State<_IncomeCard> {
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return GestureDetector(
      onLongPressStart: (_) {
        _longPressTimer = Timer(const Duration(milliseconds: 1500), widget.onTapEdit);
      },
      onLongPressEnd: (_) => _longPressTimer?.cancel(),
      child: Container(
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.source),
                  Text(
                    '${e.date.day}/${e.date.month}/${e.date.year}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'R\$${e.amount.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accentSuccess, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
