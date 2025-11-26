// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LeaveRequestModel _$LeaveRequestModelFromJson(Map<String, dynamic> json) {
  return _LeaveRequestModel.fromJson(json);
}

/// @nodoc
mixin _$LeaveRequestModel {
  String get id => throw _privateConstructorUsedError;
  String get workerId => throw _privateConstructorUsedError;
  String get workerName => throw _privateConstructorUsedError;
  String get requestedById => throw _privateConstructorUsedError;
  String get leaveType => throw _privateConstructorUsedError;
  String get startDate => throw _privateConstructorUsedError;
  String get endDate => throw _privateConstructorUsedError;
  int get totalDays => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // PENDING, APPROVED, REJECTED, CANCELLED
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;
  String? get approvedById => throw _privateConstructorUsedError;
  String? get approvedAt => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  double? get dailyPayRate => throw _privateConstructorUsedError;
  bool get paidLeave => throw _privateConstructorUsedError;
  String? get emergencyContact => throw _privateConstructorUsedError;
  String? get emergencyPhone => throw _privateConstructorUsedError;

  /// Serializes this LeaveRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LeaveRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaveRequestModelCopyWith<LeaveRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveRequestModelCopyWith<$Res> {
  factory $LeaveRequestModelCopyWith(
    LeaveRequestModel value,
    $Res Function(LeaveRequestModel) then,
  ) = _$LeaveRequestModelCopyWithImpl<$Res, LeaveRequestModel>;
  @useResult
  $Res call({
    String id,
    String workerId,
    String workerName,
    String requestedById,
    String leaveType,
    String startDate,
    String endDate,
    int totalDays,
    String reason,
    String status,
    String createdAt,
    String updatedAt,
    String? approvedById,
    String? approvedAt,
    String? rejectionReason,
    double? dailyPayRate,
    bool paidLeave,
    String? emergencyContact,
    String? emergencyPhone,
  });
}

/// @nodoc
class _$LeaveRequestModelCopyWithImpl<$Res, $Val extends LeaveRequestModel>
    implements $LeaveRequestModelCopyWith<$Res> {
  _$LeaveRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaveRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workerId = null,
    Object? workerName = null,
    Object? requestedById = null,
    Object? leaveType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? totalDays = null,
    Object? reason = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? rejectionReason = freezed,
    Object? dailyPayRate = freezed,
    Object? paidLeave = null,
    Object? emergencyContact = freezed,
    Object? emergencyPhone = freezed,
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
            requestedById: null == requestedById
                ? _value.requestedById
                : requestedById // ignore: cast_nullable_to_non_nullable
                      as String,
            leaveType: null == leaveType
                ? _value.leaveType
                : leaveType // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String,
            totalDays: null == totalDays
                ? _value.totalDays
                : totalDays // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            approvedById: freezed == approvedById
                ? _value.approvedById
                : approvedById // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedAt: freezed == approvedAt
                ? _value.approvedAt
                : approvedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            dailyPayRate: freezed == dailyPayRate
                ? _value.dailyPayRate
                : dailyPayRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            paidLeave: null == paidLeave
                ? _value.paidLeave
                : paidLeave // ignore: cast_nullable_to_non_nullable
                      as bool,
            emergencyContact: freezed == emergencyContact
                ? _value.emergencyContact
                : emergencyContact // ignore: cast_nullable_to_non_nullable
                      as String?,
            emergencyPhone: freezed == emergencyPhone
                ? _value.emergencyPhone
                : emergencyPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaveRequestModelImplCopyWith<$Res>
    implements $LeaveRequestModelCopyWith<$Res> {
  factory _$$LeaveRequestModelImplCopyWith(
    _$LeaveRequestModelImpl value,
    $Res Function(_$LeaveRequestModelImpl) then,
  ) = __$$LeaveRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String workerId,
    String workerName,
    String requestedById,
    String leaveType,
    String startDate,
    String endDate,
    int totalDays,
    String reason,
    String status,
    String createdAt,
    String updatedAt,
    String? approvedById,
    String? approvedAt,
    String? rejectionReason,
    double? dailyPayRate,
    bool paidLeave,
    String? emergencyContact,
    String? emergencyPhone,
  });
}

