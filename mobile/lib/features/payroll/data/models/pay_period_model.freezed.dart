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
  /// Unique identifier.
  String get id => throw _privateConstructorUsedError;

  /// Display name (e.g., "August 2025", "Week 32").
  String get name => throw _privateConstructorUsedError;

  /// First day of the pay period (inclusive).
  DateTime get startDate => throw _privateConstructorUsedError;

  /// Last day of the pay period (inclusive).
  DateTime get endDate => throw _privateConstructorUsedError;

  /// How often this type of period recurs.
  PayPeriodFrequency get frequency => throw _privateConstructorUsedError;

  /// Current status in the payroll workflow.
  PayPeriodStatus get status => throw _privateConstructorUsedError;

  /// Total number of workers included in this period.
  @JsonKey(fromJson: _intFromJson)
  int? get totalWorkers => throw _privateConstructorUsedError;

  /// Sum of all gross salaries.
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalGrossAmount => throw _privateConstructorUsedError;

  /// Sum of all net pay amounts.
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalNetAmount => throw _privateConstructorUsedError;

  /// Sum of all tax deductions.
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalTaxAmount => throw _privateConstructorUsedError;

  /// Number of workers whose payroll has been processed.
  @JsonKey(fromJson: _intFromJson)
  int? get processedWorkers => throw _privateConstructorUsedError;

  /// When this pay period was created.
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// When this pay period was last updated.
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Additional notes or comments.
  String? get notes => throw _privateConstructorUsedError;

  /// Owner/employer user ID.
  String? get userId => throw _privateConstructorUsedError;

  /// Scheduled payment date.
  DateTime? get payDate => throw _privateConstructorUsedError;

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
    @JsonKey(fromJson: _intFromJson) int? totalWorkers,
    @JsonKey(fromJson: _doubleFromJson) double? totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson) double? totalNetAmount,
    @JsonKey(fromJson: _doubleFromJson) double? totalTaxAmount,
    @JsonKey(fromJson: _intFromJson) int? processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? userId,
    DateTime? payDate,
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
    Object? totalWorkers = freezed,
    Object? totalGrossAmount = freezed,
    Object? totalNetAmount = freezed,
    Object? totalTaxAmount = freezed,
    Object? processedWorkers = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? notes = freezed,
    Object? userId = freezed,
    Object? payDate = freezed,
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
            totalWorkers: freezed == totalWorkers
                ? _value.totalWorkers
                : totalWorkers // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalGrossAmount: freezed == totalGrossAmount
                ? _value.totalGrossAmount
                : totalGrossAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalNetAmount: freezed == totalNetAmount
                ? _value.totalNetAmount
                : totalNetAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalTaxAmount: freezed == totalTaxAmount
                ? _value.totalTaxAmount
                : totalTaxAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            processedWorkers: freezed == processedWorkers
                ? _value.processedWorkers
                : processedWorkers // ignore: cast_nullable_to_non_nullable
                      as int?,
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
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            payDate: freezed == payDate
                ? _value.payDate
                : payDate // ignore: cast_nullable_to_non_nullable
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
    String name,
    DateTime startDate,
    DateTime endDate,
    PayPeriodFrequency frequency,
    PayPeriodStatus status,
    @JsonKey(fromJson: _intFromJson) int? totalWorkers,
    @JsonKey(fromJson: _doubleFromJson) double? totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson) double? totalNetAmount,
    @JsonKey(fromJson: _doubleFromJson) double? totalTaxAmount,
    @JsonKey(fromJson: _intFromJson) int? processedWorkers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? userId,
    DateTime? payDate,
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
    Object? totalWorkers = freezed,
    Object? totalGrossAmount = freezed,
    Object? totalNetAmount = freezed,
    Object? totalTaxAmount = freezed,
    Object? processedWorkers = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? notes = freezed,
    Object? userId = freezed,
    Object? payDate = freezed,
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
        totalWorkers: freezed == totalWorkers
            ? _value.totalWorkers
            : totalWorkers // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalGrossAmount: freezed == totalGrossAmount
            ? _value.totalGrossAmount
            : totalGrossAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalNetAmount: freezed == totalNetAmount
            ? _value.totalNetAmount
            : totalNetAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalTaxAmount: freezed == totalTaxAmount
            ? _value.totalTaxAmount
            : totalTaxAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        processedWorkers: freezed == processedWorkers
            ? _value.processedWorkers
            : processedWorkers // ignore: cast_nullable_to_non_nullable
                  as int?,
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
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        payDate: freezed == payDate
            ? _value.payDate
            : payDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayPeriodImpl extends _PayPeriod {
  const _$PayPeriodImpl({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    required this.status,
    @JsonKey(fromJson: _intFromJson) this.totalWorkers,
    @JsonKey(fromJson: _doubleFromJson) this.totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson) this.totalNetAmount,
    @JsonKey(fromJson: _doubleFromJson) this.totalTaxAmount,
    @JsonKey(fromJson: _intFromJson) this.processedWorkers,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.userId,
    this.payDate,
  }) : super._();

  factory _$PayPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayPeriodImplFromJson(json);

  /// Unique identifier.
  @override
  final String id;

  /// Display name (e.g., "August 2025", "Week 32").
  @override
  final String name;

  /// First day of the pay period (inclusive).
  @override
  final DateTime startDate;

  /// Last day of the pay period (inclusive).
  @override
  final DateTime endDate;

  /// How often this type of period recurs.
  @override
  final PayPeriodFrequency frequency;

  /// Current status in the payroll workflow.
  @override
  final PayPeriodStatus status;

  /// Total number of workers included in this period.
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? totalWorkers;

  /// Sum of all gross salaries.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? totalGrossAmount;

  /// Sum of all net pay amounts.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? totalNetAmount;

  /// Sum of all tax deductions.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? totalTaxAmount;

  /// Number of workers whose payroll has been processed.
  @override
  @JsonKey(fromJson: _intFromJson)
  final int? processedWorkers;

  /// When this pay period was created.
  @override
  final DateTime? createdAt;

  /// When this pay period was last updated.
  @override
  final DateTime? updatedAt;

  /// Additional notes or comments.
  @override
  final String? notes;

  /// Owner/employer user ID.
  @override
  final String? userId;

  /// Scheduled payment date.
  @override
  final DateTime? payDate;

  @override
  String toString() {
    return 'PayPeriod(id: $id, name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, totalWorkers: $totalWorkers, totalGrossAmount: $totalGrossAmount, totalNetAmount: $totalNetAmount, totalTaxAmount: $totalTaxAmount, processedWorkers: $processedWorkers, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, userId: $userId, payDate: $payDate)';
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
            (identical(other.totalTaxAmount, totalTaxAmount) ||
                other.totalTaxAmount == totalTaxAmount) &&
            (identical(other.processedWorkers, processedWorkers) ||
                other.processedWorkers == processedWorkers) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.payDate, payDate) || other.payDate == payDate));
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
    totalTaxAmount,
    processedWorkers,
    createdAt,
    updatedAt,
    notes,
    userId,
    payDate,
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

