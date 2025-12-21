// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_tracking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimeEntry {

 String get id; String get userId; String get workerId; String get clockInTime; String? get clockOutTime; double? get clockInLatitude; double? get clockInLongitude; double? get clockOutLatitude; double? get clockOutLongitude; double? get totalHours; TimeEntryStatus get status; String? get notes; String get createdAt; String? get propertyId;
/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeEntryCopyWith<TimeEntry> get copyWith => _$TimeEntryCopyWithImpl<TimeEntry>(this as TimeEntry, _$identity);

  /// Serializes this TimeEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.clockInTime, clockInTime) || other.clockInTime == clockInTime)&&(identical(other.clockOutTime, clockOutTime) || other.clockOutTime == clockOutTime)&&(identical(other.clockInLatitude, clockInLatitude) || other.clockInLatitude == clockInLatitude)&&(identical(other.clockInLongitude, clockInLongitude) || other.clockInLongitude == clockInLongitude)&&(identical(other.clockOutLatitude, clockOutLatitude) || other.clockOutLatitude == clockOutLatitude)&&(identical(other.clockOutLongitude, clockOutLongitude) || other.clockOutLongitude == clockOutLongitude)&&(identical(other.totalHours, totalHours) || other.totalHours == totalHours)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,workerId,clockInTime,clockOutTime,clockInLatitude,clockInLongitude,clockOutLatitude,clockOutLongitude,totalHours,status,notes,createdAt,propertyId);

@override
String toString() {
  return 'TimeEntry(id: $id, userId: $userId, workerId: $workerId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, totalHours: $totalHours, status: $status, notes: $notes, createdAt: $createdAt, propertyId: $propertyId)';
}


}

