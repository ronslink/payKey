import 'dart:convert';
import 'package:crypto/crypto.dart';

/// IntaSend webhook handler
/// 
/// Use this on your backend to handle IntaSend webhooks.
class IntaSendWebhookHandler {
  final String secretKey;
  final Future<void> Function(PaymentReceivedEvent)? onPaymentReceived;
  final Future<void> Function(PaymentFailedEvent)? onPaymentFailed;
  final Future<void> Function(PayoutCompletedEvent)? onPayoutCompleted;
  final Future<void> Function(PayoutFailedEvent)? onPayoutFailed;

  IntaSendWebhookHandler({
    required this.secretKey,
    this.onPaymentReceived,
    this.onPaymentFailed,
    this.onPayoutCompleted,
    this.onPayoutFailed,
  });

  /// Verify webhook signature
  bool verifySignature(String payload, String? signature) {
    if (signature == null) return false;

    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(payload));
    final expectedSignature = digest.toString();

    return signature == expectedSignature;
  }

  /// Handle incoming webhook
  Future<void> handleWebhook(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final eventType = json['event_type'] as String? ?? json['state'] as String?;

    switch (eventType) {
      case 'COMPLETE':
      case 'PAYMENT.RECEIVED':
        if (onPaymentReceived != null) {
          await onPaymentReceived!(PaymentReceivedEvent.fromJson(json));
        }
        break;

      case 'FAILED':
      case 'PAYMENT.FAILED':
        if (onPaymentFailed != null) {
          await onPaymentFailed!(PaymentFailedEvent.fromJson(json));
        }
        break;

      case 'PAYOUT.COMPLETED':
      case 'SUCCESSFUL':
        if (onPayoutCompleted != null) {
          await onPayoutCompleted!(PayoutCompletedEvent.fromJson(json));
        }
        break;

      case 'PAYOUT.FAILED':
        if (onPayoutFailed != null) {
          await onPayoutFailed!(PayoutFailedEvent.fromJson(json));
        }
        break;
    }
  }
}

/// Base webhook event
abstract class IntaSendWebhookEvent {
  final String eventType;
  final DateTime receivedAt;

  IntaSendWebhookEvent({
    required this.eventType,
  }) : receivedAt = DateTime.now();
}

/// Payment received event (STK Push success)
class PaymentReceivedEvent extends IntaSendWebhookEvent {
  final String invoiceId;
  final String? checkoutId;
  final double amount;
  final String currency;
  final String phoneNumber;
  final String? apiRef;
  final String? mpesaRef;
  final String? name;
  final String? email;

  PaymentReceivedEvent({
    required this.invoiceId,
    this.checkoutId,
    required this.amount,
    required this.currency,
    required this.phoneNumber,
    this.apiRef,
    this.mpesaRef,
    this.name,
    this.email,
  }) : super(eventType: 'PAYMENT.RECEIVED');

  factory PaymentReceivedEvent.fromJson(Map<String, dynamic> json) {
    return PaymentReceivedEvent(
      invoiceId: json['invoice_id'] as String? ?? json['id'] as String? ?? '',
      checkoutId: json['checkout_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      phoneNumber: json['phone_number'] as String? ?? json['account'] as String? ?? '',
      apiRef: json['api_ref'] as String?,
      mpesaRef: json['mpesa_reference'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Payment failed event
class PaymentFailedEvent extends IntaSendWebhookEvent {
  final String invoiceId;
  final String? checkoutId;
  final double amount;
  final String phoneNumber;
  final String? reason;
  final String? apiRef;

  PaymentFailedEvent({
    required this.invoiceId,
    this.checkoutId,
    required this.amount,
    required this.phoneNumber,
    this.reason,
    this.apiRef,
  }) : super(eventType: 'PAYMENT.FAILED');

  factory PaymentFailedEvent.fromJson(Map<String, dynamic> json) {
    return PaymentFailedEvent(
      invoiceId: json['invoice_id'] as String? ?? json['id'] as String? ?? '',
      checkoutId: json['checkout_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      phoneNumber: json['phone_number'] as String? ?? '',
      reason: json['failure_reason'] as String? ?? json['reason'] as String?,
      apiRef: json['api_ref'] as String?,
    );
  }
}

/// Payout completed event
class PayoutCompletedEvent extends IntaSendWebhookEvent {
  final String trackingId;
  final String? transactionRef;
  final double amount;
  final String currency;
  final String account;
  final String? name;
  final String status;

  PayoutCompletedEvent({
    required this.trackingId,
    this.transactionRef,
    required this.amount,
    required this.currency,
    required this.account,
    this.name,
    required this.status,
  }) : super(eventType: 'PAYOUT.COMPLETED');

  factory PayoutCompletedEvent.fromJson(Map<String, dynamic> json) {
    return PayoutCompletedEvent(
      trackingId: json['tracking_id'] as String? ?? '',
      transactionRef: json['transaction_ref'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      account: json['account'] as String? ?? '',
      name: json['name'] as String?,
      status: json['status'] as String? ?? 'SUCCESSFUL',
    );
  }
}

/// Payout failed event
class PayoutFailedEvent extends IntaSendWebhookEvent {
  final String trackingId;
  final double amount;
  final String account;
  final String? name;
  final String? reason;

  PayoutFailedEvent({
    required this.trackingId,
    required this.amount,
    required this.account,
    this.name,
    this.reason,
  }) : super(eventType: 'PAYOUT.FAILED');

  factory PayoutFailedEvent.fromJson(Map<String, dynamic> json) {
    return PayoutFailedEvent(
      trackingId: json['tracking_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      account: json['account'] as String? ?? '',
      name: json['name'] as String?,
      reason: json['failure_reason'] as String? ?? json['reason'] as String?,
    );
  }
}
