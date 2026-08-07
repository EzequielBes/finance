import 'package:flutter/material.dart';
import 'package:mobile/screens/income_screen.dart';
import 'package:mobile/screens/transactions_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/month_selector.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: MonthSelector(
                month: _month,
                onChanged: (month) => setState(() => _month = month),
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
                  TransactionsScreen(embedded: true, selectedMonth: _month),
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
