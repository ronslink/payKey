// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) {
  return _SubscriptionPlan.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionPlan {
  String get id => throw _privateConstructorUsedError;
  String get tier => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get priceUSD => throw _privateConstructorUsedError;
  double get priceKES => throw _privateConstructorUsedError;
  int get workerLimit => throw _privateConstructorUsedError;
  List<String> get features => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionPlanCopyWith<SubscriptionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPlanCopyWith<$Res> {
  factory $SubscriptionPlanCopyWith(
    SubscriptionPlan value,
    $Res Function(SubscriptionPlan) then,
  ) = _$SubscriptionPlanCopyWithImpl<$Res, SubscriptionPlan>;
  @useResult
  $Res call({
    String id,
    String tier,
    String name,
    String description,
    double priceUSD,
    double priceKES,
    int workerLimit,
    List<String> features,
    bool isPopular,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$SubscriptionPlanCopyWithImpl<$Res, $Val extends SubscriptionPlan>
    implements $SubscriptionPlanCopyWith<$Res> {
  _$SubscriptionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tier = null,
    Object? name = null,
    Object? description = null,
    Object? priceUSD = null,
    Object? priceKES = null,
    Object? workerLimit = null,
    Object? features = null,
    Object? isPopular = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tier: null == tier
                ? _value.tier
                : tier // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            priceUSD: null == priceUSD
                ? _value.priceUSD
                : priceUSD // ignore: cast_nullable_to_non_nullable
                      as double,
            priceKES: null == priceKES
                ? _value.priceKES
                : priceKES // ignore: cast_nullable_to_non_nullable
                      as double,
            workerLimit: null == workerLimit
                ? _value.workerLimit
                : workerLimit // ignore: cast_nullable_to_non_nullable
                      as int,
            features: null == features
                ? _value.features
                : features // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isPopular: null == isPopular
                ? _value.isPopular
                : isPopular // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubscriptionPlanImplCopyWith<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  factory _$$SubscriptionPlanImplCopyWith(
    _$SubscriptionPlanImpl value,
    $Res Function(_$SubscriptionPlanImpl) then,
  ) = __$$SubscriptionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tier,
    String name,
    String description,
    double priceUSD,
    double priceKES,
    int workerLimit,
    List<String> features,
    bool isPopular,
    bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SubscriptionPlanImplCopyWithImpl<$Res>
    extends _$SubscriptionPlanCopyWithImpl<$Res, _$SubscriptionPlanImpl>
    implements _$$SubscriptionPlanImplCopyWith<$Res> {
  __$$SubscriptionPlanImplCopyWithImpl(
    _$SubscriptionPlanImpl _value,
    $Res Function(_$SubscriptionPlanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tier = null,
    Object? name = null,
    Object? description = null,
    Object? priceUSD = null,
    Object? priceKES = null,
    Object? workerLimit = null,
    Object? features = null,
    Object? isPopular = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SubscriptionPlanImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tier: null == tier
            ? _value.tier
            : tier // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        priceUSD: null == priceUSD
            ? _value.priceUSD
            : priceUSD // ignore: cast_nullable_to_non_nullable
                  as double,
        priceKES: null == priceKES
            ? _value.priceKES
            : priceKES // ignore: cast_nullable_to_non_nullable
                  as double,
        workerLimit: null == workerLimit
            ? _value.workerLimit
            : workerLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        features: null == features
            ? _value._features
            : features // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isPopular: null == isPopular
            ? _value.isPopular
            : isPopular // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionPlanImpl implements _SubscriptionPlan {
  const _$SubscriptionPlanImpl({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.priceUSD,
    required this.priceKES,
    required this.workerLimit,
    required final List<String> features,
    this.isPopular = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  }) : _features = features;

  factory _$SubscriptionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String tier;
  @override
  final String name;
  @override
  final String description;
  @override
  final double priceUSD;
  @override
  final double priceKES;
  @override
  final int workerLimit;
  final List<String> _features;
  @override
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  @JsonKey()
  final bool isPopular;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, tier: $tier, name: $name, description: $description, priceUSD: $priceUSD, priceKES: $priceKES, workerLimit: $workerLimit, features: $features, isPopular: $isPopular, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.priceUSD, priceUSD) ||
                other.priceUSD == priceUSD) &&
            (identical(other.priceKES, priceKES) ||
                other.priceKES == priceKES) &&
            (identical(other.workerLimit, workerLimit) ||
                other.workerLimit == workerLimit) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tier,
    name,
    description,
    priceUSD,
    priceKES,
    workerLimit,
    const DeepCollectionEquality().hash(_features),
    isPopular,
    isActive,
    createdAt,
    updatedAt,
  );

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      __$$SubscriptionPlanImplCopyWithImpl<_$SubscriptionPlanImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionPlanImplToJson(this);
  }
}

abstract class _SubscriptionPlan implements SubscriptionPlan {
  const factory _SubscriptionPlan({
    required final String id,
    required final String tier,
    required final String name,
    required final String description,
    required final double priceUSD,
    required final double priceKES,
    required final int workerLimit,
    required final List<String> features,
    final bool isPopular,
    final bool isActive,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$SubscriptionPlanImpl;

  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get tier;
  @override
  String get name;
  @override
  String get description;
  @override
  double get priceUSD;
  @override
  double get priceKES;
  @override
  int get workerLimit;
  @override
  List<String> get features;
  @override
  bool get isPopular;
  @override
  bool get isActive;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) {
  return _Subscription.fromJson(json);
}

/// @nodoc
mixin _$Subscription {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  SubscriptionPlan get plan => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  double get amountPaid => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  bool get autoRenew => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  String? get cancellationReason => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionCopyWith<Subscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionCopyWith<$Res> {
  factory $SubscriptionCopyWith(
    Subscription value,
    $Res Function(Subscription) then,
  ) = _$SubscriptionCopyWithImpl<$Res, Subscription>;
  @useResult
  $Res call({
    String id,
    String userId,
    String planId,
    SubscriptionPlan plan,
    String status,
    DateTime startDate,
    DateTime endDate,
    double amountPaid,
    String currency,
    bool autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  $SubscriptionPlanCopyWith<$Res> get plan;
}

/// @nodoc
class _$SubscriptionCopyWithImpl<$Res, $Val extends Subscription>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = null,
    Object? plan = null,
    Object? status = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? amountPaid = null,
    Object? currency = null,
    Object? autoRenew = null,
    Object? cancelledAt = freezed,
    Object? cancellationReason = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            planId: null == planId
                ? _value.planId
                : planId // ignore: cast_nullable_to_non_nullable
                      as String,
            plan: null == plan
                ? _value.plan
                : plan // ignore: cast_nullable_to_non_nullable
                      as SubscriptionPlan,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            amountPaid: null == amountPaid
                ? _value.amountPaid
                : amountPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            autoRenew: null == autoRenew
                ? _value.autoRenew
                : autoRenew // ignore: cast_nullable_to_non_nullable
                      as bool,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancellationReason: freezed == cancellationReason
                ? _value.cancellationReason
                : cancellationReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SubscriptionPlanCopyWith<$Res> get plan {
    return $SubscriptionPlanCopyWith<$Res>(_value.plan, (value) {
      return _then(_value.copyWith(plan: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubscriptionImplCopyWith<$Res>
    implements $SubscriptionCopyWith<$Res> {
  factory _$$SubscriptionImplCopyWith(
    _$SubscriptionImpl value,
    $Res Function(_$SubscriptionImpl) then,
  ) = __$$SubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String planId,
    SubscriptionPlan plan,
    String status,
    DateTime startDate,
    DateTime endDate,
    double amountPaid,
    String currency,
    bool autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  @override
  $SubscriptionPlanCopyWith<$Res> get plan;
}

/// @nodoc
class __$$SubscriptionImplCopyWithImpl<$Res>
    extends _$SubscriptionCopyWithImpl<$Res, _$SubscriptionImpl>
    implements _$$SubscriptionImplCopyWith<$Res> {
  __$$SubscriptionImplCopyWithImpl(
    _$SubscriptionImpl _value,
    $Res Function(_$SubscriptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? planId = null,
    Object? plan = null,
    Object? status = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? amountPaid = null,
    Object? currency = null,
    Object? autoRenew = null,
    Object? cancelledAt = freezed,
    Object? cancellationReason = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SubscriptionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        planId: null == planId
            ? _value.planId
            : planId // ignore: cast_nullable_to_non_nullable
                  as String,
        plan: null == plan
            ? _value.plan
            : plan // ignore: cast_nullable_to_non_nullable
                  as SubscriptionPlan,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        amountPaid: null == amountPaid
            ? _value.amountPaid
            : amountPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        autoRenew: null == autoRenew
            ? _value.autoRenew
            : autoRenew // ignore: cast_nullable_to_non_nullable
                  as bool,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancellationReason: freezed == cancellationReason
            ? _value.cancellationReason
            : cancellationReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionImpl implements _Subscription {
  const _$SubscriptionImpl({
    required this.id,
    required this.userId,
    required this.planId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.amountPaid = 0.0,
    required this.currency,
    this.autoRenew = false,
    this.cancelledAt,
    this.cancellationReason,
    final Map<String, dynamic>? metadata,
    this.createdAt,
    this.updatedAt,
  }) : _metadata = metadata;

  factory _$SubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String planId;
  @override
  final SubscriptionPlan plan;
  @override
  final String status;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  @JsonKey()
  final double amountPaid;
  @override
  final String currency;
  @override
  @JsonKey()
  final bool autoRenew;
  @override
  final DateTime? cancelledAt;
  @override
  final String? cancellationReason;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, planId: $planId, plan: $plan, status: $status, startDate: $startDate, endDate: $endDate, amountPaid: $amountPaid, currency: $currency, autoRenew: $autoRenew, cancelledAt: $cancelledAt, cancellationReason: $cancellationReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.autoRenew, autoRenew) ||
                other.autoRenew == autoRenew) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.cancellationReason, cancellationReason) ||
                other.cancellationReason == cancellationReason) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    planId,
    plan,
    status,
    startDate,
    endDate,
    amountPaid,
    currency,
    autoRenew,
    cancelledAt,
    cancellationReason,
    const DeepCollectionEquality().hash(_metadata),
    createdAt,
    updatedAt,
  );

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      __$$SubscriptionImplCopyWithImpl<_$SubscriptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionImplToJson(this);
  }
}

abstract class _Subscription implements Subscription {
  const factory _Subscription({
    required final String id,
    required final String userId,
    required final String planId,
    required final SubscriptionPlan plan,
    required final String status,
    required final DateTime startDate,
    required final DateTime endDate,
    final double amountPaid,
    required final String currency,
    final bool autoRenew,
    final DateTime? cancelledAt,
    final String? cancellationReason,
    final Map<String, dynamic>? metadata,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$SubscriptionImpl;

  factory _Subscription.fromJson(Map<String, dynamic> json) =
      _$SubscriptionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get planId;
  @override
  SubscriptionPlan get plan;
  @override
  String get status;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  double get amountPaid;
  @override
  String get currency;
  @override
  bool get autoRenew;
  @override
  DateTime? get cancelledAt;
  @override
  String? get cancellationReason;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Subscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionImplCopyWith<_$SubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubscriptionPayment _$SubscriptionPaymentFromJson(Map<String, dynamic> json) {
  return _SubscriptionPayment.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionPayment {
  String get id => throw _privateConstructorUsedError;
  String get subscriptionId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  String get providerTransactionId => throw _privateConstructorUsedError;
  DateTime? get processedAt => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionPayment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionPaymentCopyWith<SubscriptionPayment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPaymentCopyWith<$Res> {
  factory $SubscriptionPaymentCopyWith(
    SubscriptionPayment value,
    $Res Function(SubscriptionPayment) then,
  ) = _$SubscriptionPaymentCopyWithImpl<$Res, SubscriptionPayment>;
  @useResult
  $Res call({
    String id,
    String subscriptionId,
    String userId,
    double amount,
    String currency,
    String status,
    String paymentMethod,
    String provider,
    String providerTransactionId,
    DateTime? processedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$SubscriptionPaymentCopyWithImpl<$Res, $Val extends SubscriptionPayment>
    implements $SubscriptionPaymentCopyWith<$Res> {
  _$SubscriptionPaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subscriptionId = null,
    Object? userId = null,
    Object? amount = null,
    Object? currency = null,
    Object? status = null,
    Object? paymentMethod = null,
    Object? provider = null,
    Object? providerTransactionId = null,
    Object? processedAt = freezed,
    Object? failureReason = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            subscriptionId: null == subscriptionId
                ? _value.subscriptionId
                : subscriptionId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            provider: null == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                      as String,
            providerTransactionId: null == providerTransactionId
                ? _value.providerTransactionId
                : providerTransactionId // ignore: cast_nullable_to_non_nullable
                      as String,
            processedAt: freezed == processedAt
                ? _value.processedAt
                : processedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubscriptionPaymentImplCopyWith<$Res>
    implements $SubscriptionPaymentCopyWith<$Res> {
  factory _$$SubscriptionPaymentImplCopyWith(
    _$SubscriptionPaymentImpl value,
    $Res Function(_$SubscriptionPaymentImpl) then,
  ) = __$$SubscriptionPaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String subscriptionId,
    String userId,
    double amount,
    String currency,
    String status,
    String paymentMethod,
    String provider,
    String providerTransactionId,
    DateTime? processedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SubscriptionPaymentImplCopyWithImpl<$Res>
    extends _$SubscriptionPaymentCopyWithImpl<$Res, _$SubscriptionPaymentImpl>
    implements _$$SubscriptionPaymentImplCopyWith<$Res> {
  __$$SubscriptionPaymentImplCopyWithImpl(
    _$SubscriptionPaymentImpl _value,
    $Res Function(_$SubscriptionPaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubscriptionPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subscriptionId = null,
    Object? userId = null,
    Object? amount = null,
    Object? currency = null,
    Object? status = null,
    Object? paymentMethod = null,
    Object? provider = null,
    Object? providerTransactionId = null,
    Object? processedAt = freezed,
    Object? failureReason = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SubscriptionPaymentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        subscriptionId: null == subscriptionId
            ? _value.subscriptionId
            : subscriptionId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        provider: null == provider
            ? _value.provider
            : provider // ignore: cast_nullable_to_non_nullable
                  as String,
        providerTransactionId: null == providerTransactionId
            ? _value.providerTransactionId
            : providerTransactionId // ignore: cast_nullable_to_non_nullable
                  as String,
        processedAt: freezed == processedAt
            ? _value.processedAt
            : processedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionPaymentImpl implements _SubscriptionPayment {
  const _$SubscriptionPaymentImpl({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.provider,
    required this.providerTransactionId,
    this.processedAt,
    this.failureReason,
    final Map<String, dynamic>? metadata,
    this.createdAt,
    this.updatedAt,
  }) : _metadata = metadata;

  factory _$SubscriptionPaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPaymentImplFromJson(json);

  @override
  final String id;
  @override
  final String subscriptionId;
  @override
  final String userId;
  @override
  final double amount;
  @override
  final String currency;
  @override
  final String status;
  @override
  final String paymentMethod;
  @override
  final String provider;
  @override
  final String providerTransactionId;
  @override
  final DateTime? processedAt;
  @override
  final String? failureReason;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SubscriptionPayment(id: $id, subscriptionId: $subscriptionId, userId: $userId, amount: $amount, currency: $currency, status: $status, paymentMethod: $paymentMethod, provider: $provider, providerTransactionId: $providerTransactionId, processedAt: $processedAt, failureReason: $failureReason, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.subscriptionId, subscriptionId) ||
                other.subscriptionId == subscriptionId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.providerTransactionId, providerTransactionId) ||
                other.providerTransactionId == providerTransactionId) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    subscriptionId,
    userId,
    amount,
    currency,
    status,
    paymentMethod,
    provider,
    providerTransactionId,
    processedAt,
    failureReason,
    const DeepCollectionEquality().hash(_metadata),
    createdAt,
    updatedAt,
  );

  /// Create a copy of SubscriptionPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPaymentImplCopyWith<_$SubscriptionPaymentImpl> get copyWith =>
      __$$SubscriptionPaymentImplCopyWithImpl<_$SubscriptionPaymentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionPaymentImplToJson(this);
  }
}

abstract class _SubscriptionPayment implements SubscriptionPayment {
  const factory _SubscriptionPayment({
    required final String id,
    required final String subscriptionId,
    required final String userId,
    required final double amount,
    required final String currency,
    required final String status,
    required final String paymentMethod,
    required final String provider,
    required final String providerTransactionId,
    final DateTime? processedAt,
    final String? failureReason,
    final Map<String, dynamic>? metadata,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$SubscriptionPaymentImpl;

  factory _SubscriptionPayment.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPaymentImpl.fromJson;

  @override
  String get id;
  @override
  String get subscriptionId;
  @override
  String get userId;
  @override
  double get amount;
  @override
  String get currency;
  @override
  String get status;
  @override
  String get paymentMethod;
  @override
  String get provider;
  @override
  String get providerTransactionId;
  @override
  DateTime? get processedAt;
  @override
  String? get failureReason;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of SubscriptionPayment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPaymentImplCopyWith<_$SubscriptionPaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubscriptionUsage _$SubscriptionUsageFromJson(Map<String, dynamic> json) {
  return _SubscriptionUsage.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionUsage {
  String get id => throw _privateConstructorUsedError;
  String get subscriptionId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get currentWorkers => throw _privateConstructorUsedError;
  int get maxWorkers => throw _privateConstructorUsedError;
  double get usagePercentage => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;
  Map<String, dynamic>? get breakdown => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionUsage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionUsage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionUsageCopyWith<SubscriptionUsage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionUsageCopyWith<$Res> {
  factory $SubscriptionUsageCopyWith(
    SubscriptionUsage value,
    $Res Function(SubscriptionUsage) then,
  ) = _$SubscriptionUsageCopyWithImpl<$Res, SubscriptionUsage>;
  @useResult
  $Res call({
    String id,
    String subscriptionId,
    String userId,
    int currentWorkers,
    int maxWorkers,
    double usagePercentage,
    DateTime? lastUpdated,
    Map<String, dynamic>? breakdown,
  });
}

/// @nodoc
class _$SubscriptionUsageCopyWithImpl<$Res, $Val extends SubscriptionUsage>
    implements $SubscriptionUsageCopyWith<$Res> {
  _$SubscriptionUsageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionUsage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subscriptionId = null,
    Object? userId = null,
    Object? currentWorkers = null,
    Object? maxWorkers = null,
    Object? usagePercentage = null,
    Object? lastUpdated = freezed,
    Object? breakdown = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            subscriptionId: null == subscriptionId
                ? _value.subscriptionId
                : subscriptionId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentWorkers: null == currentWorkers
                ? _value.currentWorkers
                : currentWorkers // ignore: cast_nullable_to_non_nullable
                      as int,
            maxWorkers: null == maxWorkers
                ? _value.maxWorkers
                : maxWorkers // ignore: cast_nullable_to_non_nullable
                      as int,
            usagePercentage: null == usagePercentage
                ? _value.usagePercentage
                : usagePercentage // ignore: cast_nullable_to_non_nullable
                      as double,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            breakdown: freezed == breakdown
                ? _value.breakdown
                : breakdown // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubscriptionUsageImplCopyWith<$Res>
    implements $SubscriptionUsageCopyWith<$Res> {
  factory _$$SubscriptionUsageImplCopyWith(
    _$SubscriptionUsageImpl value,
    $Res Function(_$SubscriptionUsageImpl) then,
  ) = __$$SubscriptionUsageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String subscriptionId,
    String userId,
    int currentWorkers,
    int maxWorkers,
    double usagePercentage,
    DateTime? lastUpdated,
    Map<String, dynamic>? breakdown,
  });
}

/// @nodoc
class __$$SubscriptionUsageImplCopyWithImpl<$Res>
    extends _$SubscriptionUsageCopyWithImpl<$Res, _$SubscriptionUsageImpl>
    implements _$$SubscriptionUsageImplCopyWith<$Res> {
  __$$SubscriptionUsageImplCopyWithImpl(
    _$SubscriptionUsageImpl _value,
    $Res Function(_$SubscriptionUsageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubscriptionUsage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? subscriptionId = null,
    Object? userId = null,
    Object? currentWorkers = null,
    Object? maxWorkers = null,
    Object? usagePercentage = null,
    Object? lastUpdated = freezed,
    Object? breakdown = freezed,
  }) {
    return _then(
      _$SubscriptionUsageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        subscriptionId: null == subscriptionId
            ? _value.subscriptionId
            : subscriptionId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentWorkers: null == currentWorkers
            ? _value.currentWorkers
            : currentWorkers // ignore: cast_nullable_to_non_nullable
                  as int,
        maxWorkers: null == maxWorkers
            ? _value.maxWorkers
            : maxWorkers // ignore: cast_nullable_to_non_nullable
                  as int,
        usagePercentage: null == usagePercentage
            ? _value.usagePercentage
            : usagePercentage // ignore: cast_nullable_to_non_nullable
                  as double,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        breakdown: freezed == breakdown
            ? _value._breakdown
            : breakdown // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionUsageImpl implements _SubscriptionUsage {
  const _$SubscriptionUsageImpl({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.currentWorkers,
    required this.maxWorkers,
    required this.usagePercentage,
    this.lastUpdated,
    final Map<String, dynamic>? breakdown,
  }) : _breakdown = breakdown;

  factory _$SubscriptionUsageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionUsageImplFromJson(json);

  @override
  final String id;
  @override
  final String subscriptionId;
  @override
  final String userId;
  @override
  final int currentWorkers;
  @override
  final int maxWorkers;
  @override
  final double usagePercentage;
  @override
  final DateTime? lastUpdated;
  final Map<String, dynamic>? _breakdown;
  @override
  Map<String, dynamic>? get breakdown {
    final value = _breakdown;
    if (value == null) return null;
    if (_breakdown is EqualUnmodifiableMapView) return _breakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SubscriptionUsage(id: $id, subscriptionId: $subscriptionId, userId: $userId, currentWorkers: $currentWorkers, maxWorkers: $maxWorkers, usagePercentage: $usagePercentage, lastUpdated: $lastUpdated, breakdown: $breakdown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionUsageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.subscriptionId, subscriptionId) ||
                other.subscriptionId == subscriptionId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentWorkers, currentWorkers) ||
                other.currentWorkers == currentWorkers) &&
            (identical(other.maxWorkers, maxWorkers) ||
                other.maxWorkers == maxWorkers) &&
            (identical(other.usagePercentage, usagePercentage) ||
                other.usagePercentage == usagePercentage) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            const DeepCollectionEquality().equals(
              other._breakdown,
              _breakdown,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    subscriptionId,
    userId,
    currentWorkers,
    maxWorkers,
    usagePercentage,
    lastUpdated,
    const DeepCollectionEquality().hash(_breakdown),
  );

  /// Create a copy of SubscriptionUsage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionUsageImplCopyWith<_$SubscriptionUsageImpl> get copyWith =>
      __$$SubscriptionUsageImplCopyWithImpl<_$SubscriptionUsageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionUsageImplToJson(this);
  }
}

abstract class _SubscriptionUsage implements SubscriptionUsage {
  const factory _SubscriptionUsage({
    required final String id,
    required final String subscriptionId,
    required final String userId,
    required final int currentWorkers,
    required final int maxWorkers,
    required final double usagePercentage,
    final DateTime? lastUpdated,
    final Map<String, dynamic>? breakdown,
  }) = _$SubscriptionUsageImpl;

  factory _SubscriptionUsage.fromJson(Map<String, dynamic> json) =
      _$SubscriptionUsageImpl.fromJson;

  @override
  String get id;
  @override
  String get subscriptionId;
  @override
  String get userId;
  @override
  int get currentWorkers;
  @override
  int get maxWorkers;
  @override
  double get usagePercentage;
  @override
  DateTime? get lastUpdated;
  @override
  Map<String, dynamic>? get breakdown;

  /// Create a copy of SubscriptionUsage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionUsageImplCopyWith<_$SubscriptionUsageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
