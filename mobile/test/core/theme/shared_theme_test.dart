import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/config/store_policy.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/feature_gate.dart';
import 'package:mobile/main_layout_new.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final brightness in Brightness.values) {
    ThemeData activeTheme() =>
        brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;

    testWidgets('primary action and content contrast in $brightness', (
      tester,
    ) async {
      final theme = activeTheme();
      final colors = theme.colorScheme;
      expect(
        theme.appBarTheme.systemOverlayStyle!.statusBarIconBrightness,
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );
      expect(
        _contrast(colors.primary, colors.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.primary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.onSurfaceVariant, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      for (final style in [
        theme.elevatedButtonTheme.style!,
        theme.filledButtonTheme.style!,
      ]) {
        expect(style.backgroundColor!.resolve({}), colors.primary);
        expect(style.foregroundColor!.resolve({}), colors.onPrimary);
      }
    });

    testWidgets(
      'navigation follows $brightness at narrow width and large text',
      (tester) async {
        final theme = activeTheme();
        _smallViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const MainLayoutNew(child: SizedBox.shrink()),
          ),
        );
        await tester.pumpAndSettle();
        final nav =
            tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar!
                as Container;
        final decoration = nav.decoration! as BoxDecoration;
        expect(decoration.color, theme.colorScheme.surface);
        expect(
          (decoration.border! as Border).top.color,
          theme.colorScheme.outlineVariant,
        );
        for (final label in [
          'Home',
          'People',
          'Payroll',
          'Finance',
          'Settings',
        ]) {
          final finder = find.text(label);
          final text = tester.widget<Text>(finder);
          expect(
            _contrast(text.style!.color!, decoration.color!),
            greaterThanOrEqualTo(4.5),
          );
          expect(finder.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets(
        'plan dialog is readable and dismissible in $brightness on $platform with large text',
        (tester) async {
          final theme = activeTheme();
          _smallViewport(tester);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => FeatureUpgradeDialog(
                        featureName: 'Off-cycle payroll',
                        requiredTier: 'GOLD',
                        onUpgrade: () =>
                            fail('Upgrade must not be triggered by dismissal'),
                      ),
                    ),
                    child: const Text('Show plan'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Show plan'));
          await tester.pumpAndSettle();
          final title = find.text(
            StorePolicy.purchasesAllowed
                ? 'Upgrade Required'
                : 'Not in your plan',
          );
          final titleWidget = tester.widget<Text>(title);
          expect(
            _contrast(titleWidget.style!.color!, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          final body = tester.widget<Text>(
            find.textContaining('Off-cycle payroll'),
          );
          expect(
            _contrast(body.style!.color!, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          final cancel = find.byType(OutlinedButton);
          expect(
            find.text('Upgrade Now'),
            platform == TargetPlatform.iOS ? findsNothing : findsOneWidget,
          );
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(find.byType(FeatureUpgradeDialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({platform}),
      );
    }
  }
}

void _smallViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + 0.05) / (second + 0.05)
      : (second + 0.05) / (first + 0.05);
}
