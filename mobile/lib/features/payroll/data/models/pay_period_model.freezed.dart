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
  String get name => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  PayPeriodFrequency get frequency => throw _privateConstructorUsedError;
  PayPeriodStatus get status => throw _privateConstructorUsedError;
  int get totalWorkers => throw _privateConstructorUsedError;
  double get totalGrossAmount => throw _privateConstructorUsedError;
  double get totalNetAmount => throw _privateConstructorUsedError;
  int get processedWorkers => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

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
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodFrequency frequency,
    PayPeriodStatus status,
    int totalWorkers,
    double totalGrossAmount,
    double totalNetAmount,
    int processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
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
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? frequency = null,
    Object? status = null,
    Object? totalWorkers = null,
    Object? totalGrossAmount = null,
    Object? totalNetAmount = null,
    Object? processedWorkers = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
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
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as PayPeriodFrequency,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayPeriodStatus,
            totalWorkers: null == totalWorkers
                ? _value.totalWorkers
                : totalWorkers // ignore: cast_nullable_to_non_nullable
                      as int,
            totalGrossAmount: null == totalGrossAmount
                ? _value.totalGrossAmount
                : totalGrossAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalNetAmount: null == totalNetAmount
                ? _value.totalNetAmount
                : totalNetAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            processedWorkers: null == processedWorkers
                ? _value.processedWorkers
                : processedWorkers // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
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
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodFrequency frequency,
    PayPeriodStatus status,
    int totalWorkers,
    double totalGrossAmount,
    double totalNetAmount,
    int processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
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
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? frequency = null,
    Object? status = null,
    Object? totalWorkers = null,
    Object? totalGrossAmount = null,
    Object? totalNetAmount = null,
    Object? processedWorkers = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$PayPeriodImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
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
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as PayPeriodFrequency,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayPeriodStatus,
        totalWorkers: null == totalWorkers
            ? _value.totalWorkers
            : totalWorkers // ignore: cast_nullable_to_non_nullable
                  as int,
        totalGrossAmount: null == totalGrossAmount
            ? _value.totalGrossAmount
            : totalGrossAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalNetAmount: null == totalNetAmount
            ? _value.totalNetAmount
            : totalNetAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        processedWorkers: null == processedWorkers
            ? _value.processedWorkers
            : processedWorkers // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayPeriodImpl implements _PayPeriod {
  const _$PayPeriodImpl({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    required this.status,
    required this.totalWorkers,
    required this.totalGrossAmount,
    required this.totalNetAmount,
    required this.processedWorkers,
    this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory _$PayPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayPeriodImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final PayPeriodFrequency frequency;
  @override
  final PayPeriodStatus status;
  @override
  final int totalWorkers;
  @override
  final double totalGrossAmount;
  @override
  final double totalNetAmount;
  @override
  final int processedWorkers;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? notes;

  @override
  String toString() {
    return 'PayPeriod(id: $id, name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, totalWorkers: $totalWorkers, totalGrossAmount: $totalGrossAmount, totalNetAmount: $totalNetAmount, processedWorkers: $processedWorkers, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayPeriodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalWorkers, totalWorkers) ||
                other.totalWorkers == totalWorkers) &&
            (identical(other.totalGrossAmount, totalGrossAmount) ||
                other.totalGrossAmount == totalGrossAmount) &&
            (identical(other.totalNetAmount, totalNetAmount) ||
                other.totalNetAmount == totalNetAmount) &&
            (identical(other.processedWorkers, processedWorkers) ||
                other.processedWorkers == processedWorkers) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    startDate,
    endDate,
    frequency,
    status,
    totalWorkers,
    totalGrossAmount,
    totalNetAmount,
    processedWorkers,
    createdAt,
    updatedAt,
    notes,
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
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    required final PayPeriodFrequency frequency,
    required final PayPeriodStatus status,
    required final int totalWorkers,
    required final double totalGrossAmount,
    required final double totalNetAmount,
    required final int processedWorkers,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final String? notes,
  }) = _$PayPeriodImpl;

  factory _PayPeriod.fromJson(Map<String, dynamic> json) =
      _$PayPeriodImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  PayPeriodFrequency get frequency;
  @override
  PayPeriodStatus get status;
  @override
  int get totalWorkers;
  @override
  double get totalGrossAmount;
  @override
  double get totalNetAmount;
  @override
  int get processedWorkers;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get notes;

  /// Create a copy of PayPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayPeriodImplCopyWith<_$PayPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatePayPeriodRequest _$CreatePayPeriodRequestFromJson(
  Map<String, dynamic> json,
) {
  return _CreatePayPeriodRequest.fromJson(json);
}

