import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intasend_models.dart';
import '../providers/intasend_providers.dart';

/// Payment service adapter for PayKey
/// 
/// Bridges the gap between app-specific models and IntaSend integration.
class PaymentService {
  final Ref ref;

  PaymentService(this.ref);

  /// Initiate subscription payment via STK Push
  Future<StkPushResponse?> paySubscription({
    required String planId,
    required String planName,
    required double amount,
    required String phoneNumber,
    String? email,
  }) async {
    final notifier = ref.read(stkPushProvider.notifier);
    
    // Generate unique reference
    final reference = 'sub_${planId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return notifier.initiateTopUp(
      phoneNumber: phoneNumber,
      amount: amount,
      reference: reference,
      name: 'Subscription - $planName',
      email: email,
    );
  }

  /// Wallet top-up for payroll
  Future<StkPushResponse?> topUpWallet({
    required double amount,
    required String phoneNumber,
  }) async {
    final notifier = ref.read(stkPushProvider.notifier);
    
    final reference = 'topup_${DateTime.now().millisecondsSinceEpoch}';
    
    return notifier.initiateTopUp(
      phoneNumber: phoneNumber,
      amount: amount,
      reference: reference,
      name: 'Wallet Top Up',
    );
  }
}

/// Provider for payment service
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref);
});