/// @nodoc
class __$$LeaveRequestModelImplCopyWithImpl<$Res>
    extends _$LeaveRequestModelCopyWithImpl<$Res, _$LeaveRequestModelImpl>
    implements _$$LeaveRequestModelImplCopyWith<$Res> {
  __$$LeaveRequestModelImplCopyWithImpl(
    _$LeaveRequestModelImpl _value,
    $Res Function(_$LeaveRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaveRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workerId = null,
    Object? workerName = null,
    Object? requestedById = null,
    Object? leaveType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? totalDays = null,
    Object? reason = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? approvedById = freezed,
    Object? approvedAt = freezed,
    Object? rejectionReason = freezed,
    Object? dailyPayRate = freezed,
    Object? paidLeave = null,
    Object? emergencyContact = freezed,
    Object? emergencyPhone = freezed,
  }) {
    return _then(
      _$LeaveRequestModelImpl(
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
        requestedById: null == requestedById
            ? _value.requestedById
            : requestedById // ignore: cast_nullable_to_non_nullable
                  as String,
        leaveType: null == leaveType
            ? _value.leaveType
            : leaveType // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String,
        totalDays: null == totalDays
            ? _value.totalDays
            : totalDays // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        approvedById: freezed == approvedById
            ? _value.approvedById
            : approvedById // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedAt: freezed == approvedAt
            ? _value.approvedAt
            : approvedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        dailyPayRate: freezed == dailyPayRate
            ? _value.dailyPayRate
            : dailyPayRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        paidLeave: null == paidLeave
            ? _value.paidLeave
            : paidLeave // ignore: cast_nullable_to_non_nullable
                  as bool,
        emergencyContact: freezed == emergencyContact
            ? _value.emergencyContact
            : emergencyContact // ignore: cast_nullable_to_non_nullable
                  as String?,
        emergencyPhone: freezed == emergencyPhone
            ? _value.emergencyPhone
            : emergencyPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaveRequestModelImpl implements _LeaveRequestModel {
  const _$LeaveRequestModelImpl({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.requestedById,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.approvedById,
    this.approvedAt,
    this.rejectionReason,
    this.dailyPayRate,
    required this.paidLeave,
    this.emergencyContact,
    this.emergencyPhone,
  });

  factory _$LeaveRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaveRequestModelImplFromJson(json);

  @override
  final String id;
  @override
  final String workerId;
  @override
  final String workerName;
  @override
  final String requestedById;
  @override
  final String leaveType;
  @override
  final String startDate;
  @override
  final String endDate;
  @override
  final int totalDays;
  @override
  final String reason;
  @override
  final String status;
  // PENDING, APPROVED, REJECTED, CANCELLED
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final String? approvedById;
  @override
  final String? approvedAt;
  @override
  final String? rejectionReason;
  @override
  final double? dailyPayRate;
  @override
  final bool paidLeave;
  @override
  final String? emergencyContact;
  @override
  final String? emergencyPhone;

  @override
  String toString() {
    return 'LeaveRequestModel(id: $id, workerId: $workerId, workerName: $workerName, requestedById: $requestedById, leaveType: $leaveType, startDate: $startDate, endDate: $endDate, totalDays: $totalDays, reason: $reason, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, approvedById: $approvedById, approvedAt: $approvedAt, rejectionReason: $rejectionReason, dailyPayRate: $dailyPayRate, paidLeave: $paidLeave, emergencyContact: $emergencyContact, emergencyPhone: $emergencyPhone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveRequestModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.workerName, workerName) ||
                other.workerName == workerName) &&
            (identical(other.requestedById, requestedById) ||
                other.requestedById == requestedById) &&
            (identical(other.leaveType, leaveType) ||
                other.leaveType == leaveType) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.totalDays, totalDays) ||
                other.totalDays == totalDays) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.approvedById, approvedById) ||
                other.approvedById == approvedById) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.dailyPayRate, dailyPayRate) ||
                other.dailyPayRate == dailyPayRate) &&
            (identical(other.paidLeave, paidLeave) ||
                other.paidLeave == paidLeave) &&
            (identical(other.emergencyContact, emergencyContact) ||
                other.emergencyContact == emergencyContact) &&
            (identical(other.emergencyPhone, emergencyPhone) ||
                other.emergencyPhone == emergencyPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    workerId,
    workerName,
    requestedById,
    leaveType,
    startDate,
    endDate,
    totalDays,
    reason,
    status,
    createdAt,
    updatedAt,
    approvedById,
    approvedAt,
    rejectionReason,
    dailyPayRate,
    paidLeave,
    emergencyContact,
    emergencyPhone,
  ]);

  /// Create a copy of LeaveRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveRequestModelImplCopyWith<_$LeaveRequestModelImpl> get copyWith =>
      __$$LeaveRequestModelImplCopyWithImpl<_$LeaveRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaveRequestModelImplToJson(this);
  }
}

abstract class _LeaveRequestModel implements LeaveRequestModel {
  const factory _LeaveRequestModel({
    required final String id,
    required final String workerId,
    required final String workerName,
    required final String requestedById,
    required final String leaveType,
    required final String startDate,
    required final String endDate,
    required final int totalDays,
    required final String reason,
    required final String status,
    required final String createdAt,
    required final String updatedAt,
    final String? approvedById,
    final String? approvedAt,
    final String? rejectionReason,
    final double? dailyPayRate,
    required final bool paidLeave,
    final String? emergencyContact,
    final String? emergencyPhone,
  }) = _$LeaveRequestModelImpl;

