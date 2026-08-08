import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/screens/import_preview_screen.dart';
import 'package:mobile/screens/income_screen.dart';
import 'package:mobile/screens/transactions_screen.dart';
import 'package:mobile/services/import/bank_import_service.dart';
import 'package:mobile/services/import/import_result.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/widgets/month_selector.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _refreshCounter = 0;

  TabController? _tabController;
  int _subTabIndex = 0;

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    setState(() => _subTabIndex = controller.index);
  }

  Future<void> _importStatement() async {
    final picked = await FilePicker.pickFiles(
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
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          if (_tabController != controller) {
            _tabController?.removeListener(_handleTabChange);
            _tabController = controller;
            _tabController!.addListener(_handleTabChange);
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
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
                  dividerColor: LiquidGlassColors.glassBorder,
                  indicatorColor: LiquidGlassColors.accentPrimary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: LiquidGlassColors.textPrimary,
                  unselectedLabelColor: LiquidGlassColors.textSecondary,
                  tabs: [
                    Tab(text: 'Transações'),
                    Tab(text: 'Receitas'),
                  ],
                ),
                Expanded(
                  child: IndexedStack(
                    index: _subTabIndex,
                    children: [
                      TransactionsScreen(
                        key: ValueKey('transactions-$_refreshCounter'),
                        embedded: true,
                        selectedMonth: _month,
                      ),
                      IncomeScreen(
                        key: ValueKey('income-$_refreshCounter'),
                        embedded: true,
                        selectedMonth: _month,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }
}
