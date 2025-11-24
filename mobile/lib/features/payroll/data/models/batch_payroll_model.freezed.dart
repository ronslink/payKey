// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch_payroll_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkerPayrollResult _$WorkerPayrollResultFromJson(Map<String, dynamic> json) {
  return _WorkerPayrollResult.fromJson(json);
}

/// @nodoc
mixin _$WorkerPayrollResult {
  String get workerId => throw _privateConstructorUsedError;
  String get workerName => throw _privateConstructorUsedError;
  bool get success => throw _privateConstructorUsedError;
  double? get grossSalary => throw _privateConstructorUsedError;
  double? get netPay => throw _privateConstructorUsedError;
  String? get transactionId => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this WorkerPayrollResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkerPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkerPayrollResultCopyWith<WorkerPayrollResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkerPayrollResultCopyWith<$Res> {
  factory $WorkerPayrollResultCopyWith(
    WorkerPayrollResult value,
    $Res Function(WorkerPayrollResult) then,
  ) = _$WorkerPayrollResultCopyWithImpl<$Res, WorkerPayrollResult>;
  @useResult
  $Res call({
    String workerId,
    String workerName,
    bool success,
    double? grossSalary,
    double? netPay,
    String? transactionId,
    String? error,
  });
}

/// @nodoc
class _$WorkerPayrollResultCopyWithImpl<$Res, $Val extends WorkerPayrollResult>
    implements $WorkerPayrollResultCopyWith<$Res> {
  _$WorkerPayrollResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkerPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? workerName = null,
    Object? success = null,
    Object? grossSalary = freezed,
    Object? netPay = freezed,
    Object? transactionId = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            workerId: null == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String,
            workerName: null == workerName
                ? _value.workerName
                : workerName // ignore: cast_nullable_to_non_nullable
                      as String,
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            grossSalary: freezed == grossSalary
                ? _value.grossSalary
                : grossSalary // ignore: cast_nullable_to_non_nullable
                      as double?,
            netPay: freezed == netPay
                ? _value.netPay
                : netPay // ignore: cast_nullable_to_non_nullable
                      as double?,
            transactionId: freezed == transactionId
                ? _value.transactionId
                : transactionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkerPayrollResultImplCopyWith<$Res>
    implements $WorkerPayrollResultCopyWith<$Res> {
  factory _$$WorkerPayrollResultImplCopyWith(
    _$WorkerPayrollResultImpl value,
    $Res Function(_$WorkerPayrollResultImpl) then,
  ) = __$$WorkerPayrollResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String workerId,
    String workerName,
    bool success,
    double? grossSalary,
    double? netPay,
    String? transactionId,
    String? error,
  });
}

/// @nodoc
class __$$WorkerPayrollResultImplCopyWithImpl<$Res>
    extends _$WorkerPayrollResultCopyWithImpl<$Res, _$WorkerPayrollResultImpl>
    implements _$$WorkerPayrollResultImplCopyWith<$Res> {
  __$$WorkerPayrollResultImplCopyWithImpl(
    _$WorkerPayrollResultImpl _value,
    $Res Function(_$WorkerPayrollResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkerPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? workerName = null,
    Object? success = null,
    Object? grossSalary = freezed,
    Object? netPay = freezed,
    Object? transactionId = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$WorkerPayrollResultImpl(
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerName: null == workerName
            ? _value.workerName
            : workerName // ignore: cast_nullable_to_non_nullable
                  as String,
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        grossSalary: freezed == grossSalary
            ? _value.grossSalary
            : grossSalary // ignore: cast_nullable_to_non_nullable
                  as double?,
        netPay: freezed == netPay
            ? _value.netPay
            : netPay // ignore: cast_nullable_to_non_nullable
                  as double?,
        transactionId: freezed == transactionId
            ? _value.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkerPayrollResultImpl implements _WorkerPayrollResult {
  const _$WorkerPayrollResultImpl({
    required this.workerId,
    required this.workerName,
    required this.success,
    this.grossSalary,
    this.netPay,
    this.transactionId,
    this.error,
  });

  factory _$WorkerPayrollResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkerPayrollResultImplFromJson(json);

  @override
  final String workerId;
  @override
  final String workerName;
  @override
  final bool success;
  @override
  final double? grossSalary;
  @override
  final double? netPay;
  @override
  final String? transactionId;
  @override
  final String? error;

  @override
  String toString() {
    return 'WorkerPayrollResult(workerId: $workerId, workerName: $workerName, success: $success, grossSalary: $grossSalary, netPay: $netPay, transactionId: $transactionId, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkerPayrollResultImpl &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.workerName, workerName) ||
                other.workerName == workerName) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.grossSalary, grossSalary) ||
                other.grossSalary == grossSalary) &&
            (identical(other.netPay, netPay) || other.netPay == netPay) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    workerId,
    workerName,
    success,
    grossSalary,
    netPay,
    transactionId,
    error,
  );

  /// Create a copy of WorkerPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkerPayrollResultImplCopyWith<_$WorkerPayrollResultImpl> get copyWith =>
      __$$WorkerPayrollResultImplCopyWithImpl<_$WorkerPayrollResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkerPayrollResultImplToJson(this);
  }
}

