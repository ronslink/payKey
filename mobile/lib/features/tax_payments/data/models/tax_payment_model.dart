import 'package:freezed_annotation/freezed_annotation.dart';

part 'tax_payment_model.freezed.dart';
part 'tax_payment_model.g.dart';

enum TaxType {
  @JsonValue('PAYE')
  paye,
  @JsonValue('SHIF')
  shif,
  @JsonValue('NSSF_TIER1')
  nssfTier1,
  @JsonValue('NSSF_TIER2')
  nssfTier2,
  @JsonValue('HOUSING_LEVY')
  housingLevy,
}

enum PaymentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('PAID')
  paid,
  @JsonValue('OVERDUE')
  overdue,
}

enum PaymentMethod {
  @JsonValue('MPESA')
  mpesa,
  @JsonValue('BANK')
  bank,
}

@freezed
class TaxPayment with _$TaxPayment {
  const factory TaxPayment({
    required String id,
    required TaxType taxType,
    required int paymentYear,
    required int paymentMonth,
    required double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    required PaymentStatus status,
    String? notes,
    required String createdAt,
  }) = _TaxPayment;

  factory TaxPayment.fromJson(Map<String, dynamic> json) =>
      _$TaxPaymentFromJson(json);
}

@freezed
class TaxSummary with _$TaxSummary {
  const factory TaxSummary({
    required TaxType taxType,
    required double amount,
    required String status,
    required String dueDate,
  }) = _TaxSummary;

  factory TaxSummary.fromJson(Map<String, dynamic> json) =>
      _$TaxSummaryFromJson(json);
}

@freezed
class MonthlyTaxSummary with _$MonthlyTaxSummary {
  const factory MonthlyTaxSummary({
    required int year,
    required int month,
    required double totalDue,
    required double totalPaid,
    required List<TaxSummary> taxes,
    required PaymentInstructions paymentInstructions,
  }) = _MonthlyTaxSummary;

  factory MonthlyTaxSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTaxSummaryFromJson(json);
}

@freezed
class PaymentInstructions with _$PaymentInstructions {
  const factory PaymentInstructions({
    required MpesaInstructions mpesa,
    required String bank,
    required String deadline,
  }) = _PaymentInstructions;

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) =>
      _$PaymentInstructionsFromJson(json);
}

@freezed
class MpesaInstructions with _$MpesaInstructions {
  const factory MpesaInstructions({
    required String paybill,
    required String accountNumber,
  }) = _MpesaInstructions;

  factory MpesaInstructions.fromJson(Map<String, dynamic> json) =>
      _$MpesaInstructionsFromJson(json);
}

@freezed
class TaxPaymentRequest with _$TaxPaymentRequest {
  const factory TaxPaymentRequest({
    required TaxType taxType,
    required int paymentYear,
    required int paymentMonth,
    required double amount,
    String? paymentDate,
    PaymentMethod? paymentMethod,
    String? receiptNumber,
    String? notes,
  }) = _TaxPaymentRequest;

  factory TaxPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$TaxPaymentRequestFromJson(json);
}

// Helper extensions
extension TaxTypeExtension on TaxType {
  String get displayName {
    switch (this) {
      case TaxType.paye:
        return 'PAYE';
      case TaxType.shif:
        return 'SHIF';
      case TaxType.nssfTier1:
        return 'NSSF Tier I';
      case TaxType.nssfTier2:
        return 'NSSF Tier II';
      case TaxType.housingLevy:
        return 'Housing Levy';
    }
  }

  String get description {
    switch (this) {
      case TaxType.paye:
        return 'Pay As You Earn';
      case TaxType.shif:
        return 'Social Health Insurance Fund';
      case TaxType.nssfTier1:
        return 'NSSF Tier I (First KES 8,000)';
      case TaxType.nssfTier2:
        return 'NSSF Tier II (KES 8,001-72,000)';
      case TaxType.housingLevy:
        return 'Affordable Housing Levy';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
    }
  }
}