abstract class _PayPeriod extends PayPeriod {
  const factory _PayPeriod({
    required final String id,
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    required final PayPeriodFrequency frequency,
    required final PayPeriodStatus status,
    @JsonKey(fromJson: _intFromJson) final int? totalWorkers,
    @JsonKey(fromJson: _doubleFromJson) final double? totalGrossAmount,
    @JsonKey(fromJson: _doubleFromJson) final double? totalNetAmount,
    @JsonKey(fromJson: _doubleFromJson) final double? totalTaxAmount,
    @JsonKey(fromJson: _intFromJson) final int? processedWorkers,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final String? notes,
    final String? userId,
    final DateTime? payDate,
  }) = _$PayPeriodImpl;
  const _PayPeriod._() : super._();

  factory _PayPeriod.fromJson(Map<String, dynamic> json) =
      _$PayPeriodImpl.fromJson;

  /// Unique identifier.
  @override
  String get id;

  /// Display name (e.g., "August 2025", "Week 32").
  @override
  String get name;

  /// First day of the pay period (inclusive).
  @override
  DateTime get startDate;

  /// Last day of the pay period (inclusive).
  @override
  DateTime get endDate;

  /// How often this type of period recurs.
  @override
  PayPeriodFrequency get frequency;

  /// Current status in the payroll workflow.
  @override
  PayPeriodStatus get status;

  /// Total number of workers included in this period.
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get totalWorkers;

  /// Sum of all gross salaries.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalGrossAmount;

  /// Sum of all net pay amounts.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalNetAmount;

  /// Sum of all tax deductions.
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get totalTaxAmount;

  /// Number of workers whose payroll has been processed.
  @override
  @JsonKey(fromJson: _intFromJson)
  int? get processedWorkers;

  /// When this pay period was created.
  @override
  DateTime? get createdAt;

