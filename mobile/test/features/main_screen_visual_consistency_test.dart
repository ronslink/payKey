import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/finance/presentation/pages/finance_page.dart';
import 'package:mobile/features/finance/widgets/finance_quick_actions.dart';
import 'package:mobile/features/home/presentation/pages/home_page.dart';
import 'package:mobile/features/home/presentation/providers/statutory_deadlines_provider.dart';
import 'package:mobile/features/payroll/data/models/pay_period_model.dart';
import 'package:mobile/features/payroll/presentation/providers/pay_period_provider.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile/features/settings/models/setting_item.dart';
import 'package:mobile/features/settings/providers/settings_provider.dart';
import 'package:mobile/features/settings/widgets/settings_widgets.dart';
import 'package:mobile/features/subscriptions/presentation/providers/feature_access_provider.dart';
import 'package:mobile/features/workers/data/models/worker_model.dart';
import 'package:mobile/features/workers/presentation/providers/workers_provider.dart';
import 'package:mobile/features/workers/utils/worker_filter.dart';
import 'package:mobile/features/workers/utils/compliance_checker.dart';
import 'package:mobile/features/workers/widgets/worker_card.dart';
import 'package:mobile/features/workers/widgets/workers_widgets.dart';
import 'package:mobile/integrations/intasend/models/intasend_models.dart';
import 'package:mobile/integrations/intasend/providers/intasend_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PayPeriods extends PayPeriodsNotifier {
  @override
  List<PayPeriod> build() => [
    PayPeriod(
      id: 'completed',
      name: 'September household payroll',
      startDate: DateTime(2026, 9),
      endDate: DateTime(2026, 9, 30),
      frequency: PayPeriodFrequency.monthly,
      status: PayPeriodStatus.completed,
      totalGrossAmount: 200000,
      totalNetAmount: 165000,
    ),
    PayPeriod(
      id: 'active',
      name: 'October household payroll',
      startDate: DateTime(2026, 10),
      endDate: DateTime(2026, 10, 31),
      frequency: PayPeriodFrequency.monthly,
      status: PayPeriodStatus.active,
    ),
  ];
}

class _Workers extends WorkersNotifier {
  @override
  List<WorkerModel> build() => [];
}

