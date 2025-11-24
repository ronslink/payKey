import 'package:freezed_annotation/freezed_annotation.dart';

part 'pay_period_model.freezed.dart';
part 'pay_period_model.g.dart';

enum PayPeriodStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('CLOSED')
  closed,
}

@freezed
class PayPeriod with _$PayPeriod {
  const factory PayPeriod({
    required String id,
    required String userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    @Default(PayPeriodStatus.open) PayPeriodStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PayPeriod;

  factory PayPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayPeriodFromJson(json);
}
