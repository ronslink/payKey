/// IntaSend webhook configuration
/// 
/// These values should match your IntaSend dashboard webhook settings.
class IntaSendWebhookConfig {
  IntaSendWebhookConfig._();

  /// Webhook endpoint URL
  static const String webhookUrl = 'https://api.paydome.co/webhooks/intasend';

  /// Webhook challenge/secret for signature verification
  static const String webhookChallenge = 'paydome_intasend_wh_2025_Kf8mPx3nQr7vYz';
}
