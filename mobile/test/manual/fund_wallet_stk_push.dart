import 'package:mobile/integrations/intasend/config/intasend_config.dart';
import 'package:mobile/integrations/intasend/services/intasend_service.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart test/manual/fund_wallet_stk_push.dart <phone_number> <amount>');
    print('Example: dart test/manual/fund_wallet_stk_push.dart 254712345678 100');
    return;
  }

  final phone = args[0];
  final amount = double.tryParse(args.length > 1 ? args[1] : '100') ?? 100.0;

  final env = IntaSendEnvironment.sandbox(
    // Using keys from intasend_providers.dart
    publishableKey: 'ISPubKey_test_98b2ef28-5e6f-46c8-bae9-0e2acedcbf64',
    secretKey: 'ISSecretKey_test_469d4169-737d-4701-8539-ab65dd2ab2ee',
  );
  
  final service = IntaSendService(environment: env);

  print('Initiating STK Push to $phone for $amount KES...');

  try {
    final response = await service.initiateStkPush(
      phoneNumber: phone,
      amount: amount,
      reference: 'FUND-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Dev Funding',
      email: 'dev@example.com'
    );

    print('STK Push Initiated!');
    print('Invoice ID: ${response.invoiceId}');
    print('Check your phone to complete the transaction.');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    service.dispose();
  }
}
