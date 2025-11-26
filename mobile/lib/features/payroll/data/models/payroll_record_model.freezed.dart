// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PayrollRecordModel _$PayrollRecordModelFromJson(Map<String, dynamic> json) {
  return _PayrollRecordModel.fromJson(json);
}

/// @nodoc
mixin _$PayrollRecordModel {
  String get id => throw _privateConstructorUsedError;
  String get workerId => throw _privateConstructorUsedError;
  String get workerName => throw _privateConstructorUsedError;
  double get grossSalary => throw _privateConstructorUsedError;
  double get netPay => throw _privateConstructorUsedError;
  String get payPeriodId => throw _privateConstructorUsedError;
  String get paymentStatus => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get deductions => throw _privateConstructorUsedError;
  double get bonuses => throw _privateConstructorUsedError;
  double get otherEarnings => throw _privateConstructorUsedError;

  /// Serializes this PayrollRecordModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PayrollRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PayrollRecordModelCopyWith<PayrollRecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PayrollRecordModelCopyWith<$Res> {
  factory $PayrollRecordModelCopyWith(
    PayrollRecordModel value,
    $Res Function(PayrollRecordModel) then,
  ) = _$PayrollRecordModelCopyWithImpl<$Res, PayrollRecordModel>;
  @useResult
  $Res call({
    String id,
    String workerId,
    String workerName,
    double grossSalary,
    double netPay,
    String payPeriodId,
    String paymentStatus,
    DateTime createdAt,
    List<String> deductions,
    double bonuses,
    double otherEarnings,
  });
}

/// @nodoc
class _$PayrollRecordModelCopyWithImpl<$Res, $Val extends PayrollRecordModel>
    implements $PayrollRecordModelCopyWith<$Res> {
  _$PayrollRecordModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PayrollRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workerId = null,
    Object? workerName = null,
    Object? grossSalary = null,
    Object? netPay = null,
    Object? payPeriodId = null,
    Object? paymentStatus = null,
    Object? createdAt = null,
    Object? deductions = null,
    Object? bonuses = null,
    Object? otherEarnings = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            workerId: null == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String,
            workerName: null == workerName
                ? _value.workerName
                : workerName // ignore: cast_nullable_to_non_nullable
                      as String,
            grossSalary: null == grossSalary
                ? _value.grossSalary
                : grossSalary // ignore: cast_nullable_to_non_nullable
                      as double,
            netPay: null == netPay
                ? _value.netPay
                : netPay // ignore: cast_nullable_to_non_nullable
                      as double,
            payPeriodId: null == payPeriodId
                ? _value.payPeriodId
                : payPeriodId // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deductions: null == deductions
                ? _value.deductions
                : deductions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            bonuses: null == bonuses
                ? _value.bonuses
                : bonuses // ignore: cast_nullable_to_non_nullable
                      as double,
            otherEarnings: null == otherEarnings
                ? _value.otherEarnings
                : otherEarnings // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PayrollRecordModelImplCopyWith<$Res>
    implements $PayrollRecordModelCopyWith<$Res> {
  factory _$$PayrollRecordModelImplCopyWith(
    _$PayrollRecordModelImpl value,
    $Res Function(_$PayrollRecordModelImpl) then,
  ) = __$$PayrollRecordModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String workerId,
    String workerName,
    double grossSalary,
    double netPay,
    String payPeriodId,
    String paymentStatus,
    DateTime createdAt,
    List<String> deductions,
    double bonuses,
    double otherEarnings,
  });
}