/// @nodoc
abstract mixin class $TimeEntryCopyWith<$Res>  {
  factory $TimeEntryCopyWith(TimeEntry value, $Res Function(TimeEntry) _then) = _$TimeEntryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String workerId, String clockInTime, String? clockOutTime, double? clockInLatitude, double? clockInLongitude, double? clockOutLatitude, double? clockOutLongitude, double? totalHours, TimeEntryStatus status, String? notes, String createdAt, String? propertyId
});




}
/// @nodoc
class _$TimeEntryCopyWithImpl<$Res>
    implements $TimeEntryCopyWith<$Res> {
  _$TimeEntryCopyWithImpl(this._self, this._then);

  final TimeEntry _self;
  final $Res Function(TimeEntry) _then;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? workerId = null,Object? clockInTime = null,Object? clockOutTime = freezed,Object? clockInLatitude = freezed,Object? clockInLongitude = freezed,Object? clockOutLatitude = freezed,Object? clockOutLongitude = freezed,Object? totalHours = freezed,Object? status = null,Object? notes = freezed,Object? createdAt = null,Object? propertyId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,clockInTime: null == clockInTime ? _self.clockInTime : clockInTime // ignore: cast_nullable_to_non_nullable
as String,clockOutTime: freezed == clockOutTime ? _self.clockOutTime : clockOutTime // ignore: cast_nullable_to_non_nullable
as String?,clockInLatitude: freezed == clockInLatitude ? _self.clockInLatitude : clockInLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockInLongitude: freezed == clockInLongitude ? _self.clockInLongitude : clockInLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLatitude: freezed == clockOutLatitude ? _self.clockOutLatitude : clockOutLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLongitude: freezed == clockOutLongitude ? _self.clockOutLongitude : clockOutLongitude // ignore: cast_nullable_to_non_nullable
as double?,totalHours: freezed == totalHours ? _self.totalHours : totalHours // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimeEntryStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeEntry].
extension TimeEntryPatterns on TimeEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeEntry value)  $default,){
final _that = this;
switch (_that) {
case _TimeEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String workerId,  String clockInTime,  String? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  double? clockOutLatitude,  double? clockOutLongitude,  double? totalHours,  TimeEntryStatus status,  String? notes,  String createdAt,  String? propertyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
return $default(_that.id,_that.userId,_that.workerId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockOutLatitude,_that.clockOutLongitude,_that.totalHours,_that.status,_that.notes,_that.createdAt,_that.propertyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String workerId,  String clockInTime,  String? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  double? clockOutLatitude,  double? clockOutLongitude,  double? totalHours,  TimeEntryStatus status,  String? notes,  String createdAt,  String? propertyId)  $default,) {final _that = this;
switch (_that) {
case _TimeEntry():
return $default(_that.id,_that.userId,_that.workerId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockOutLatitude,_that.clockOutLongitude,_that.totalHours,_that.status,_that.notes,_that.createdAt,_that.propertyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String workerId,  String clockInTime,  String? clockOutTime,  double? clockInLatitude,  double? clockInLongitude,  double? clockOutLatitude,  double? clockOutLongitude,  double? totalHours,  TimeEntryStatus status,  String? notes,  String createdAt,  String? propertyId)?  $default,) {final _that = this;
switch (_that) {
case _TimeEntry() when $default != null:
return $default(_that.id,_that.userId,_that.workerId,_that.clockInTime,_that.clockOutTime,_that.clockInLatitude,_that.clockInLongitude,_that.clockOutLatitude,_that.clockOutLongitude,_that.totalHours,_that.status,_that.notes,_that.createdAt,_that.propertyId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeEntry implements TimeEntry {
  const _TimeEntry({required this.id, required this.userId, required this.workerId, required this.clockInTime, this.clockOutTime, this.clockInLatitude, this.clockInLongitude, this.clockOutLatitude, this.clockOutLongitude, this.totalHours, required this.status, this.notes, required this.createdAt, this.propertyId});
  factory _TimeEntry.fromJson(Map<String, dynamic> json) => _$TimeEntryFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String workerId;
@override final  String clockInTime;
@override final  String? clockOutTime;
@override final  double? clockInLatitude;
@override final  double? clockInLongitude;
@override final  double? clockOutLatitude;
@override final  double? clockOutLongitude;
@override final  double? totalHours;
@override final  TimeEntryStatus status;
@override final  String? notes;
@override final  String createdAt;
@override final  String? propertyId;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeEntryCopyWith<_TimeEntry> get copyWith => __$TimeEntryCopyWithImpl<_TimeEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.clockInTime, clockInTime) || other.clockInTime == clockInTime)&&(identical(other.clockOutTime, clockOutTime) || other.clockOutTime == clockOutTime)&&(identical(other.clockInLatitude, clockInLatitude) || other.clockInLatitude == clockInLatitude)&&(identical(other.clockInLongitude, clockInLongitude) || other.clockInLongitude == clockInLongitude)&&(identical(other.clockOutLatitude, clockOutLatitude) || other.clockOutLatitude == clockOutLatitude)&&(identical(other.clockOutLongitude, clockOutLongitude) || other.clockOutLongitude == clockOutLongitude)&&(identical(other.totalHours, totalHours) || other.totalHours == totalHours)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,workerId,clockInTime,clockOutTime,clockInLatitude,clockInLongitude,clockOutLatitude,clockOutLongitude,totalHours,status,notes,createdAt,propertyId);

@override
String toString() {
  return 'TimeEntry(id: $id, userId: $userId, workerId: $workerId, clockInTime: $clockInTime, clockOutTime: $clockOutTime, clockInLatitude: $clockInLatitude, clockInLongitude: $clockInLongitude, clockOutLatitude: $clockOutLatitude, clockOutLongitude: $clockOutLongitude, totalHours: $totalHours, status: $status, notes: $notes, createdAt: $createdAt, propertyId: $propertyId)';
}


}

/// @nodoc
abstract mixin class _$TimeEntryCopyWith<$Res> implements $TimeEntryCopyWith<$Res> {
  factory _$TimeEntryCopyWith(_TimeEntry value, $Res Function(_TimeEntry) _then) = __$TimeEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String workerId, String clockInTime, String? clockOutTime, double? clockInLatitude, double? clockInLongitude, double? clockOutLatitude, double? clockOutLongitude, double? totalHours, TimeEntryStatus status, String? notes, String createdAt, String? propertyId
});




}
/// @nodoc
class __$TimeEntryCopyWithImpl<$Res>
    implements _$TimeEntryCopyWith<$Res> {
  __$TimeEntryCopyWithImpl(this._self, this._then);

  final _TimeEntry _self;
  final $Res Function(_TimeEntry) _then;

/// Create a copy of TimeEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? workerId = null,Object? clockInTime = null,Object? clockOutTime = freezed,Object? clockInLatitude = freezed,Object? clockInLongitude = freezed,Object? clockOutLatitude = freezed,Object? clockOutLongitude = freezed,Object? totalHours = freezed,Object? status = null,Object? notes = freezed,Object? createdAt = null,Object? propertyId = freezed,}) {
  return _then(_TimeEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,clockInTime: null == clockInTime ? _self.clockInTime : clockInTime // ignore: cast_nullable_to_non_nullable
as String,clockOutTime: freezed == clockOutTime ? _self.clockOutTime : clockOutTime // ignore: cast_nullable_to_non_nullable
as String?,clockInLatitude: freezed == clockInLatitude ? _self.clockInLatitude : clockInLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockInLongitude: freezed == clockInLongitude ? _self.clockInLongitude : clockInLongitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLatitude: freezed == clockOutLatitude ? _self.clockOutLatitude : clockOutLatitude // ignore: cast_nullable_to_non_nullable
as double?,clockOutLongitude: freezed == clockOutLongitude ? _self.clockOutLongitude : clockOutLongitude // ignore: cast_nullable_to_non_nullable
as double?,totalHours: freezed == totalHours ? _self.totalHours : totalHours // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TimeEntryStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ClockInRequest {

 String get workerId; double get latitude; double get longitude; String? get notes;
/// Create a copy of ClockInRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClockInRequestCopyWith<ClockInRequest> get copyWith => _$ClockInRequestCopyWithImpl<ClockInRequest>(this as ClockInRequest, _$identity);

  /// Serializes this ClockInRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClockInRequest&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,latitude,longitude,notes);

@override
String toString() {
  return 'ClockInRequest(workerId: $workerId, latitude: $latitude, longitude: $longitude, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ClockInRequestCopyWith<$Res>  {
  factory $ClockInRequestCopyWith(ClockInRequest value, $Res Function(ClockInRequest) _then) = _$ClockInRequestCopyWithImpl;
@useResult
$Res call({
 String workerId, double latitude, double longitude, String? notes
});




}
/// @nodoc
class _$ClockInRequestCopyWithImpl<$Res>
    implements $ClockInRequestCopyWith<$Res> {
  _$ClockInRequestCopyWithImpl(this._self, this._then);

  final ClockInRequest _self;
  final $Res Function(ClockInRequest) _then;

/// Create a copy of ClockInRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workerId = null,Object? latitude = null,Object? longitude = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ClockInRequest].
extension ClockInRequestPatterns on ClockInRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClockInRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClockInRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClockInRequest value)  $default,){
final _that = this;
switch (_that) {
case _ClockInRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClockInRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ClockInRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workerId,  double latitude,  double longitude,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClockInRequest() when $default != null:
return $default(_that.workerId,_that.latitude,_that.longitude,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workerId,  double latitude,  double longitude,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ClockInRequest():
return $default(_that.workerId,_that.latitude,_that.longitude,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workerId,  double latitude,  double longitude,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ClockInRequest() when $default != null:
return $default(_that.workerId,_that.latitude,_that.longitude,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClockInRequest implements ClockInRequest {
  const _ClockInRequest({required this.workerId, required this.latitude, required this.longitude, this.notes});
  factory _ClockInRequest.fromJson(Map<String, dynamic> json) => _$ClockInRequestFromJson(json);

@override final  String workerId;
@override final  double latitude;
@override final  double longitude;
@override final  String? notes;

/// Create a copy of ClockInRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClockInRequestCopyWith<_ClockInRequest> get copyWith => __$ClockInRequestCopyWithImpl<_ClockInRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClockInRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClockInRequest&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,latitude,longitude,notes);

@override
String toString() {
  return 'ClockInRequest(workerId: $workerId, latitude: $latitude, longitude: $longitude, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ClockInRequestCopyWith<$Res> implements $ClockInRequestCopyWith<$Res> {
  factory _$ClockInRequestCopyWith(_ClockInRequest value, $Res Function(_ClockInRequest) _then) = __$ClockInRequestCopyWithImpl;
@override @useResult
$Res call({
 String workerId, double latitude, double longitude, String? notes
});




}
/// @nodoc
class __$ClockInRequestCopyWithImpl<$Res>
    implements _$ClockInRequestCopyWith<$Res> {
  __$ClockInRequestCopyWithImpl(this._self, this._then);

  final _ClockInRequest _self;
  final $Res Function(_ClockInRequest) _then;

/// Create a copy of ClockInRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workerId = null,Object? latitude = null,Object? longitude = null,Object? notes = freezed,}) {
  return _then(_ClockInRequest(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ClockOutRequest {

 String get timeEntryId; double get latitude; double get longitude; String? get notes;
/// Create a copy of ClockOutRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClockOutRequestCopyWith<ClockOutRequest> get copyWith => _$ClockOutRequestCopyWithImpl<ClockOutRequest>(this as ClockOutRequest, _$identity);

  /// Serializes this ClockOutRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClockOutRequest&&(identical(other.timeEntryId, timeEntryId) || other.timeEntryId == timeEntryId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeEntryId,latitude,longitude,notes);

@override
String toString() {
  return 'ClockOutRequest(timeEntryId: $timeEntryId, latitude: $latitude, longitude: $longitude, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ClockOutRequestCopyWith<$Res>  {
  factory $ClockOutRequestCopyWith(ClockOutRequest value, $Res Function(ClockOutRequest) _then) = _$ClockOutRequestCopyWithImpl;
@useResult
$Res call({
 String timeEntryId, double latitude, double longitude, String? notes
});




}
/// @nodoc
class _$ClockOutRequestCopyWithImpl<$Res>
    implements $ClockOutRequestCopyWith<$Res> {
  _$ClockOutRequestCopyWithImpl(this._self, this._then);

  final ClockOutRequest _self;
  final $Res Function(ClockOutRequest) _then;

/// Create a copy of ClockOutRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timeEntryId = null,Object? latitude = null,Object? longitude = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
timeEntryId: null == timeEntryId ? _self.timeEntryId : timeEntryId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ClockOutRequest].
extension ClockOutRequestPatterns on ClockOutRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClockOutRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClockOutRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClockOutRequest value)  $default,){
final _that = this;
switch (_that) {
case _ClockOutRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClockOutRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ClockOutRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String timeEntryId,  double latitude,  double longitude,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClockOutRequest() when $default != null:
return $default(_that.timeEntryId,_that.latitude,_that.longitude,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String timeEntryId,  double latitude,  double longitude,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ClockOutRequest():
return $default(_that.timeEntryId,_that.latitude,_that.longitude,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String timeEntryId,  double latitude,  double longitude,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ClockOutRequest() when $default != null:
return $default(_that.timeEntryId,_that.latitude,_that.longitude,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClockOutRequest implements ClockOutRequest {
  const _ClockOutRequest({required this.timeEntryId, required this.latitude, required this.longitude, this.notes});
  factory _ClockOutRequest.fromJson(Map<String, dynamic> json) => _$ClockOutRequestFromJson(json);

@override final  String timeEntryId;
@override final  double latitude;
@override final  double longitude;
@override final  String? notes;

/// Create a copy of ClockOutRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClockOutRequestCopyWith<_ClockOutRequest> get copyWith => __$ClockOutRequestCopyWithImpl<_ClockOutRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClockOutRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClockOutRequest&&(identical(other.timeEntryId, timeEntryId) || other.timeEntryId == timeEntryId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeEntryId,latitude,longitude,notes);

@override
String toString() {
  return 'ClockOutRequest(timeEntryId: $timeEntryId, latitude: $latitude, longitude: $longitude, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ClockOutRequestCopyWith<$Res> implements $ClockOutRequestCopyWith<$Res> {
  factory _$ClockOutRequestCopyWith(_ClockOutRequest value, $Res Function(_ClockOutRequest) _then) = __$ClockOutRequestCopyWithImpl;
@override @useResult
$Res call({
 String timeEntryId, double latitude, double longitude, String? notes
});




}
/// @nodoc
class __$ClockOutRequestCopyWithImpl<$Res>
    implements _$ClockOutRequestCopyWith<$Res> {
  __$ClockOutRequestCopyWithImpl(this._self, this._then);

  final _ClockOutRequest _self;
  final $Res Function(_ClockOutRequest) _then;

/// Create a copy of ClockOutRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timeEntryId = null,Object? latitude = null,Object? longitude = null,Object? notes = freezed,}) {
  return _then(_ClockOutRequest(
timeEntryId: null == timeEntryId ? _self.timeEntryId : timeEntryId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
