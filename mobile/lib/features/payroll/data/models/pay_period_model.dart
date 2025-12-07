import 'package:freezed_annotation/freezed_annotation.dart';

part 'pay_period_model.freezed.dart';
part 'pay_period_model.g.dart';

enum PayPeriodFrequency {
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('BIWEEKLY')
  biWeekly,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('QUARTERLY')
  quarterly,
  @JsonValue('YEARLY')
  yearly,
}

enum PayPeriodStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CLOSED')
  closed,
  @JsonValue('CANCELLED')
  cancelled,
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
    int? totalWorkers,
    double? totalGrossAmount,
    double? totalNetAmount,
    double? totalTaxAmount,
    int? processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? userId,
    DateTime? payDate,
  }) = _PayPeriod;

  factory PayPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayPeriodFromJson(json);
}

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.parse(value);
  if (value is double) return value.toInt();
  return null;
}

double? _doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is String) return double.parse(value);
  if (value is int) return value.toDouble();
  return null;
}

// Helper functions for toJson
dynamic _intToJson(int? value) {
  return value;
}

dynamic _doubleToJson(double? value) {
  return value;
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
