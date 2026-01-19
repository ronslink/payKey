import 'package:flutter/foundation.dart';
import '../config/intasend_config.dart';

// =============================================================================
// STK PUSH MODELS
// =============================================================================

/// STK Push request
@immutable
class StkPushRequest {
  final String phoneNumber;
  final double amount;
  final String apiRef;
  final String? email;
  final String? name;

  const StkPushRequest({
    required this.phoneNumber,
    required this.amount,
    required this.apiRef,
    this.email,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'amount': amount,
      'api_ref': apiRef,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }
}

/// STK Push response
@immutable
class StkPushResponse {
  final String? invoiceId;
  final String status;
  final String? checkoutId;
  final String? message;
  final DateTime createdAt;

  const StkPushResponse({
    this.invoiceId,
    required this.status,
    this.checkoutId,
    this.message,
    required this.createdAt,
  });

  bool get isInitiated => status == 'PENDING' || status == 'CREATED';
  bool get isComplete => status == 'COMPLETE';
  bool get isFailed => status == 'FAILED';

  factory StkPushResponse.fromJson(Map<String, dynamic> json) {
    return StkPushResponse(
      invoiceId: json['invoice']?['invoice_id'] as String? ?? json['invoice_id'] as String?,
      status: json['invoice']?['state'] as String? ?? json['status'] as String? ?? 'PENDING',
      checkoutId: json['id'] as String? ?? json['checkout_id'] as String?,
      message: json['message'] as String?,
      createdAt: DateTime.now(),
    );
  }
}

// =============================================================================
// PAYOUT MODELS
// =============================================================================

/// Single payout transaction
@immutable
class PayoutTransaction {
  final String account;
  final double amount;
  final String name;
  final String? narrative;

  const PayoutTransaction({
    required this.account,
    required this.amount,
    required this.name,
    this.narrative,
  });

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'amount': amount.toString(),
      'name': name,
      if (narrative != null) 'narrative': narrative,
    };
  }
}

/// Payout request for batch disbursement
@immutable
class PayoutRequest {
  final String currency;
  final String provider;
  final String? callbackUrl;
  final List<PayoutTransaction> transactions;

