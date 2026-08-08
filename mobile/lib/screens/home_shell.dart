import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/screens/categories_screen.dart';
import 'package:mobile/screens/dashboard_screen.dart';
import 'package:mobile/screens/movements_screen.dart';
import 'package:mobile/screens/plans_screen.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/theme/plan_icons.dart';
import 'package:mobile/widgets/page_dots_indicator.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _HomeShellState extends State<HomeShell> {
  final _pageController = PageController();
  int _index = 0;

  static const _screens = [
    _KeepAlivePage(child: DashboardScreen()),
    _KeepAlivePage(child: MovementsScreen()),
    _KeepAlivePage(child: CategoriesScreen()),
    _KeepAlivePage(child: PlansScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _index) {
      setState(() => _index = rounded);
    }
  }

  void _navigateTo(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    _pageController.animateToPage(
      index,
      duration: reducedMotion ? Duration.zero : LiquidGlassMotion.navigation,
      curve: LiquidGlassMotion.curveEnter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PageDotsIndicator(
              controller: _pageController,
              pageCount: _screens.length,
            ),
          ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _navigateTo,
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
        ],
      ),
    );
  }
}