/// @nodoc
mixin _$CreatePayPeriodRequest {
  String get name => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  PayPeriodFrequency get frequency => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this CreatePayPeriodRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatePayPeriodRequestCopyWith<CreatePayPeriodRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatePayPeriodRequestCopyWith<$Res> {
  factory $CreatePayPeriodRequestCopyWith(
    CreatePayPeriodRequest value,
    $Res Function(CreatePayPeriodRequest) then,
  ) = _$CreatePayPeriodRequestCopyWithImpl<$Res, CreatePayPeriodRequest>;
  @useResult
  $Res call({
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodFrequency frequency,
    String? notes,
  });
}

/// @nodoc
class _$CreatePayPeriodRequestCopyWithImpl<
  $Res,
  $Val extends CreatePayPeriodRequest
>
    implements $CreatePayPeriodRequestCopyWith<$Res> {
  _$CreatePayPeriodRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? frequency = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
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
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as PayPeriodFrequency,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatePayPeriodRequestImplCopyWith<$Res>
    implements $CreatePayPeriodRequestCopyWith<$Res> {
  factory _$$CreatePayPeriodRequestImplCopyWith(
    _$CreatePayPeriodRequestImpl value,
    $Res Function(_$CreatePayPeriodRequestImpl) then,
  ) = __$$CreatePayPeriodRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodFrequency frequency,
    String? notes,
  });
}

