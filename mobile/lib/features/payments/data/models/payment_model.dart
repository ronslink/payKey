import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

enum TransactionType {
  @JsonValue('SUBSCRIPTION')
  subscription,
  @JsonValue('SALARY_PAYOUT')
  salaryPayout,
  @JsonValue('TOPUP')
  topup,
}

enum TransactionStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('SUCCESS')
  success,
  @JsonValue('FAILED')
  failed,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String userId,
    String? workerId,
    required double amount,
    @Default('KES') String currency,
    required TransactionType type,
    required TransactionStatus status,
    String? providerRef,
    Map<String, dynamic>? metadata,
    required String createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

@freezed
class TopupRequest with _$TopupRequest {
  const factory TopupRequest({
    required String phoneNumber,
    required double amount,
  }) = _TopupRequest;

  factory TopupRequest.fromJson(Map<String, dynamic> json) =>
      _$TopupRequestFromJson(json);
}

@freezed
class PaymentResponse with _$PaymentResponse {
  const factory PaymentResponse({
    required String message,
    String? checkoutRequestId,
    Transaction? transaction,
  }) = _PaymentResponse;

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);
}