  const PayoutRequest({
    this.currency = 'KES',
    this.provider = 'MPESA-B2C',
    this.callbackUrl,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'provider': provider,
      if (callbackUrl != null) 'callback_url': callbackUrl,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

/// Payout response
@immutable
class PayoutResponse {
  final String? trackingId;
  final String status;
  final String? batchReference;
  final int? totalCount;
  final List<PayoutItemResponse> transactions;
  final DateTime createdAt;

  const PayoutResponse({
    this.trackingId,
    required this.status,
    this.batchReference,
    this.totalCount,
    required this.transactions,
    required this.createdAt,
  });

  bool get isPending => status == IntaSendConfig.statusPending;
  bool get isProcessing => status == IntaSendConfig.statusProcessing;
  bool get isComplete => status == IntaSendConfig.statusComplete;
  bool get isFailed => status == IntaSendConfig.statusFailed;

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    final txnList = json['transactions'] as List<dynamic>? ?? [];
    
    return PayoutResponse(
      trackingId: json['tracking_id'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      batchReference: json['batch_reference'] as String?,
      totalCount: json['total'] as int?,
      transactions: txnList
          .map((t) => PayoutItemResponse.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.now(),
    );
  }
}

/// Individual payout item response
@immutable
class PayoutItemResponse {
  final String? id;
  final String status;
  final String account;
  final double amount;
  final String? name;
  final String? narrative;
  final String? failureReason;
  final String? transactionRef;

  const PayoutItemResponse({
    this.id,
    required this.status,
    required this.account,
    required this.amount,
    this.name,
    this.narrative,
    this.failureReason,
    this.transactionRef,
  });

  bool get isSuccess => status == 'SUCCESSFUL' || status == 'COMPLETE';
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
  bool get isFailed => status == 'FAILED';

  factory PayoutItemResponse.fromJson(Map<String, dynamic> json) {
    return PayoutItemResponse(
      id: json['id']?.toString(),
      status: json['status'] as String? ?? 'PENDING',
      account: json['account'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      name: json['name'] as String?,
      narrative: json['narrative'] as String?,
      failureReason: json['failure_reason'] as String?,
      transactionRef: json['transaction_ref'] as String?,
    );
  }
}

// =============================================================================
// WALLET MODELS
// =============================================================================

/// Wallet information
@immutable
class WalletInfo {
  final String? walletId;
  final String currency;
  final double availableBalance;
  final double currentBalance;
  final double? floatBalance;
  final String? label;
  final bool canDisburse;
  final double clearingBalance;
  final DateTime updatedAt;

  const WalletInfo({
    this.walletId,
    required this.currency,
    required this.availableBalance,
    required this.currentBalance,
    this.floatBalance,
    this.floatBalance,
    this.label,
    required this.canDisburse,
    this.clearingBalance = 0.0,
    required this.updatedAt,
  });

  /// Check if wallet has sufficient funds
  bool hasSufficientFunds(double amount) => availableBalance >= amount;

  /// Calculate shortfall
  double shortfall(double amount) {
    if (hasSufficientFunds(amount)) return 0;
    return amount - availableBalance;
  }

  /// Formatted balance
  String get formattedBalance => '$currency ${availableBalance.toStringAsFixed(2)}';

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      walletId: json['wallet_id'] as String?,
      currency: json['currency'] as String? ?? 'KES',
      availableBalance: _parseDouble(json['available_balance']),
      currentBalance: _parseDouble(json['current_balance']),
      floatBalance: json['float_balance'] != null 
          ? _parseDouble(json['float_balance']) 
          : null,
      label: json['label'] as String?,
      canDisburse: json['can_disburse'] as bool? ?? true,
      clearingBalance: _parseDouble(json['clearing_balance']),
      updatedAt: DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

// =============================================================================
// TRANSACTION MODELS
// =============================================================================

/// Transaction record
@immutable
class TransactionRecord {
  final String id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String? reference;
  final String? account;
  final String? narrative;
  final DateTime createdAt;

  const TransactionRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.reference,
    this.account,
    this.narrative,
    required this.createdAt,
  });

  bool get isCredit => type == 'CREDIT' || type == 'COLLECTION';
  bool get isDebit => type == 'DEBIT' || type == 'PAYOUT';

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      reference: json['reference'] as String?,
      account: json['account'] as String?,
      narrative: json['narrative'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// =============================================================================
// DISBURSEMENT BATCH MODELS
// =============================================================================

/// Batch disbursement result (for UI)
@immutable
class DisbursementResult {
  final String? trackingId;
  final List<DisbursementItemResult> items;
  final int totalCount;
  final int successCount;
  final int pendingCount;
  final int failedCount;
  final double totalAmount;

  const DisbursementResult({
    this.trackingId,
    required this.items,
    required this.totalCount,
    required this.successCount,
    required this.pendingCount,
    required this.failedCount,
    required this.totalAmount,
  });

  bool get allSuccessful => failedCount == 0 && pendingCount == 0;
  bool get allPending => pendingCount == totalCount;
  bool get hasFailures => failedCount > 0;

  factory DisbursementResult.fromPayoutResponse(
    PayoutResponse response,
    List<WorkerPayout> originalWorkers,
  ) {
    final items = <DisbursementItemResult>[];
    
    for (var i = 0; i < response.transactions.length; i++) {
      final txn = response.transactions[i];
      final worker = i < originalWorkers.length ? originalWorkers[i] : null;
      
      items.add(DisbursementItemResult(
        workerId: worker?.workerId ?? '',
        workerName: txn.name ?? worker?.name ?? 'Unknown',
        phoneNumber: txn.account,
        amount: txn.amount,
        status: txn.status,
        transactionRef: txn.transactionRef,
        error: txn.failureReason,
      ));
    }

    final successful = items.where((i) => i.isSuccess).length;
    final pending = items.where((i) => i.isPending).length;
    final failed = items.where((i) => i.isFailed).length;
    final total = items.fold<double>(0, (sum, i) => sum + i.amount);

    return DisbursementResult(
      trackingId: response.trackingId,
      items: items,
      totalCount: items.length,
      successCount: successful,
      pendingCount: pending,
      failedCount: failed,
      totalAmount: total,
    );
  }
}

/// Single disbursement item result
@immutable
class DisbursementItemResult {
  final String workerId;
  final String workerName;
  final String phoneNumber;
  final double amount;
  final String status;
  final String? transactionRef;
  final String? error;

  const DisbursementItemResult({
    required this.workerId,
    required this.workerName,
    required this.phoneNumber,
    required this.amount,
    required this.status,
    this.transactionRef,
    this.error,
  });

  bool get isSuccess => status == 'SUCCESSFUL' || status == 'COMPLETE';
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
  bool get isFailed => status == 'FAILED';
}

/// Worker payout input
@immutable
class WorkerPayout {
  final String workerId;
  final String name;
  final String phoneNumber;
  final double amount;
  final String? narrative;

  const WorkerPayout({
    required this.workerId,
    required this.name,
    required this.phoneNumber,
    required this.amount,
    this.narrative,
  });

  /// Convert to payout transaction
  PayoutTransaction toTransaction() {
    return PayoutTransaction(
      account: phoneNumber,
      amount: amount,
      name: name,
      narrative: narrative,
    );
  }
}

// =============================================================================
// FUND VERIFICATION
// =============================================================================

/// Fund verification result for payroll
@immutable
class FundVerification {
  final double requiredAmount;
  final double availableBalance;
  final double clearingBalance;
  final double shortfall;
  final int workerCount;
  final bool canProceed;

  const FundVerification({
    required this.requiredAmount,
    required this.availableBalance,
    this.clearingBalance = 0.0,
    required this.shortfall,
    required this.workerCount,
    required this.canProceed,
  });

  String get formattedRequired => 'KES ${requiredAmount.toStringAsFixed(0)}';
  String get formattedBalance => 'KES ${availableBalance.toStringAsFixed(0)}';
  String get formattedShortfall => 'KES ${shortfall.toStringAsFixed(0)}';

  factory FundVerification.check({
    required double requiredAmount,
    required WalletInfo wallet,
    required int workerCount,
  }) {
    final shortfall = wallet.shortfall(requiredAmount);
    return FundVerification(
      requiredAmount: requiredAmount,
      availableBalance: wallet.availableBalance,
      clearingBalance: wallet.clearingBalance,
      shortfall: shortfall,
      workerCount: workerCount,
      canProceed: shortfall == 0,
    );
  }
}
