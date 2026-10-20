import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/taxes/data/models/monthly_tax_summary.dart';
import 'package:mobile/features/taxes/data/models/tax_submission_model.dart';
import 'package:mobile/features/taxes/presentation/pages/comprehensive_tax_page.dart';
import 'package:mobile/features/taxes/presentation/providers/tax_provider.dart';
import 'package:mobile/features/taxes/presentation/providers/tax_submission_provider.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('tax filing, history and calculator are readable in $mode', (
      tester,
    ) async {
      await _pumpPage(tester, mode);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      _expectReadable(tester, 'Tax Management', scaffold.backgroundColor!);
      for (final title in ['Compliance Status', 'Tax Calendar']) {
        _expectReadable(tester, title, _cardColor(tester, title));
      }
      _expectReadable(
        tester,
        'Process payroll to generate tax submissions',
        _cardColor(tester, 'No tax submissions yet'),
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      _expectReadable(
        tester,
        'No filed returns yet',
        scaffold.backgroundColor!,
      );
      _expectReadable(
        tester,
        'Your filed returns will appear here',
        scaffold.backgroundColor!,
      );

      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();
      _expectReadable(
        tester,
        'Income Tax Calculator',
        _cardColor(tester, 'Income Tax Calculator'),
      );
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '120000');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final input = tester.widget<InputDecorator>(find.byType(InputDecorator));
      expect(field.enabled, isNot(false));
      expect(
        _contrast(editable.style.color!, input.decoration.fillColor!),
        greaterThanOrEqualTo(4.5),
      );

      await tester.tap(find.text('Calculate Breakdown'));
      await tester.pumpAndSettle();
      final sheetColor = _cardColor(tester, 'Tax Breakdown');
      for (final label in [
        'Tax Breakdown',
        'Gross Income',
        'NSSF Contribution',
      ]) {
        _expectReadable(tester, label, sheetColor);
      }
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Tax Breakdown'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tax download sheet is readable in $mode', (tester) async {
      await _pumpPage(tester, mode, summaries: [_summary]);
      final download = find.widgetWithText(OutlinedButton, 'Download');
      await tester.ensureVisible(download);
      await tester.tap(download);
      await tester.pumpAndSettle();

      final sheetColor = _cardColor(tester, 'Download Tax Returns');
      for (final label in [
        'Download Tax Returns',
        'PAYE Supporting Schedule',
        'Use with the current KRA/iTax return',
      ]) {
        _expectReadable(tester, label, sheetColor);
      }
      final lastOption = find.text('SHIF Contribution Schedule');
      await tester.ensureVisible(lastOption);
      await tester.pumpAndSettle();
      expect(lastOption.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  ThemeMode mode, {
  List<MonthlyTaxSummary> summaries = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  // Keep the default test font's wide glyphs out of the contrast checks,
  // while retaining a short viewport to exercise the scrollable sheets.
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        monthlyTaxSummariesProvider.overrideWith(
          () => _MonthlyTaxNotifier(summaries),
        ),
        taxNotifierProvider.overrideWith(_TaxNotifier.new),
        taxSubmissionProvider.overrideWith(_TaxSubmissionNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const ComprehensiveTaxPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _cardColor(WidgetTester tester, String text) {
  final cards = find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color != null,
    ),
  );
  final card = tester.widget<Container>(cards.first);
  return (card.decoration! as BoxDecoration).color!;
}

void _expectReadable(WidgetTester tester, String text, Color background) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  final color = richText.text.style!.color!;
  expect(
    _contrast(color, background),
    greaterThanOrEqualTo(4.5),
    reason: '"$text" must contrast with its actual rendered surface',
  );
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
}

class _MonthlyTaxNotifier extends MonthlyTaxNotifier {
  _MonthlyTaxNotifier(this.summaries);

  final List<MonthlyTaxSummary> summaries;

  @override
  List<MonthlyTaxSummary> build() => summaries;
}

class _TaxNotifier extends TaxNotifier {
  @override
  List<dynamic> build() => [];

  @override
  Future<Map<String, dynamic>> getComplianceStatus() async => {
    'kraPin': true,
    'nssf': true,
    'shif': true,
  };
}

class _TaxSubmissionNotifier extends TaxSubmissionNotifier {
  @override
  List<TaxSubmissionModel> build() => [];

  @override
  Future<List<TaxSubmissionModel>> calculateTax(
    double income,
    double deductions,
  ) async => [];
}

const _summary = MonthlyTaxSummary(
  year: 2026,
  month: 9,
  monthName: 'September',
  totalPaye: 1000,
  totalNssf: 600,
  totalNhif: 275,
  totalHousingLevy: 150,
  totalTax: 2025,
  status: 'FILED',
  submissions: [],
  submissionIds: [],
);
