// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_tracking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TimeEntry _$TimeEntryFromJson(Map<String, dynamic> json) {
  return _TimeEntry.fromJson(json);
}

/// @nodoc
mixin _$TimeEntry {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get workerId => throw _privateConstructorUsedError;
  String get clockInTime => throw _privateConstructorUsedError;
  String? get clockOutTime => throw _privateConstructorUsedError;
  double? get clockInLatitude => throw _privateConstructorUsedError;
  double? get clockInLongitude => throw _privateConstructorUsedError;
  double? get clockOutLatitude => throw _privateConstructorUsedError;
  double? get clockOutLongitude => throw _privateConstructorUsedError;
  double? get totalHours => throw _privateConstructorUsedError;
  TimeEntryStatus get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get propertyId => throw _privateConstructorUsedError;

  /// Serializes this TimeEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimeEntryCopyWith<TimeEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeEntryCopyWith<$Res> {
  factory $TimeEntryCopyWith(TimeEntry value, $Res Function(TimeEntry) then) =
      _$TimeEntryCopyWithImpl<$Res, TimeEntry>;
  @useResult
  $Res call({
    String id,
    String userId,
    String workerId,
    String clockInTime,
    String? clockOutTime,
    double? clockInLatitude,
    double? clockInLongitude,
    double? clockOutLatitude,
    double? clockOutLongitude,
    double? totalHours,
    TimeEntryStatus status,
    String? notes,
    String createdAt,
    String? propertyId,
  });
}

/// @nodoc
class _$TimeEntryCopyWithImpl<$Res, $Val extends TimeEntry>
    implements $TimeEntryCopyWith<$Res> {
  _$TimeEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workerId = null,
    Object? clockInTime = null,
    Object? clockOutTime = freezed,
    Object? clockInLatitude = freezed,
    Object? clockInLongitude = freezed,
    Object? clockOutLatitude = freezed,
    Object? clockOutLongitude = freezed,
    Object? totalHours = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? propertyId = freezed,
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
            workerId: null == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String,
            clockInTime: null == clockInTime
                ? _value.clockInTime
                : clockInTime // ignore: cast_nullable_to_non_nullable
                      as String,
            clockOutTime: freezed == clockOutTime
                ? _value.clockOutTime
                : clockOutTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            clockInLatitude: freezed == clockInLatitude
                ? _value.clockInLatitude
                : clockInLatitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            clockInLongitude: freezed == clockInLongitude
                ? _value.clockInLongitude
                : clockInLongitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            clockOutLatitude: freezed == clockOutLatitude
                ? _value.clockOutLatitude
                : clockOutLatitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            clockOutLongitude: freezed == clockOutLongitude
                ? _value.clockOutLongitude
                : clockOutLongitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalHours: freezed == totalHours
                ? _value.totalHours
                : totalHours // ignore: cast_nullable_to_non_nullable
                      as double?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TimeEntryStatus,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            propertyId: freezed == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeEntryImplCopyWith<$Res>
    implements $TimeEntryCopyWith<$Res> {
  factory _$$TimeEntryImplCopyWith(
    _$TimeEntryImpl value,
    $Res Function(_$TimeEntryImpl) then,
  ) = __$$TimeEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String workerId,
    String clockInTime,
    String? clockOutTime,
    double? clockInLatitude,
    double? clockInLongitude,
    double? clockOutLatitude,
    double? clockOutLongitude,
    double? totalHours,
    TimeEntryStatus status,
    String? notes,
    String createdAt,
    String? propertyId,
  });
}