  /// When this pay period was last updated.
  @override
  DateTime? get updatedAt;

  /// Additional notes or comments.
  @override
  String? get notes;

  /// Owner/employer user ID.
  @override
  String? get userId;

  /// Scheduled payment date.
  @override
  DateTime? get payDate;

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
  /// Display name for the pay period.
  String get name => throw _privateConstructorUsedError;

  /// First day of the pay period.
  DateTime get startDate => throw _privateConstructorUsedError;

  /// Last day of the pay period.
  DateTime get endDate => throw _privateConstructorUsedError;

  /// Pay frequency.
  PayPeriodFrequency get frequency => throw _privateConstructorUsedError;

  /// Optional notes.
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
class _$CreatePayPeriodRequestImpl extends _CreatePayPeriodRequest {
  const _$CreatePayPeriodRequestImpl({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    this.notes,
  }) : super._();

  factory _$CreatePayPeriodRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatePayPeriodRequestImplFromJson(json);

  /// Display name for the pay period.
  @override
  final String name;

  /// First day of the pay period.
  @override
  final DateTime startDate;

  /// Last day of the pay period.
  @override
  final DateTime endDate;

  /// Pay frequency.
  @override
  final PayPeriodFrequency frequency;

  /// Optional notes.
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

abstract class _CreatePayPeriodRequest extends CreatePayPeriodRequest {
  const factory _CreatePayPeriodRequest({
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    required final PayPeriodFrequency frequency,
    final String? notes,
  }) = _$CreatePayPeriodRequestImpl;
  const _CreatePayPeriodRequest._() : super._();

  factory _CreatePayPeriodRequest.fromJson(Map<String, dynamic> json) =
      _$CreatePayPeriodRequestImpl.fromJson;

  /// Display name for the pay period.
  @override
  String get name;

  /// First day of the pay period.
  @override
  DateTime get startDate;

  /// Last day of the pay period.
  @override
  DateTime get endDate;

  /// Pay frequency.
  @override
  PayPeriodFrequency get frequency;

  /// Optional notes.
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
  /// Updated name (optional).
  String? get name => throw _privateConstructorUsedError;

  /// Updated start date (optional).
  DateTime? get startDate => throw _privateConstructorUsedError;

  /// Updated end date (optional).
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Updated frequency (optional).
  PayPeriodFrequency? get frequency => throw _privateConstructorUsedError;

  /// Updated status (optional).
  PayPeriodStatus? get status => throw _privateConstructorUsedError;

  /// Updated notes (optional).
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
class _$UpdatePayPeriodRequestImpl extends _UpdatePayPeriodRequest {
  const _$UpdatePayPeriodRequestImpl({
    this.name,
    this.startDate,
    this.endDate,
    this.frequency,
    this.status,
    this.notes,
  }) : super._();

  factory _$UpdatePayPeriodRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdatePayPeriodRequestImplFromJson(json);

  /// Updated name (optional).
  @override
  final String? name;

  /// Updated start date (optional).
  @override
  final DateTime? startDate;

  /// Updated end date (optional).
  @override
  final DateTime? endDate;

  /// Updated frequency (optional).
  @override
  final PayPeriodFrequency? frequency;

  /// Updated status (optional).
  @override
  final PayPeriodStatus? status;

  /// Updated notes (optional).
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

abstract class _UpdatePayPeriodRequest extends UpdatePayPeriodRequest {
  const factory _UpdatePayPeriodRequest({
    final String? name,
    final DateTime? startDate,
    final DateTime? endDate,
    final PayPeriodFrequency? frequency,
    final PayPeriodStatus? status,
    final String? notes,
  }) = _$UpdatePayPeriodRequestImpl;
  const _UpdatePayPeriodRequest._() : super._();

  factory _UpdatePayPeriodRequest.fromJson(Map<String, dynamic> json) =
      _$UpdatePayPeriodRequestImpl.fromJson;

  /// Updated name (optional).
  @override
  String? get name;

  /// Updated start date (optional).
  @override
  DateTime? get startDate;

  /// Updated end date (optional).
  @override
  DateTime? get endDate;

  /// Updated frequency (optional).
  @override
  PayPeriodFrequency? get frequency;

  /// Updated status (optional).
  @override
  PayPeriodStatus? get status;

  /// Updated notes (optional).
  @override
  String? get notes;

  /// Create a copy of UpdatePayPeriodRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePayPeriodRequestImplCopyWith<_$UpdatePayPeriodRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
