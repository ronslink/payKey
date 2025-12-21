// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeaveRequestModel {

 String get id; String get workerId; String get workerName; String get requestedById; String get leaveType; String get startDate; String get endDate; int get totalDays; String get reason; String get status;// PENDING, APPROVED, REJECTED, CANCELLED
 String get createdAt; String get updatedAt; String? get approvedById; String? get approvedAt; String? get rejectionReason; double? get dailyPayRate; bool get paidLeave; String? get emergencyContact; String? get emergencyPhone;
/// Create a copy of LeaveRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaveRequestModelCopyWith<LeaveRequestModel> get copyWith => _$LeaveRequestModelCopyWithImpl<LeaveRequestModel>(this as LeaveRequestModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaveRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.requestedById, requestedById) || other.requestedById == requestedById)&&(identical(other.leaveType, leaveType) || other.leaveType == leaveType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.totalDays, totalDays) || other.totalDays == totalDays)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.dailyPayRate, dailyPayRate) || other.dailyPayRate == dailyPayRate)&&(identical(other.paidLeave, paidLeave) || other.paidLeave == paidLeave)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.emergencyPhone, emergencyPhone) || other.emergencyPhone == emergencyPhone));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,workerId,workerName,requestedById,leaveType,startDate,endDate,totalDays,reason,status,createdAt,updatedAt,approvedById,approvedAt,rejectionReason,dailyPayRate,paidLeave,emergencyContact,emergencyPhone]);

@override
String toString() {
  return 'LeaveRequestModel(id: $id, workerId: $workerId, workerName: $workerName, requestedById: $requestedById, leaveType: $leaveType, startDate: $startDate, endDate: $endDate, totalDays: $totalDays, reason: $reason, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, approvedById: $approvedById, approvedAt: $approvedAt, rejectionReason: $rejectionReason, dailyPayRate: $dailyPayRate, paidLeave: $paidLeave, emergencyContact: $emergencyContact, emergencyPhone: $emergencyPhone)';
}


}

