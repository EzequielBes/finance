// mobile/test/widgets/glass_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/widgets/glass_card.dart';

void main() {
  testWidgets('renders BackdropFilter when intensity is full', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlassCard(
          intensity: GlassIntensity.full,
          child: Text('conteúdo'),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('skips BackdropFilter entirely when intensity is opaque', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlassCard(
          intensity: GlassIntensity.opaque,
          child: Text('conteúdo'),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('clips the backdrop filter with ClipRRect using card radius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlassCard(child: Text('conteúdo')),
      ),
    );

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    expect(clip.borderRadius, BorderRadius.circular(LiquidGlassRadius.card));
  });

  testWidgets('forces opaque intensity when MediaQuery.highContrast is true, even if intensity: full was requested', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: const MaterialApp(
          home: GlassCard(
            intensity: GlassIntensity.full,
            child: Text('conteúdo'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('keeps BackdropFilter when highContrast is false and intensity is full', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(highContrast: false),
        child: const MaterialApp(
          home: GlassCard(
            intensity: GlassIntensity.full,
            child: Text('conteúdo'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
