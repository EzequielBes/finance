import 'package:flutter/material.dart';
import 'package:mobile/screens/categories_screen.dart';
import 'package:mobile/screens/dashboard_screen.dart';
import 'package:mobile/screens/movements_screen.dart';
import 'package:mobile/screens/plans_screen.dart';
import 'package:mobile/theme/plan_icons.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    MovementsScreen(),
    CategoriesScreen(),
    PlansScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_rounded),
            label: 'Movimentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Despesas',
          ),
          NavigationDestination(icon: Icon(planSavingsIcon), label: 'Planos'),
        ],
      ),
    );
  }
}
