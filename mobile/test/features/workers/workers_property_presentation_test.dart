import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/properties/presentation/providers/properties_provider.dart';
import 'package:mobile/features/subscriptions/presentation/providers/feature_access_provider.dart';
import 'package:mobile/features/workers/data/models/worker_model.dart';
import 'package:mobile/features/workers/pages/workers_page.dart';
import 'package:mobile/features/workers/presentation/providers/workers_provider.dart';
import 'package:mobile/features/workers/widgets/worker_card.dart';
import 'package:mobile/features/workers/widgets/workers_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Workers extends WorkersNotifier {
  @override
  List<WorkerModel> build() => const [
    WorkerModel(
      id: 'alex',
      name: 'Alex Example',
      phoneNumber: '0712345678',
      salaryGross: 25000,
      isActive: true,
      nssfNumber: 'test',
      nhifNumber: 'test',
    ),
    WorkerModel(
      id: 'zola',
      name: 'Zola Example',
      phoneNumber: '0712345679',
      salaryGross: 30000,
      isActive: false,
      nssfNumber: 'test',
      nhifNumber: 'test',
    ),
  ];
}

double _contrast(Color foreground, Color background) {
  final first = Color.alphaBlend(foreground, background).computeLuminance();
  final second = background.computeLuminance();
  return ((first > second ? first : second) + 0.05) /
      ((first < second ? first : second) + 0.05);
}

void _expectReadable(WidgetTester tester, String label, Color background) {
  final finder = find.descendant(
    of: find.text(label),
    matching: find.byType(RichText),
  );
  final rendered = tester.widget<RichText>(finder);
  expect(
    _contrast(rendered.text.style!.color!, background),
    greaterThanOrEqualTo(4.5),
    reason: label,
  );
  expect(
    tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
    isFalse,
    reason: label,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required ThemeMode mode,
  double width = 390,
  double height = 844,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workersProvider.overrideWith(_Workers.new),
        propertiesProvider.overrideWith((ref) async => []),
        subscriptionSummaryProvider.overrideWith(
          (ref) async => const SubscriptionSummary(
            tier: 'PLATINUM',
            isTrialActive: false,
            trialDaysRemaining: 0,
            workerLimit: 100,
            currentWorkerCount: 2,
            accessibleFeatures: [],
            previewFeatures: [],
            lockedFeatures: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final vertical = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    await tester.scrollUntilVisible(finder, -200, scrollable: vertical);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('property prompt is readable and actionable in ${mode.name}', (
      tester,
    ) async {
      var infoCount = 0;
      var addCount = 0;
      var dismissCount = 0;
      await _pump(
        tester,
        Scaffold(
          body: PropertySetupPrompt(
            onShowInfo: () => infoCount++,
            onAddProperty: () => addCount++,
            onDismiss: () => dismissCount++,
          ),
        ),
        mode: mode,
      );
      final card = tester.widget<Container>(
        find.descendant(
          of: find.byType(PropertySetupPrompt),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).border != null,
          ),
        ),
      );
      final background = (card.decoration! as BoxDecoration).color!;
      _expectReadable(tester, 'Set Up Property', background);
      _expectReadable(
        tester,
        'Optional: Enable geofencing for time tracking',
        background,
      );
      final button = find.widgetWithText(ElevatedButton, 'Add');
      final buttonMaterial = tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)),
      );
      _expectReadable(tester, 'Add', buttonMaterial.color!);
      await tester.tap(find.text('Set Up Property'));
      await tester.tap(button);
      await tester.tap(find.byTooltip('Dismiss'));
      expect([infoCount, addCount, dismissCount], [1, 1, 1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('property dialog scrolls at 320px 2x text in ${mode.name}', (
      tester,
    ) async {
      var added = false;
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => PropertyInfoDialog(
                  onMaybeLater: () => Navigator.of(dialogContext).pop(),
                  onAddProperty: () {
                    added = true;
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
              child: const Text('Open information'),
            ),
          ),
        ),
        mode: mode,
        width: 320,
        height: 600,
        scale: 2,
      );
      await tester.tap(find.text('Open information'));
      await tester.pumpAndSettle();
      final theme = mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
      for (final title in [
        'Property Management',
        'Geofencing for Time Tracking',
        'Multi-Property Payroll',
        'Worker Assignment',
      ]) {
        _expectReadable(tester, title, theme.colorScheme.surface);
      }
      await tester.ensureVisible(find.text('Property setup is optional'));
      _expectReadable(
        tester,
        'Property setup is optional',
        theme.colorScheme.surfaceContainerHighest,
      );
      final explanation = find.text(
        'You can still add workers and run payroll without properties. Only set up properties if you need geofencing for time tracking or manage multiple locations.',
      );
      await tester.ensureVisible(explanation);
      expect(explanation, findsOneWidget);
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();
      expect(find.byType(PropertyInfoDialog), findsNothing);
      expect(added, isFalse);
      await tester.tap(find.text('Open information'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Property'));
      await tester.pumpAndSettle();
      expect(added, isTrue);
      expect(find.byType(PropertyInfoDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'People header and workers scroll at 320px 2x in ${mode.name}',
      (tester) async {
        FlutterErrorDetails? layoutError;
        final onError = FlutterError.onError;
        FlutterError.onError = (details) {
          layoutError ??= details;
          onError?.call(details);
        };
        addTearDown(() => FlutterError.onError = onError);
        await _pump(
          tester,
          const WorkersPage(),
          mode: mode,
          width: 320,
          height: 600,
          scale: 2,
        );
        final title = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('My Workforce'),
            matching: find.byType(RichText),
          ),
        );
        expect(title.didExceedMaxLines, isFalse);
        await _reveal(tester, find.text('Set Up Property'));
        await tester.tap(find.text('Set Up Property'));
        await tester.pumpAndSettle();
        expect(find.byType(PropertyInfoDialog), findsOneWidget);
        await tester.tap(find.text('Maybe Later'));
        await tester.pumpAndSettle();
        await _reveal(tester, find.byTooltip('Dismiss'));
        await tester.tap(find.byTooltip('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.byType(PropertySetupPrompt), findsNothing);
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getBool('property_prompt_dismissed'), isTrue);

        await _reveal(tester, find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Zola');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        final vertical = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Zola Example'),
          200,
          scrollable: vertical,
        );
        await tester.pumpAndSettle();
        expect(find.byType(WorkerCard), findsOneWidget);
        expect(find.text('Alex Example'), findsNothing);
        await _reveal(tester, find.byTooltip('Clear search'));
        await tester.tap(find.byTooltip('Clear search'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        final inactiveFilter = find.descendant(
          of: find.byType(WorkerFilterChips),
          matching: find.text('Inactive'),
        );
        await _reveal(tester, inactiveFilter);
        await tester.tap(inactiveFilter);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Zola Example'),
          200,
          scrollable: vertical,
        );
        await tester.pumpAndSettle();
        expect(find.byType(WorkerCard), findsOneWidget);
        expect(find.text('Alex Example'), findsNothing);
        expect(tester.takeException(), isNull, reason: layoutError?.toString());
      },
    );
  }
}
