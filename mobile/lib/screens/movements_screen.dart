import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/screens/import_preview_screen.dart';
import 'package:mobile/screens/income_screen.dart';
import 'package:mobile/screens/transactions_screen.dart';
import 'package:mobile/services/import/bank_import_service.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/month_selector.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _refreshCounter = 0;

  Future<void> _importStatement() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.files.single.path == null) return;

    ImportResult? result;
    try {
      final content = await File(picked.files.single.path!).readAsString();
      result = await const BankImportService().parse(content);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler o arquivo')),
      );
      return;
    }

    if (!mounted) return;
    final matched = result;
    if (matched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato não reconhecido')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImportPreviewScreen(result: matched)),
    );
    if (!mounted) return;
    setState(() => _refreshCounter++);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: MonthSelector(
                      month: _month,
                      onChanged: (month) => setState(() => _month = month),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file_outlined),
                    tooltip: 'Importar extrato',
                    onPressed: _importStatement,
                  ),
                ],
              ),
            ),
            const TabBar(
              dividerColor: AppColors.border,
              indicatorColor: AppColors.accentPrimary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'Transações'),
                Tab(text: 'Receitas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TransactionsScreen(
                    key: ValueKey('transactions-$_refreshCounter'),
                    embedded: true,
                    selectedMonth: _month,
                  ),
                  IncomeScreen(embedded: true, selectedMonth: _month),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
