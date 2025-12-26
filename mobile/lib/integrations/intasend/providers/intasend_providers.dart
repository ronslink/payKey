import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../config/intasend_config.dart';
import '../models/intasend_models.dart';
import '../services/intasend_service.dart';

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Provider for IntaSend environment configuration
final intaSendEnvironmentProvider = Provider<IntaSendEnvironment>((ref) {
  // 1. Check for Production/Live Mode
  if (AppEnvironment.intasendIsLive) {
    return IntaSendEnvironment.production(
      publishableKey: AppEnvironment.intasendPubKey,
      secretKey: AppEnvironment.intasendSecretKey,
      webhookUrl: '${AppEnvironment.apiUrl}/webhooks/intasend',
    );
  }

  // 2. Sandbox Mode
  // If keys are injected via env, use them. Otherwise fallback to hardcoded test keys.
  final pubKey = AppEnvironment.intasendPubKey.isNotEmpty 
      ? AppEnvironment.intasendPubKey 
      : 'ISPubKey_test_98b2ef28-5e6f-46c8-bae9-0e2acedcbf64';
      
  final secretKey = AppEnvironment.intasendSecretKey.isNotEmpty 
      ? AppEnvironment.intasendSecretKey 
      : 'ISSecretKey_test_469d4169-737d-4701-8539-ab65dd2ab2ee';

  return IntaSendEnvironment.sandbox(
    publishableKey: pubKey,
    secretKey: secretKey,
    // Use the configured API URL for webhooks
    webhookUrl: '${AppEnvironment.apiUrl}/webhooks/intasend',
  );
});

/// Provider for IntaSend service
final intaSendServiceProvider = Provider<IntaSendService>((ref) {
  final environment = ref.watch(intaSendEnvironmentProvider);
  final service = IntaSendService(environment: environment);
  ref.onDispose(() => service.dispose());
  return service;
});

// =============================================================================
// WALLET PROVIDERS
// =============================================================================

/// Provider for wallet balance
final walletBalanceProvider = FutureProvider<WalletInfo>((ref) async {
  final service = ref.watch(intaSendServiceProvider);
  return service.getWalletBalance();
});

/// Provider for wallet balance with auto-refresh
final walletBalanceStreamProvider = StreamProvider<WalletInfo>((ref) async* {
  final service = ref.watch(intaSendServiceProvider);
  
  // Initial fetch
  yield await service.getWalletBalance();
  
  // Refresh every 30 seconds when active
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      yield await service.getWalletBalance();
    } catch (_) {
      // Keep last value on error
    }
  }
});

// =============================================================================
// STK PUSH PROVIDERS
// =============================================================================

/// State for STK Push operation
class StkPushState {
  final bool isLoading;
  final StkPushResponse? response;
  final String? error;

  const StkPushState({
    this.isLoading = false,
    this.response,
    this.error,
  });

  StkPushState copyWith({
    bool? isLoading,
    StkPushResponse? response,
    String? error,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return StkPushState(
      isLoading: isLoading ?? this.isLoading,
      response: clearResponse ? null : (response ?? this.response),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for STK Push operations using Notifier pattern
class StkPushNotifier extends Notifier<StkPushState> {
  @override
  StkPushState build() => const StkPushState();

  IntaSendService get _service => ref.read(intaSendServiceProvider);

  /// Initiate STK Push for wallet top-up
  Future<StkPushResponse?> initiateTopUp({
    required String phoneNumber,
    required double amount,
    required String reference,
    String? email,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.initiateStkPush(
        phoneNumber: phoneNumber,
        amount: amount,
        reference: reference,
        email: email,
        name: name,
      );

      state = state.copyWith(isLoading: false, response: response);
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is IntaSendException ? e.detailedMessage : e.toString(),
      );
      return null;
    }
  }

  /// Poll for STK Push status
  Future<StkPushResponse?> pollStatus(String invoiceId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 40, // 2 minutes
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final status = await _service.getStkPushStatus(invoiceId);
        
        if (status.isComplete) {
          state = state.copyWith(response: status);
          // Refresh wallet balance
          ref.invalidate(walletBalanceProvider);
          return status;
        } else if (status.isFailed) {
          state = state.copyWith(response: status, error: 'Payment failed');
          return status;
        }
      } catch (_) {
        // Continue polling on error
      }

      await Future.delayed(interval);
    }

    state = state.copyWith(error: 'Payment timed out');
    return null;
  }

  void reset() {
    state = const StkPushState();
  }
}

/// Provider for STK Push
final stkPushProvider = NotifierProvider<StkPushNotifier, StkPushState>(
  StkPushNotifier.new,
);

// =============================================================================
// DISBURSEMENT PROVIDERS
// =============================================================================

/// State for disbursement operation
class DisbursementState {
  final bool isLoading;
  final DisbursementResult? result;
  final String? error;

  const DisbursementState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  DisbursementState copyWith({
    bool? isLoading,
    DisbursementResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return DisbursementState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for disbursement operations using Notifier pattern
class DisbursementNotifier extends Notifier<DisbursementState> {
  @override
  DisbursementState build() => const DisbursementState();

  IntaSendService get _service => ref.read(intaSendServiceProvider);

  /// Disburse salaries to workers
  Future<DisbursementResult?> disburseSalaries({
    required List<WorkerPayout> workers,
    String? payPeriod,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.disburseSalaries(
        workers: workers,
        payPeriod: payPeriod,
      );

      state = state.copyWith(isLoading: false, result: result);
      
      // Refresh wallet balance after disbursement
      ref.invalidate(walletBalanceProvider);
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is IntaSendException ? e.detailedMessage : e.toString(),
      );
      return null;
    }
  }

  /// Check disbursement status
  Future<DisbursementResult?> checkStatus(String trackingId, List<WorkerPayout> workers) async {
    try {
      final response = await _service.getPayoutStatus(trackingId);
      final result = DisbursementResult.fromPayoutResponse(response, workers);
      state = state.copyWith(result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        error: e is IntaSendException ? e.detailedMessage : e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const DisbursementState();
  }
}

/// Provider for disbursement
final disbursementProvider = NotifierProvider<DisbursementNotifier, DisbursementState>(
  DisbursementNotifier.new,
);

// =============================================================================
// FUND VERIFICATION PROVIDERS
// =============================================================================

/// Provider for fund verification
final fundVerificationProvider = FutureProvider.family<FundVerification, List<WorkerPayout>>((ref, workers) async {
  final service = ref.watch(intaSendServiceProvider);
  return service.verifyFundsForPayroll(workers: workers);
});

// =============================================================================
// TRANSACTION PROVIDERS
// =============================================================================

/// Provider for transaction history
final transactionHistoryProvider = FutureProvider<List<TransactionRecord>>((ref) async {
  final service = ref.watch(intaSendServiceProvider);
  return service.getTransactions();
});
