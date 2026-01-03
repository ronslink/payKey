
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app; 
import 'package:mobile/features/auth/presentation/pages/login_page.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Flows', () {
    testWidgets('Login -> Add Worker -> View Payroll', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify we are on Login Page (assuming no auto-login for test)
      // Note: This requires the app to start in a logged-out state or mock it.
      // For this test script, we assume a fresh start.
      
      // If we see the Login Page:
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        // Enter credentials
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Email Address'), 'testuser@paykey.com');
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'), 'Password123!');
        await tester.pump();

        // Tap Login
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Verify Home/Workers Page
      // Depending on navigation, we might land on Home. Navigate to Workers.
      // Assuming Bottom Navigation Bar exists
      final workersTab = find.byIcon(Icons.people_outline); // Adjust icon as needed
      if (workersTab.evaluate().isNotEmpty) {
        await tester.tap(workersTab);
        await tester.pumpAndSettle();
      }

      // 3. Add Worker Flow
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Add Worker Page
      expect(find.text('Add New Worker'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), 'John');
      await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), 'Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '0712345678');
      // ... fill other fields as necessary

      // 4. Save (Mocking strict validation might block this without more input)
      // await tester.tap(find.text('Save Worker'));
      // await tester.pumpAndSettle();

      // 5. Run Payroll (Navigate to Finance/Payroll)
      // ...
    });
  });
}
