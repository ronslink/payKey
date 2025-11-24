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
  String get tier => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get priceUSD => throw _privateConstructorUsedError;
  double get priceKES => throw _privateConstructorUsedError;
  int get workerLimit => throw _privateConstructorUsedError;
  List<String> get features => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;

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
    String tier,
    String name,
    double priceUSD,
    double priceKES,
    int workerLimit,
    List<String> features,
    bool isPopular,
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
    Object? tier = null,
    Object? name = null,
    Object? priceUSD = null,
    Object? priceKES = null,
    Object? workerLimit = null,
    Object? features = null,
    Object? isPopular = null,
  }) {
    return _then(
      _value.copyWith(
            tier: null == tier
                ? _value.tier
                : tier // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
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
    String tier,
    String name,
    double priceUSD,
    double priceKES,
    int workerLimit,
    List<String> features,
    bool isPopular,
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
    Object? tier = null,
    Object? name = null,
    Object? priceUSD = null,
    Object? priceKES = null,
    Object? workerLimit = null,
    Object? features = null,
    Object? isPopular = null,
  }) {
    return _then(
      _$SubscriptionPlanImpl(
        tier: null == tier
            ? _value.tier
            : tier // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionPlanImpl implements _SubscriptionPlan {
  const _$SubscriptionPlanImpl({
    required this.tier,
    required this.name,
    required this.priceUSD,
    required this.priceKES,
    required this.workerLimit,
    required final List<String> features,
    this.isPopular = false,
  }) : _features = features;

  factory _$SubscriptionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPlanImplFromJson(json);

  @override
  final String tier;
  @override
  final String name;
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
  String toString() {
    return 'SubscriptionPlan(tier: $tier, name: $name, priceUSD: $priceUSD, priceKES: $priceKES, workerLimit: $workerLimit, features: $features, isPopular: $isPopular)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPlanImpl &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priceUSD, priceUSD) ||
                other.priceUSD == priceUSD) &&
            (identical(other.priceKES, priceKES) ||
                other.priceKES == priceKES) &&
            (identical(other.workerLimit, workerLimit) ||
                other.workerLimit == workerLimit) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    tier,
    name,
    priceUSD,
    priceKES,
    workerLimit,
    const DeepCollectionEquality().hash(_features),
    isPopular,
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
    required final String tier,
    required final String name,
    required final double priceUSD,
    required final double priceKES,
    required final int workerLimit,
    required final List<String> features,
    final bool isPopular,
  }) = _$SubscriptionPlanImpl;

  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPlanImpl.fromJson;

  @override
  String get tier;
  @override
  String get name;
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

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPlanImplCopyWith<_$SubscriptionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
