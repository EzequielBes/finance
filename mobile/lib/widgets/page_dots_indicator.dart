import 'package:flutter/material.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

class PageDotsIndicator extends StatefulWidget {
  const PageDotsIndicator({
    required this.controller,
    required this.pageCount,
    super.key,
  });

  final PageController controller;
  final int pageCount;

  @override
  State<PageDotsIndicator> createState() => _PageDotsIndicatorState();
}

class _PageDotsIndicatorState extends State<PageDotsIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {});
  }

  double _pageFraction() {
    if (!widget.controller.hasClients || widget.controller.page == null) {
      return widget.controller.initialPage.toDouble();
    }
    return widget.controller.page!;
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pageFraction();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.pageCount, (index) {
        final distance = (currentPage - index).abs().clamp(0.0, 1.0);
        final isActive = distance < 0.5;

        return AnimatedContainer(
          duration: LiquidGlassMotion.stateChange,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? LiquidGlassColors.accentPrimary
                : LiquidGlassColors.textSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
