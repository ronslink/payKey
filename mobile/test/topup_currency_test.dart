import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/widgets/topup_selection_sheet.dart';

void main() {
  testWidgets(
    'KES shortfall cannot become an EUR charge when switching methods',
    (tester) async {
      double? chargedEur;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => TopupSelectionSheet.show(
                  context: context,
                  shortfall: 1000,
                  onMpesaConfirm: (_, _) {},
                  onCheckoutConfirm: (_) {},
                  onStripeConfirm: (amount) => chargedEur = amount,
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

      await tester.tap(find.text('EUR (Stripe)'));
      await tester.pumpAndSettle();
      final eurField = find.byKey(const ValueKey('topup-amount-EUR'));
      expect(tester.widget<TextField>(eurField).controller!.text, isEmpty);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.enterText(eurField, '10.25');
      await tester.pump();
      expect(find.text('Pay EUR 10.25'), findsOneWidget);
      await tester.tap(find.text('M-Pesa'));
      await tester.pumpAndSettle();
      expect(find.text('Add KES 1000.00'), findsOneWidget);

      await tester.tap(find.text('EUR (Stripe)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pay EUR 10.25'));
      await tester.tap(find.text('Pay EUR 10.25'));
      await tester.pumpAndSettle();
      expect(chargedEur, 10.25);
    },
  );
}
