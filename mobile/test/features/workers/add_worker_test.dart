import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/workers/presentation/pages/worker_form_page.dart';

void main() {
  group('WorkerFormPage Widget Tests', () {
    testWidgets('should render page without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page should render without throwing
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have form widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Form widget
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should have multiple text form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have multiple form fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });

    testWidgets('should have submit button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button text is 'Add Worker' for new worker
      expect(find.text('Add Worker'), findsNWidgets(2)); // Title + Button
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkerFormPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
