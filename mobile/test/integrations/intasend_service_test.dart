
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile/integrations/intasend/services/intasend_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:dio/dio.dart';
import 'intasend_service_test.mocks.dart';

// Generate a MockApiService
@GenerateMocks([ApiService, PaymentEndpoints])
void main() {
  late IntaSendService service;
  late MockApiService mockApiService;
  late MockPaymentEndpoints mockPaymentEndpoints;

  setUp(() {
    mockApiService = MockApiService();
    mockPaymentEndpoints = MockPaymentEndpoints();
    
    // Stub the getter on ApiService to return our mock PaymentEndpoints
    when(mockApiService.payments).thenReturn(mockPaymentEndpoints);
    
    service = IntaSendService(mockApiService);
  });

  group('IntaSendService Integration Tests', () {
    // =========================================================================
    // WALLET TESTS
    // =========================================================================
    test('getWalletBalance - successfully parses KES wallet', () async {
      // Mock Response from Backend Proxy
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/wallet'),
        data: <Map<String, dynamic>>[
          {
            'wallet_id': 'w_123',
            'label': 'KES Wallet',
            'can_disburse': true,
            'currency': 'KES',
            'available_balance': 5000.0,
            'current_balance': 5000.0,
            'updated_at': '2024-01-01T12:00:00Z'
          },
          {
            'wallet_id': 'w_456',
            'label': 'USD Wallet',
            'currency': 'USD',
            'can_disburse': false,
            'available_balance': 100.0
          }
        ],
        statusCode: 200,
      );

      when(mockPaymentEndpoints.getWalletBalance())
          .thenAnswer((_) async => mockResponse);

      final wallet = await service.getWalletBalance();

      expect(wallet.currency, 'KES');
      expect(wallet.availableBalance, 5000.0);
      expect(wallet.canDisburse, true);
    });

    test('getWalletBalance - handles list wrapper from backend', () async {
      // Mock Response with 'results' wrapper
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/wallet'),
        data: {
          'results': [
             {
            'wallet_id': 'w_123',
            'label': 'KES Wallet',
            'can_disburse': true,
            'currency': 'KES',
            'available_balance': 2500.0,
            'current_balance': 2500.0,
            'updated_at': '2024-01-01T12:00:00Z'
          }
          ]
        },
        statusCode: 200,
      );

      when(mockPaymentEndpoints.getWalletBalance())
          .thenAnswer((_) async => mockResponse);

      final wallet = await service.getWalletBalance();
      expect(wallet.availableBalance, 2500.0);
    });

    // =========================================================================
    // STK PUSH TESTS
    // =========================================================================
    test('initiateStkPush - successfully creates request', () async {
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/mpesa/stkpush'),
        data: {
          'checkoutRequestId': 'ws_CO_12345',
          'message': 'STK Push Initiated',
          'success': true
        },
        statusCode: 200,
      );

      when(mockPaymentEndpoints.initiateMpesaTopup(
        any, any, accountReference: anyNamed('accountReference'), transactionDesc: anyNamed('transactionDesc')
      )).thenAnswer((_) async => mockResponse);

      final response = await service.initiateStkPush(
        phoneNumber: '254712345678', 
        amount: 1000, 
        reference: 'REF123'
      );

      expect(response.invoiceId, 'ws_CO_12345');
      expect(response.status, 'PENDING');
      verify(mockPaymentEndpoints.initiateMpesaTopup(
        '254712345678', 1000, accountReference: 'REF123', transactionDesc: 'Wallet Topup'
      )).called(1);
    });

    test('initiateStkPush - throws exception on API failure', () async {
      when(mockPaymentEndpoints.initiateMpesaTopup(
        any, any, accountReference: anyNamed('accountReference'), transactionDesc: anyNamed('transactionDesc')
      )).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      expect(
        () => service.initiateStkPush(phoneNumber: '254712345678', amount: 100, reference: 'REF'),
        throwsA(isA<IntaSendException>())
      );
    });
  });
}
