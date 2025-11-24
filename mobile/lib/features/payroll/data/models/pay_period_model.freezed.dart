// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pay_period_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PayPeriod _$PayPeriodFromJson(Map<String, dynamic> json) {
  return _PayPeriod.fromJson(json);
}

/// @nodoc
mixin _$PayPeriod {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  PayPeriodStatus get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PayPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayPeriodCopyWith<PayPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayPeriodCopyWith<$Res> {
  factory $PayPeriodCopyWith(PayPeriod value, $Res Function(PayPeriod) then) =
      _$PayPeriodCopyWithImpl<$Res, PayPeriod>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$PayPeriodCopyWithImpl<$Res, $Val extends PayPeriod>
    implements $PayPeriodCopyWith<$Res> {
  _$PayPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayPeriodStatus,
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
abstract class _$$PayPeriodImplCopyWith<$Res>
    implements $PayPeriodCopyWith<$Res> {
  factory _$$PayPeriodImplCopyWith(
    _$PayPeriodImpl value,
    $Res Function(_$PayPeriodImpl) then,
  ) = __$$PayPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PayPeriodImplCopyWithImpl<$Res>
    extends _$PayPeriodCopyWithImpl<$Res, _$PayPeriodImpl>
    implements _$$PayPeriodImplCopyWith<$Res> {
  __$$PayPeriodImplCopyWithImpl(
    _$PayPeriodImpl _value,
    $Res Function(_$PayPeriodImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PayPeriodImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayPeriodStatus,
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
class _$PayPeriodImpl implements _PayPeriod {
  const _$PayPeriodImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = PayPeriodStatus.open,
    this.createdAt,
    this.updatedAt,
  });

  factory _$PayPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayPeriodImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  @JsonKey()
  final PayPeriodStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PayPeriod(id: $id, userId: $userId, name: $name, startDate: $startDate, endDate: $endDate, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayPeriodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.status, status) || other.status == status) &&
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
    name,
    startDate,
    endDate,
    status,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayPeriodImplCopyWith<_$PayPeriodImpl> get copyWith =>
      __$$PayPeriodImplCopyWithImpl<_$PayPeriodImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PayPeriodImplToJson(this);
  }
}

abstract class _PayPeriod implements PayPeriod {
  const factory _PayPeriod({
    required final String id,
    required final String userId,
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    final PayPeriodStatus status,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$PayPeriodImpl;

  factory _PayPeriod.fromJson(Map<String, dynamic> json) =
      _$PayPeriodImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  PayPeriodStatus get status;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayPeriodImplCopyWith<_$PayPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
