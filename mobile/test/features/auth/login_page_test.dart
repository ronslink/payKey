import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('should display all UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header elements
      expect(find.text('PayKey'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);

      // Verify input fields exist
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Verify Sign In button exists
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should have two text form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify exactly 2 form fields (email and password)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should have Sign In button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sign In button
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);
    });

    testWidgets('should have Sign Up button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sign Up button
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should display demo credentials', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify demo credentials section
      expect(find.text('Demo Credentials'), findsOneWidget);
    });

    testWidgets('should be able to enter text in fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all TextFormFields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      // Enter text in first field (email)
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pumpAndSettle();

      // Enter text in second field (password)
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should have clickable Sign In button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap Sign In button
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);

      // Tapping should not throw
      await tester.tap(signInButton);
      await tester.pumpAndSettle();
    });
  });
}
