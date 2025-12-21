// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionPlan {

 String get id; String get tier; String get name; String get description; double get priceUSD; double get priceKES; int get workerLimit; List<String> get features; bool get isPopular; bool get isActive; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of SubscriptionPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionPlanCopyWith<SubscriptionPlan> get copyWith => _$SubscriptionPlanCopyWithImpl<SubscriptionPlan>(this as SubscriptionPlan, _$identity);

  /// Serializes this SubscriptionPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceUSD, priceUSD) || other.priceUSD == priceUSD)&&(identical(other.priceKES, priceKES) || other.priceKES == priceKES)&&(identical(other.workerLimit, workerLimit) || other.workerLimit == workerLimit)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.isPopular, isPopular) || other.isPopular == isPopular)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tier,name,description,priceUSD,priceKES,workerLimit,const DeepCollectionEquality().hash(features),isPopular,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'SubscriptionPlan(id: $id, tier: $tier, name: $name, description: $description, priceUSD: $priceUSD, priceKES: $priceKES, workerLimit: $workerLimit, features: $features, isPopular: $isPopular, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubscriptionPlanCopyWith<$Res>  {
  factory $SubscriptionPlanCopyWith(SubscriptionPlan value, $Res Function(SubscriptionPlan) _then) = _$SubscriptionPlanCopyWithImpl;
@useResult
$Res call({
 String id, String tier, String name, String description, double priceUSD, double priceKES, int workerLimit, List<String> features, bool isPopular, bool isActive, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$SubscriptionPlanCopyWithImpl<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  _$SubscriptionPlanCopyWithImpl(this._self, this._then);

  final SubscriptionPlan _self;
  final $Res Function(SubscriptionPlan) _then;

/// Create a copy of SubscriptionPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tier = null,Object? name = null,Object? description = null,Object? priceUSD = null,Object? priceKES = null,Object? workerLimit = null,Object? features = null,Object? isPopular = null,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceUSD: null == priceUSD ? _self.priceUSD : priceUSD // ignore: cast_nullable_to_non_nullable
as double,priceKES: null == priceKES ? _self.priceKES : priceKES // ignore: cast_nullable_to_non_nullable
as double,workerLimit: null == workerLimit ? _self.workerLimit : workerLimit // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,isPopular: null == isPopular ? _self.isPopular : isPopular // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionPlan].
extension SubscriptionPlanPatterns on SubscriptionPlan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionPlan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionPlan value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionPlan value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tier,  String name,  String description,  double priceUSD,  double priceKES,  int workerLimit,  List<String> features,  bool isPopular,  bool isActive,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionPlan() when $default != null:
return $default(_that.id,_that.tier,_that.name,_that.description,_that.priceUSD,_that.priceKES,_that.workerLimit,_that.features,_that.isPopular,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tier,  String name,  String description,  double priceUSD,  double priceKES,  int workerLimit,  List<String> features,  bool isPopular,  bool isActive,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlan():
return $default(_that.id,_that.tier,_that.name,_that.description,_that.priceUSD,_that.priceKES,_that.workerLimit,_that.features,_that.isPopular,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tier,  String name,  String description,  double priceUSD,  double priceKES,  int workerLimit,  List<String> features,  bool isPopular,  bool isActive,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlan() when $default != null:
return $default(_that.id,_that.tier,_that.name,_that.description,_that.priceUSD,_that.priceKES,_that.workerLimit,_that.features,_that.isPopular,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionPlan implements SubscriptionPlan {
  const _SubscriptionPlan({required this.id, required this.tier, required this.name, required this.description, required this.priceUSD, required this.priceKES, required this.workerLimit, required final  List<String> features, this.isPopular = false, this.isActive = true, this.createdAt, this.updatedAt}): _features = features;
  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanFromJson(json);

@override final  String id;
@override final  String tier;
@override final  String name;
@override final  String description;
@override final  double priceUSD;
@override final  double priceKES;
@override final  int workerLimit;
 final  List<String> _features;
@override List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

@override@JsonKey() final  bool isPopular;
@override@JsonKey() final  bool isActive;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of SubscriptionPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionPlanCopyWith<_SubscriptionPlan> get copyWith => __$SubscriptionPlanCopyWithImpl<_SubscriptionPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceUSD, priceUSD) || other.priceUSD == priceUSD)&&(identical(other.priceKES, priceKES) || other.priceKES == priceKES)&&(identical(other.workerLimit, workerLimit) || other.workerLimit == workerLimit)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.isPopular, isPopular) || other.isPopular == isPopular)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tier,name,description,priceUSD,priceKES,workerLimit,const DeepCollectionEquality().hash(_features),isPopular,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'SubscriptionPlan(id: $id, tier: $tier, name: $name, description: $description, priceUSD: $priceUSD, priceKES: $priceKES, workerLimit: $workerLimit, features: $features, isPopular: $isPopular, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionPlanCopyWith<$Res> implements $SubscriptionPlanCopyWith<$Res> {
  factory _$SubscriptionPlanCopyWith(_SubscriptionPlan value, $Res Function(_SubscriptionPlan) _then) = __$SubscriptionPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String tier, String name, String description, double priceUSD, double priceKES, int workerLimit, List<String> features, bool isPopular, bool isActive, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$SubscriptionPlanCopyWithImpl<$Res>
    implements _$SubscriptionPlanCopyWith<$Res> {
  __$SubscriptionPlanCopyWithImpl(this._self, this._then);

  final _SubscriptionPlan _self;
  final $Res Function(_SubscriptionPlan) _then;

/// Create a copy of SubscriptionPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tier = null,Object? name = null,Object? description = null,Object? priceUSD = null,Object? priceKES = null,Object? workerLimit = null,Object? features = null,Object? isPopular = null,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SubscriptionPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceUSD: null == priceUSD ? _self.priceUSD : priceUSD // ignore: cast_nullable_to_non_nullable
as double,priceKES: null == priceKES ? _self.priceKES : priceKES // ignore: cast_nullable_to_non_nullable
as double,workerLimit: null == workerLimit ? _self.workerLimit : workerLimit // ignore: cast_nullable_to_non_nullable
as int,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,isPopular: null == isPopular ? _self.isPopular : isPopular // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Subscription {

 String get id; String get userId; String get planId; SubscriptionPlan get plan; String get status; DateTime get startDate; DateTime get endDate; double get amountPaid; String get currency; bool get autoRenew; DateTime? get cancelledAt; String? get cancellationReason; Map<String, dynamic>? get metadata; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.status, status) || other.status == status)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.autoRenew, autoRenew) || other.autoRenew == autoRenew)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,planId,plan,status,startDate,endDate,amountPaid,currency,autoRenew,cancelledAt,cancellationReason,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt);

