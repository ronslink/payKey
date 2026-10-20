import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/payroll/data/models/pay_period_model.dart';
import 'package:mobile/features/payroll/presentation/constants/payroll_confirm_constants.dart';
import 'package:mobile/features/payroll/presentation/models/payroll_breakdown.dart';
import 'package:mobile/features/payroll/presentation/pages/off_cycle_payroll_page.dart';
import 'package:mobile/features/payroll/presentation/pages/payroll_page.dart';
import 'package:mobile/features/payroll/presentation/providers/pay_period_provider.dart';
import 'package:mobile/features/payroll/presentation/widgets/payroll_review_widgets.dart';
import 'package:mobile/features/payroll/presentation/widgets/payroll_widgets.dart';

class _FakePayPeriodsNotifier extends PayPeriodsNotifier {
  @override
  List<PayPeriod> build() => [
    PayPeriod(
      id: 'period',
      name: 'October Payroll',
      frequency: PayPeriodFrequency.monthly,
      startDate: DateTime(DateTime.now().year, 10, 1),
      endDate: DateTime(DateTime.now().year, 10, 31),
      status: PayPeriodStatus.draft,
      totalWorkers: 12,
      totalGrossAmount: 320000,
      totalNetAmount: 250000,
    ),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  Widget page,
  ThemeData theme, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [payPeriodsProvider.overrideWith(_FakePayPeriodsNotifier.new)],
      child: MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _contrast(Color foreground, Color background) {
  final values = [
    Color.alphaBlend(foreground, background).computeLuminance(),
    background.computeLuminance(),
  ]..sort();
  return (values.last + 0.05) / (values.first + 0.05);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final mode = brightness.name;

    testWidgets('payroll overview keeps $mode surfaces and labels readable', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await _pump(tester, const PayrollPage(), theme);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor ?? theme.scaffoldBackgroundColor,
        theme.scaffoldBackgroundColor,
      );
      final hero = tester.widget<Container>(
        find.ancestor(
          of: find.text('Payroll'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).gradient != null,
          ),
        ),
      );
      final gradient = (hero.decoration! as BoxDecoration).gradient!;
      final heroLabel = tester.widget<Text>(find.text('Payroll'));
      for (final background in gradient.colors) {
        expect(
          _contrast(heroLabel.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      }

      await tester.scrollUntilVisible(
        find.text('October Payroll'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(find.text('October Payroll'));
      expect(name.style?.color, theme.colorScheme.onSurface);
      final card = find.ancestor(
        of: find.text('October Payroll'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color ==
                  theme.colorScheme.surface &&
              (widget.decoration! as BoxDecoration).border != null,
        ),
      );
      expect(card, findsOneWidget);
      expect(
        _contrast(name.style!.color!, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('off-cycle headings and primary action use $mode theme', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await _pump(tester, const OffCyclePayrollPage(), theme);
      final title = tester.widget<Text>(find.text('Period Details'));
      expect(title.style?.color, theme.colorScheme.onSurface);
      final submit = find.widgetWithText(
        ElevatedButton,
        'Create & Run Off-Cycle Payroll',
      );
      await tester.ensureVisible(submit);
      final button = tester.widget<ElevatedButton>(submit);
      final background = button.style!.backgroundColor!.resolve({});
      final foreground = button.style!.foregroundColor!.resolve({});
      expect(background, theme.colorScheme.primary);
      expect(foreground, theme.colorScheme.onPrimary);
      expect(_contrast(foreground!, background!), greaterThanOrEqualTo(4.5));
      expect(
        PayrollConfirmTheme.primaryButtonStyle(
          tester.element(submit),
        ).backgroundColor!.resolve({}),
        theme.colorScheme.primary,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('payroll overview fits a narrow screen with large $mode text', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await _pump(tester, const PayrollPage(), theme, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('October Payroll'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('October Payroll'), findsOneWidget);
    });

    testWidgets('off-cycle dates stack and action fits with large $mode text', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await _pump(
        tester,
        const OffCyclePayrollPage(
          preSelectedWorkerId: 'worker',
          preSelectedWorkerName: 'Jane Example',
        ),
        theme,
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final dates = find.byWidgetPredicate(
        (widget) =>
            widget is InputDecorator &&
            ['Start Date', 'End Date'].contains(widget.decoration.labelText),
      );
      expect(dates, findsNWidgets(2));
      expect(
        tester.getTopLeft(dates.last).dy,
        greaterThan(tester.getBottomLeft(dates.first).dy),
      );
      await tester.ensureVisible(find.text('Create & Run Off-Cycle Payroll'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // This test never presses the server-mutating action.
    });
  }

  testWidgets('initialization card and payment action fit large narrow text', (
    tester,
  ) async {
    await _pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              InitializePayPeriodsCard(
                year: 2027,
                subtitle: 'Ready for 2027 payroll',
                onPressed: () {},
              ),
              const PayrollSummaryCard(
                totals: PayrollBreakdown(
                  grossSalary: 1200000,
                  netSalary: 1000000,
                  paye: 100000,
                  nssfContribution: 10000,
                  nhifContribution: 33000,
                  housingLevy: 18000,
                  taxableIncome: 1190000,
                ),
                workerCount: 12,
              ),
              PayrollBottomActionBar(
                totalAmount: 1000000,
                isProcessing: false,
                onConfirm: () {},
              ),
            ],
          ),
        ),
      ),
      AppTheme.dark,
      width: 320,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Confirm & Pay KES 1,000,000'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