  factory _LeaveRequestModel.fromJson(Map<String, dynamic> json) =
      _$LeaveRequestModelImpl.fromJson;

  @override
  String get id;
  @override
  String get workerId;
  @override
  String get workerName;
  @override
  String get requestedById;
  @override
  String get leaveType;
  @override
  String get startDate;
  @override
  String get endDate;
  @override
  int get totalDays;
  @override
  String get reason;
  @override
  String get status; // PENDING, APPROVED, REJECTED, CANCELLED
  @override
  String get createdAt;
  @override
  String get updatedAt;
  @override
  String? get approvedById;
  @override
  String? get approvedAt;
  @override
  String? get rejectionReason;
  @override
  double? get dailyPayRate;
  @override
  bool get paidLeave;
  @override
  String? get emergencyContact;
  @override
  String? get emergencyPhone;

  /// Create a copy of LeaveRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaveRequestModelImplCopyWith<_$LeaveRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LeaveBalanceModel _$LeaveBalanceModelFromJson(Map<String, dynamic> json) {
  return _LeaveBalanceModel.fromJson(json);
}

/// @nodoc
mixin _$LeaveBalanceModel {
  String get workerId => throw _privateConstructorUsedError;
  String get workerName => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get totalAnnualLeaves => throw _privateConstructorUsedError;
  int get usedAnnualLeaves => throw _privateConstructorUsedError;
  int get remainingAnnualLeaves => throw _privateConstructorUsedError;
  int get sickLeaves => throw _privateConstructorUsedError;
  int get pendingLeaves => throw _privateConstructorUsedError;

  /// Serializes this LeaveBalanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LeaveBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaveBalanceModelCopyWith<LeaveBalanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveBalanceModelCopyWith<$Res> {
  factory $LeaveBalanceModelCopyWith(
    LeaveBalanceModel value,
    $Res Function(LeaveBalanceModel) then,
  ) = _$LeaveBalanceModelCopyWithImpl<$Res, LeaveBalanceModel>;
  @useResult
  $Res call({
    String workerId,
    String workerName,
    int year,
    int totalAnnualLeaves,
    int usedAnnualLeaves,
    int remainingAnnualLeaves,
    int sickLeaves,
    int pendingLeaves,
  });
}

/// @nodoc
class _$LeaveBalanceModelCopyWithImpl<$Res, $Val extends LeaveBalanceModel>
    implements $LeaveBalanceModelCopyWith<$Res> {
  _$LeaveBalanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaveBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? workerName = null,
    Object? year = null,
    Object? totalAnnualLeaves = null,
    Object? usedAnnualLeaves = null,
    Object? remainingAnnualLeaves = null,
    Object? sickLeaves = null,
    Object? pendingLeaves = null,
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
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            totalAnnualLeaves: null == totalAnnualLeaves
                ? _value.totalAnnualLeaves
                : totalAnnualLeaves // ignore: cast_nullable_to_non_nullable
                      as int,
            usedAnnualLeaves: null == usedAnnualLeaves
                ? _value.usedAnnualLeaves
                : usedAnnualLeaves // ignore: cast_nullable_to_non_nullable
                      as int,
            remainingAnnualLeaves: null == remainingAnnualLeaves
                ? _value.remainingAnnualLeaves
                : remainingAnnualLeaves // ignore: cast_nullable_to_non_nullable
                      as int,
            sickLeaves: null == sickLeaves
                ? _value.sickLeaves
                : sickLeaves // ignore: cast_nullable_to_non_nullable
                      as int,
            pendingLeaves: null == pendingLeaves
                ? _value.pendingLeaves
                : pendingLeaves // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaveBalanceModelImplCopyWith<$Res>
    implements $LeaveBalanceModelCopyWith<$Res> {
  factory _$$LeaveBalanceModelImplCopyWith(
    _$LeaveBalanceModelImpl value,
    $Res Function(_$LeaveBalanceModelImpl) then,
  ) = __$$LeaveBalanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String workerId,
    String workerName,
    int year,
    int totalAnnualLeaves,
    int usedAnnualLeaves,
    int remainingAnnualLeaves,
    int sickLeaves,
    int pendingLeaves,
  });
}

