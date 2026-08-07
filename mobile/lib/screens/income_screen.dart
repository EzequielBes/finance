import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/providers/income_provider.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/widgets/income_form_sheet.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key, this.embedded = false, this.selectedMonth});

  final bool embedded;
  final DateTime? selectedMonth;

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
    final result = await repo.watchList(
      month: widget.selectedMonth?.month,
      year: widget.selectedMonth?.year,
    );
    if (!mounted) return;
    setState(() => _items = result);
  }

  @override
  void didUpdateWidget(covariant IncomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Receitas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showIncomeFormSheet(context, ref);
          _load();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
        itemCount: _items.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _IncomeSummary(total: total, count: _items.length);
          final e = _items[i - 1];
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
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSuccess.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.accentSuccess,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.source,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatFullDate(e.date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+ ${formatMoney(e.amount, SettingsScope.of(context).currency)}',
            style: const TextStyle(
              color: AppColors.accentSuccess,
              fontWeight: FontWeight.bold,
            ),
          ),
          PopupMenuButton<void>(
            tooltip: 'Opções da receita',
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (_) => widget.onTapEdit(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Editar receita')),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeSummary extends StatelessWidget {
  const _IncomeSummary({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263028), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSuccess.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECEBIDO NO PERÍODO',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatMoney(total, SettingsScope.of(context).currency),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$count ${count == 1 ? 'entrada registrada' : 'entradas registradas'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
