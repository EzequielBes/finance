import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/pill_button.dart';

void main() {
  testWidgets('calls onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PillButton(label: 'Importar', onPressed: () => tapped = true),
      ),
    );

    await tester.tap(find.text('Importar'));
    expect(tapped, isTrue);
  });

  testWidgets('is disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PillButton(label: 'Importar', onPressed: null),
      ),
    );

    final semantics = tester.getSemantics(find.byType(PillButton));
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
  });

  testWidgets('meets the 48dp minimum touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PillButton(label: 'Importar', onPressed: () {}),
      ),
    );

    final size = tester.getSize(find.byType(PillButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('selected state exposes Semantics.selected and heavier font weight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PillButton(label: 'Categoria', selected: true, onPressed: () {}),
      ),
    );

    final semantics = tester.getSemantics(find.byType(PillButton));
    expect(semantics.getSemanticsData().hasFlag(SemanticsFlag.isSelected), isTrue);

    final text = tester.widget<Text>(find.text('Categoria'));
    expect(text.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('unselected state uses normal font weight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PillButton(label: 'Categoria', onPressed: () {}),
      ),
    );

    final text = tester.widget<Text>(find.text('Categoria'));
    expect(text.style?.fontWeight, FontWeight.w500);
  });

  testWidgets('does not expand to fill available width when wrapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          child: Wrap(
            children: [
              PillButton(label: 'Curto', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(PillButton));
    expect(size.width, lessThan(400));
  });
}