@override
String toString() {
  return 'Subscription(id: $id, userId: $userId, planId: $planId, plan: $plan, status: $status, startDate: $startDate, endDate: $endDate, amountPaid: $amountPaid, currency: $currency, autoRenew: $autoRenew, cancelledAt: $cancelledAt, cancellationReason: $cancellationReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String planId, SubscriptionPlan plan, String status, DateTime startDate, DateTime endDate, double amountPaid, String currency, bool autoRenew, DateTime? cancelledAt, String? cancellationReason, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});


$SubscriptionPlanCopyWith<$Res> get plan;

}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? planId = null,Object? plan = null,Object? status = null,Object? startDate = null,Object? endDate = null,Object? amountPaid = null,Object? currency = null,Object? autoRenew = null,Object? cancelledAt = freezed,Object? cancellationReason = freezed,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,amountPaid: null == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPlanCopyWith<$Res> get plan {
  
  return $SubscriptionPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String planId,  SubscriptionPlan plan,  String status,  DateTime startDate,  DateTime endDate,  double amountPaid,  String currency,  bool autoRenew,  DateTime? cancelledAt,  String? cancellationReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.userId,_that.planId,_that.plan,_that.status,_that.startDate,_that.endDate,_that.amountPaid,_that.currency,_that.autoRenew,_that.cancelledAt,_that.cancellationReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String planId,  SubscriptionPlan plan,  String status,  DateTime startDate,  DateTime endDate,  double amountPaid,  String currency,  bool autoRenew,  DateTime? cancelledAt,  String? cancellationReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.userId,_that.planId,_that.plan,_that.status,_that.startDate,_that.endDate,_that.amountPaid,_that.currency,_that.autoRenew,_that.cancelledAt,_that.cancellationReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String planId,  SubscriptionPlan plan,  String status,  DateTime startDate,  DateTime endDate,  double amountPaid,  String currency,  bool autoRenew,  DateTime? cancelledAt,  String? cancellationReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.userId,_that.planId,_that.plan,_that.status,_that.startDate,_that.endDate,_that.amountPaid,_that.currency,_that.autoRenew,_that.cancelledAt,_that.cancellationReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.id, required this.userId, required this.planId, required this.plan, required this.status, required this.startDate, required this.endDate, this.amountPaid = 0.0, required this.currency, this.autoRenew = false, this.cancelledAt, this.cancellationReason, final  Map<String, dynamic>? metadata, this.createdAt, this.updatedAt}): _metadata = metadata;
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String planId;
@override final  SubscriptionPlan plan;
@override final  String status;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override@JsonKey() final  double amountPaid;
@override final  String currency;
@override@JsonKey() final  bool autoRenew;
@override final  DateTime? cancelledAt;
@override final  String? cancellationReason;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.status, status) || other.status == status)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.autoRenew, autoRenew) || other.autoRenew == autoRenew)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,planId,plan,status,startDate,endDate,amountPaid,currency,autoRenew,cancelledAt,cancellationReason,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt);