/// @nodoc
abstract mixin class $LeaveRequestModelCopyWith<$Res>  {
  factory $LeaveRequestModelCopyWith(LeaveRequestModel value, $Res Function(LeaveRequestModel) _then) = _$LeaveRequestModelCopyWithImpl;
@useResult
$Res call({
 String id, String workerId, String workerName, String requestedById, String leaveType, String startDate, String endDate, int totalDays, String reason, String status, String createdAt, String updatedAt, String? approvedById, String? approvedAt, String? rejectionReason, double? dailyPayRate, bool paidLeave, String? emergencyContact, String? emergencyPhone
});




}
/// @nodoc
class _$LeaveRequestModelCopyWithImpl<$Res>
    implements $LeaveRequestModelCopyWith<$Res> {
  _$LeaveRequestModelCopyWithImpl(this._self, this._then);

  final LeaveRequestModel _self;
  final $Res Function(LeaveRequestModel) _then;

/// Create a copy of LeaveRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workerId = null,Object? workerName = null,Object? requestedById = null,Object? leaveType = null,Object? startDate = null,Object? endDate = null,Object? totalDays = null,Object? reason = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? dailyPayRate = freezed,Object? paidLeave = null,Object? emergencyContact = freezed,Object? emergencyPhone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,requestedById: null == requestedById ? _self.requestedById : requestedById // ignore: cast_nullable_to_non_nullable
as String,leaveType: null == leaveType ? _self.leaveType : leaveType // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,dailyPayRate: freezed == dailyPayRate ? _self.dailyPayRate : dailyPayRate // ignore: cast_nullable_to_non_nullable
as double?,paidLeave: null == paidLeave ? _self.paidLeave : paidLeave // ignore: cast_nullable_to_non_nullable
as bool,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,emergencyPhone: freezed == emergencyPhone ? _self.emergencyPhone : emergencyPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaveRequestModel].
extension LeaveRequestModelPatterns on LeaveRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaveRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaveRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaveRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _LeaveRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaveRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _LeaveRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workerId,  String workerName,  String requestedById,  String leaveType,  String startDate,  String endDate,  int totalDays,  String reason,  String status,  String createdAt,  String updatedAt,  String? approvedById,  String? approvedAt,  String? rejectionReason,  double? dailyPayRate,  bool paidLeave,  String? emergencyContact,  String? emergencyPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaveRequestModel() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.requestedById,_that.leaveType,_that.startDate,_that.endDate,_that.totalDays,_that.reason,_that.status,_that.createdAt,_that.updatedAt,_that.approvedById,_that.approvedAt,_that.rejectionReason,_that.dailyPayRate,_that.paidLeave,_that.emergencyContact,_that.emergencyPhone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workerId,  String workerName,  String requestedById,  String leaveType,  String startDate,  String endDate,  int totalDays,  String reason,  String status,  String createdAt,  String updatedAt,  String? approvedById,  String? approvedAt,  String? rejectionReason,  double? dailyPayRate,  bool paidLeave,  String? emergencyContact,  String? emergencyPhone)  $default,) {final _that = this;
switch (_that) {
case _LeaveRequestModel():
return $default(_that.id,_that.workerId,_that.workerName,_that.requestedById,_that.leaveType,_that.startDate,_that.endDate,_that.totalDays,_that.reason,_that.status,_that.createdAt,_that.updatedAt,_that.approvedById,_that.approvedAt,_that.rejectionReason,_that.dailyPayRate,_that.paidLeave,_that.emergencyContact,_that.emergencyPhone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workerId,  String workerName,  String requestedById,  String leaveType,  String startDate,  String endDate,  int totalDays,  String reason,  String status,  String createdAt,  String updatedAt,  String? approvedById,  String? approvedAt,  String? rejectionReason,  double? dailyPayRate,  bool paidLeave,  String? emergencyContact,  String? emergencyPhone)?  $default,) {final _that = this;
switch (_that) {
case _LeaveRequestModel() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.requestedById,_that.leaveType,_that.startDate,_that.endDate,_that.totalDays,_that.reason,_that.status,_that.createdAt,_that.updatedAt,_that.approvedById,_that.approvedAt,_that.rejectionReason,_that.dailyPayRate,_that.paidLeave,_that.emergencyContact,_that.emergencyPhone);case _:
  return null;

}
}

}

/// @nodoc


class _LeaveRequestModel extends LeaveRequestModel {
  const _LeaveRequestModel({required this.id, required this.workerId, required this.workerName, required this.requestedById, required this.leaveType, required this.startDate, required this.endDate, required this.totalDays, required this.reason, required this.status, required this.createdAt, required this.updatedAt, this.approvedById, this.approvedAt, this.rejectionReason, this.dailyPayRate, required this.paidLeave, this.emergencyContact, this.emergencyPhone}): super._();
  

@override final  String id;
@override final  String workerId;
@override final  String workerName;
@override final  String requestedById;
@override final  String leaveType;
@override final  String startDate;
@override final  String endDate;
@override final  int totalDays;
@override final  String reason;
@override final  String status;
// PENDING, APPROVED, REJECTED, CANCELLED
@override final  String createdAt;
@override final  String updatedAt;
@override final  String? approvedById;
@override final  String? approvedAt;
@override final  String? rejectionReason;
@override final  double? dailyPayRate;
@override final  bool paidLeave;
@override final  String? emergencyContact;
@override final  String? emergencyPhone;

/// Create a copy of LeaveRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaveRequestModelCopyWith<_LeaveRequestModel> get copyWith => __$LeaveRequestModelCopyWithImpl<_LeaveRequestModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaveRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.requestedById, requestedById) || other.requestedById == requestedById)&&(identical(other.leaveType, leaveType) || other.leaveType == leaveType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.totalDays, totalDays) || other.totalDays == totalDays)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.approvedById, approvedById) || other.approvedById == approvedById)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.dailyPayRate, dailyPayRate) || other.dailyPayRate == dailyPayRate)&&(identical(other.paidLeave, paidLeave) || other.paidLeave == paidLeave)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.emergencyPhone, emergencyPhone) || other.emergencyPhone == emergencyPhone));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,workerId,workerName,requestedById,leaveType,startDate,endDate,totalDays,reason,status,createdAt,updatedAt,approvedById,approvedAt,rejectionReason,dailyPayRate,paidLeave,emergencyContact,emergencyPhone]);

@override
String toString() {
  return 'LeaveRequestModel(id: $id, workerId: $workerId, workerName: $workerName, requestedById: $requestedById, leaveType: $leaveType, startDate: $startDate, endDate: $endDate, totalDays: $totalDays, reason: $reason, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, approvedById: $approvedById, approvedAt: $approvedAt, rejectionReason: $rejectionReason, dailyPayRate: $dailyPayRate, paidLeave: $paidLeave, emergencyContact: $emergencyContact, emergencyPhone: $emergencyPhone)';
}


}