/// @nodoc
class __$$CreatePayPeriodRequestImplCopyWithImpl<$Res>
    extends
        _$CreatePayPeriodRequestCopyWithImpl<$Res, _$CreatePayPeriodRequestImpl>
    implements _$$CreatePayPeriodRequestImplCopyWith<$Res> {
  __$$CreatePayPeriodRequestImplCopyWithImpl(
    _$CreatePayPeriodRequestImpl _value,
    $Res Function(_$CreatePayPeriodRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? frequency = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$CreatePayPeriodRequestImpl(
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
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as PayPeriodFrequency,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatePayPeriodRequestImpl implements _CreatePayPeriodRequest {
  const _$CreatePayPeriodRequestImpl({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    this.notes,
  });

  factory _$CreatePayPeriodRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatePayPeriodRequestImplFromJson(json);

  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final PayPeriodFrequency frequency;
  @override
  final String? notes;

  @override
  String toString() {
    return 'CreatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatePayPeriodRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, startDate, endDate, frequency, notes);

  /// Create a copy of CreatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatePayPeriodRequestImplCopyWith<_$CreatePayPeriodRequestImpl>
  get copyWith =>
      __$$CreatePayPeriodRequestImplCopyWithImpl<_$CreatePayPeriodRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatePayPeriodRequestImplToJson(this);
  }
}

abstract class _CreatePayPeriodRequest implements CreatePayPeriodRequest {
  const factory _CreatePayPeriodRequest({
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    required final PayPeriodFrequency frequency,
    final String? notes,
  }) = _$CreatePayPeriodRequestImpl;

  factory _CreatePayPeriodRequest.fromJson(Map<String, dynamic> json) =
      _$CreatePayPeriodRequestImpl.fromJson;

  @override
  String get name;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  PayPeriodFrequency get frequency;
  @override
  String? get notes;

  /// Create a copy of CreatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatePayPeriodRequestImplCopyWith<_$CreatePayPeriodRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

UpdatePayPeriodRequest _$UpdatePayPeriodRequestFromJson(
  Map<String, dynamic> json,
) {
  return _UpdatePayPeriodRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdatePayPeriodRequest {
  String? get name => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  PayPeriodFrequency? get frequency => throw _privateConstructorUsedError;
  PayPeriodStatus? get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this UpdatePayPeriodRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdatePayPeriodRequestCopyWith<UpdatePayPeriodRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdatePayPeriodRequestCopyWith<$Res> {
  factory $UpdatePayPeriodRequestCopyWith(
    UpdatePayPeriodRequest value,
    $Res Function(UpdatePayPeriodRequest) then,
  ) = _$UpdatePayPeriodRequestCopyWithImpl<$Res, UpdatePayPeriodRequest>;
  @useResult
  $Res call({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    PayPeriodFrequency? frequency,
    PayPeriodStatus? status,
    String? notes,
  });
}

/// @nodoc
class _$UpdatePayPeriodRequestCopyWithImpl<
  $Res,
  $Val extends UpdatePayPeriodRequest
>
    implements $UpdatePayPeriodRequestCopyWith<$Res> {
  _$UpdatePayPeriodRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? frequency = freezed,
    Object? status = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            frequency: freezed == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as PayPeriodFrequency?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PayPeriodStatus?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdatePayPeriodRequestImplCopyWith<$Res>
    implements $UpdatePayPeriodRequestCopyWith<$Res> {
  factory _$$UpdatePayPeriodRequestImplCopyWith(
    _$UpdatePayPeriodRequestImpl value,
    $Res Function(_$UpdatePayPeriodRequestImpl) then,
  ) = __$$UpdatePayPeriodRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    PayPeriodFrequency? frequency,
    PayPeriodStatus? status,
    String? notes,
  });
}

/// @nodoc
class __$$UpdatePayPeriodRequestImplCopyWithImpl<$Res>
    extends
        _$UpdatePayPeriodRequestCopyWithImpl<$Res, _$UpdatePayPeriodRequestImpl>
    implements _$$UpdatePayPeriodRequestImplCopyWith<$Res> {
  __$$UpdatePayPeriodRequestImplCopyWithImpl(
    _$UpdatePayPeriodRequestImpl _value,
    $Res Function(_$UpdatePayPeriodRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? frequency = freezed,
    Object? status = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$UpdatePayPeriodRequestImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        frequency: freezed == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as PayPeriodFrequency?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PayPeriodStatus?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdatePayPeriodRequestImpl implements _UpdatePayPeriodRequest {
  const _$UpdatePayPeriodRequestImpl({
    this.name,
    this.startDate,
    this.endDate,
    this.frequency,
    this.status,
    this.notes,
  });

  factory _$UpdatePayPeriodRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdatePayPeriodRequestImplFromJson(json);

  @override
  final String? name;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final PayPeriodFrequency? frequency;
  @override
  final PayPeriodStatus? status;
  @override
  final String? notes;

  @override
  String toString() {
    return 'UpdatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdatePayPeriodRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    startDate,
    endDate,
    frequency,
    status,
    notes,
  );

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdatePayPeriodRequestImplCopyWith<_$UpdatePayPeriodRequestImpl>
  get copyWith =>
      __$$UpdatePayPeriodRequestImplCopyWithImpl<_$UpdatePayPeriodRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdatePayPeriodRequestImplToJson(this);
  }
}

abstract class _UpdatePayPeriodRequest implements UpdatePayPeriodRequest {
  const factory _UpdatePayPeriodRequest({
    final String? name,
    final DateTime? startDate,
    final DateTime? endDate,
    final PayPeriodFrequency? frequency,
    final PayPeriodStatus? status,
    final String? notes,
  }) = _$UpdatePayPeriodRequestImpl;

  factory _UpdatePayPeriodRequest.fromJson(Map<String, dynamic> json) =
      _$UpdatePayPeriodRequestImpl.fromJson;

  @override
  String? get name;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  PayPeriodFrequency? get frequency;
  @override
  PayPeriodStatus? get status;
  @override
  String? get notes;

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePayPeriodRequestImplCopyWith<_$UpdatePayPeriodRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
