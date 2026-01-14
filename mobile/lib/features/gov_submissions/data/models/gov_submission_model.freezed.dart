// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gov_submission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GovSubmission {

 String get id; String get userId; String get payPeriodId; GovSubmissionType get type; GovSubmissionStatus get status; String? get filePath; String? get fileName; String? get referenceNumber; String? get notes; double? get totalAmount; int? get employeeCount; DateTime? get uploadedAt; DateTime? get confirmedAt; DateTime? get createdAt;
/// Create a copy of GovSubmission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GovSubmissionCopyWith<GovSubmission> get copyWith => _$GovSubmissionCopyWithImpl<GovSubmission>(this as GovSubmission, _$identity);

  /// Serializes this GovSubmission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GovSubmission&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.payPeriodId, payPeriodId) || other.payPeriodId == payPeriodId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.referenceNumber, referenceNumber) || other.referenceNumber == referenceNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.employeeCount, employeeCount) || other.employeeCount == employeeCount)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,payPeriodId,type,status,filePath,fileName,referenceNumber,notes,totalAmount,employeeCount,uploadedAt,confirmedAt,createdAt);

@override
String toString() {
  return 'GovSubmission(id: $id, userId: $userId, payPeriodId: $payPeriodId, type: $type, status: $status, filePath: $filePath, fileName: $fileName, referenceNumber: $referenceNumber, notes: $notes, totalAmount: $totalAmount, employeeCount: $employeeCount, uploadedAt: $uploadedAt, confirmedAt: $confirmedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GovSubmissionCopyWith<$Res>  {
  factory $GovSubmissionCopyWith(GovSubmission value, $Res Function(GovSubmission) _then) = _$GovSubmissionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String payPeriodId, GovSubmissionType type, GovSubmissionStatus status, String? filePath, String? fileName, String? referenceNumber, String? notes, double? totalAmount, int? employeeCount, DateTime? uploadedAt, DateTime? confirmedAt, DateTime? createdAt
});




}
/// @nodoc
class _$GovSubmissionCopyWithImpl<$Res>
    implements $GovSubmissionCopyWith<$Res> {
  _$GovSubmissionCopyWithImpl(this._self, this._then);

  final GovSubmission _self;
  final $Res Function(GovSubmission) _then;

/// Create a copy of GovSubmission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? payPeriodId = null,Object? type = null,Object? status = null,Object? filePath = freezed,Object? fileName = freezed,Object? referenceNumber = freezed,Object? notes = freezed,Object? totalAmount = freezed,Object? employeeCount = freezed,Object? uploadedAt = freezed,Object? confirmedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,payPeriodId: null == payPeriodId ? _self.payPeriodId : payPeriodId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GovSubmissionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GovSubmissionStatus,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,referenceNumber: freezed == referenceNumber ? _self.referenceNumber : referenceNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,employeeCount: freezed == employeeCount ? _self.employeeCount : employeeCount // ignore: cast_nullable_to_non_nullable
as int?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GovSubmission].
extension GovSubmissionPatterns on GovSubmission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GovSubmission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GovSubmission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GovSubmission value)  $default,){
final _that = this;
switch (_that) {
case _GovSubmission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GovSubmission value)?  $default,){
final _that = this;
switch (_that) {
case _GovSubmission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String payPeriodId,  GovSubmissionType type,  GovSubmissionStatus status,  String? filePath,  String? fileName,  String? referenceNumber,  String? notes,  double? totalAmount,  int? employeeCount,  DateTime? uploadedAt,  DateTime? confirmedAt,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GovSubmission() when $default != null:
return $default(_that.id,_that.userId,_that.payPeriodId,_that.type,_that.status,_that.filePath,_that.fileName,_that.referenceNumber,_that.notes,_that.totalAmount,_that.employeeCount,_that.uploadedAt,_that.confirmedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String payPeriodId,  GovSubmissionType type,  GovSubmissionStatus status,  String? filePath,  String? fileName,  String? referenceNumber,  String? notes,  double? totalAmount,  int? employeeCount,  DateTime? uploadedAt,  DateTime? confirmedAt,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _GovSubmission():
return $default(_that.id,_that.userId,_that.payPeriodId,_that.type,_that.status,_that.filePath,_that.fileName,_that.referenceNumber,_that.notes,_that.totalAmount,_that.employeeCount,_that.uploadedAt,_that.confirmedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String payPeriodId,  GovSubmissionType type,  GovSubmissionStatus status,  String? filePath,  String? fileName,  String? referenceNumber,  String? notes,  double? totalAmount,  int? employeeCount,  DateTime? uploadedAt,  DateTime? confirmedAt,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GovSubmission() when $default != null:
return $default(_that.id,_that.userId,_that.payPeriodId,_that.type,_that.status,_that.filePath,_that.fileName,_that.referenceNumber,_that.notes,_that.totalAmount,_that.employeeCount,_that.uploadedAt,_that.confirmedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GovSubmission implements GovSubmission {
  const _GovSubmission({required this.id, required this.userId, required this.payPeriodId, required this.type, required this.status, this.filePath, this.fileName, this.referenceNumber, this.notes, this.totalAmount, this.employeeCount, this.uploadedAt, this.confirmedAt, this.createdAt});
  factory _GovSubmission.fromJson(Map<String, dynamic> json) => _$GovSubmissionFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String payPeriodId;
@override final  GovSubmissionType type;
@override final  GovSubmissionStatus status;
@override final  String? filePath;
@override final  String? fileName;
@override final  String? referenceNumber;
@override final  String? notes;
@override final  double? totalAmount;
@override final  int? employeeCount;
@override final  DateTime? uploadedAt;
@override final  DateTime? confirmedAt;
@override final  DateTime? createdAt;

/// Create a copy of GovSubmission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GovSubmissionCopyWith<_GovSubmission> get copyWith => __$GovSubmissionCopyWithImpl<_GovSubmission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GovSubmissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GovSubmission&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.payPeriodId, payPeriodId) || other.payPeriodId == payPeriodId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.referenceNumber, referenceNumber) || other.referenceNumber == referenceNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.employeeCount, employeeCount) || other.employeeCount == employeeCount)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,payPeriodId,type,status,filePath,fileName,referenceNumber,notes,totalAmount,employeeCount,uploadedAt,confirmedAt,createdAt);

@override
String toString() {
  return 'GovSubmission(id: $id, userId: $userId, payPeriodId: $payPeriodId, type: $type, status: $status, filePath: $filePath, fileName: $fileName, referenceNumber: $referenceNumber, notes: $notes, totalAmount: $totalAmount, employeeCount: $employeeCount, uploadedAt: $uploadedAt, confirmedAt: $confirmedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GovSubmissionCopyWith<$Res> implements $GovSubmissionCopyWith<$Res> {
  factory _$GovSubmissionCopyWith(_GovSubmission value, $Res Function(_GovSubmission) _then) = __$GovSubmissionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String payPeriodId, GovSubmissionType type, GovSubmissionStatus status, String? filePath, String? fileName, String? referenceNumber, String? notes, double? totalAmount, int? employeeCount, DateTime? uploadedAt, DateTime? confirmedAt, DateTime? createdAt
});




}
/// @nodoc
class __$GovSubmissionCopyWithImpl<$Res>
    implements _$GovSubmissionCopyWith<$Res> {
  __$GovSubmissionCopyWithImpl(this._self, this._then);

  final _GovSubmission _self;
  final $Res Function(_GovSubmission) _then;

/// Create a copy of GovSubmission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? payPeriodId = null,Object? type = null,Object? status = null,Object? filePath = freezed,Object? fileName = freezed,Object? referenceNumber = freezed,Object? notes = freezed,Object? totalAmount = freezed,Object? employeeCount = freezed,Object? uploadedAt = freezed,Object? confirmedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_GovSubmission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,payPeriodId: null == payPeriodId ? _self.payPeriodId : payPeriodId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GovSubmissionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GovSubmissionStatus,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,referenceNumber: freezed == referenceNumber ? _self.referenceNumber : referenceNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,employeeCount: freezed == employeeCount ? _self.employeeCount : employeeCount // ignore: cast_nullable_to_non_nullable
as int?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
