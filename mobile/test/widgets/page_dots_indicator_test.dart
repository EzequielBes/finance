import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/page_dots_indicator.dart';

void main() {
  testWidgets('renders one dot per page', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: PageDotsIndicator(controller: controller, pageCount: 4),
      ),
    );

    expect(find.byType(Container), findsNWidgets(4));
  });

  testWidgets('dot width interpolates continuously with fractional page position',
      (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView(
                controller: controller,
                children: const [Placeholder(), Placeholder()],
              ),
            ),
            PageDotsIndicator(controller: controller, pageCount: 2),
          ],
        ),
      ),
    );

    // Drive the controller to a fractional position between page 0 and 1
    // via a real PageView so `controller.page` reports genuine mid-transition
    // fractional state.
    controller.animateTo(
      controller.position.viewportDimension * 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.constraints != null)
        .toList();
    final widths = containers
        .map((c) => c.constraints!.maxWidth)
        .whereType<double>()
        .toList();

    // Mid-transition, at least one dot should be partially active (neither
    // fully collapsed to 6 nor fully expanded to 20) — this is the behavior
    // that was broken before the fix (binary snap meant every dot was
    // either fully inactive or fully active, never in between).
    expect(widths.any((w) => w > 6 && w < 20), isTrue);
  });
}
