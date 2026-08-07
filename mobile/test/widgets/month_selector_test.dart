import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/month_selector.dart';

void main() {
  testWidgets('moves to the previous and next month', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(MaterialApp(home: MonthSelector(month: DateTime(2026, 1), onChanged: (month) => selected = month)));

    await tester.tap(find.byTooltip('Mês anterior'));
    expect(selected, DateTime(2025, 12));

    await tester.tap(find.byTooltip('Próximo mês'));
    expect(selected, DateTime(2026, 2));
  });
}
