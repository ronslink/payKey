import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password, {BuildContext? context}) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _authRepository.loginApi(email, password);
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'];
        if (token != null) {
          await _authRepository.saveToken(token);
          state = const AsyncValue.data(null);
          
          // Check if user has completed onboarding
          final user = data['user'];
          final isOnboardingCompleted = user?['isOnboardingCompleted'] ?? false;
          
          
          // Navigate based on onboarding status
          if (context != null && context.mounted) {
            if (isOnboardingCompleted) {
              context.go('/home');
            } else {
              context.go('/onboarding');
            }
          }
        } else {
          state = AsyncValue.error('Invalid response from server', StackTrace.current);
        }
      } else {
        state = AsyncValue.error('Login failed: ${response.data?['message'] ?? 'Unknown error'}', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }

  Future<void> register(String email, String password, String firstName, String lastName, {BuildContext? context}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _authRepository.registerApi(email, password, firstName, lastName);
      
      if (response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'];
        if (token != null) {
          await _authRepository.saveToken(token);
          state = const AsyncValue.data(null);
          
          // New users always need to complete onboarding
          if (context != null && context.mounted) {
            context.go('/onboarding');
          }
        } else {
          state = AsyncValue.error('Invalid response from server', StackTrace.current);
        }
      } else {
        state = AsyncValue.error('Registration failed: ${response.data?['message'] ?? 'Unknown error'}', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.clearToken();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }
}
