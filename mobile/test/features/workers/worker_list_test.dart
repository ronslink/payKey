import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/workers/presentation/pages/workers_list_page.dart';

void main() {
  group('WorkersListPage Widget Tests', () {
    testWidgets('should render page without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkersListPage(),
          ),
        ),
      );
      
      // Allow async operations to complete
      await tester.pump(const Duration(seconds: 1));

      // Page should render without throwing
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkersListPage(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Verify app bar with title
      expect(find.text('Workers'), findsOneWidget);
    });

    testWidgets('should have action buttons in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkersListPage(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Verify action icons exist
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should have floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WorkersListPage(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
