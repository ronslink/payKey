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
  @JsonKey(fromJson: _intFromJson, toJson: _intToJson)
  const factory PayPeriod({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required PayPeriodFrequency frequency,
    required PayPeriodStatus status,
    @JsonKey(fromJson: _intFromJson, toJson: _intToJson) int? totalWorkers,
    @JsonKey(fromJson: _doubleFromJson, toJson: _doubleToJson) double? totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson, toJson: _doubleToJson) double? totalNetAmount,
    @JsonKey(fromJson: _doubleFromJson, toJson: _doubleToJson) double? totalTaxAmount,
    @JsonKey(fromJson: _intFromJson, toJson: _intToJson) int? processedWorkers,
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

// Helper function to convert string to PayPeriodFrequency (case-insensitive)
PayPeriodFrequency _frequencyFromJson(dynamic value) {
  if (value is String) {
    final upper = value.toUpperCase();
    // Handle special mapping if needed, otherwise match by name
    try {
      return PayPeriodFrequency.values.firstWhere(
        (e) {
          // Handle biWeekly specifically if needed, but BIWEEKLY matches biWeekly.toUpperCase()
          // weekly -> WEEKLY
          // biWeekly -> BIWEEKLY
          // monthly -> MONTHLY
          // quarterly -> QUARTERLY
          // yearly -> YEARLY
          
          // Check against the JsonValue annotation if possible? No, can't access it easily at runtime.
          // Just check against the expected backend values.
          if (e == PayPeriodFrequency.weekly && upper == 'WEEKLY') return true;
          if (e == PayPeriodFrequency.biWeekly && upper == 'BIWEEKLY') return true;
          if (e == PayPeriodFrequency.monthly && upper == 'MONTHLY') return true;
          if (e == PayPeriodFrequency.quarterly && upper == 'QUARTERLY') return true;
          // yearly is now properly defined in the enum
          
          // Fallback to name check
          return e.name.toUpperCase() == upper;
        },
      );
    } catch (_) {
      return PayPeriodFrequency.monthly; // Default fallback
    }
  }
  return PayPeriodFrequency.monthly;
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
