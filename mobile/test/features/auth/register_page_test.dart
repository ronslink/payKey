import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart'
    show AuthRepository;
import 'package:mobile/features/auth/presentation/pages/register_page.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.duplicate = false});

  final bool duplicate;
  int registrationCalls = 0;

  @override
  Future<Response> registerApi(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    registrationCalls++;
    final request = RequestOptions(path: '/auth/register');
    if (duplicate) {
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 409,
          data: {'message': 'Email already exists'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return Response(
      requestOptions: request,
      statusCode: 201,
      data: {'access_token': 'test-token'},
    );
  }

  @override
  Future<void> saveToken(String token) async {}
}

Future<GoRouter> _pumpRegistration(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const Scaffold(body: Text('Onboarding')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Test');
  await tester.enterText(fields.at(1), 'User');
  await tester.enterText(fields.at(2), 'test+review@example.com');
  await tester.enterText(fields.at(3), 'test-password');
  final submit = find.widgetWithText(ElevatedButton, 'Create Account');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('successful signup confirms creation and opens onboarding', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final router = await _pumpRegistration(tester, repository);

    expect(repository.registrationCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    expect(find.text('Onboarding'), findsOneWidget);
    expect(
      find.text('Account created. Complete your profile.'),
      findsOneWidget,
    );
  });

  testWidgets('duplicate email shows a useful error and stays on signup', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(duplicate: true);
    final router = await _pumpRegistration(tester, repository);

    expect(repository.registrationCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/register');
    expect(
      find.text(
        'This email is already in use. Please sign in or use a different email.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('connecting'), findsNothing);
  });
}
