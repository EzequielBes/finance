import 'package:flutter/material.dart';
import 'package:mobile/screens/categories_screen.dart';
import 'package:mobile/screens/income_screen.dart';
import 'package:mobile/screens/transactions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    TransactionsScreen(),
    IncomeScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transações'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Receitas'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorias'),
        ],
      ),
    );
  }
}
