import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/widgets/topup_selection_sheet.dart';

void main() {
  for (final card in [false, true]) {
    testWidgets(
      card
          ? 'KES card top-up is sent to Stripe'
          : 'M-Pesa is the default KES route',
      (tester) async {
        double? mpesaAmount;
        String? mpesaPhone;
        double? cardAmount;
        String? cardCurrency;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => TopupSelectionSheet.show(
                    context: context,
                    shortfall: 1000,
                    defaultPhone: '0712345678',
                    onMpesaConfirm: (amount, phone) {
                      mpesaAmount = amount;
                      mpesaPhone = phone;
                    },
                    onStripeConfirm: (amount, currency) {
                      cardAmount = amount;
                      cardCurrency = currency;
                    },
                  ),
                  child: const Text('Top up'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Top up'));
        await tester.pumpAndSettle();
        expect(find.text('Add KES 1000.00'), findsOneWidget);
        if (card) {
          await tester.tap(find.text('Card'));
          await tester.pumpAndSettle();
        }
        final confirm = find.text('${card ? 'Pay' : 'Add'} KES 1000.00');
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        if (card) {
          expect(cardAmount, 1000);
          expect(cardCurrency, 'KES');
          expect(mpesaAmount, isNull);
        } else {
          expect(mpesaAmount, 1000);
          expect(mpesaPhone, '0712345678');
          expect(cardAmount, isNull);
        }
      },
    );
  }
}
