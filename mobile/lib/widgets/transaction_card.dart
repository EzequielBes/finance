import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';
import 'package:mobile/theme/money_format.dart';
import 'package:mobile/theme/category_icons.dart';

class TransactionGroup {
  TransactionGroup({required this.installments, required this.category});

  final List<Transaction> installments;
  final Category? category;

  bool get isInstallmentGroup => installments.length > 1;

  Transaction get current {
    final sorted = [...installments]..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    Transaction result = sorted.first;
    for (final t in sorted) {
      if (t.date.isAfter(now)) break;
      result = t;
    }
    return result;
  }
}

class TransactionCard extends StatefulWidget {
  const TransactionCard({
    super.key,
    required this.group,
    required this.onTapEdit,
    required this.onDelete,
  });

  final TransactionGroup group;
  final void Function(Transaction toEdit) onTapEdit;
  final VoidCallback onDelete;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _expanded = false;

  Future<void> _edit() async {
    final group = widget.group;
    if (!group.isInstallmentGroup) {
      widget.onTapEdit(group.current);
      return;
    }
    final sorted = [...group.installments]
      ..sort((a, b) => a.date.compareTo(b.date));
    final chosen = await showDialog<Transaction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Qual parcela editar?'),
        children: sorted.map((t) {
          final label =
              '${t.installmentsCurrent}/${t.installmentsTotal} — '
              '${formatShortDate(t.date)} — ${formatMoney(t.amount, SettingsScope.of(context).currency)}';
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, t),
            child: Text(label),
          );
        }).toList(),
      ),
    );
    if (chosen != null) widget.onTapEdit(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final current = group.current;
    final category = group.category;
    final avatarColor = category != null
        ? Color(int.parse('0xFF${category.color.substring(1)}'))
        : AppColors.textPrimary;
    final isExpense = current.type == TransactionType.expense;

    final sorted = [...group.installments]
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: group.isInstallmentGroup
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(_expanded ? 0 : 16),
                bottomRight: Radius.circular(_expanded ? 0 : 16),
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: avatarColor.withValues(alpha: 0.2),
                  child: Icon(
                    categoryIconFor(category?.icon),
                    color: avatarColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              current.description,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (group.isInstallmentGroup) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentPrimary.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${current.installmentsCurrent}/${current.installmentsTotal}',
                                style: const TextStyle(
                                  color: AppColors.accentPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category != null
                            ? '${category.name} · ${formatShortDate(current.date)}'
                            : formatShortDate(current.date),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '− ${formatMoney(current.amount, SettingsScope.of(context).currency)}',
                  style: TextStyle(
                    color: isExpense
                        ? AppColors.accentDanger
                        : AppColors.accentSuccess,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opções da transação',
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) =>
                      value == 'edit' ? _edit() : widget.onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_expanded && group.isInstallmentGroup)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: sorted.map((t) {
                final now = DateTime.now();
                final isPaid = t.date.isBefore(now) && t != current;
                final isCurrent = t == current;
                final statusColor = isCurrent
                    ? AppColors.accentPrimary
                    : (isPaid
                          ? AppColors.accentSuccess
                          : AppColors.textSecondary);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.installmentsCurrent}/${t.installmentsTotal} — ${formatShortDate(t.date)}',
                          style: TextStyle(color: statusColor, fontSize: 12.5),
                        ),
                      ),
                      Text(
                        formatMoney(
                          t.amount,
                          SettingsScope.of(context).currency,
                        ),
                        style: TextStyle(color: statusColor, fontSize: 12.5),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