/// @nodoc
class __$$PayrollRecordModelImplCopyWithImpl<$Res>
    extends _$PayrollRecordModelCopyWithImpl<$Res, _$PayrollRecordModelImpl>
    implements _$$PayrollRecordModelImplCopyWith<$Res> {
  __$$PayrollRecordModelImplCopyWithImpl(
    _$PayrollRecordModelImpl _value,
    $Res Function(_$PayrollRecordModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PayrollRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workerId = null,
    Object? workerName = null,
    Object? grossSalary = null,
    Object? netPay = null,
    Object? payPeriodId = null,
    Object? paymentStatus = null,
    Object? createdAt = null,
    Object? deductions = null,
    Object? bonuses = null,
    Object? otherEarnings = null,
  }) {
    return _then(
      _$PayrollRecordModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerName: null == workerName
            ? _value.workerName
            : workerName // ignore: cast_nullable_to_non_nullable
                  as String,
        grossSalary: null == grossSalary
            ? _value.grossSalary
            : grossSalary // ignore: cast_nullable_to_non_nullable
                  as double,
        netPay: null == netPay
            ? _value.netPay
            : netPay // ignore: cast_nullable_to_non_nullable
                  as double,
        payPeriodId: null == payPeriodId
            ? _value.payPeriodId
            : payPeriodId // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deductions: null == deductions
            ? _value._deductions
            : deductions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        bonuses: null == bonuses
            ? _value.bonuses
            : bonuses // ignore: cast_nullable_to_non_nullable
                  as double,
        otherEarnings: null == otherEarnings
            ? _value.otherEarnings
            : otherEarnings // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PayrollRecordModelImpl implements _PayrollRecordModel {
  const _$PayrollRecordModelImpl({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.grossSalary,
    required this.netPay,
    required this.payPeriodId,
    required this.paymentStatus,
    required this.createdAt,
    final List<String> deductions = const [],
    this.bonuses = 0.0,
    this.otherEarnings = 0.0,
  }) : _deductions = deductions;

  factory _$PayrollRecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PayrollRecordModelImplFromJson(json);

  @override
  final String id;
  @override
  final String workerId;
  @override
  final String workerName;
  @override
  final double grossSalary;
  @override
  final double netPay;
  @override
  final String payPeriodId;
  @override
  final String paymentStatus;
  @override
  final DateTime createdAt;
  final List<String> _deductions;
  @override
  @JsonKey()
  List<String> get deductions {
    if (_deductions is EqualUnmodifiableListView) return _deductions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deductions);
  }

  @override
  @JsonKey()
  final double bonuses;
  @override
  @JsonKey()
  final double otherEarnings;

  @override
  String toString() {
    return 'PayrollRecordModel(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, netPay: $netPay, payPeriodId: $payPeriodId, paymentStatus: $paymentStatus, createdAt: $createdAt, deductions: $deductions, bonuses: $bonuses, otherEarnings: $otherEarnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PayrollRecordModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.workerName, workerName) ||
                other.workerName == workerName) &&
            (identical(other.grossSalary, grossSalary) ||
                other.grossSalary == grossSalary) &&
            (identical(other.netPay, netPay) || other.netPay == netPay) &&
            (identical(other.payPeriodId, payPeriodId) ||
                other.payPeriodId == payPeriodId) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._deductions,
              _deductions,
            ) &&
            (identical(other.bonuses, bonuses) || other.bonuses == bonuses) &&
            (identical(other.otherEarnings, otherEarnings) ||
                other.otherEarnings == otherEarnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    workerId,
    workerName,
    grossSalary,
    netPay,
    payPeriodId,
    paymentStatus,
    createdAt,
    const DeepCollectionEquality().hash(_deductions),
    bonuses,
    otherEarnings,
  );

  /// Create a copy of PayrollRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PayrollRecordModelImplCopyWith<_$PayrollRecordModelImpl> get copyWith =>
      __$$PayrollRecordModelImplCopyWithImpl<_$PayrollRecordModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PayrollRecordModelImplToJson(this);
  }
}

abstract class _PayrollRecordModel implements PayrollRecordModel {
  const factory _PayrollRecordModel({
    required final String id,
    required final String workerId,
    required final String workerName,
    required final double grossSalary,
    required final double netPay,
    required final String payPeriodId,
    required final String paymentStatus,
    required final DateTime createdAt,
    final List<String> deductions,
    final double bonuses,
    final double otherEarnings,
  }) = _$PayrollRecordModelImpl;

  factory _PayrollRecordModel.fromJson(Map<String, dynamic> json) =
      _$PayrollRecordModelImpl.fromJson;

  @override
  String get id;
  @override
  String get workerId;
  @override
  String get workerName;
  @override
  double get grossSalary;
  @override
  double get netPay;
  @override
  String get payPeriodId;
  @override
  String get paymentStatus;
  @override
  DateTime get createdAt;
  @override
  List<String> get deductions;
  @override
  double get bonuses;
  @override
  double get otherEarnings;

  /// Create a copy of PayrollRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PayrollRecordModelImplCopyWith<_$PayrollRecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
