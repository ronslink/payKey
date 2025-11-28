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
    @JsonKey(fromJson: _frequencyFromJson) required PayPeriodFrequency frequency,
    required PayPeriodStatus status,
    @JsonKey(fromJson: _intFromJson) required int totalWorkers,
    @JsonKey(fromJson: _doubleFromJson) required double totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson) required double totalNetAmount,
    @JsonKey(fromJson: _intFromJson) required int processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) = _PayPeriod;

  factory PayPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayPeriodFromJson(json);
}

// Helper functions to convert string/num to int
int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  if (value is double) return value.toInt();
  return 0;
}

// Helper functions to convert string/num to double
double _doubleFromJson(dynamic value) {
  if (value is double) return value;
  if (value is String) return double.parse(value);
  if (value is int) return value.toDouble();
  return 0.0;
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
          if (e == PayPeriodFrequency.yearly && upper == 'YEARLY') return true;
          
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
