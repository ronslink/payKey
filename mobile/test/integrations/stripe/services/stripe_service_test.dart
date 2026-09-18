import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/integrations/stripe/services/stripe_service.dart';

@GenerateMocks([ApiService])
import 'stripe_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.stripe/payments', JSONMethodCodec());
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialise') return null;
          if (call.method == 'initPaymentSheet') return <dynamic>[];
          throw StateError('Unexpected Stripe method: ${call.method}');
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final currency in ['KES', 'EUR']) {
    test(
      '$currency card amount reaches API and configured native sheet',
      () async {
        final api = MockApiService();
        final service = StripeIntegrationService(api);
        final amount = currency == 'KES' ? 1000.0 : 10.25;
        const publicKey = 'pk_test_walletCardFixture';
        when(api.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: {
              'clientSecret': 'pi_fixture_secret_fixture',
              'publishableKey': publicKey,
              'transactionId': 'tx_fixture',
            },
            statusCode: 201,
          ),
        );

        await service.initPaymentSheet(amount: amount, currency: currency);

        verify(
          api.post(
            '/payments/unified/stripe/create-intent',
            data: {
              'amount': amount,
              'currency': currency,
              'paymentMethodTypes': ['card'],
            },
          ),
        ).called(1);
        expect(calls.map((call) => call.method), [
          'initialise',
          'initPaymentSheet',
        ]);
        expect(calls.first.arguments['publishableKey'], publicKey);
        final parameters = calls.last.arguments['params'];
        expect(
          parameters['paymentIntentClientSecret'],
          'pi_fixture_secret_fixture',
        );
        expect(parameters['allowsDelayedPaymentMethods'], isFalse);
      },
    );
  }
}
