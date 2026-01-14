import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  Future<void> loginWithGoogle({BuildContext? context}) async {
    state = const AsyncValue.loading();
    try {
      final googleSignIn = google.GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null); // User cancelled
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to get Google ID Token');
      }

      await _handleSocialLogin(
        provider: 'GOOGLE',
        token: idToken, // Send ID token as the token
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
        photoUrl: googleUser.photoUrl,
        context: context,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }

  Future<void> loginWithApple({BuildContext? context}) async {
    state = const AsyncValue.loading();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Apple only returns name on first sign in, so might be null on subsequent logins
      // The identityToken is the JWT we need to send
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw Exception('Failed to get Apple Identity Token');
      }

      final email = credential.email;
      // If email is hidden, we might need to rely on the backend decoding the token
      // But for this simple implementation, we assume we get it or backend handles it from token
      // If email is empty, we must fail as our backend requires it for this implementation plan
      if (email == null && credential.identityToken == null) {
         throw Exception('Email is required');
      }

      await _handleSocialLogin(
        provider: 'APPLE',
        token: identityToken,
        email: email ?? '', // If null, backend must extract from token
        firstName: credential.givenName,
        lastName: credential.familyName,
        context: context,
      );
    } catch (error, stackTrace) {
      if (error is SignInWithAppleAuthorizationException && 
          error.code == AuthorizationErrorCode.canceled) {
        state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }

  Future<void> _handleSocialLogin({
    required String provider,
    required String token,
    required String email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    BuildContext? context,
  }) async {
      final response = await _authRepository.socialLoginApi(
        provider: provider,
        token: token,
        email: email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: photoUrl,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access_token'];
        
        if (accessToken != null) {
          await _authRepository.saveToken(accessToken);
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
           throw Exception('Invalid response from server');
        }
      } else {
         throw Exception('Social login failed: ${response.data?['message'] ?? 'Unknown error'}');
      }
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
