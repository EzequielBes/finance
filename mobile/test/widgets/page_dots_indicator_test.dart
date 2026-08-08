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

    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