/// @nodoc
class __$$LeaveBalanceModelImplCopyWithImpl<$Res>
    extends _$LeaveBalanceModelCopyWithImpl<$Res, _$LeaveBalanceModelImpl>
    implements _$$LeaveBalanceModelImplCopyWith<$Res> {
  __$$LeaveBalanceModelImplCopyWithImpl(
    _$LeaveBalanceModelImpl _value,
    $Res Function(_$LeaveBalanceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaveBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? workerName = null,
    Object? year = null,
    Object? totalAnnualLeaves = null,
    Object? usedAnnualLeaves = null,
    Object? remainingAnnualLeaves = null,
    Object? sickLeaves = null,
    Object? pendingLeaves = null,
  }) {
    return _then(
      _$LeaveBalanceModelImpl(
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerName: null == workerName
            ? _value.workerName
            : workerName // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        totalAnnualLeaves: null == totalAnnualLeaves
            ? _value.totalAnnualLeaves
            : totalAnnualLeaves // ignore: cast_nullable_to_non_nullable
                  as int,
        usedAnnualLeaves: null == usedAnnualLeaves
            ? _value.usedAnnualLeaves
            : usedAnnualLeaves // ignore: cast_nullable_to_non_nullable
                  as int,
        remainingAnnualLeaves: null == remainingAnnualLeaves
            ? _value.remainingAnnualLeaves
            : remainingAnnualLeaves // ignore: cast_nullable_to_non_nullable
                  as int,
        sickLeaves: null == sickLeaves
            ? _value.sickLeaves
            : sickLeaves // ignore: cast_nullable_to_non_nullable
                  as int,
        pendingLeaves: null == pendingLeaves
            ? _value.pendingLeaves
            : pendingLeaves // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaveBalanceModelImpl implements _LeaveBalanceModel {
  const _$LeaveBalanceModelImpl({
    required this.workerId,
    required this.workerName,
    required this.year,
    required this.totalAnnualLeaves,
    required this.usedAnnualLeaves,
    required this.remainingAnnualLeaves,
    required this.sickLeaves,
    required this.pendingLeaves,
  });

  factory _$LeaveBalanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaveBalanceModelImplFromJson(json);

  @override
  final String workerId;
  @override
  final String workerName;
  @override
  final int year;
  @override
  final int totalAnnualLeaves;
  @override
  final int usedAnnualLeaves;
  @override
  final int remainingAnnualLeaves;
  @override
  final int sickLeaves;
  @override
  final int pendingLeaves;

  @override
  String toString() {
    return 'LeaveBalanceModel(workerId: $workerId, workerName: $workerName, year: $year, totalAnnualLeaves: $totalAnnualLeaves, usedAnnualLeaves: $usedAnnualLeaves, remainingAnnualLeaves: $remainingAnnualLeaves, sickLeaves: $sickLeaves, pendingLeaves: $pendingLeaves)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveBalanceModelImpl &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.workerName, workerName) ||
                other.workerName == workerName) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.totalAnnualLeaves, totalAnnualLeaves) ||
                other.totalAnnualLeaves == totalAnnualLeaves) &&
            (identical(other.usedAnnualLeaves, usedAnnualLeaves) ||
                other.usedAnnualLeaves == usedAnnualLeaves) &&
            (identical(other.remainingAnnualLeaves, remainingAnnualLeaves) ||
                other.remainingAnnualLeaves == remainingAnnualLeaves) &&
            (identical(other.sickLeaves, sickLeaves) ||
                other.sickLeaves == sickLeaves) &&
            (identical(other.pendingLeaves, pendingLeaves) ||
                other.pendingLeaves == pendingLeaves));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    workerId,
    workerName,
    year,
    totalAnnualLeaves,
    usedAnnualLeaves,
    remainingAnnualLeaves,
    sickLeaves,
    pendingLeaves,
  );

  /// Create a copy of LeaveBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveBalanceModelImplCopyWith<_$LeaveBalanceModelImpl> get copyWith =>
      __$$LeaveBalanceModelImplCopyWithImpl<_$LeaveBalanceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaveBalanceModelImplToJson(this);
  }
}

abstract class _LeaveBalanceModel implements LeaveBalanceModel {
  const factory _LeaveBalanceModel({
    required final String workerId,
    required final String workerName,
    required final int year,
    required final int totalAnnualLeaves,
    required final int usedAnnualLeaves,
    required final int remainingAnnualLeaves,
    required final int sickLeaves,
    required final int pendingLeaves,
  }) = _$LeaveBalanceModelImpl;

  factory _LeaveBalanceModel.fromJson(Map<String, dynamic> json) =
      _$LeaveBalanceModelImpl.fromJson;

  @override
  String get workerId;
  @override
  String get workerName;
  @override
  int get year;
  @override
  int get totalAnnualLeaves;
  @override
  int get usedAnnualLeaves;
  @override
  int get remainingAnnualLeaves;
  @override
  int get sickLeaves;
  @override
  int get pendingLeaves;

  /// Create a copy of LeaveBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaveBalanceModelImplCopyWith<_$LeaveBalanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