@override
String toString() {
  return 'Subscription(id: $id, userId: $userId, planId: $planId, plan: $plan, status: $status, startDate: $startDate, endDate: $endDate, amountPaid: $amountPaid, currency: $currency, autoRenew: $autoRenew, cancelledAt: $cancelledAt, cancellationReason: $cancellationReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String planId, SubscriptionPlan plan, String status, DateTime startDate, DateTime endDate, double amountPaid, String currency, bool autoRenew, DateTime? cancelledAt, String? cancellationReason, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});


@override $SubscriptionPlanCopyWith<$Res> get plan;

}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? planId = null,Object? plan = null,Object? status = null,Object? startDate = null,Object? endDate = null,Object? amountPaid = null,Object? currency = null,Object? autoRenew = null,Object? cancelledAt = freezed,Object? cancellationReason = freezed,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,amountPaid: null == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPlanCopyWith<$Res> get plan {
  
  return $SubscriptionPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// @nodoc
mixin _$SubscriptionPayment {

 String get id; String get subscriptionId; String get userId; double get amount; String get currency; String get status; String get paymentMethod; String get provider; String get providerTransactionId; DateTime? get processedAt; String? get failureReason; Map<String, dynamic>? get metadata; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of SubscriptionPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionPaymentCopyWith<SubscriptionPayment> get copyWith => _$SubscriptionPaymentCopyWithImpl<SubscriptionPayment>(this as SubscriptionPayment, _$identity);

  /// Serializes this SubscriptionPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.providerTransactionId, providerTransactionId) || other.providerTransactionId == providerTransactionId)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionId,userId,amount,currency,status,paymentMethod,provider,providerTransactionId,processedAt,failureReason,const DeepCollectionEquality().hash(metadata),createdAt,updatedAt);

@override
String toString() {
  return 'SubscriptionPayment(id: $id, subscriptionId: $subscriptionId, userId: $userId, amount: $amount, currency: $currency, status: $status, paymentMethod: $paymentMethod, provider: $provider, providerTransactionId: $providerTransactionId, processedAt: $processedAt, failureReason: $failureReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubscriptionPaymentCopyWith<$Res>  {
  factory $SubscriptionPaymentCopyWith(SubscriptionPayment value, $Res Function(SubscriptionPayment) _then) = _$SubscriptionPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String subscriptionId, String userId, double amount, String currency, String status, String paymentMethod, String provider, String providerTransactionId, DateTime? processedAt, String? failureReason, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$SubscriptionPaymentCopyWithImpl<$Res>
    implements $SubscriptionPaymentCopyWith<$Res> {
  _$SubscriptionPaymentCopyWithImpl(this._self, this._then);

  final SubscriptionPayment _self;
  final $Res Function(SubscriptionPayment) _then;

/// Create a copy of SubscriptionPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subscriptionId = null,Object? userId = null,Object? amount = null,Object? currency = null,Object? status = null,Object? paymentMethod = null,Object? provider = null,Object? providerTransactionId = null,Object? processedAt = freezed,Object? failureReason = freezed,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,providerTransactionId: null == providerTransactionId ? _self.providerTransactionId : providerTransactionId // ignore: cast_nullable_to_non_nullable
as String,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionPayment].
extension SubscriptionPaymentPatterns on SubscriptionPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionPayment value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPayment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionPayment value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subscriptionId,  String userId,  double amount,  String currency,  String status,  String paymentMethod,  String provider,  String providerTransactionId,  DateTime? processedAt,  String? failureReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionPayment() when $default != null:
return $default(_that.id,_that.subscriptionId,_that.userId,_that.amount,_that.currency,_that.status,_that.paymentMethod,_that.provider,_that.providerTransactionId,_that.processedAt,_that.failureReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subscriptionId,  String userId,  double amount,  String currency,  String status,  String paymentMethod,  String provider,  String providerTransactionId,  DateTime? processedAt,  String? failureReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPayment():
return $default(_that.id,_that.subscriptionId,_that.userId,_that.amount,_that.currency,_that.status,_that.paymentMethod,_that.provider,_that.providerTransactionId,_that.processedAt,_that.failureReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subscriptionId,  String userId,  double amount,  String currency,  String status,  String paymentMethod,  String provider,  String providerTransactionId,  DateTime? processedAt,  String? failureReason,  Map<String, dynamic>? metadata,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPayment() when $default != null:
return $default(_that.id,_that.subscriptionId,_that.userId,_that.amount,_that.currency,_that.status,_that.paymentMethod,_that.provider,_that.providerTransactionId,_that.processedAt,_that.failureReason,_that.metadata,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionPayment implements SubscriptionPayment {
  const _SubscriptionPayment({required this.id, required this.subscriptionId, required this.userId, required this.amount, required this.currency, required this.status, required this.paymentMethod, required this.provider, required this.providerTransactionId, this.processedAt, this.failureReason, final  Map<String, dynamic>? metadata, this.createdAt, this.updatedAt}): _metadata = metadata;
  factory _SubscriptionPayment.fromJson(Map<String, dynamic> json) => _$SubscriptionPaymentFromJson(json);

@override final  String id;
@override final  String subscriptionId;
@override final  String userId;
@override final  double amount;
@override final  String currency;
@override final  String status;
@override final  String paymentMethod;
@override final  String provider;
@override final  String providerTransactionId;
@override final  DateTime? processedAt;
@override final  String? failureReason;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of SubscriptionPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionPaymentCopyWith<_SubscriptionPayment> get copyWith => __$SubscriptionPaymentCopyWithImpl<_SubscriptionPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.providerTransactionId, providerTransactionId) || other.providerTransactionId == providerTransactionId)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionId,userId,amount,currency,status,paymentMethod,provider,providerTransactionId,processedAt,failureReason,const DeepCollectionEquality().hash(_metadata),createdAt,updatedAt);

@override
String toString() {
  return 'SubscriptionPayment(id: $id, subscriptionId: $subscriptionId, userId: $userId, amount: $amount, currency: $currency, status: $status, paymentMethod: $paymentMethod, provider: $provider, providerTransactionId: $providerTransactionId, processedAt: $processedAt, failureReason: $failureReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionPaymentCopyWith<$Res> implements $SubscriptionPaymentCopyWith<$Res> {
  factory _$SubscriptionPaymentCopyWith(_SubscriptionPayment value, $Res Function(_SubscriptionPayment) _then) = __$SubscriptionPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String subscriptionId, String userId, double amount, String currency, String status, String paymentMethod, String provider, String providerTransactionId, DateTime? processedAt, String? failureReason, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$SubscriptionPaymentCopyWithImpl<$Res>
    implements _$SubscriptionPaymentCopyWith<$Res> {
  __$SubscriptionPaymentCopyWithImpl(this._self, this._then);

  final _SubscriptionPayment _self;
  final $Res Function(_SubscriptionPayment) _then;

/// Create a copy of SubscriptionPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subscriptionId = null,Object? userId = null,Object? amount = null,Object? currency = null,Object? status = null,Object? paymentMethod = null,Object? provider = null,Object? providerTransactionId = null,Object? processedAt = freezed,Object? failureReason = freezed,Object? metadata = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SubscriptionPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,providerTransactionId: null == providerTransactionId ? _self.providerTransactionId : providerTransactionId // ignore: cast_nullable_to_non_nullable
as String,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SubscriptionUsage {

 String get id; String get subscriptionId; String get userId; int get currentWorkers; int get maxWorkers; double get usagePercentage; DateTime? get lastUpdated; Map<String, dynamic>? get breakdown;
/// Create a copy of SubscriptionUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionUsageCopyWith<SubscriptionUsage> get copyWith => _$SubscriptionUsageCopyWithImpl<SubscriptionUsage>(this as SubscriptionUsage, _$identity);

  /// Serializes this SubscriptionUsage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionUsage&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.currentWorkers, currentWorkers) || other.currentWorkers == currentWorkers)&&(identical(other.maxWorkers, maxWorkers) || other.maxWorkers == maxWorkers)&&(identical(other.usagePercentage, usagePercentage) || other.usagePercentage == usagePercentage)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&const DeepCollectionEquality().equals(other.breakdown, breakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionId,userId,currentWorkers,maxWorkers,usagePercentage,lastUpdated,const DeepCollectionEquality().hash(breakdown));

@override
String toString() {
  return 'SubscriptionUsage(id: $id, subscriptionId: $subscriptionId, userId: $userId, currentWorkers: $currentWorkers, maxWorkers: $maxWorkers, usagePercentage: $usagePercentage, lastUpdated: $lastUpdated, breakdown: $breakdown)';
}


}

/// @nodoc
abstract mixin class $SubscriptionUsageCopyWith<$Res>  {
  factory $SubscriptionUsageCopyWith(SubscriptionUsage value, $Res Function(SubscriptionUsage) _then) = _$SubscriptionUsageCopyWithImpl;
@useResult
$Res call({
 String id, String subscriptionId, String userId, int currentWorkers, int maxWorkers, double usagePercentage, DateTime? lastUpdated, Map<String, dynamic>? breakdown
});




}
/// @nodoc
class _$SubscriptionUsageCopyWithImpl<$Res>
    implements $SubscriptionUsageCopyWith<$Res> {
  _$SubscriptionUsageCopyWithImpl(this._self, this._then);

  final SubscriptionUsage _self;
  final $Res Function(SubscriptionUsage) _then;

/// Create a copy of SubscriptionUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subscriptionId = null,Object? userId = null,Object? currentWorkers = null,Object? maxWorkers = null,Object? usagePercentage = null,Object? lastUpdated = freezed,Object? breakdown = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,currentWorkers: null == currentWorkers ? _self.currentWorkers : currentWorkers // ignore: cast_nullable_to_non_nullable
as int,maxWorkers: null == maxWorkers ? _self.maxWorkers : maxWorkers // ignore: cast_nullable_to_non_nullable
as int,usagePercentage: null == usagePercentage ? _self.usagePercentage : usagePercentage // ignore: cast_nullable_to_non_nullable
as double,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionUsage].
extension SubscriptionUsagePatterns on SubscriptionUsage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionUsage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionUsage value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionUsage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionUsage value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionUsage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subscriptionId,  String userId,  int currentWorkers,  int maxWorkers,  double usagePercentage,  DateTime? lastUpdated,  Map<String, dynamic>? breakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionUsage() when $default != null:
return $default(_that.id,_that.subscriptionId,_that.userId,_that.currentWorkers,_that.maxWorkers,_that.usagePercentage,_that.lastUpdated,_that.breakdown);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subscriptionId,  String userId,  int currentWorkers,  int maxWorkers,  double usagePercentage,  DateTime? lastUpdated,  Map<String, dynamic>? breakdown)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionUsage():
return $default(_that.id,_that.subscriptionId,_that.userId,_that.currentWorkers,_that.maxWorkers,_that.usagePercentage,_that.lastUpdated,_that.breakdown);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subscriptionId,  String userId,  int currentWorkers,  int maxWorkers,  double usagePercentage,  DateTime? lastUpdated,  Map<String, dynamic>? breakdown)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionUsage() when $default != null:
return $default(_that.id,_that.subscriptionId,_that.userId,_that.currentWorkers,_that.maxWorkers,_that.usagePercentage,_that.lastUpdated,_that.breakdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionUsage implements SubscriptionUsage {
  const _SubscriptionUsage({required this.id, required this.subscriptionId, required this.userId, required this.currentWorkers, required this.maxWorkers, required this.usagePercentage, this.lastUpdated, final  Map<String, dynamic>? breakdown}): _breakdown = breakdown;
  factory _SubscriptionUsage.fromJson(Map<String, dynamic> json) => _$SubscriptionUsageFromJson(json);

@override final  String id;
@override final  String subscriptionId;
@override final  String userId;
@override final  int currentWorkers;
@override final  int maxWorkers;
@override final  double usagePercentage;
@override final  DateTime? lastUpdated;
 final  Map<String, dynamic>? _breakdown;
@override Map<String, dynamic>? get breakdown {
  final value = _breakdown;
  if (value == null) return null;
  if (_breakdown is EqualUnmodifiableMapView) return _breakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SubscriptionUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionUsageCopyWith<_SubscriptionUsage> get copyWith => __$SubscriptionUsageCopyWithImpl<_SubscriptionUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionUsageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionUsage&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.currentWorkers, currentWorkers) || other.currentWorkers == currentWorkers)&&(identical(other.maxWorkers, maxWorkers) || other.maxWorkers == maxWorkers)&&(identical(other.usagePercentage, usagePercentage) || other.usagePercentage == usagePercentage)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&const DeepCollectionEquality().equals(other._breakdown, _breakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionId,userId,currentWorkers,maxWorkers,usagePercentage,lastUpdated,const DeepCollectionEquality().hash(_breakdown));

@override
String toString() {
  return 'SubscriptionUsage(id: $id, subscriptionId: $subscriptionId, userId: $userId, currentWorkers: $currentWorkers, maxWorkers: $maxWorkers, usagePercentage: $usagePercentage, lastUpdated: $lastUpdated, breakdown: $breakdown)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionUsageCopyWith<$Res> implements $SubscriptionUsageCopyWith<$Res> {
  factory _$SubscriptionUsageCopyWith(_SubscriptionUsage value, $Res Function(_SubscriptionUsage) _then) = __$SubscriptionUsageCopyWithImpl;
@override @useResult
$Res call({
 String id, String subscriptionId, String userId, int currentWorkers, int maxWorkers, double usagePercentage, DateTime? lastUpdated, Map<String, dynamic>? breakdown
});




}
/// @nodoc
class __$SubscriptionUsageCopyWithImpl<$Res>
    implements _$SubscriptionUsageCopyWith<$Res> {
  __$SubscriptionUsageCopyWithImpl(this._self, this._then);

  final _SubscriptionUsage _self;
  final $Res Function(_SubscriptionUsage) _then;

/// Create a copy of SubscriptionUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subscriptionId = null,Object? userId = null,Object? currentWorkers = null,Object? maxWorkers = null,Object? usagePercentage = null,Object? lastUpdated = freezed,Object? breakdown = freezed,}) {
  return _then(_SubscriptionUsage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,currentWorkers: null == currentWorkers ? _self.currentWorkers : currentWorkers // ignore: cast_nullable_to_non_nullable
as int,maxWorkers: null == maxWorkers ? _self.maxWorkers : maxWorkers // ignore: cast_nullable_to_non_nullable
as int,usagePercentage: null == usagePercentage ? _self.usagePercentage : usagePercentage // ignore: cast_nullable_to_non_nullable
as double,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,breakdown: freezed == breakdown ? _self._breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