/// @nodoc
class __$$TimeEntryImplCopyWithImpl<$Res>
    extends _$TimeEntryCopyWithImpl<$Res, _$TimeEntryImpl>
    implements _$$TimeEntryImplCopyWith<$Res> {
  __$$TimeEntryImplCopyWithImpl(
    _$TimeEntryImpl _value,
    $Res Function(_$TimeEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? workerId = null,
    Object? clockInTime = null,
    Object? clockOutTime = freezed,
    Object? clockInLatitude = freezed,
    Object? clockInLongitude = freezed,
    Object? clockOutLatitude = freezed,
    Object? clockOutLongitude = freezed,
    Object? totalHours = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? propertyId = freezed,
  }) {
    return _then(
      _$TimeEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        clockInTime: null == clockInTime
            ? _value.clockInTime
            : clockInTime // ignore: cast_nullable_to_non_nullable
                  as String,
        clockOutTime: freezed == clockOutTime
            ? _value.clockOutTime
            : clockOutTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        clockInLatitude: freezed == clockInLatitude
            ? _value.clockInLatitude
            : clockInLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        clockInLongitude: freezed == clockInLongitude
            ? _value.clockInLongitude
            : clockInLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        clockOutLatitude: freezed == clockOutLatitude
            ? _value.clockOutLatitude
            : clockOutLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        clockOutLongitude: freezed == clockOutLongitude
            ? _value.clockOutLongitude
            : clockOutLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalHours: freezed == totalHours
            ? _value.totalHours
            : totalHours // ignore: cast_nullable_to_non_nullable
                  as double?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TimeEntryStatus,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        propertyId: freezed == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TimeEntryImpl implements _TimeEntry {
  const _$TimeEntryImpl({
    required this.id,
    required this.userId,
    required this.workerId,
    required this.clockInTime,
    this.clockOutTime,
    this.clockInLatitude,
    this.clockInLongitude,
    this.clockOutLatitude,
    this.clockOutLongitude,
    this.totalHours,
    required this.status,
    this.notes,
    required this.createdAt,
    this.propertyId,
  });

  factory _$TimeEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimeEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String workerId;
  @override
  final String clockInTime;
  @override
  final String? clockOutTime;
  @override
  final double? clockInLatitude;
  @override
  final double? clockInLongitude;
  @override
  final double? clockOutLatitude;
  @override
  final double? clockOutLongitude;
  @override
  final double? totalHours;
  @override
  final TimeEntryStatus status;
  @override
  final String? notes;
  @override
  final String createdAt;
  @override
  final String? propertyId;

  @override
  String toString() {
    return 'TimeEntry(id: $id, userId: $userId, workerId: $workerId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, totalHours: $totalHours, status: $status, notes: $notes, createdAt: $createdAt, propertyId: $propertyId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.clockInTime, clockInTime) ||
                other.clockInTime == clockInTime) &&
            (identical(other.clockOutTime, clockOutTime) ||
                other.clockOutTime == clockOutTime) &&
            (identical(other.clockInLatitude, clockInLatitude) ||
                other.clockInLatitude == clockInLatitude) &&
            (identical(other.clockInLongitude, clockInLongitude) ||
                other.clockInLongitude == clockInLongitude) &&
            (identical(other.clockOutLatitude, clockOutLatitude) ||
                other.clockOutLatitude == clockOutLatitude) &&
            (identical(other.clockOutLongitude, clockOutLongitude) ||
                other.clockOutLongitude == clockOutLongitude) &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    workerId,
    clockInTime,
    clockOutTime,
    clockInLatitude,
    clockInLongitude,
    clockOutLatitude,
    clockOutLongitude,
    totalHours,
    status,
    notes,
    createdAt,
    propertyId,
  );

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeEntryImplCopyWith<_$TimeEntryImpl> get copyWith =>
      __$$TimeEntryImplCopyWithImpl<_$TimeEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimeEntryImplToJson(this);
  }
}

abstract class _TimeEntry implements TimeEntry {
  const factory _TimeEntry({
    required final String id,
    required final String userId,
    required final String workerId,
    required final String clockInTime,
    final String? clockOutTime,
    final double? clockInLatitude,
    final double? clockInLongitude,
    final double? clockOutLatitude,
    final double? clockOutLongitude,
    final double? totalHours,
    required final TimeEntryStatus status,
    final String? notes,
    required final String createdAt,
    final String? propertyId,
  }) = _$TimeEntryImpl;

  factory _TimeEntry.fromJson(Map<String, dynamic> json) =
      _$TimeEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get workerId;
  @override
  String get clockInTime;
  @override
  String? get clockOutTime;
  @override
  double? get clockInLatitude;
  @override
  double? get clockInLongitude;
  @override
  double? get clockOutLatitude;
  @override
  double? get clockOutLongitude;
  @override
  double? get totalHours;
  @override
  TimeEntryStatus get status;
  @override
  String? get notes;
  @override
  String get createdAt;
  @override
  String? get propertyId;

  /// Create a copy of TimeEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimeEntryImplCopyWith<_$TimeEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClockInRequest _$ClockInRequestFromJson(Map<String, dynamic> json) {
  return _ClockInRequest.fromJson(json);
}

/// @nodoc
mixin _$ClockInRequest {
  String get workerId => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this ClockInRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClockInRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClockInRequestCopyWith<ClockInRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClockInRequestCopyWith<$Res> {
  factory $ClockInRequestCopyWith(
    ClockInRequest value,
    $Res Function(ClockInRequest) then,
  ) = _$ClockInRequestCopyWithImpl<$Res, ClockInRequest>;
  @useResult
  $Res call({
    String workerId,
    double latitude,
    double longitude,
    String? notes,
  });
}

/// @nodoc
class _$ClockInRequestCopyWithImpl<$Res, $Val extends ClockInRequest>
    implements $ClockInRequestCopyWith<$Res> {
  _$ClockInRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClockInRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            workerId: null == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
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
abstract class _$$ClockInRequestImplCopyWith<$Res>
    implements $ClockInRequestCopyWith<$Res> {
  factory _$$ClockInRequestImplCopyWith(
    _$ClockInRequestImpl value,
    $Res Function(_$ClockInRequestImpl) then,
  ) = __$$ClockInRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String workerId,
    double latitude,
    double longitude,
    String? notes,
  });
}

/// @nodoc
class __$$ClockInRequestImplCopyWithImpl<$Res>
    extends _$ClockInRequestCopyWithImpl<$Res, _$ClockInRequestImpl>
    implements _$$ClockInRequestImplCopyWith<$Res> {
  __$$ClockInRequestImplCopyWithImpl(
    _$ClockInRequestImpl _value,
    $Res Function(_$ClockInRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClockInRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workerId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$ClockInRequestImpl(
        workerId: null == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
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
class _$ClockInRequestImpl implements _ClockInRequest {
  const _$ClockInRequestImpl({
    required this.workerId,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  factory _$ClockInRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClockInRequestImplFromJson(json);

  @override
  final String workerId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? notes;

  @override
  String toString() {
    return 'ClockInRequest(workerId: $workerId, latitude: $latitude, longitude: $longitude, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClockInRequestImpl &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, workerId, latitude, longitude, notes);

  /// Create a copy of ClockInRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClockInRequestImplCopyWith<_$ClockInRequestImpl> get copyWith =>
      __$$ClockInRequestImplCopyWithImpl<_$ClockInRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ClockInRequestImplToJson(this);
  }
}

abstract class _ClockInRequest implements ClockInRequest {
  const factory _ClockInRequest({
    required final String workerId,
    required final double latitude,
    required final double longitude,
    final String? notes,
  }) = _$ClockInRequestImpl;

  factory _ClockInRequest.fromJson(Map<String, dynamic> json) =
      _$ClockInRequestImpl.fromJson;

  @override
  String get workerId;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get notes;

  /// Create a copy of ClockInRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClockInRequestImplCopyWith<_$ClockInRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClockOutRequest _$ClockOutRequestFromJson(Map<String, dynamic> json) {
  return _ClockOutRequest.fromJson(json);
}

/// @nodoc
mixin _$ClockOutRequest {
  String get timeEntryId => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this ClockOutRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClockOutRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClockOutRequestCopyWith<ClockOutRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClockOutRequestCopyWith<$Res> {
  factory $ClockOutRequestCopyWith(
    ClockOutRequest value,
    $Res Function(ClockOutRequest) then,
  ) = _$ClockOutRequestCopyWithImpl<$Res, ClockOutRequest>;
  @useResult
  $Res call({
    String timeEntryId,
    double latitude,
    double longitude,
    String? notes,
  });
}

/// @nodoc
class _$ClockOutRequestCopyWithImpl<$Res, $Val extends ClockOutRequest>
    implements $ClockOutRequestCopyWith<$Res> {
  _$ClockOutRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClockOutRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timeEntryId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            timeEntryId: null == timeEntryId
                ? _value.timeEntryId
                : timeEntryId // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
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
abstract class _$$ClockOutRequestImplCopyWith<$Res>
    implements $ClockOutRequestCopyWith<$Res> {
  factory _$$ClockOutRequestImplCopyWith(
    _$ClockOutRequestImpl value,
    $Res Function(_$ClockOutRequestImpl) then,
  ) = __$$ClockOutRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String timeEntryId,
    double latitude,
    double longitude,
    String? notes,
  });
}

/// @nodoc
class __$$ClockOutRequestImplCopyWithImpl<$Res>
    extends _$ClockOutRequestCopyWithImpl<$Res, _$ClockOutRequestImpl>
    implements _$$ClockOutRequestImplCopyWith<$Res> {
  __$$ClockOutRequestImplCopyWithImpl(
    _$ClockOutRequestImpl _value,
    $Res Function(_$ClockOutRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClockOutRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timeEntryId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$ClockOutRequestImpl(
        timeEntryId: null == timeEntryId
            ? _value.timeEntryId
            : timeEntryId // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
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
class _$ClockOutRequestImpl implements _ClockOutRequest {
  const _$ClockOutRequestImpl({
    required this.timeEntryId,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  factory _$ClockOutRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClockOutRequestImplFromJson(json);

  @override
  final String timeEntryId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? notes;

  @override
  String toString() {
    return 'ClockOutRequest(timeEntryId: $timeEntryId, latitude: $latitude, longitude: $longitude, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClockOutRequestImpl &&
            (identical(other.timeEntryId, timeEntryId) ||
                other.timeEntryId == timeEntryId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, timeEntryId, latitude, longitude, notes);

  /// Create a copy of ClockOutRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClockOutRequestImplCopyWith<_$ClockOutRequestImpl> get copyWith =>
      __$$ClockOutRequestImplCopyWithImpl<_$ClockOutRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ClockOutRequestImplToJson(this);
  }
}

abstract class _ClockOutRequest implements ClockOutRequest {
  const factory _ClockOutRequest({
    required final String timeEntryId,
    required final double latitude,
    required final double longitude,
    final String? notes,
  }) = _$ClockOutRequestImpl;

  factory _ClockOutRequest.fromJson(Map<String, dynamic> json) =
      _$ClockOutRequestImpl.fromJson;

  @override
  String get timeEntryId;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get notes;

  /// Create a copy of ClockOutRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClockOutRequestImplCopyWith<_$ClockOutRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
