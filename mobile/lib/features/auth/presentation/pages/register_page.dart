import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .register(
            _emailController.text,
            _passwordController.text,
            _firstNameController.text,
            _lastNameController.text,
          );
    }
  }

  String _getFriendlyErrorMessage(Object? error) {
    if (error == null) return 'An unknown error occurred.';

    String message = error.toString();

    // Clean up typical wrappers
    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    if (message.contains('DioException') && message.contains('message:')) {
      final match = RegExp(r'message:\s*([^,}]+)').firstMatch(message);
      if (match != null) {
        message = match.group(1)?.trim() ?? message;
      }
    } else if (message.contains('DioException [bad response]:')) {
      final match = RegExp(r'''Response:.*?([^"'\n}]+)''').firstMatch(message);
      if (match != null) {
        message = match.group(1)?.trim() ?? message;
      }
    }

    // If it's still a raw DioException string, just show a fallback so users don't see technical blobs
    if (message.startsWith('DioException')) {
      message = 'An error occurred while connecting. Please try again.';
    }

    final lower = message.toLowerCase();

    if (lower.contains('email already in use') ||
        lower.contains('email_exists') ||
        lower.contains('duplicate')) {
      return 'This email is already in use. Please sign in or use a different email.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('network error') ||
        lower.contains('connection timeout') ||
        lower.contains('failed host lookup')) {
      return 'Network error. Please check your internet connection.';
    }

    return message;
  }

  String? _validateField(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter ${label.toLowerCase()}';
    }
    if (label == 'Email' && !value.contains('@')) {
      return 'Please enter a valid email';
    }
    if (label == 'Password' && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (label.contains('Name') && value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  Widget _buildNameFields(BuildContext context) {
    final firstName = AuthTextField(
      controller: _firstNameController,
      label: 'First Name',
      hint: 'John',
      validator: (value) => _validateField('First Name', value),
    );
    final lastName = AuthTextField(
      controller: _lastNameController,
      label: 'Last Name',
      hint: 'Doe',
      validator: (value) => _validateField('Last Name', value),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedFields =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        if (useStackedFields) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [firstName, const SizedBox(height: 24), lastName],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: firstName),
            const SizedBox(width: 16),
            Expanded(child: lastName),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading && !next.hasError) {
        context.go('/onboarding');
      }
    });

    final authState = ref.watch(authStateProvider);
    return AuthPageScaffold(
      formKey: _formKey,
      title: 'Create Account',
      subtitle: 'Join payDome to manage your workers',
      fields: [
        if (authState.hasError) ...[
          AuthErrorMessage(message: _getFriendlyErrorMessage(authState.error)),
          const SizedBox(height: 24),
        ],
        _buildNameFields(context),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'john@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _validateField('Email', value),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a secure password',
          obscureText: true,
          validator: (value) => _validateField('Password', value),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          label: 'Create Account',
          isLoading: authState.isLoading,
          onPressed: _register,
        ),
        const SizedBox(height: 24),
        AuthSocialButtons(
          isRegistration: true,
          onApple: () => ref
              .read(authStateProvider.notifier)
              .loginWithApple(context: context),
          onGoogle: () => ref
              .read(authStateProvider.notifier)
              .loginWithGoogle(context: context),
        ),
      ],
      footer: [
        AuthAccountLink(
          prompt: 'Already have an account?',
          label: 'Sign In',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
