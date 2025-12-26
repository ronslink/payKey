import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/integrations/intasend/config/intasend_config.dart';
import 'package:mobile/integrations/intasend/services/intasend_service.dart';
// import 'package:http/http.dart' as http;

@Tags(['manual'])
void main() {
  test('IntaSend Integration Test - Sandbox Payout', skip: 'Manual integration test - requires real IntaSend sandbox', () async {
    // Keys from intasend_providers.dart
    final env = IntaSendEnvironment.sandbox(
      publishableKey: 'ISPubKey_test_98b2ef28-5e6f-46c8-bae9-0e2acedcbf64',
      secretKey: 'ISSecretKey_test_469d4169-737d-4701-8539-ab65dd2ab2ee',
    );

    final service = IntaSendService(environment: env);

    print('1. Checking Wallet Balance...');
    try {
      final wallet = await service.getWalletBalance();
      print('   Wallet Balance: ${wallet.availableBalance} ${wallet.currency}');
      
      if (wallet.availableBalance < 100) {
        print('   WARNING: Low balance. Top up might be needed.');
      }
    } catch (e) {
      print('   Error checking balance: $e');
      if (e is IntaSendException) {
         print('   Status Code: ${e.statusCode}');
         print('   Body: ${e.body}');
      }
      fail('Failed to connect to IntaSend Sandbox used by the app');
    }

    print('\n2. Testing Payout to Test Number (254708374149)...');
    try {
      final response = await service.sendToMpesa(
        phoneNumber: '254708374149',
        amount: 50.0,
        name: 'Test Wrapper',
        narrative: 'Integration Test'
      );
      
      print('   Payout Initiated Successfully.');
      print('   Tracking ID: ${response.trackingId}');
      print('   Status: ${response.status}');
      
      // Basic validation
      expect(response.trackingId, isNotNull);
      
    } catch (e) {
      print('   Error sending money: $e');
      if (e is IntaSendException) {
         print('   Status Code: ${e.statusCode}');
         print('   Body: ${e.body}');
      }
      fail('Failed to send money');
    } finally {
      service.dispose();
    }
  });
}