class _Settings extends SettingsNotifier {
  @override
  Future<UserSettings> build() async => UserSettings();
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return ((first > second ? first : second) + 0.05) /
      ((first < second ? first : second) + 0.05);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required ThemeMode mode,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        payPeriodsProvider.overrideWith(_PayPeriods.new),
        workersProvider.overrideWith(_Workers.new),
        settingsProvider.overrideWith(_Settings.new),
        profileProvider.overrideWith(
          (ref) async => ProfileModel(
            id: 'test',
            email: 'test@example.com',
            firstName: 'Alexandra',
            bankName: 'Example Commercial Bank',
            bankAccount: '123456789012',
            mpesaPhone: '0712345678',
          ),
        ),
        featureAccessProvider(
          'accounting_integration',
        ).overrideWith((ref) async => FeatureAccessResult.full()),
        statutoryDeadlinesProvider.overrideWith((ref) async => []),
        walletBalanceProvider.overrideWith(
          (ref) async => WalletInfo(
            currency: 'KES',
            availableBalance: 123456.78,
            currentBalance: 123456.78,
            canDisburse: true,
            updatedAt: DateTime(2026),
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
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = ApiService().dio;
    final adapter = dio.httpClientAdapter;
    final interceptors = dio.interceptors.toList();
    dio.interceptors.clear();
    dio.httpClientAdapter = _OfflineAdapter();
    addTearDown(() {
      dio.httpClientAdapter = adapter;
      dio.interceptors
        ..clear()
        ..addAll(interceptors);
    });
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('People search has one themed outline in ${mode.name}', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Alex');
      addTearDown(controller.dispose);
      var cleared = false;
      await _pump(
        tester,
        Scaffold(
          body: WorkerSearchBar(
            controller: controller,
            query: 'Alex',
            onClear: () {
              controller.clear();
              cleared = true;
            },
          ),
        ),
        mode: mode,
      );
      expect(
        find.descendant(
          of: find.byType(WorkerSearchBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).border != null,
          ),
        ),
        findsNothing,
      );
      final decoration = tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration;
      expect(decoration.enabledBorder, isA<OutlineInputBorder>());
      expect(decoration.focusedBorder, isA<OutlineInputBorder>());
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      expect(cleared, isTrue);
      expect(controller.text, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'action cards and labels fit ${mode.name} at ${scale}x text',
        (tester) async {
          var route = '';
          await _pump(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    FinanceQuickActions(onNavigate: (value) => route = value),
                    QuickAccessGrid(
                      items: QuickAccessItems.defaults,
                      onItemTap: (value) => route = value,
                    ),
                    const WorkerStatsRow(
                      stats: WorkerStats(total: 123, active: 120, pending: 3),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: WorkerCard(
                        data: const WorkerCardData(
                          id: 'worker',
                          name: 'Alexandra Example',
                          isActive: true,
                          jobTitle: 'Household manager',
                          complianceStatus: ComplianceStatus(
                            hasNssf: false,
                            hasNhif: false,
                          ),
                        ),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            mode: mode,
            width: scale == 1 ? 390 : 320,
            textScale: scale,
          );
          final actions = find.descendant(
            of: find.byType(FinanceQuickActions),
            matching: find.byType(InkWell),
          );
          if (scale == 1) {
            final heights = tester
                .widgetList(actions)
                .map((widget) => tester.getSize(find.byWidget(widget)).height);
            expect(heights.toSet(), hasLength(1));
          }
          for (final label in [
            'Tax Records',
            'Statutory reports',
            'Reports',
            'Financial reports',
            'Top Up',
            'Add funds',
            'Subscription',
            'Pending',
            'Alexandra Example',
            'Missing NSSF & SHIF',
          ]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(label),
                matching: find.byType(RichText),
              ),
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          }
          for (final ink in tester.widgetList<Ink>(
            find.descendant(
              of: find.byType(FinanceQuickActions),
              matching: find.byType(Ink),
            ),
          )) {
            final colors = (ink.decoration! as BoxDecoration).gradient!.colors;
            final text = tester.widgetList<RichText>(
              find.descendant(
                of: find.byWidget(ink),
                matching: find.byType(RichText),
              ),
            );
            for (final richText in text) {
              for (final background in colors) {
                expect(
                  _contrast(richText.text.style!.color!, background),
                  greaterThanOrEqualTo(4.5),
                );
              }
            }
          }
          await tester.tap(find.text('Tax Records'));
          expect(route, '/taxes');
          await tester.ensureVisible(find.text('Subscription'));
          await tester.tap(find.text('Subscription'));
          expect(route, '/settings/subscription');
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Finance remains readable on narrow ${mode.name} screen', (
      tester,
    ) async {
      await _pump(
        tester,
        const FinancePage(),
        mode: mode,
        width: 320,
        textScale: 2,
      );
      await tester.scrollUntilVisible(
        find.text('Financial Breakdown'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final heading = tester.widget<RichText>(
        find.descendant(
          of: find.text('Financial Breakdown'),
          matching: find.byType(RichText),
        ),
      );
      final theme = mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
      expect(
        _contrast(heading.text.style!.color!, theme.cardTheme.color!),
        greaterThanOrEqualTo(4.5),
      );
      await tester.scrollUntilVisible(
        find.text('Chart of Accounts'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Chart of Accounts'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Mappings'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home grows for narrow ${mode.name} screen and large text', (
      tester,
    ) async {
      FlutterErrorDetails? layoutError;
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        layoutError ??= details;
        onError?.call(details);
      };
      addTearDown(() => FlutterError.onError = onError);
      await _pump(
        tester,
        const HomePage(),
        mode: mode,
        width: 320,
        textScale: 2,
      );
      await tester.ensureVisible(find.text('No upcoming deadlines'));
      expect(find.text('Process Payroll Now'), findsOneWidget);
      expect(find.text('Last Payroll'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: layoutError?.toString());
    });
  }
}
