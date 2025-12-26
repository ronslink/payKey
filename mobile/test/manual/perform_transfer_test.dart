import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/integrations/intasend/config/intasend_config.dart';

void main() {
  test('Transfer Funds Test', () async {
    print('Running IntaSend Fund Transfer Script...');

    // 1. Setup Environment
    final env = IntaSendEnvironment.sandbox(
      publishableKey: 'ISPubKey_test_98b2ef28-5e6f-46c8-bae9-0e2acedcbf64',
      secretKey: 'ISSecretKey_test_469d4169-737d-4701-8539-ab65dd2ab2ee',
    );

    final headers = {
      'Authorization': 'Bearer ${env.secretKey}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      // 2. Fetch Wallets
      print('Fetching wallets...');
      final walletsResponse = await http.get(
        Uri.parse('${env.baseUrl}/wallets/'),
        headers: headers,
      );

      if (walletsResponse.statusCode != 200) {
        throw Exception('Failed to fetch wallets: ${walletsResponse.body}');
      }

      final dynamic decoded = jsonDecode(walletsResponse.body);
      List<dynamic> wallets = [];
      
      if (decoded is List) {
          wallets = decoded;
      } else if (decoded is Map && decoded.containsKey('results')) {
          wallets = decoded['results'];
      } else if (decoded is Map) {
          // Maybe single wallet returned? Or error?
          print('Warning: API returned a Map without results: $decoded');
          wallets = [decoded];
      }
      
      print('Found ${wallets.length} wallets.');

      // 3. Identify Source and Destination
      Map<String, dynamic>? sourceWallet;
      Map<String, dynamic>? destWallet;

      for (var w in wallets) {
          print('Examining Wallet: ID=${w['wallet_id']}, Currency=${w['currency']}, CanDisburse=${w['can_disburse']}, Balance=${w['available_balance']}');
          
          if (w['currency'] != 'KES') continue;

          // Source: Has balance > 1000 and (can_disburse is false OR just simply has funds)
          final balance = double.tryParse(w['available_balance'].toString()) ?? 0.0;
          final canDisburse = w['can_disburse'] == true; // Strict check
          
          // Strategy: Source is HIGH balance
          if (balance > 1000) {
              sourceWallet = w;
          } 
          
          if (canDisburse || (balance == 0 && w['wallet_type'] == 'WORKING')) {
              destWallet = w;
          }
      }

      if (sourceWallet == null) {
          print('Error: Could not find a source wallet with sufficient funds (> 1000 KES).');
          return;
      }
      if (destWallet == null) {
          print('Error: Could not find a destination (disbursement) wallet.');
          return;
      }

      print('Source Wallet: ${sourceWallet['wallet_id']} - Balance: ${sourceWallet['available_balance']}');
      print('Dest Wallet: ${destWallet['wallet_id']} - Balance: ${destWallet['available_balance']}');

      final amountToTransfer = 20000.0;
      print('Transferring $amountToTransfer KES...');

      // 4. Perform Transfer
      // Endpoint: /wallets/{source_id}/intra_transfer/
      final transferUrl = '${env.baseUrl}/wallets/${sourceWallet['wallet_id']}/intra_transfer/';
      final body = jsonEncode({
          'wallet_id': destWallet['wallet_id'],
          'amount': amountToTransfer,
          'narrative': 'Transfer for Payroll Testing'
      });

      final transferResponse = await http.post(
          Uri.parse(transferUrl),
          headers: headers,
          body: body
      );

      if (transferResponse.statusCode >= 200 && transferResponse.statusCode < 300) {
          print('SUCCESS: Transfer complete.');
          print('Response: ${transferResponse.body}');
      } else {
          print('FAILED: Transfer failed.');
          print('Status: ${transferResponse.statusCode}');
          print('Body: ${transferResponse.body}');
          fail('Transfer failed: ${transferResponse.statusCode} ${transferResponse.body}');
      }

    } catch (e) {
      print('An error occurred: $e');
      fail(e.toString());
    }
  });
}