abstract class _WorkerPayrollResult implements WorkerPayrollResult {
  const factory _WorkerPayrollResult({
    required final String workerId,
    required final String workerName,
    required final bool success,
    final double? grossSalary,
    final double? netPay,
    final String? transactionId,
    final String? error,
  }) = _$WorkerPayrollResultImpl;

  factory _WorkerPayrollResult.fromJson(Map<String, dynamic> json) =
      _$WorkerPayrollResultImpl.fromJson;

  @override
  String get workerId;
  @override
  String get workerName;
  @override
  bool get success;
  @override
  double? get grossSalary;
  @override
  double? get netPay;
  @override
  String? get transactionId;
  @override
  String? get error;

  /// Create a copy of WorkerPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkerPayrollResultImplCopyWith<_$WorkerPayrollResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BatchPayrollResult _$BatchPayrollResultFromJson(Map<String, dynamic> json) {
  return _BatchPayrollResult.fromJson(json);
}

/// @nodoc
mixin _$BatchPayrollResult {
  int get totalWorkers => throw _privateConstructorUsedError;
  int get successCount => throw _privateConstructorUsedError;
  int get failureCount => throw _privateConstructorUsedError;
  double get totalGross => throw _privateConstructorUsedError;
  double get totalNet => throw _privateConstructorUsedError;
  List<WorkerPayrollResult> get results => throw _privateConstructorUsedError;
  String get processedAt => throw _privateConstructorUsedError;

  /// Serializes this BatchPayrollResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BatchPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BatchPayrollResultCopyWith<BatchPayrollResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchPayrollResultCopyWith<$Res> {
  factory $BatchPayrollResultCopyWith(
    BatchPayrollResult value,
    $Res Function(BatchPayrollResult) then,
  ) = _$BatchPayrollResultCopyWithImpl<$Res, BatchPayrollResult>;
  @useResult
  $Res call({
    int totalWorkers,
    int successCount,
    int failureCount,
    double totalGross,
    double totalNet,
    List<WorkerPayrollResult> results,
    String processedAt,
  });
}

