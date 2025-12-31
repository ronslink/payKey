import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends AsyncNotifier<void> {
  late AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return null;
  }

  Future<void> login(String email, String password, {BuildContext? context}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authRepository.loginApi(email, password);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'];
        if (token != null) {
          await _authRepository.saveToken(token);
          state = const AsyncValue.data(null);
          
          final user = data['user'];
          final isOnboardingCompleted = user?['isOnboardingCompleted'] ?? false;
          
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
    state = const AsyncValue.loading();
    try {
      final response = await _authRepository.registerApi(email, password, firstName, lastName);
      
      if (response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'];
        if (token != null) {
          await _authRepository.saveToken(token);
          state = const AsyncValue.data(null);
          
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

final authStateProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
