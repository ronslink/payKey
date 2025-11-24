import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String tier,
    required String name,
    required double priceUSD,
    required double priceKES,
    required int workerLimit,
    required List<String> features,
    @Default(false) bool isPopular,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}
