import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_widgets.dart';

class _IdleAuthNotifier extends AuthNotifier {
  @override
  FutureOr<void> build() {}
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = Color.alphaBlend(
    foreground,
    background,
  ).computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance < backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

Color _textColor(WidgetTester tester, Finder text) {
  return tester
      .widget<RichText>(
        find.descendant(of: text, matching: find.byType(RichText)),
      )
      .text
      .style!
      .color!;
}

Future<void> _pumpAuth(
  WidgetTester tester, {
  required bool registration,
  required ThemeMode mode,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(_IdleAuthNotifier.new)],
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
        home: registration ? const RegisterPage() : const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final registration in [false, true]) {
    final page = registration ? 'registration' : 'login';
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '$page uses the brand mark and readable ${mode.name} surfaces',
        (tester) async {
          await _pumpAuth(tester, registration: registration, mode: mode);

          expect(
            find.image(const AssetImage('assets/icon/app_icon.jpg')),
            findsOneWidget,
          );
          final theme = Theme.of(tester.element(find.byType(AuthPageScaffold)));
          final card = tester.widget<Material>(
            find
                .descendant(
                  of: find.byType(Card),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(card.color, theme.cardTheme.color);
          final title = find
              .text(registration ? 'Create Account' : 'payDome')
              .first;
          expect(
            _contrastRatio(
              _textColor(tester, title),
              theme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(4.5),
          );
          for (final label in ['Email', 'Password']) {
            expect(
              _contrastRatio(_textColor(tester, find.text(label)), card.color!),
              greaterThanOrEqualTo(4.5),
            );
          }
          for (final field in find.byType(AuthTextField).evaluate()) {
            final fieldFinder = find.byWidget(field.widget);
            final editable = tester.widget<EditableText>(
              find.descendant(
                of: fieldFinder,
                matching: find.byType(EditableText),
              ),
            );
            final decoration = tester.widget<InputDecorator>(
              find.descendant(
                of: fieldFinder,
                matching: find.byType(InputDecorator),
              ),
            );
            expect(
              _contrastRatio(
                editable.style.color!,
                decoration.decoration.fillColor!,
              ),
              greaterThanOrEqualTo(4.5),
            );
            expect(editable.controller.text, isEmpty);
          }
          final action = find.byType(ElevatedButton);
          final actionMaterial = tester.widget<Material>(
            find.descendant(of: action, matching: find.byType(Material)),
          );
          final actionLabel = find.descendant(
            of: action,
            matching: find.text(registration ? 'Create Account' : 'Sign In'),
          );
          expect(actionMaterial.color, theme.colorScheme.primary);
          expect(
            _contrastRatio(
              _textColor(tester, actionLabel),
              actionMaterial.color!,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(find.text('Demo Credentials'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('$page remains usable at 320px and 200% ${mode.name} text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpAuth(
          tester,
          registration: registration,
          mode: mode,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);

        if (registration) {
          expect(
            tester.getTopLeft(find.text('Last Name')).dy,
            greaterThan(tester.getBottomLeft(find.text('First Name')).dy),
          );
        }
        final action = find.byType(ElevatedButton);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.text('Please enter email'), findsOneWidget);
        expect(find.text('Please enter password'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final socialButton = find.byType(OutlinedButton).last;
        await tester.ensureVisible(socialButton);
        expect(socialButton.hitTestable(), findsOneWidget);
        final footer = find.text(registration ? 'Sign In' : 'Sign Up');
        await tester.ensureVisible(footer);
        expect(footer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('password visibility preserves manually entered login values', (
    tester,
  ) async {
    await _pumpAuth(tester, registration: false, mode: ThemeMode.dark);
    final password = find.byType(TextFormField).last;
    await tester.enterText(password, 'entered-by-user');
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(
      find.descendant(of: password, matching: find.byType(EditableText)),
    );
    expect(editable.obscureText, isFalse);
    expect(editable.controller.text, 'entered-by-user');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: password, matching: find.byType(EditableText)),
          )
          .obscureText,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
