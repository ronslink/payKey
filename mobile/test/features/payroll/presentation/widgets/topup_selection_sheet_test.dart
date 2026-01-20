
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/widgets/topup_selection_sheet.dart';

void main() {
  group('TopupSelectionSheet Widget Test', () {
    testWidgets('renders all tabs and amount field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TopupSelectionSheet(
            defaultAmount: 1000,
            onMpesaConfirm: (_, __) {},
            onCheckoutConfirm: (_) {},
            onStripeConfirm: (_) {},
          ),
        ),
      ));

      // Verify Tabs
      expect(find.text('M-Pesa'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Global/SEPA'), findsOneWidget);

      // Verify Amount Field
      expect(find.text('Amount to Load'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('Stripe tab triggers onStripeConfirm', (WidgetTester tester) async {
      bool stripeCalled = false;
      double? confirmedAmount;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TopupSelectionSheet(
            defaultAmount: 5000,
            onMpesaConfirm: (_, __) {},
            onCheckoutConfirm: (_) {},
            onStripeConfirm: (amount) {
              stripeCalled = true;
              confirmedAmount = amount;
            },
          ),
        ),
      ));

      // Tap Stripe Tab
      await tester.tap(find.text('Global/SEPA'));
      await tester.pumpAndSettle();

      // Verify Stripe info text
      expect(find.text('Pay with Card, SEPA, or Apple/Google Pay via Stripe.'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Proceed'));
      await tester.pump();

      // Assert
      expect(stripeCalled, isTrue);
      expect(confirmedAmount, 5000);
    });
  });
}
