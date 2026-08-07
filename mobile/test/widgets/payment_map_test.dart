import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';
import 'package:mobile/repositories/dashboard_repository.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/widgets/payment_map.dart';

void main() {
  test('payment gaps preserve the relative distance between dates', () {
    expect(paymentGapHeight(1, 10), lessThan(paymentGapHeight(5, 10)));
    expect(paymentGapHeight(5, 10), lessThan(paymentGapHeight(10, 10)));
  });

  testWidgets('payment map summarizes and expands a busy month', (tester) async {
    final now = DateTime(2026, 8, 7);
    final events = List.generate(7, (index) => TransactionTimelineEvent(
      id: index,
      title: 'Pagamento $index',
      amount: 100,
      date: now.add(Duration(days: index + 1)),
      categoryName: 'Contas fixas',
      transactionType: TransactionType.expense,
      isRecurring: false,
      installmentsTotal: null,
    ));

    await tester.pumpWidget(
      SettingsScope(
        settings: AppSettings(),
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PaymentMap(events: events, now: now)))),
      ),
    );

    expect(find.text('Pagamento 4'), findsOneWidget);
    expect(find.text('Pagamento 5'), findsNothing);

    await tester.tap(find.text('Ver todos os 7 pagamentos'));
    await tester.pump();

    expect(find.text('Pagamento 6'), findsOneWidget);
  });
}
