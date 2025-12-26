import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/integrations/intasend/config/intasend_config.dart';

@Tags(['manual'])
void main() {
  test('Create Working Wallet Test', skip: 'Manual integration test - requires real IntaSend sandbox', () async {
    final env = IntaSendEnvironment.sandbox(
      publishableKey: 'ISPubKey_test_98b2ef28-5e6f-46c8-bae9-0e2acedcbf64',
      secretKey: 'ISSecretKey_test_469d4169-737d-4701-8539-ab65dd2ab2ee',
    );

    final headers = {
      'Authorization': 'Bearer ${env.secretKey}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('Attempting to create a Working Wallet...');
    
    final response = await http.post(
        Uri.parse('${env.baseUrl}/wallets/'),
        headers: headers,
        body: jsonEncode({
            'currency': 'KES',
            'label': 'Working Payouts',
            'wallet_type': 'WORKING', // Guessing field
            'can_disburse': true
        })
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  });
}
