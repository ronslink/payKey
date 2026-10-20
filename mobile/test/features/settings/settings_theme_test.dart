import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/models/setting_item.dart';
import 'package:mobile/features/settings/pages/settings_page.dart';
import 'package:mobile/features/settings/providers/settings_provider.dart';
import 'package:mobile/features/settings/widgets/settings_widgets.dart';
import 'package:mobile/features/subscriptions/presentation/providers/subscription_provider.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this.themeMode);

  final ThemeMode themeMode;

  @override
  Future<UserSettings> build() async => UserSettings(themeMode: themeMode);
}

double _contrastRatio(Color foreground, Color background) {
  final textLuminance = Color.alphaBlend(
    foreground,
    background,
  ).computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = textLuminance > backgroundLuminance
      ? textLuminance
      : backgroundLuminance;
  final darker = textLuminance < backgroundLuminance
      ? textLuminance
      : backgroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pumpSettingsPage(WidgetTester tester, ThemeMode themeMode) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => _FakeSettingsNotifier(themeMode)),
        userSubscriptionProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _darkModeTile() => find.ancestor(
  of: find.text('Dark Mode'),
  matching: find.byType(SettingTile),
);

void _expectDarkMode(
  WidgetTester tester, {
  required String subtitle,
  required bool enabled,
}) {
  final tile = _darkModeTile();
  expect(tile, findsOneWidget);
  expect(
    find.descendant(of: tile, matching: find.text(subtitle)),
    findsOneWidget,
  );
  final toggle = tester.widget<Switch>(
    find.descendant(of: tile, matching: find.byType(Switch)),
  );
  expect(toggle.value, enabled);
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'settings title and subtitle have readable ${mode.name} contrast',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const Scaffold(
              body: SettingsCard(
                items: [
                  SettingItem(
                    icon: Icons.schedule_outlined,
                    title: 'Default Pay Frequency',
                    subtitle: 'Monthly',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = tester.widget<Container>(
          find.descendant(
            of: find.byType(SettingsCard),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).border != null,
            ),
          ),
        );
        final background = (card.decoration! as BoxDecoration).color!;
        for (final label in ['Default Pay Frequency', 'Monthly']) {
          // Inspect the merged style passed to the rendered text, not a token.
          final renderedText = tester.widget<RichText>(
            find.descendant(
              of: find.text(label),
              matching: find.byType(RichText),
            ),
          );
          final foreground = renderedText.text.style!.color!;
          expect(
            _contrastRatio(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: '$label must remain readable on the ${mode.name} card.',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('system mode follows brightness changes in label and switch', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await _pumpSettingsPage(tester, ThemeMode.system);
    _expectDarkMode(tester, subtitle: 'Following system (dark)', enabled: true);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    _expectDarkMode(
      tester,
      subtitle: 'Following system (light)',
      enabled: false,
    );
    expect(tester.takeException(), isNull);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'explicit ${mode.name} mode ignores opposite system brightness',
      (tester) async {
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final enabled = mode == ThemeMode.dark;
        tester.platformDispatcher.platformBrightnessTestValue = enabled
            ? Brightness.light
            : Brightness.dark;
        await _pumpSettingsPage(tester, mode);
        _expectDarkMode(
          tester,
          subtitle: enabled ? 'Enabled' : 'Disabled',
          enabled: enabled,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
