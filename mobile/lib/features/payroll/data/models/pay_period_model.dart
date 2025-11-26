import 'package:freezed_annotation/freezed_annotation.dart';

part 'pay_period_model.freezed.dart';
part 'pay_period_model.g.dart';

enum PayPeriodFrequency {
  weekly,
  biWeekly,
  monthly,
  quarterly,
  yearly,
}

enum PayPeriodStatus {
  DRAFT,
  ACTIVE,
  PROCESSING,
  COMPLETED,
  CLOSED,
  CANCELLED,
}

enum PayPeriodStatusAction {
  activate,
  process,
  complete,
  close,
  cancel,
  reopen,
}

@freezed
class PayPeriod with _$PayPeriod {
  const factory PayPeriod({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required PayPeriodFrequency frequency,
    required PayPeriodStatus status,
    required int totalWorkers,
    required double totalGrossAmount,
    required double totalNetAmount,
    required int processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) = _PayPeriod;

  factory PayPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayPeriodFromJson(json);
}

@freezed
class CreatePayPeriodRequest with _$CreatePayPeriodRequest {
  const factory CreatePayPeriodRequest({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required PayPeriodFrequency frequency,
    String? notes,
  }) = _CreatePayPeriodRequest;

  factory CreatePayPeriodRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePayPeriodRequestFromJson(json);
}

@freezed
class UpdatePayPeriodRequest with _$UpdatePayPeriodRequest {
  const factory UpdatePayPeriodRequest({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    PayPeriodFrequency? frequency,
    PayPeriodStatus? status,
    String? notes,
  }) = _UpdatePayPeriodRequest;

  factory UpdatePayPeriodRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePayPeriodRequestFromJson(json);
}
