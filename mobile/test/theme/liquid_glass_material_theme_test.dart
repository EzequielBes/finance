import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/liquid_glass_material_theme.dart';

void main() {
  testWidgets(
    'a pushed Scaffold without its own backgroundColor is not transparent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLiquidGlassMaterialTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(body: Text('pushed')),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final material = tester
          .widgetList<Material>(find.byType(Material))
          .firstWhere((m) => m.type == MaterialType.canvas);
      expect(material.color?.a, greaterThan(0.0));
    },
  );
}