/// @nodoc
abstract mixin class _$LeaveRequestModelCopyWith<$Res> implements $LeaveRequestModelCopyWith<$Res> {
  factory _$LeaveRequestModelCopyWith(_LeaveRequestModel value, $Res Function(_LeaveRequestModel) _then) = __$LeaveRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String workerId, String workerName, String requestedById, String leaveType, String startDate, String endDate, int totalDays, String reason, String status, String createdAt, String updatedAt, String? approvedById, String? approvedAt, String? rejectionReason, double? dailyPayRate, bool paidLeave, String? emergencyContact, String? emergencyPhone
});




}
/// @nodoc
class __$LeaveRequestModelCopyWithImpl<$Res>
    implements _$LeaveRequestModelCopyWith<$Res> {
  __$LeaveRequestModelCopyWithImpl(this._self, this._then);

  final _LeaveRequestModel _self;
  final $Res Function(_LeaveRequestModel) _then;

/// Create a copy of LeaveRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workerId = null,Object? workerName = null,Object? requestedById = null,Object? leaveType = null,Object? startDate = null,Object? endDate = null,Object? totalDays = null,Object? reason = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? approvedById = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? dailyPayRate = freezed,Object? paidLeave = null,Object? emergencyContact = freezed,Object? emergencyPhone = freezed,}) {
  return _then(_LeaveRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,requestedById: null == requestedById ? _self.requestedById : requestedById // ignore: cast_nullable_to_non_nullable
as String,leaveType: null == leaveType ? _self.leaveType : leaveType // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,approvedById: freezed == approvedById ? _self.approvedById : approvedById // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,dailyPayRate: freezed == dailyPayRate ? _self.dailyPayRate : dailyPayRate // ignore: cast_nullable_to_non_nullable
as double?,paidLeave: null == paidLeave ? _self.paidLeave : paidLeave // ignore: cast_nullable_to_non_nullable
as bool,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,emergencyPhone: freezed == emergencyPhone ? _self.emergencyPhone : emergencyPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LeaveBalanceModel {

 String get workerId; String get workerName; int get year; int get totalAnnualLeaves; int get usedAnnualLeaves; int get remainingAnnualLeaves; int get sickLeaves; int get pendingLeaves;
/// Create a copy of LeaveBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaveBalanceModelCopyWith<LeaveBalanceModel> get copyWith => _$LeaveBalanceModelCopyWithImpl<LeaveBalanceModel>(this as LeaveBalanceModel, _$identity);

  /// Serializes this LeaveBalanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaveBalanceModel&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.year, year) || other.year == year)&&(identical(other.totalAnnualLeaves, totalAnnualLeaves) || other.totalAnnualLeaves == totalAnnualLeaves)&&(identical(other.usedAnnualLeaves, usedAnnualLeaves) || other.usedAnnualLeaves == usedAnnualLeaves)&&(identical(other.remainingAnnualLeaves, remainingAnnualLeaves) || other.remainingAnnualLeaves == remainingAnnualLeaves)&&(identical(other.sickLeaves, sickLeaves) || other.sickLeaves == sickLeaves)&&(identical(other.pendingLeaves, pendingLeaves) || other.pendingLeaves == pendingLeaves));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,workerName,year,totalAnnualLeaves,usedAnnualLeaves,remainingAnnualLeaves,sickLeaves,pendingLeaves);

@override
String toString() {
  return 'LeaveBalanceModel(workerId: $workerId, workerName: $workerName, year: $year, totalAnnualLeaves: $totalAnnualLeaves, usedAnnualLeaves: $usedAnnualLeaves, remainingAnnualLeaves: $remainingAnnualLeaves, sickLeaves: $sickLeaves, pendingLeaves: $pendingLeaves)';
}


}

/// @nodoc
abstract mixin class $LeaveBalanceModelCopyWith<$Res>  {
  factory $LeaveBalanceModelCopyWith(LeaveBalanceModel value, $Res Function(LeaveBalanceModel) _then) = _$LeaveBalanceModelCopyWithImpl;
@useResult
$Res call({
 String workerId, String workerName, int year, int totalAnnualLeaves, int usedAnnualLeaves, int remainingAnnualLeaves, int sickLeaves, int pendingLeaves
});




}
/// @nodoc
class _$LeaveBalanceModelCopyWithImpl<$Res>
    implements $LeaveBalanceModelCopyWith<$Res> {
  _$LeaveBalanceModelCopyWithImpl(this._self, this._then);

  final LeaveBalanceModel _self;
  final $Res Function(LeaveBalanceModel) _then;

/// Create a copy of LeaveBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workerId = null,Object? workerName = null,Object? year = null,Object? totalAnnualLeaves = null,Object? usedAnnualLeaves = null,Object? remainingAnnualLeaves = null,Object? sickLeaves = null,Object? pendingLeaves = null,}) {
  return _then(_self.copyWith(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,totalAnnualLeaves: null == totalAnnualLeaves ? _self.totalAnnualLeaves : totalAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,usedAnnualLeaves: null == usedAnnualLeaves ? _self.usedAnnualLeaves : usedAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,remainingAnnualLeaves: null == remainingAnnualLeaves ? _self.remainingAnnualLeaves : remainingAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,sickLeaves: null == sickLeaves ? _self.sickLeaves : sickLeaves // ignore: cast_nullable_to_non_nullable
as int,pendingLeaves: null == pendingLeaves ? _self.pendingLeaves : pendingLeaves // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaveBalanceModel].
extension LeaveBalanceModelPatterns on LeaveBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaveBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaveBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaveBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _LeaveBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaveBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _LeaveBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workerId,  String workerName,  int year,  int totalAnnualLeaves,  int usedAnnualLeaves,  int remainingAnnualLeaves,  int sickLeaves,  int pendingLeaves)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaveBalanceModel() when $default != null:
return $default(_that.workerId,_that.workerName,_that.year,_that.totalAnnualLeaves,_that.usedAnnualLeaves,_that.remainingAnnualLeaves,_that.sickLeaves,_that.pendingLeaves);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workerId,  String workerName,  int year,  int totalAnnualLeaves,  int usedAnnualLeaves,  int remainingAnnualLeaves,  int sickLeaves,  int pendingLeaves)  $default,) {final _that = this;
switch (_that) {
case _LeaveBalanceModel():
return $default(_that.workerId,_that.workerName,_that.year,_that.totalAnnualLeaves,_that.usedAnnualLeaves,_that.remainingAnnualLeaves,_that.sickLeaves,_that.pendingLeaves);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workerId,  String workerName,  int year,  int totalAnnualLeaves,  int usedAnnualLeaves,  int remainingAnnualLeaves,  int sickLeaves,  int pendingLeaves)?  $default,) {final _that = this;
switch (_that) {
case _LeaveBalanceModel() when $default != null:
return $default(_that.workerId,_that.workerName,_that.year,_that.totalAnnualLeaves,_that.usedAnnualLeaves,_that.remainingAnnualLeaves,_that.sickLeaves,_that.pendingLeaves);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeaveBalanceModel implements LeaveBalanceModel {
  const _LeaveBalanceModel({required this.workerId, required this.workerName, required this.year, required this.totalAnnualLeaves, required this.usedAnnualLeaves, required this.remainingAnnualLeaves, required this.sickLeaves, required this.pendingLeaves});
  factory _LeaveBalanceModel.fromJson(Map<String, dynamic> json) => _$LeaveBalanceModelFromJson(json);

@override final  String workerId;
@override final  String workerName;
@override final  int year;
@override final  int totalAnnualLeaves;
@override final  int usedAnnualLeaves;
@override final  int remainingAnnualLeaves;
@override final  int sickLeaves;
@override final  int pendingLeaves;

/// Create a copy of LeaveBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaveBalanceModelCopyWith<_LeaveBalanceModel> get copyWith => __$LeaveBalanceModelCopyWithImpl<_LeaveBalanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeaveBalanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaveBalanceModel&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.year, year) || other.year == year)&&(identical(other.totalAnnualLeaves, totalAnnualLeaves) || other.totalAnnualLeaves == totalAnnualLeaves)&&(identical(other.usedAnnualLeaves, usedAnnualLeaves) || other.usedAnnualLeaves == usedAnnualLeaves)&&(identical(other.remainingAnnualLeaves, remainingAnnualLeaves) || other.remainingAnnualLeaves == remainingAnnualLeaves)&&(identical(other.sickLeaves, sickLeaves) || other.sickLeaves == sickLeaves)&&(identical(other.pendingLeaves, pendingLeaves) || other.pendingLeaves == pendingLeaves));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,workerName,year,totalAnnualLeaves,usedAnnualLeaves,remainingAnnualLeaves,sickLeaves,pendingLeaves);

@override
String toString() {
  return 'LeaveBalanceModel(workerId: $workerId, workerName: $workerName, year: $year, totalAnnualLeaves: $totalAnnualLeaves, usedAnnualLeaves: $usedAnnualLeaves, remainingAnnualLeaves: $remainingAnnualLeaves, sickLeaves: $sickLeaves, pendingLeaves: $pendingLeaves)';
}


}

/// @nodoc
abstract mixin class _$LeaveBalanceModelCopyWith<$Res> implements $LeaveBalanceModelCopyWith<$Res> {
  factory _$LeaveBalanceModelCopyWith(_LeaveBalanceModel value, $Res Function(_LeaveBalanceModel) _then) = __$LeaveBalanceModelCopyWithImpl;
@override @useResult
$Res call({
 String workerId, String workerName, int year, int totalAnnualLeaves, int usedAnnualLeaves, int remainingAnnualLeaves, int sickLeaves, int pendingLeaves
});




}
/// @nodoc
class __$LeaveBalanceModelCopyWithImpl<$Res>
    implements _$LeaveBalanceModelCopyWith<$Res> {
  __$LeaveBalanceModelCopyWithImpl(this._self, this._then);

  final _LeaveBalanceModel _self;
  final $Res Function(_LeaveBalanceModel) _then;

/// Create a copy of LeaveBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workerId = null,Object? workerName = null,Object? year = null,Object? totalAnnualLeaves = null,Object? usedAnnualLeaves = null,Object? remainingAnnualLeaves = null,Object? sickLeaves = null,Object? pendingLeaves = null,}) {
  return _then(_LeaveBalanceModel(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,totalAnnualLeaves: null == totalAnnualLeaves ? _self.totalAnnualLeaves : totalAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,usedAnnualLeaves: null == usedAnnualLeaves ? _self.usedAnnualLeaves : usedAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,remainingAnnualLeaves: null == remainingAnnualLeaves ? _self.remainingAnnualLeaves : remainingAnnualLeaves // ignore: cast_nullable_to_non_nullable
as int,sickLeaves: null == sickLeaves ? _self.sickLeaves : sickLeaves // ignore: cast_nullable_to_non_nullable
as int,pendingLeaves: null == pendingLeaves ? _self.pendingLeaves : pendingLeaves // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
