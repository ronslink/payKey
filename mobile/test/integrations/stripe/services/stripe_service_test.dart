
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/integrations/stripe/services/stripe_service.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'stripe_service_test.mocks.dart';

void main() {
  late StripeIntegrationService stripeService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    stripeService = StripeIntegrationService(mockApiService);
  });

  group('StripeIntegrationService', () {
    test('initPaymentSheet should call correct API endpoint', () async {
      // Arrange
      const amount = 500.0;
      const currency = 'EUR';
      final responseData = {
        'clientSecret': 'pi_123_secret_456',
        'transactionId': 'tx_789'
      };

      when(mockApiService.post(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: responseData,
        statusCode: 201,
      ));

      // Act
      // Note: We cannot easily test the Stripe.instance.initPaymentSheet call 
      // without setting up a method channel mock. 
      // For this unit test, we expect the service to call the backend 
      // and fail on the actual Stripe call (since it's not mocked here),
      // OR we can wrap the Stripe call in a wrapper class for better testing.
      // 
      // Given the implementation wraps everything in try-catch, 
      // the test might fail with "Stripe Init Failed" but we can verify the API call.

      try {
        await stripeService.initPaymentSheet(amount: amount, currency: currency);
      } catch (e) {
        // Expected to fail on Stripe.instance call
      }

      // Assert
      verify(mockApiService.post(
        '/payments/unified/stripe/create-intent',
        data: {
          'amount': amount,
          'paymentMethodTypes': ['card', 'sepa_debit'],
        },
      )).called(1);
    });
  });
}
