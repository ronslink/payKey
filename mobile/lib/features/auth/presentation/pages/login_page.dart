import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .login(
            _emailController.text,
            _passwordController.text,
            context: context,
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

    if (lower.contains('invalid credentials') ||
        lower.contains('unauthorized') ||
        lower.contains('incorrect') ||
        lower.contains('401') ||
        lower.contains('login failed')) {
      return 'The email or password you entered is incorrect. Please try again.';
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
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && previous?.isLoading == true) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authStateProvider);
    return AuthPageScaffold(
      formKey: _formKey,
      title: 'payDome',
      subtitle: 'Sign in to manage your workers',
      fields: [
        if (authState.hasError) ...[
          AuthErrorMessage(message: _getFriendlyErrorMessage(authState.error)),
          const SizedBox(height: 24),
        ],
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _validateField('Email', value),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          obscureText: _obscurePassword,
          validator: (value) => _validateField('Password', value),
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          label: 'Sign In',
          isLoading: authState.isLoading,
          onPressed: _login,
        ),
        const SizedBox(height: 24),
        AuthSocialButtons(
          isRegistration: false,
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
          prompt: "Don't have an account?",
          label: 'Sign Up',
          onPressed: () => context.go('/register'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/employee/login'),
          child: const Text(
            'Worker? Sign in here',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
