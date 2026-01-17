// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkerModel {

 String get id; String get name; String get phoneNumber; double get salaryGross; DateTime? get startDate; DateTime? get dateOfBirth; bool get isActive; String get employmentType; double? get hourlyRate; String? get propertyId; String? get photoUrl; String? get email; String? get idNumber; String? get kraPin; String? get nssfNumber; String? get nhifNumber; String? get jobTitle; double get housingAllowance; double get transportAllowance; String get paymentFrequency; String get paymentMethod; String? get mpesaNumber; String? get bankName; String? get bankCode; String? get bankAccount; String? get notes; String? get emergencyContactName; String? get emergencyContactPhone; String? get emergencyContactRelationship; DateTime? get terminatedAt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of WorkerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerModelCopyWith<WorkerModel> get copyWith => _$WorkerModelCopyWithImpl<WorkerModel>(this as WorkerModel, _$identity);

  /// Serializes this WorkerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship)&&(identical(other.terminatedAt, terminatedAt) || other.terminatedAt == terminatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,phoneNumber,salaryGross,startDate,dateOfBirth,isActive,employmentType,hourlyRate,propertyId,photoUrl,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship,terminatedAt,createdAt,updatedAt]);

@override
String toString() {
  return 'WorkerModel(id: $id, name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, isActive: $isActive, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship, terminatedAt: $terminatedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkerModelCopyWith<$Res>  {
  factory $WorkerModelCopyWith(WorkerModel value, $Res Function(WorkerModel) _then) = _$WorkerModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String phoneNumber, double salaryGross, DateTime? startDate, DateTime? dateOfBirth, bool isActive, String employmentType, double? hourlyRate, String? propertyId, String? photoUrl, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double housingAllowance, double transportAllowance, String paymentFrequency, String paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship, DateTime? terminatedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WorkerModelCopyWithImpl<$Res>
    implements $WorkerModelCopyWith<$Res> {
  _$WorkerModelCopyWithImpl(this._self, this._then);

  final WorkerModel _self;
  final $Res Function(WorkerModel) _then;

/// Create a copy of WorkerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phoneNumber = null,Object? salaryGross = null,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? isActive = null,Object? employmentType = null,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = null,Object? transportAllowance = null,Object? paymentFrequency = null,Object? paymentMethod = null,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,Object? terminatedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,salaryGross: null == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: null == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double,transportAllowance: null == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double,paymentFrequency: null == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,terminatedAt: freezed == terminatedAt ? _self.terminatedAt : terminatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerModel].
extension WorkerModelPatterns on WorkerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerModel value)  $default,){
final _that = this;
switch (_that) {
case _WorkerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerModel value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  bool isActive,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double housingAllowance,  double transportAllowance,  String paymentFrequency,  String paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship,  DateTime? terminatedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerModel() when $default != null:
return $default(_that.id,_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.isActive,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship,_that.terminatedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  bool isActive,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double housingAllowance,  double transportAllowance,  String paymentFrequency,  String paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship,  DateTime? terminatedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkerModel():
return $default(_that.id,_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.isActive,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship,_that.terminatedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  bool isActive,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double housingAllowance,  double transportAllowance,  String paymentFrequency,  String paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship,  DateTime? terminatedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkerModel() when $default != null:
return $default(_that.id,_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.isActive,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship,_that.terminatedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkerModel implements WorkerModel {
  const _WorkerModel({required this.id, required this.name, required this.phoneNumber, required this.salaryGross, this.startDate, this.dateOfBirth, required this.isActive, this.employmentType = 'FIXED', this.hourlyRate, this.propertyId, this.photoUrl, this.email, this.idNumber, this.kraPin, this.nssfNumber, this.nhifNumber, this.jobTitle, this.housingAllowance = 0.0, this.transportAllowance = 0.0, this.paymentFrequency = 'MONTHLY', this.paymentMethod = 'MPESA', this.mpesaNumber, this.bankName, this.bankCode, this.bankAccount, this.notes, this.emergencyContactName, this.emergencyContactPhone, this.emergencyContactRelationship, this.terminatedAt, this.createdAt, this.updatedAt});
  factory _WorkerModel.fromJson(Map<String, dynamic> json) => _$WorkerModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String phoneNumber;
@override final  double salaryGross;
@override final  DateTime? startDate;
@override final  DateTime? dateOfBirth;
@override final  bool isActive;
@override@JsonKey() final  String employmentType;
@override final  double? hourlyRate;
@override final  String? propertyId;
@override final  String? photoUrl;
@override final  String? email;
@override final  String? idNumber;
@override final  String? kraPin;
@override final  String? nssfNumber;
@override final  String? nhifNumber;
@override final  String? jobTitle;
@override@JsonKey() final  double housingAllowance;
@override@JsonKey() final  double transportAllowance;
@override@JsonKey() final  String paymentFrequency;
@override@JsonKey() final  String paymentMethod;
@override final  String? mpesaNumber;
@override final  String? bankName;
@override final  String? bankCode;
@override final  String? bankAccount;
@override final  String? notes;
@override final  String? emergencyContactName;
@override final  String? emergencyContactPhone;
@override final  String? emergencyContactRelationship;
@override final  DateTime? terminatedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of WorkerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerModelCopyWith<_WorkerModel> get copyWith => __$WorkerModelCopyWithImpl<_WorkerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship)&&(identical(other.terminatedAt, terminatedAt) || other.terminatedAt == terminatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,phoneNumber,salaryGross,startDate,dateOfBirth,isActive,employmentType,hourlyRate,propertyId,photoUrl,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship,terminatedAt,createdAt,updatedAt]);

@override
String toString() {
  return 'WorkerModel(id: $id, name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, isActive: $isActive, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship, terminatedAt: $terminatedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkerModelCopyWith<$Res> implements $WorkerModelCopyWith<$Res> {
  factory _$WorkerModelCopyWith(_WorkerModel value, $Res Function(_WorkerModel) _then) = __$WorkerModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String phoneNumber, double salaryGross, DateTime? startDate, DateTime? dateOfBirth, bool isActive, String employmentType, double? hourlyRate, String? propertyId, String? photoUrl, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double housingAllowance, double transportAllowance, String paymentFrequency, String paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship, DateTime? terminatedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WorkerModelCopyWithImpl<$Res>
    implements _$WorkerModelCopyWith<$Res> {
  __$WorkerModelCopyWithImpl(this._self, this._then);

  final _WorkerModel _self;
  final $Res Function(_WorkerModel) _then;

/// Create a copy of WorkerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phoneNumber = null,Object? salaryGross = null,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? isActive = null,Object? employmentType = null,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = null,Object? transportAllowance = null,Object? paymentFrequency = null,Object? paymentMethod = null,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,Object? terminatedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WorkerModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,salaryGross: null == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: null == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double,transportAllowance: null == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double,paymentFrequency: null == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,terminatedAt: freezed == terminatedAt ? _self.terminatedAt : terminatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreateWorkerRequest {

 String get name; String get phoneNumber; double get salaryGross; DateTime? get startDate; DateTime? get dateOfBirth; String get employmentType; double? get hourlyRate; String? get propertyId; String? get photoUrl; String? get email; String? get idNumber; String? get kraPin; String? get nssfNumber; String? get nhifNumber; String? get jobTitle; double? get housingAllowance; double? get transportAllowance; String? get paymentFrequency; String? get paymentMethod; String? get mpesaNumber; String? get bankName; String? get bankCode; String? get bankAccount; String? get notes; String? get emergencyContactName; String? get emergencyContactPhone; String? get emergencyContactRelationship;
/// Create a copy of CreateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateWorkerRequestCopyWith<CreateWorkerRequest> get copyWith => _$CreateWorkerRequestCopyWithImpl<CreateWorkerRequest>(this as CreateWorkerRequest, _$identity);

  /// Serializes this CreateWorkerRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateWorkerRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,phoneNumber,salaryGross,startDate,dateOfBirth,employmentType,hourlyRate,propertyId,photoUrl,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship]);

@override
String toString() {
  return 'CreateWorkerRequest(name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship)';
}


}

/// @nodoc
abstract mixin class $CreateWorkerRequestCopyWith<$Res>  {
  factory $CreateWorkerRequestCopyWith(CreateWorkerRequest value, $Res Function(CreateWorkerRequest) _then) = _$CreateWorkerRequestCopyWithImpl;
@useResult
$Res call({
 String name, String phoneNumber, double salaryGross, DateTime? startDate, DateTime? dateOfBirth, String employmentType, double? hourlyRate, String? propertyId, String? photoUrl, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double? housingAllowance, double? transportAllowance, String? paymentFrequency, String? paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship
});




}
/// @nodoc
class _$CreateWorkerRequestCopyWithImpl<$Res>
    implements $CreateWorkerRequestCopyWith<$Res> {
  _$CreateWorkerRequestCopyWithImpl(this._self, this._then);

  final CreateWorkerRequest _self;
  final $Res Function(CreateWorkerRequest) _then;

/// Create a copy of CreateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phoneNumber = null,Object? salaryGross = null,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? employmentType = null,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = freezed,Object? transportAllowance = freezed,Object? paymentFrequency = freezed,Object? paymentMethod = freezed,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,salaryGross: null == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: freezed == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double?,transportAllowance: freezed == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double?,paymentFrequency: freezed == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateWorkerRequest].
extension CreateWorkerRequestPatterns on CreateWorkerRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateWorkerRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateWorkerRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateWorkerRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateWorkerRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateWorkerRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateWorkerRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateWorkerRequest() when $default != null:
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)  $default,) {final _that = this;
switch (_that) {
case _CreateWorkerRequest():
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phoneNumber,  double salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)?  $default,) {final _that = this;
switch (_that) {
case _CreateWorkerRequest() when $default != null:
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateWorkerRequest implements CreateWorkerRequest {
  const _CreateWorkerRequest({required this.name, required this.phoneNumber, required this.salaryGross, this.startDate, this.dateOfBirth, this.employmentType = 'FIXED', this.hourlyRate, this.propertyId, this.photoUrl, this.email, this.idNumber, this.kraPin, this.nssfNumber, this.nhifNumber, this.jobTitle, this.housingAllowance, this.transportAllowance, this.paymentFrequency, this.paymentMethod, this.mpesaNumber, this.bankName, this.bankCode, this.bankAccount, this.notes, this.emergencyContactName, this.emergencyContactPhone, this.emergencyContactRelationship});
  factory _CreateWorkerRequest.fromJson(Map<String, dynamic> json) => _$CreateWorkerRequestFromJson(json);

@override final  String name;
@override final  String phoneNumber;
@override final  double salaryGross;
@override final  DateTime? startDate;
@override final  DateTime? dateOfBirth;
@override@JsonKey() final  String employmentType;
@override final  double? hourlyRate;
@override final  String? propertyId;
@override final  String? photoUrl;
@override final  String? email;
@override final  String? idNumber;
@override final  String? kraPin;
@override final  String? nssfNumber;
@override final  String? nhifNumber;
@override final  String? jobTitle;
@override final  double? housingAllowance;
@override final  double? transportAllowance;
@override final  String? paymentFrequency;
@override final  String? paymentMethod;
@override final  String? mpesaNumber;
@override final  String? bankName;
@override final  String? bankCode;
@override final  String? bankAccount;
@override final  String? notes;
@override final  String? emergencyContactName;
@override final  String? emergencyContactPhone;
@override final  String? emergencyContactRelationship;

/// Create a copy of CreateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateWorkerRequestCopyWith<_CreateWorkerRequest> get copyWith => __$CreateWorkerRequestCopyWithImpl<_CreateWorkerRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateWorkerRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateWorkerRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,phoneNumber,salaryGross,startDate,dateOfBirth,employmentType,hourlyRate,propertyId,photoUrl,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship]);

@override
String toString() {
  return 'CreateWorkerRequest(name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship)';
}


}

/// @nodoc
abstract mixin class _$CreateWorkerRequestCopyWith<$Res> implements $CreateWorkerRequestCopyWith<$Res> {
  factory _$CreateWorkerRequestCopyWith(_CreateWorkerRequest value, $Res Function(_CreateWorkerRequest) _then) = __$CreateWorkerRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String phoneNumber, double salaryGross, DateTime? startDate, DateTime? dateOfBirth, String employmentType, double? hourlyRate, String? propertyId, String? photoUrl, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double? housingAllowance, double? transportAllowance, String? paymentFrequency, String? paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship
});




}
/// @nodoc
class __$CreateWorkerRequestCopyWithImpl<$Res>
    implements _$CreateWorkerRequestCopyWith<$Res> {
  __$CreateWorkerRequestCopyWithImpl(this._self, this._then);

  final _CreateWorkerRequest _self;
  final $Res Function(_CreateWorkerRequest) _then;

/// Create a copy of CreateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phoneNumber = null,Object? salaryGross = null,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? employmentType = null,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = freezed,Object? transportAllowance = freezed,Object? paymentFrequency = freezed,Object? paymentMethod = freezed,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,}) {
  return _then(_CreateWorkerRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,salaryGross: null == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: freezed == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double?,transportAllowance: freezed == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double?,paymentFrequency: freezed == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UpdateWorkerRequest {

 String? get name; String? get phoneNumber; double? get salaryGross; DateTime? get startDate; DateTime? get dateOfBirth; String? get employmentType; double? get hourlyRate; String? get propertyId; String? get photoUrl; bool? get isActive; String? get email; String? get idNumber; String? get kraPin; String? get nssfNumber; String? get nhifNumber; String? get jobTitle; double? get housingAllowance; double? get transportAllowance; String? get paymentFrequency; String? get paymentMethod; String? get mpesaNumber; String? get bankName; String? get bankCode; String? get bankAccount; String? get notes; String? get emergencyContactName; String? get emergencyContactPhone; String? get emergencyContactRelationship;
/// Create a copy of UpdateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateWorkerRequestCopyWith<UpdateWorkerRequest> get copyWith => _$UpdateWorkerRequestCopyWithImpl<UpdateWorkerRequest>(this as UpdateWorkerRequest, _$identity);

  /// Serializes this UpdateWorkerRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateWorkerRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,phoneNumber,salaryGross,startDate,dateOfBirth,employmentType,hourlyRate,propertyId,photoUrl,isActive,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship]);

@override
String toString() {
  return 'UpdateWorkerRequest(name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, isActive: $isActive, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship)';
}


}

/// @nodoc
abstract mixin class $UpdateWorkerRequestCopyWith<$Res>  {
  factory $UpdateWorkerRequestCopyWith(UpdateWorkerRequest value, $Res Function(UpdateWorkerRequest) _then) = _$UpdateWorkerRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? phoneNumber, double? salaryGross, DateTime? startDate, DateTime? dateOfBirth, String? employmentType, double? hourlyRate, String? propertyId, String? photoUrl, bool? isActive, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double? housingAllowance, double? transportAllowance, String? paymentFrequency, String? paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship
});




}
/// @nodoc
class _$UpdateWorkerRequestCopyWithImpl<$Res>
    implements $UpdateWorkerRequestCopyWith<$Res> {
  _$UpdateWorkerRequestCopyWithImpl(this._self, this._then);

  final UpdateWorkerRequest _self;
  final $Res Function(UpdateWorkerRequest) _then;

/// Create a copy of UpdateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? phoneNumber = freezed,Object? salaryGross = freezed,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? employmentType = freezed,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? isActive = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = freezed,Object? transportAllowance = freezed,Object? paymentFrequency = freezed,Object? paymentMethod = freezed,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,salaryGross: freezed == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: freezed == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String?,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: freezed == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double?,transportAllowance: freezed == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double?,paymentFrequency: freezed == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateWorkerRequest].
extension UpdateWorkerRequestPatterns on UpdateWorkerRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateWorkerRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateWorkerRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateWorkerRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdateWorkerRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateWorkerRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateWorkerRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? phoneNumber,  double? salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String? employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  bool? isActive,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateWorkerRequest() when $default != null:
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.isActive,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? phoneNumber,  double? salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String? employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  bool? isActive,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)  $default,) {final _that = this;
switch (_that) {
case _UpdateWorkerRequest():
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.isActive,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? phoneNumber,  double? salaryGross,  DateTime? startDate,  DateTime? dateOfBirth,  String? employmentType,  double? hourlyRate,  String? propertyId,  String? photoUrl,  bool? isActive,  String? email,  String? idNumber,  String? kraPin,  String? nssfNumber,  String? nhifNumber,  String? jobTitle,  double? housingAllowance,  double? transportAllowance,  String? paymentFrequency,  String? paymentMethod,  String? mpesaNumber,  String? bankName,  String? bankCode,  String? bankAccount,  String? notes,  String? emergencyContactName,  String? emergencyContactPhone,  String? emergencyContactRelationship)?  $default,) {final _that = this;
switch (_that) {
case _UpdateWorkerRequest() when $default != null:
return $default(_that.name,_that.phoneNumber,_that.salaryGross,_that.startDate,_that.dateOfBirth,_that.employmentType,_that.hourlyRate,_that.propertyId,_that.photoUrl,_that.isActive,_that.email,_that.idNumber,_that.kraPin,_that.nssfNumber,_that.nhifNumber,_that.jobTitle,_that.housingAllowance,_that.transportAllowance,_that.paymentFrequency,_that.paymentMethod,_that.mpesaNumber,_that.bankName,_that.bankCode,_that.bankAccount,_that.notes,_that.emergencyContactName,_that.emergencyContactPhone,_that.emergencyContactRelationship);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateWorkerRequest implements UpdateWorkerRequest {
  const _UpdateWorkerRequest({this.name, this.phoneNumber, this.salaryGross, this.startDate, this.dateOfBirth, this.employmentType, this.hourlyRate, this.propertyId, this.photoUrl, this.isActive, this.email, this.idNumber, this.kraPin, this.nssfNumber, this.nhifNumber, this.jobTitle, this.housingAllowance, this.transportAllowance, this.paymentFrequency, this.paymentMethod, this.mpesaNumber, this.bankName, this.bankCode, this.bankAccount, this.notes, this.emergencyContactName, this.emergencyContactPhone, this.emergencyContactRelationship});
  factory _UpdateWorkerRequest.fromJson(Map<String, dynamic> json) => _$UpdateWorkerRequestFromJson(json);

@override final  String? name;
@override final  String? phoneNumber;
@override final  double? salaryGross;
@override final  DateTime? startDate;
@override final  DateTime? dateOfBirth;
@override final  String? employmentType;
@override final  double? hourlyRate;
@override final  String? propertyId;
@override final  String? photoUrl;
@override final  bool? isActive;
@override final  String? email;
@override final  String? idNumber;
@override final  String? kraPin;
@override final  String? nssfNumber;
@override final  String? nhifNumber;
@override final  String? jobTitle;
@override final  double? housingAllowance;
@override final  double? transportAllowance;
@override final  String? paymentFrequency;
@override final  String? paymentMethod;
@override final  String? mpesaNumber;
@override final  String? bankName;
@override final  String? bankCode;
@override final  String? bankAccount;
@override final  String? notes;
@override final  String? emergencyContactName;
@override final  String? emergencyContactPhone;
@override final  String? emergencyContactRelationship;

/// Create a copy of UpdateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateWorkerRequestCopyWith<_UpdateWorkerRequest> get copyWith => __$UpdateWorkerRequestCopyWithImpl<_UpdateWorkerRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateWorkerRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateWorkerRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.salaryGross, salaryGross) || other.salaryGross == salaryGross)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.kraPin, kraPin) || other.kraPin == kraPin)&&(identical(other.nssfNumber, nssfNumber) || other.nssfNumber == nssfNumber)&&(identical(other.nhifNumber, nhifNumber) || other.nhifNumber == nhifNumber)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.housingAllowance, housingAllowance) || other.housingAllowance == housingAllowance)&&(identical(other.transportAllowance, transportAllowance) || other.transportAllowance == transportAllowance)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.mpesaNumber, mpesaNumber) || other.mpesaNumber == mpesaNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankAccount, bankAccount) || other.bankAccount == bankAccount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.emergencyContactRelationship, emergencyContactRelationship) || other.emergencyContactRelationship == emergencyContactRelationship));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,phoneNumber,salaryGross,startDate,dateOfBirth,employmentType,hourlyRate,propertyId,photoUrl,isActive,email,idNumber,kraPin,nssfNumber,nhifNumber,jobTitle,housingAllowance,transportAllowance,paymentFrequency,paymentMethod,mpesaNumber,bankName,bankCode,bankAccount,notes,emergencyContactName,emergencyContactPhone,emergencyContactRelationship]);

@override
String toString() {
  return 'UpdateWorkerRequest(name: $name, phoneNumber: $phoneNumber, salaryGross: $salaryGross, startDate: $startDate, dateOfBirth: $dateOfBirth, employmentType: $employmentType, hourlyRate: $hourlyRate, propertyId: $propertyId, photoUrl: $photoUrl, isActive: $isActive, email: $email, idNumber: $idNumber, kraPin: $kraPin, nssfNumber: $nssfNumber, nhifNumber: $nhifNumber, jobTitle: $jobTitle, housingAllowance: $housingAllowance, transportAllowance: $transportAllowance, paymentFrequency: $paymentFrequency, paymentMethod: $paymentMethod, mpesaNumber: $mpesaNumber, bankName: $bankName, bankCode: $bankCode, bankAccount: $bankAccount, notes: $notes, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, emergencyContactRelationship: $emergencyContactRelationship)';
}


}

/// @nodoc
abstract mixin class _$UpdateWorkerRequestCopyWith<$Res> implements $UpdateWorkerRequestCopyWith<$Res> {
  factory _$UpdateWorkerRequestCopyWith(_UpdateWorkerRequest value, $Res Function(_UpdateWorkerRequest) _then) = __$UpdateWorkerRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? phoneNumber, double? salaryGross, DateTime? startDate, DateTime? dateOfBirth, String? employmentType, double? hourlyRate, String? propertyId, String? photoUrl, bool? isActive, String? email, String? idNumber, String? kraPin, String? nssfNumber, String? nhifNumber, String? jobTitle, double? housingAllowance, double? transportAllowance, String? paymentFrequency, String? paymentMethod, String? mpesaNumber, String? bankName, String? bankCode, String? bankAccount, String? notes, String? emergencyContactName, String? emergencyContactPhone, String? emergencyContactRelationship
});




}
/// @nodoc
class __$UpdateWorkerRequestCopyWithImpl<$Res>
    implements _$UpdateWorkerRequestCopyWith<$Res> {
  __$UpdateWorkerRequestCopyWithImpl(this._self, this._then);

  final _UpdateWorkerRequest _self;
  final $Res Function(_UpdateWorkerRequest) _then;

/// Create a copy of UpdateWorkerRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? phoneNumber = freezed,Object? salaryGross = freezed,Object? startDate = freezed,Object? dateOfBirth = freezed,Object? employmentType = freezed,Object? hourlyRate = freezed,Object? propertyId = freezed,Object? photoUrl = freezed,Object? isActive = freezed,Object? email = freezed,Object? idNumber = freezed,Object? kraPin = freezed,Object? nssfNumber = freezed,Object? nhifNumber = freezed,Object? jobTitle = freezed,Object? housingAllowance = freezed,Object? transportAllowance = freezed,Object? paymentFrequency = freezed,Object? paymentMethod = freezed,Object? mpesaNumber = freezed,Object? bankName = freezed,Object? bankCode = freezed,Object? bankAccount = freezed,Object? notes = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? emergencyContactRelationship = freezed,}) {
  return _then(_UpdateWorkerRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,salaryGross: freezed == salaryGross ? _self.salaryGross : salaryGross // ignore: cast_nullable_to_non_nullable
as double?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: freezed == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String?,hourlyRate: freezed == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idNumber: freezed == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String?,kraPin: freezed == kraPin ? _self.kraPin : kraPin // ignore: cast_nullable_to_non_nullable
as String?,nssfNumber: freezed == nssfNumber ? _self.nssfNumber : nssfNumber // ignore: cast_nullable_to_non_nullable
as String?,nhifNumber: freezed == nhifNumber ? _self.nhifNumber : nhifNumber // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,housingAllowance: freezed == housingAllowance ? _self.housingAllowance : housingAllowance // ignore: cast_nullable_to_non_nullable
as double?,transportAllowance: freezed == transportAllowance ? _self.transportAllowance : transportAllowance // ignore: cast_nullable_to_non_nullable
as double?,paymentFrequency: freezed == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,mpesaNumber: freezed == mpesaNumber ? _self.mpesaNumber : mpesaNumber // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankCode: freezed == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String?,bankAccount: freezed == bankAccount ? _self.bankAccount : bankAccount // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactRelationship: freezed == emergencyContactRelationship ? _self.emergencyContactRelationship : emergencyContactRelationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
