// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionPlanImpl _$$SubscriptionPlanImplFromJson(
  Map<String, dynamic> json,
) => _$SubscriptionPlanImpl(
  tier: json['tier'] as String,
  name: json['name'] as String,
  priceUSD: (json['priceUSD'] as num).toDouble(),
  priceKES: (json['priceKES'] as num).toDouble(),
  workerLimit: (json['workerLimit'] as num).toInt(),
  features: (json['features'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isPopular: json['isPopular'] as bool? ?? false,
);

Map<String, dynamic> _$$SubscriptionPlanImplToJson(
  _$SubscriptionPlanImpl instance,
) => <String, dynamic>{
  'tier': instance.tier,
  'name': instance.name,
  'priceUSD': instance.priceUSD,
  'priceKES': instance.priceKES,
  'workerLimit': instance.workerLimit,
  'features': instance.features,
  'isPopular': instance.isPopular,
};
