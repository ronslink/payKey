
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/network/api_service.dart';

class StripeIntegrationService {
  final ApiService _apiService;

  StripeIntegrationService(this._apiService);

  Future<void> initPaymentSheet({
    required double amount,
    required String currency, // 'EUR', 'USD'
  }) async {
    try {
      // 1. Create Payment Intent on Backend
      final response = await _apiService.post('/payments/unified/stripe/create-intent', data: {
        'amount': amount,
        'paymentMethodTypes': ['card', 'sepa_debit'], 
      });

      final data = response.data;
      final clientSecret = data['clientSecret'];
      final transactionId = data['transactionId'];

      if (clientSecret == null) throw Exception('Missing client secret');

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PayDome',
          // billingDetails: BillingDetails(email: email), // Optional
          allowsDelayedPaymentMethods: true, // Crucial for SEPA
        ),
      );
    } catch (e) {
      throw Exception('Stripe Init Failed: $e');
    }
  }

  Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment Failed: $e');
    }
  }
}

final stripeIntegrationServiceProvider = Provider<StripeIntegrationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return StripeIntegrationService(apiService);
});