/// @nodoc
class _$BatchPayrollResultCopyWithImpl<$Res, $Val extends BatchPayrollResult>
    implements $BatchPayrollResultCopyWith<$Res> {
  _$BatchPayrollResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BatchPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWorkers = null,
    Object? successCount = null,
    Object? failureCount = null,
    Object? totalGross = null,
    Object? totalNet = null,
    Object? results = null,
    Object? processedAt = null,
  }) {
    return _then(
      _value.copyWith(
            totalWorkers: null == totalWorkers
                ? _value.totalWorkers
                : totalWorkers // ignore: cast_nullable_to_non_nullable
                      as int,
            successCount: null == successCount
                ? _value.successCount
                : successCount // ignore: cast_nullable_to_non_nullable
                      as int,
            failureCount: null == failureCount
                ? _value.failureCount
                : failureCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalGross: null == totalGross
                ? _value.totalGross
                : totalGross // ignore: cast_nullable_to_non_nullable
                      as double,
            totalNet: null == totalNet
                ? _value.totalNet
                : totalNet // ignore: cast_nullable_to_non_nullable
                      as double,
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as List<WorkerPayrollResult>,
            processedAt: null == processedAt
                ? _value.processedAt
                : processedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BatchPayrollResultImplCopyWith<$Res>
    implements $BatchPayrollResultCopyWith<$Res> {
  factory _$$BatchPayrollResultImplCopyWith(
    _$BatchPayrollResultImpl value,
    $Res Function(_$BatchPayrollResultImpl) then,
  ) = __$$BatchPayrollResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalWorkers,
    int successCount,
    int failureCount,
    double totalGross,
    double totalNet,
    List<WorkerPayrollResult> results,
    String processedAt,
  });
}

/// @nodoc
class __$$BatchPayrollResultImplCopyWithImpl<$Res>
    extends _$BatchPayrollResultCopyWithImpl<$Res, _$BatchPayrollResultImpl>
    implements _$$BatchPayrollResultImplCopyWith<$Res> {
  __$$BatchPayrollResultImplCopyWithImpl(
    _$BatchPayrollResultImpl _value,
    $Res Function(_$BatchPayrollResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BatchPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWorkers = null,
    Object? successCount = null,
    Object? failureCount = null,
    Object? totalGross = null,
    Object? totalNet = null,
    Object? results = null,
    Object? processedAt = null,
  }) {
    return _then(
      _$BatchPayrollResultImpl(
        totalWorkers: null == totalWorkers
            ? _value.totalWorkers
            : totalWorkers // ignore: cast_nullable_to_non_nullable
                  as int,
        successCount: null == successCount
            ? _value.successCount
            : successCount // ignore: cast_nullable_to_non_nullable
                  as int,
        failureCount: null == failureCount
            ? _value.failureCount
            : failureCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalGross: null == totalGross
            ? _value.totalGross
            : totalGross // ignore: cast_nullable_to_non_nullable
                  as double,
        totalNet: null == totalNet
            ? _value.totalNet
            : totalNet // ignore: cast_nullable_to_non_nullable
                  as double,
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<WorkerPayrollResult>,
        processedAt: null == processedAt
            ? _value.processedAt
            : processedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BatchPayrollResultImpl implements _BatchPayrollResult {
  const _$BatchPayrollResultImpl({
    required this.totalWorkers,
    required this.successCount,
    required this.failureCount,
    required this.totalGross,
    required this.totalNet,
    required final List<WorkerPayrollResult> results,
    required this.processedAt,
  }) : _results = results;

  factory _$BatchPayrollResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$BatchPayrollResultImplFromJson(json);

  @override
  final int totalWorkers;
  @override
  final int successCount;
  @override
  final int failureCount;
  @override
  final double totalGross;
  @override
  final double totalNet;
  final List<WorkerPayrollResult> _results;
  @override
  List<WorkerPayrollResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String processedAt;

  @override
  String toString() {
    return 'BatchPayrollResult(totalWorkers: $totalWorkers, successCount: $successCount, failureCount: $failureCount, totalGross: $totalGross, totalNet: $totalNet, results: $results, processedAt: $processedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatchPayrollResultImpl &&
            (identical(other.totalWorkers, totalWorkers) ||
                other.totalWorkers == totalWorkers) &&
            (identical(other.successCount, successCount) ||
                other.successCount == successCount) &&
            (identical(other.failureCount, failureCount) ||
                other.failureCount == failureCount) &&
            (identical(other.totalGross, totalGross) ||
                other.totalGross == totalGross) &&
            (identical(other.totalNet, totalNet) ||
                other.totalNet == totalNet) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalWorkers,
    successCount,
    failureCount,
    totalGross,
    totalNet,
    const DeepCollectionEquality().hash(_results),
    processedAt,
  );

  /// Create a copy of BatchPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BatchPayrollResultImplCopyWith<_$BatchPayrollResultImpl> get copyWith =>
      __$$BatchPayrollResultImplCopyWithImpl<_$BatchPayrollResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BatchPayrollResultImplToJson(this);
  }
}

abstract class _BatchPayrollResult implements BatchPayrollResult {
  const factory _BatchPayrollResult({
    required final int totalWorkers,
    required final int successCount,
    required final int failureCount,
    required final double totalGross,
    required final double totalNet,
    required final List<WorkerPayrollResult> results,
    required final String processedAt,
  }) = _$BatchPayrollResultImpl;

  factory _BatchPayrollResult.fromJson(Map<String, dynamic> json) =
      _$BatchPayrollResultImpl.fromJson;

  @override
  int get totalWorkers;
  @override
  int get successCount;
  @override
  int get failureCount;
  @override
  double get totalGross;
  @override
  double get totalNet;
  @override
  List<WorkerPayrollResult> get results;
  @override
  String get processedAt;

  /// Create a copy of BatchPayrollResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BatchPayrollResultImplCopyWith<_$BatchPayrollResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
