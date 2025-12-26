import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/intasend_config.dart';
import '../models/intasend_models.dart';

/// IntaSend API service
/// 
/// Provides clean methods for:
/// - STK Push (collect payments)
/// - Payouts (disburse to M-Pesa)
/// - Wallet management
/// - Transaction history
class IntaSendService {
  final IntaSendEnvironment environment;
  final http.Client _client;

  IntaSendService({
    required this.environment,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Base URL for API calls
  String get baseUrl => environment.baseUrl;

  /// Authorization headers
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${environment.secretKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // STK PUSH (Collection)
  // ===========================================================================

  /// Initiate M-Pesa STK Push
  Future<StkPushResponse> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String reference,
    String? email,
    String? name,
  }) async {
    final request = StkPushRequest(
      phoneNumber: _formatPhoneNumber(phoneNumber),
      amount: amount,
      apiRef: reference,
      email: email,
      name: name,
    );

    final response = await _client.post(
      Uri.parse('$baseUrl${IntaSendConfig.stkPushEndpoint}'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return StkPushResponse.fromJson(jsonDecode(response.body));
    }

    throw IntaSendException(
      'STK Push failed',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Check STK Push status
  Future<StkPushResponse> getStkPushStatus(String invoiceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/payment/status/?invoice_id=$invoiceId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return StkPushResponse.fromJson(jsonDecode(response.body));
    }

    throw IntaSendException(
      'Failed to get STK Push status',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  // ===========================================================================
  // PAYOUTS (Disbursement)
  // ===========================================================================

  /// Send money to M-Pesa (single or batch)
  Future<PayoutResponse> sendMoney({
    required List<PayoutTransaction> transactions,
    String currency = 'KES',
    String provider = 'MPESA-B2C',
    String? callbackUrl,
  }) async {
    final request = PayoutRequest(
      currency: currency,
      provider: provider,
      callbackUrl: callbackUrl ?? environment.webhookUrl,
      transactions: transactions,
    );

    final response = await _client.post(
      Uri.parse('$baseUrl${IntaSendConfig.payoutEndpoint}'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PayoutResponse.fromJson(jsonDecode(response.body));
    }

    throw IntaSendException(
      'Payout failed',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Send money to a single M-Pesa number
  Future<PayoutResponse> sendToMpesa({
    required String phoneNumber,
    required double amount,
    required String name,
    String? narrative,
  }) async {
    return sendMoney(
      transactions: [
        PayoutTransaction(
          account: _formatPhoneNumber(phoneNumber),
          amount: amount,
          name: name,
          narrative: narrative,
        ),
      ],
    );
  }

  /// Get payout status
  Future<PayoutResponse> getPayoutStatus(String trackingId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${IntaSendConfig.payoutStatusEndpoint}?tracking_id=$trackingId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PayoutResponse.fromJson(jsonDecode(response.body));
    }

    throw IntaSendException(
      'Failed to get payout status',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Disburse salaries to multiple workers
  Future<DisbursementResult> disburseSalaries({
    required List<WorkerPayout> workers,
    String? payPeriod,
  }) async {
    final transactions = workers.map((w) {
      return PayoutTransaction(
        account: _formatPhoneNumber(w.phoneNumber),
        amount: w.amount,
        name: w.name,
        narrative: w.narrative ?? 'Salary${payPeriod != null ? ' - $payPeriod' : ''}',
      );
    }).toList();

    final response = await sendMoney(transactions: transactions);
    return DisbursementResult.fromPayoutResponse(response, workers);
  }

  // ===========================================================================
  // WALLET
  // ===========================================================================

  /// Get wallet balance
  Future<WalletInfo> getWalletBalance() async {
    final response = await _client.get(
      Uri.parse('$baseUrl${IntaSendConfig.walletsEndpoint}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Handle pagination wrapper
      dynamic normalizedData = data;
      if (data is Map<String, dynamic> && data.containsKey('results') && data['results'] is List) {
        normalizedData = data['results'];
      }

      // IntaSend returns a list of wallets, get the KES one
      if (normalizedData is List && normalizedData.isNotEmpty) {
        // Prioritize KES wallet that can disburse
        final List<dynamic> list = normalizedData;
        final kesWallet = list.firstWhere(
          (w) => w['currency'] == 'KES' && w['can_disburse'] == true,
          orElse: () => list.firstWhere(
            (w) => w['currency'] == 'KES',
            orElse: () => list.first,
          ),
        );
        return WalletInfo.fromJson(kesWallet);
      } else if (normalizedData is Map<String, dynamic>) {
        return WalletInfo.fromJson(normalizedData);
      }
      
      throw IntaSendException('Invalid wallet response format');
    }

    throw IntaSendException(
      'Failed to get wallet balance',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  /// Verify funds for payroll
  Future<FundVerification> verifyFundsForPayroll({
    required List<WorkerPayout> workers,
  }) async {
    final wallet = await getWalletBalance();
    final totalRequired = workers.fold<double>(
      0,
      (sum, w) => sum + w.amount,
    );

    return FundVerification.check(
      requiredAmount: totalRequired,
      wallet: wallet,
      workerCount: workers.length,
    );
  }

  // ===========================================================================
  // TRANSACTIONS
  // ===========================================================================

  /// Get transaction history
  Future<List<TransactionRecord>> getTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${IntaSendConfig.transactionsEndpoint}?limit=$limit&offset=$offset'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>? ?? data as List<dynamic>;
      return results
          .map((t) => TransactionRecord.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    throw IntaSendException(
      'Failed to get transactions',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Format phone number to required format
  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-+]'), '');

    if (phone.startsWith('254')) {
      return phone;
    } else if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('7') || phone.startsWith('1')) {
      return '254$phone';
    }

    return phone;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// IntaSend API exception
class IntaSendException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  IntaSendException(
    this.message, {
    this.statusCode,
    this.body,
  });

  /// Try to extract error message from response body
  String get detailedMessage {
    if (body == null) return message;
    
    try {
      final data = jsonDecode(body!);
      if (data is Map) {
        return data['message'] as String? ?? 
               data['error'] as String? ?? 
               data['detail'] as String? ?? 
               message;
      }
    } catch (_) {}
    
    return message;
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'IntaSendException: $detailedMessage (HTTP $statusCode)';
    }
    return 'IntaSendException: $detailedMessage';
  }
}
