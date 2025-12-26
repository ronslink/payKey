/// IntaSend API configuration and constants
class IntaSendConfig {
  IntaSendConfig._();

  /// Sandbox base URL
  static const String sandboxBaseUrl = 'https://sandbox.intasend.com/api/v1';

  /// Production base URL
  static const String productionBaseUrl = 'https://payment.intasend.com/api/v1';

  /// API endpoints
  static const String stkPushEndpoint = '/payment/mpesa-stk-push/';
  static const String payoutEndpoint = '/send-money/initiate/';
  static const String payoutStatusEndpoint = '/send-money/status/';
  static const String walletsEndpoint = '/wallets/';
  static const String transactionsEndpoint = '/transactions/';

  /// Default currency
  static const String defaultCurrency = 'KES';

  /// Payout providers
  static const String mpesaProvider = 'MPESA-B2C';
  static const String bankProvider = 'PESALINK';

  /// Transaction status values
  static const String statusPending = 'PENDING';
  static const String statusComplete = 'COMPLETE';
  static const String statusFailed = 'FAILED';
  static const String statusProcessing = 'PROCESSING';
}

/// IntaSend environment configuration
class IntaSendEnvironment {
  final String publishableKey;
  final String secretKey;
  final bool isProduction;
  final String? webhookUrl;

  const IntaSendEnvironment({
    required this.publishableKey,
    required this.secretKey,
    this.isProduction = false,
    this.webhookUrl,
  });

  String get baseUrl => isProduction
      ? IntaSendConfig.productionBaseUrl
      : IntaSendConfig.sandboxBaseUrl;

  /// Create sandbox environment
  factory IntaSendEnvironment.sandbox({
    required String publishableKey,
    required String secretKey,
    String? webhookUrl,
  }) {
    return IntaSendEnvironment(
      publishableKey: publishableKey,
      secretKey: secretKey,
      isProduction: false,
      webhookUrl: webhookUrl,
    );
  }

  /// Create production environment
  factory IntaSendEnvironment.production({
    required String publishableKey,
    required String secretKey,
    String? webhookUrl,
  }) {
    return IntaSendEnvironment(
      publishableKey: publishableKey,
      secretKey: secretKey,
      isProduction: true,
      webhookUrl: webhookUrl,
    );
  }
}

/// IntaSend webhook event types
class IntaSendWebhookEvents {
  IntaSendWebhookEvents._();

  static const String paymentReceived = 'PAYMENT.RECEIVED';
  static const String paymentFailed = 'PAYMENT.FAILED';
  static const String payoutCompleted = 'PAYOUT.COMPLETED';
  static const String payoutFailed = 'PAYOUT.FAILED';
}
