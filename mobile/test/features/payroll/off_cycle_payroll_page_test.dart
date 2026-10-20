import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/payroll/data/models/pay_period_model.dart';
import 'package:mobile/features/payroll/presentation/pages/off_cycle_payroll_page.dart';
import 'package:mobile/features/payroll/presentation/providers/pay_period_provider.dart';
import 'package:mockito/mockito.dart';

import 'payroll_workflow_test.mocks.dart';

void main() {
  testWidgets('general run proceeds to review without an unsupported picker', (
    tester,
  ) async {
    final harness = await _pumpPage(tester);

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('All Workers'), findsOneWidget);
    await _submit(tester);

    expect(harness.reviewWorkerIds, isEmpty);
    expect(harness.createdRequest?.isOffCycle, isTrue);
    expect(find.text('Payroll review'), findsOneWidget);
  });

  testWidgets(
    'selected worker remains selected after switching all on and off',
    (tester) async {
      final harness = await _pumpPage(
        tester,
        workerId: 'worker-123',
        workerName: 'Jane Example',
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.onDeleted, isNull);
      expect(find.text('Jane Example'), findsOneWidget);

      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byType(Chip), findsNothing);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Jane Example'), findsOneWidget);
      await _submit(tester);

      expect(harness.reviewWorkerIds, ['worker-123']);
    },
  );

  testWidgets('selected worker can still explicitly switch to all workers', (
    tester,
  ) async {
    final harness = await _pumpPage(tester, workerId: 'worker-123');

    expect(find.text('Selected worker'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await _submit(tester);

    expect(harness.reviewWorkerIds, isEmpty);
  });
}

Future<void> _submit(WidgetTester tester) async {
  final submit = find.ancestor(
    of: find.text('Create & Run Off-Cycle Payroll'),
    matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
  );
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

class _Harness {
  List<String>? reviewWorkerIds;
  CreatePayPeriodRequest? createdRequest;
}

Future<_Harness> _pumpPage(
  WidgetTester tester, {
  String? workerId,
  String? workerName,
}) async {
  final harness = _Harness();
  final repository = MockPayPeriodRepository();
  when(repository.createPayPeriod(any)).thenAnswer((invocation) async {
    final request =
        invocation.positionalArguments.single as CreatePayPeriodRequest;
    harness.createdRequest = request;
    return PayPeriod(
      id: 'off-cycle-period',
      name: request.name,
      startDate: request.startDate,
      endDate: request.endDate,
      frequency: request.frequency,
      status: PayPeriodStatus.draft,
      isOffCycle: request.isOffCycle,
    );
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => OffCyclePayrollPage(
          preSelectedWorkerId: workerId,
          preSelectedWorkerName: workerName,
        ),
      ),
      GoRoute(
        path: '/payroll/confirm/:id',
        builder: (_, state) {
          final extra = state.extra! as Map<String, dynamic>;
          harness.reviewWorkerIds = List<String>.from(
            extra['workerIds'] as List,
          );
          return const Scaffold(body: Text('Payroll review'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [payPeriodRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}
