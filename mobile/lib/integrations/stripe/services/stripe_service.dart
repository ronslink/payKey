import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/network/api_service.dart';

class StripeIntegrationService {
  final ApiService _apiService;

  StripeIntegrationService(this._apiService);

  Future<void> initPaymentSheet({
    required double amount,
    required String currency,
  }) async {
    try {
      // 1. Create Payment Intent on Backend
      final response = await _apiService.post(
        '/payments/unified/stripe/create-intent',
        data: {
          'amount': amount,
          'currency': currency,
          'paymentMethodTypes': ['card', 'sepa_debit'],
        },
      );

      final data = response.data;
      final clientSecret = data['clientSecret'];
      final publishableKey = data['publishableKey'];

      if (clientSecret == null) throw Exception('Missing client secret');
      if (publishableKey is! String ||
          !RegExp(r'^pk_(live|test)_[A-Za-z0-9]+$').hasMatch(publishableKey)) {
        throw Exception('Stripe payment configuration is unavailable');
      }

      // The authenticated API supplies the public key for this payment's account.
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
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

final stripeIntegrationServiceProvider = Provider<StripeIntegrationService>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  return StripeIntegrationService(apiService);
});
