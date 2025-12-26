import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile/integrations/intasend/services/intasend_service.dart';
import 'package:mobile/integrations/intasend/models/intasend_models.dart';
import 'package:mobile/integrations/intasend/config/intasend_config.dart';

void main() {
  group('IntaSendService Tests', () {
    late IntaSendService service;
    late MockClient mockClient;

    setUp(() {
      // Setup default mock that returns 200 for known endpoints
      // Specific tests can override by creating a new service/client
    });

    test('initiateStkPush returns response on success', () async {
      mockClient = MockClient((request) async {
        if (request.url.path.contains(IntaSendConfig.stkPushEndpoint)) {
            // Verify payload
            final body = jsonDecode(request.body);
            expect(body['phone_number'], '254712345678');
            expect(body['amount'], 100.0);

            return http.Response(jsonEncode({
                'invoice': {
                    'invoice_id': 'INV-TEST-123',
                    'state': 'PENDING'
                },
                'customer': {
                    'phone_number': '254712345678'
                },
                'payment_link': 'https://sandbox.intasend.com/pay/INV-TEST-123'
            }), 200);
        }
        return http.Response('Not Found', 404);
      });

      service = IntaSendService(
          environment: IntaSendEnvironment.sandbox(
             publishableKey: 'pk_test',
             secretKey: 'sk_test'
          ),
          client: mockClient
      );

      final response = await service.initiateStkPush(
          phoneNumber: '0712345678', // Test formatting
          amount: 100.0,
          reference: 'REF123',
          email: 'test@example.com'
      );

      expect(response.invoiceId, 'INV-TEST-123');
      expect(response.status, 'PENDING');
    });

    test('getWalletBalance returns valid balance', () async {
      mockClient = MockClient((request) async {
        if (request.url.path.contains(IntaSendConfig.walletsEndpoint)) {
             return http.Response(jsonEncode([
                {
                    'label': 'KES Wallet',
                    'wallet_id': 'W-123',
                    'current_balance': 5000.00,
                    'available_balance': 4500.00,
                    'currency': 'KES'
                }
             ]), 200);
        }
        return http.Response('Error', 500);
      });

      service = IntaSendService(
          environment: IntaSendEnvironment.sandbox(
             publishableKey: 'pk_test',
             secretKey: 'sk_test'
          ),
          client: mockClient
      );

      final wallet = await service.getWalletBalance();
      expect(wallet.availableBalance, 4500.00);
      expect(wallet.currency, 'KES');
    });

    test('disburseSalaries sends correct payload', () async {
        mockClient = MockClient((request) async {
            if (request.url.path.contains(IntaSendConfig.payoutEndpoint)) {
                final body = jsonDecode(request.body);
                final txs = body['transactions'] as List;
                expect(txs.length, 2);
                expect(txs[0]['account'], '254712345678');
                expect(txs[0]['amount'], '1000.0');
                
                return http.Response(jsonEncode({
                    'file_id': 'FILE-123',
                    'tracking_id': 'TRACK-ABC',
                    'status': 'Processing',
                    'transactions': [
                        {'status': 'PENDING', 'account': '254712345678'},
                        {'status': 'PENDING', 'account': '254700000000'}
                    ]
                }), 200);
            }
            return http.Response('Not Found', 404);
        });

        service = IntaSendService(
            environment: IntaSendEnvironment.sandbox(
               publishableKey: 'pk_test',
               secretKey: 'sk_test'
            ),
            client: mockClient
        );

        final workers = [
            WorkerPayout(
                workerId: 'w1', 
                name: 'John', 
                phoneNumber: '0712345678', 
                amount: 1000, 
                narrative: 'Sal'
            ),
            WorkerPayout(
                workerId: 'w2',
                name: 'Jane',
                phoneNumber: '0700000000',
                amount: 2000,
                narrative: 'Sal'
            )
        ];

        final result = await service.disburseSalaries(workers: workers);
        
        expect(result.trackingId, 'TRACK-ABC');
        expect(result.pendingCount, 2); // Status is Pending/Processing initially
        expect(result.successCount, 0);
    });
  });
}
