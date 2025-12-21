// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pay_period_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayPeriod {

/// Unique identifier.
 String get id;/// Display name (e.g., "August 2025", "Week 32").
 String get name;/// First day of the pay period (inclusive).
 DateTime get startDate;/// Last day of the pay period (inclusive).
 DateTime get endDate;/// How often this type of period recurs.
 PayPeriodFrequency get frequency;/// Current status in the payroll workflow.
 PayPeriodStatus get status;/// Total number of workers included in this period.
@JsonKey(fromJson: _intFromJson) int? get totalWorkers;/// Sum of all gross salaries.
@JsonKey(fromJson: _doubleFromJson) double? get totalGrossAmount;/// Sum of all net pay amounts.
@JsonKey(fromJson: _doubleFromJson) double? get totalNetAmount;/// Sum of all tax deductions.
@JsonKey(fromJson: _doubleFromJson) double? get totalTaxAmount;/// Number of workers whose payroll has been processed.
@JsonKey(fromJson: _intFromJson) int? get processedWorkers;/// When this pay period was created.
 DateTime? get createdAt;/// When this pay period was last updated.
 DateTime? get updatedAt;/// Additional notes or comments.
 String? get notes;/// Owner/employer user ID.
 String? get userId;/// Scheduled payment date.
 DateTime? get payDate;
/// Create a copy of PayPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayPeriodCopyWith<PayPeriod> get copyWith => _$PayPeriodCopyWithImpl<PayPeriod>(this as PayPeriod, _$identity);

  /// Serializes this PayPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalWorkers, totalWorkers) || other.totalWorkers == totalWorkers)&&(identical(other.totalGrossAmount, totalGrossAmount) || other.totalGrossAmount == totalGrossAmount)&&(identical(other.totalNetAmount, totalNetAmount) || other.totalNetAmount == totalNetAmount)&&(identical(other.totalTaxAmount, totalTaxAmount) || other.totalTaxAmount == totalTaxAmount)&&(identical(other.processedWorkers, processedWorkers) || other.processedWorkers == processedWorkers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.payDate, payDate) || other.payDate == payDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,startDate,endDate,frequency,status,totalWorkers,totalGrossAmount,totalNetAmount,totalTaxAmount,processedWorkers,createdAt,updatedAt,notes,userId,payDate);

@override
String toString() {
  return 'PayPeriod(id: $id, name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, totalWorkers: $totalWorkers, totalGrossAmount: $totalGrossAmount, totalNetAmount: $totalNetAmount, totalTaxAmount: $totalTaxAmount, processedWorkers: $processedWorkers, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, userId: $userId, payDate: $payDate)';
}


}

/// @nodoc
abstract mixin class $PayPeriodCopyWith<$Res>  {
  factory $PayPeriodCopyWith(PayPeriod value, $Res Function(PayPeriod) _then) = _$PayPeriodCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime startDate, DateTime endDate, PayPeriodFrequency frequency, PayPeriodStatus status,@JsonKey(fromJson: _intFromJson) int? totalWorkers,@JsonKey(fromJson: _doubleFromJson) double? totalGrossAmount,@JsonKey(fromJson: _doubleFromJson) double? totalNetAmount,@JsonKey(fromJson: _doubleFromJson) double? totalTaxAmount,@JsonKey(fromJson: _intFromJson) int? processedWorkers, DateTime? createdAt, DateTime? updatedAt, String? notes, String? userId, DateTime? payDate
});




}
/// @nodoc
class _$PayPeriodCopyWithImpl<$Res>
    implements $PayPeriodCopyWith<$Res> {
  _$PayPeriodCopyWithImpl(this._self, this._then);

  final PayPeriod _self;
  final $Res Function(PayPeriod) _then;

/// Create a copy of PayPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? startDate = null,Object? endDate = null,Object? frequency = null,Object? status = null,Object? totalWorkers = freezed,Object? totalGrossAmount = freezed,Object? totalNetAmount = freezed,Object? totalTaxAmount = freezed,Object? processedWorkers = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? notes = freezed,Object? userId = freezed,Object? payDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PayPeriodStatus,totalWorkers: freezed == totalWorkers ? _self.totalWorkers : totalWorkers // ignore: cast_nullable_to_non_nullable
as int?,totalGrossAmount: freezed == totalGrossAmount ? _self.totalGrossAmount : totalGrossAmount // ignore: cast_nullable_to_non_nullable
as double?,totalNetAmount: freezed == totalNetAmount ? _self.totalNetAmount : totalNetAmount // ignore: cast_nullable_to_non_nullable
as double?,totalTaxAmount: freezed == totalTaxAmount ? _self.totalTaxAmount : totalTaxAmount // ignore: cast_nullable_to_non_nullable
as double?,processedWorkers: freezed == processedWorkers ? _self.processedWorkers : processedWorkers // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,payDate: freezed == payDate ? _self.payDate : payDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PayPeriod].
extension PayPeriodPatterns on PayPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayPeriod value)  $default,){
final _that = this;
switch (_that) {
case _PayPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _PayPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  PayPeriodStatus status, @JsonKey(fromJson: _intFromJson)  int? totalWorkers, @JsonKey(fromJson: _doubleFromJson)  double? totalGrossAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalNetAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalTaxAmount, @JsonKey(fromJson: _intFromJson)  int? processedWorkers,  DateTime? createdAt,  DateTime? updatedAt,  String? notes,  String? userId,  DateTime? payDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayPeriod() when $default != null:
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.totalWorkers,_that.totalGrossAmount,_that.totalNetAmount,_that.totalTaxAmount,_that.processedWorkers,_that.createdAt,_that.updatedAt,_that.notes,_that.userId,_that.payDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  PayPeriodStatus status, @JsonKey(fromJson: _intFromJson)  int? totalWorkers, @JsonKey(fromJson: _doubleFromJson)  double? totalGrossAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalNetAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalTaxAmount, @JsonKey(fromJson: _intFromJson)  int? processedWorkers,  DateTime? createdAt,  DateTime? updatedAt,  String? notes,  String? userId,  DateTime? payDate)  $default,) {final _that = this;
switch (_that) {
case _PayPeriod():
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.totalWorkers,_that.totalGrossAmount,_that.totalNetAmount,_that.totalTaxAmount,_that.processedWorkers,_that.createdAt,_that.updatedAt,_that.notes,_that.userId,_that.payDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  PayPeriodStatus status, @JsonKey(fromJson: _intFromJson)  int? totalWorkers, @JsonKey(fromJson: _doubleFromJson)  double? totalGrossAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalNetAmount, @JsonKey(fromJson: _doubleFromJson)  double? totalTaxAmount, @JsonKey(fromJson: _intFromJson)  int? processedWorkers,  DateTime? createdAt,  DateTime? updatedAt,  String? notes,  String? userId,  DateTime? payDate)?  $default,) {final _that = this;
switch (_that) {
case _PayPeriod() when $default != null:
return $default(_that.id,_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.totalWorkers,_that.totalGrossAmount,_that.totalNetAmount,_that.totalTaxAmount,_that.processedWorkers,_that.createdAt,_that.updatedAt,_that.notes,_that.userId,_that.payDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayPeriod extends PayPeriod {
  const _PayPeriod({required this.id, required this.name, required this.startDate, required this.endDate, required this.frequency, required this.status, @JsonKey(fromJson: _intFromJson) this.totalWorkers, @JsonKey(fromJson: _doubleFromJson) this.totalGrossAmount, @JsonKey(fromJson: _doubleFromJson) this.totalNetAmount, @JsonKey(fromJson: _doubleFromJson) this.totalTaxAmount, @JsonKey(fromJson: _intFromJson) this.processedWorkers, this.createdAt, this.updatedAt, this.notes, this.userId, this.payDate}): super._();
  factory _PayPeriod.fromJson(Map<String, dynamic> json) => _$PayPeriodFromJson(json);

/// Unique identifier.
@override final  String id;
/// Display name (e.g., "August 2025", "Week 32").
@override final  String name;
/// First day of the pay period (inclusive).
@override final  DateTime startDate;
/// Last day of the pay period (inclusive).
@override final  DateTime endDate;
/// How often this type of period recurs.
@override final  PayPeriodFrequency frequency;
/// Current status in the payroll workflow.
@override final  PayPeriodStatus status;
/// Total number of workers included in this period.
@override@JsonKey(fromJson: _intFromJson) final  int? totalWorkers;
/// Sum of all gross salaries.
@override@JsonKey(fromJson: _doubleFromJson) final  double? totalGrossAmount;
/// Sum of all net pay amounts.
@override@JsonKey(fromJson: _doubleFromJson) final  double? totalNetAmount;
/// Sum of all tax deductions.
@override@JsonKey(fromJson: _doubleFromJson) final  double? totalTaxAmount;
/// Number of workers whose payroll has been processed.
@override@JsonKey(fromJson: _intFromJson) final  int? processedWorkers;
/// When this pay period was created.
@override final  DateTime? createdAt;
/// When this pay period was last updated.
@override final  DateTime? updatedAt;
/// Additional notes or comments.
@override final  String? notes;
/// Owner/employer user ID.
@override final  String? userId;
/// Scheduled payment date.
@override final  DateTime? payDate;

/// Create a copy of PayPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayPeriodCopyWith<_PayPeriod> get copyWith => __$PayPeriodCopyWithImpl<_PayPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalWorkers, totalWorkers) || other.totalWorkers == totalWorkers)&&(identical(other.totalGrossAmount, totalGrossAmount) || other.totalGrossAmount == totalGrossAmount)&&(identical(other.totalNetAmount, totalNetAmount) || other.totalNetAmount == totalNetAmount)&&(identical(other.totalTaxAmount, totalTaxAmount) || other.totalTaxAmount == totalTaxAmount)&&(identical(other.processedWorkers, processedWorkers) || other.processedWorkers == processedWorkers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.payDate, payDate) || other.payDate == payDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,startDate,endDate,frequency,status,totalWorkers,totalGrossAmount,totalNetAmount,totalTaxAmount,processedWorkers,createdAt,updatedAt,notes,userId,payDate);

@override
String toString() {
  return 'PayPeriod(id: $id, name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, totalWorkers: $totalWorkers, totalGrossAmount: $totalGrossAmount, totalNetAmount: $totalNetAmount, totalTaxAmount: $totalTaxAmount, processedWorkers: $processedWorkers, createdAt: $createdAt, updatedAt: $updatedAt, notes: $notes, userId: $userId, payDate: $payDate)';
}


}

/// @nodoc
abstract mixin class _$PayPeriodCopyWith<$Res> implements $PayPeriodCopyWith<$Res> {
  factory _$PayPeriodCopyWith(_PayPeriod value, $Res Function(_PayPeriod) _then) = __$PayPeriodCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime startDate, DateTime endDate, PayPeriodFrequency frequency, PayPeriodStatus status,@JsonKey(fromJson: _intFromJson) int? totalWorkers,@JsonKey(fromJson: _doubleFromJson) double? totalGrossAmount,@JsonKey(fromJson: _doubleFromJson) double? totalNetAmount,@JsonKey(fromJson: _doubleFromJson) double? totalTaxAmount,@JsonKey(fromJson: _intFromJson) int? processedWorkers, DateTime? createdAt, DateTime? updatedAt, String? notes, String? userId, DateTime? payDate
});




}
/// @nodoc
class __$PayPeriodCopyWithImpl<$Res>
    implements _$PayPeriodCopyWith<$Res> {
  __$PayPeriodCopyWithImpl(this._self, this._then);

  final _PayPeriod _self;
  final $Res Function(_PayPeriod) _then;

/// Create a copy of PayPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? startDate = null,Object? endDate = null,Object? frequency = null,Object? status = null,Object? totalWorkers = freezed,Object? totalGrossAmount = freezed,Object? totalNetAmount = freezed,Object? totalTaxAmount = freezed,Object? processedWorkers = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? notes = freezed,Object? userId = freezed,Object? payDate = freezed,}) {
  return _then(_PayPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PayPeriodStatus,totalWorkers: freezed == totalWorkers ? _self.totalWorkers : totalWorkers // ignore: cast_nullable_to_non_nullable
as int?,totalGrossAmount: freezed == totalGrossAmount ? _self.totalGrossAmount : totalGrossAmount // ignore: cast_nullable_to_non_nullable
as double?,totalNetAmount: freezed == totalNetAmount ? _self.totalNetAmount : totalNetAmount // ignore: cast_nullable_to_non_nullable
as double?,totalTaxAmount: freezed == totalTaxAmount ? _self.totalTaxAmount : totalTaxAmount // ignore: cast_nullable_to_non_nullable
as double?,processedWorkers: freezed == processedWorkers ? _self.processedWorkers : processedWorkers // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,payDate: freezed == payDate ? _self.payDate : payDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreatePayPeriodRequest {

/// Display name for the pay period.
 String get name;/// First day of the pay period.
 DateTime get startDate;/// Last day of the pay period.
 DateTime get endDate;/// Pay frequency.
 PayPeriodFrequency get frequency;/// Optional notes.
 String? get notes;/// Whether this is an off-cycle payroll (bonus, advance, etc.).
 bool get isOffCycle;
/// Create a copy of CreatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePayPeriodRequestCopyWith<CreatePayPeriodRequest> get copyWith => _$CreatePayPeriodRequestCopyWithImpl<CreatePayPeriodRequest>(this as CreatePayPeriodRequest, _$identity);

  /// Serializes this CreatePayPeriodRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePayPeriodRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isOffCycle, isOffCycle) || other.isOffCycle == isOffCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,frequency,notes,isOffCycle);

@override
String toString() {
  return 'CreatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, notes: $notes, isOffCycle: $isOffCycle)';
}


}

/// @nodoc
abstract mixin class $CreatePayPeriodRequestCopyWith<$Res>  {
  factory $CreatePayPeriodRequestCopyWith(CreatePayPeriodRequest value, $Res Function(CreatePayPeriodRequest) _then) = _$CreatePayPeriodRequestCopyWithImpl;
@useResult
$Res call({
 String name, DateTime startDate, DateTime endDate, PayPeriodFrequency frequency, String? notes, bool isOffCycle
});




}
/// @nodoc
class _$CreatePayPeriodRequestCopyWithImpl<$Res>
    implements $CreatePayPeriodRequestCopyWith<$Res> {
  _$CreatePayPeriodRequestCopyWithImpl(this._self, this._then);

  final CreatePayPeriodRequest _self;
  final $Res Function(CreatePayPeriodRequest) _then;

/// Create a copy of CreatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? startDate = null,Object? endDate = null,Object? frequency = null,Object? notes = freezed,Object? isOffCycle = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isOffCycle: null == isOffCycle ? _self.isOffCycle : isOffCycle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatePayPeriodRequest].
extension CreatePayPeriodRequestPatterns on CreatePayPeriodRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatePayPeriodRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatePayPeriodRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatePayPeriodRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreatePayPeriodRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatePayPeriodRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreatePayPeriodRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  String? notes,  bool isOffCycle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatePayPeriodRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.notes,_that.isOffCycle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  String? notes,  bool isOffCycle)  $default,) {final _that = this;
switch (_that) {
case _CreatePayPeriodRequest():
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.notes,_that.isOffCycle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  DateTime startDate,  DateTime endDate,  PayPeriodFrequency frequency,  String? notes,  bool isOffCycle)?  $default,) {final _that = this;
switch (_that) {
case _CreatePayPeriodRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.notes,_that.isOffCycle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatePayPeriodRequest extends CreatePayPeriodRequest {
  const _CreatePayPeriodRequest({required this.name, required this.startDate, required this.endDate, required this.frequency, this.notes, this.isOffCycle = false}): super._();
  factory _CreatePayPeriodRequest.fromJson(Map<String, dynamic> json) => _$CreatePayPeriodRequestFromJson(json);

/// Display name for the pay period.
@override final  String name;
/// First day of the pay period.
@override final  DateTime startDate;
/// Last day of the pay period.
@override final  DateTime endDate;
/// Pay frequency.
@override final  PayPeriodFrequency frequency;
/// Optional notes.
@override final  String? notes;
/// Whether this is an off-cycle payroll (bonus, advance, etc.).
@override@JsonKey() final  bool isOffCycle;

/// Create a copy of CreatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePayPeriodRequestCopyWith<_CreatePayPeriodRequest> get copyWith => __$CreatePayPeriodRequestCopyWithImpl<_CreatePayPeriodRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatePayPeriodRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePayPeriodRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isOffCycle, isOffCycle) || other.isOffCycle == isOffCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,frequency,notes,isOffCycle);

@override
String toString() {
  return 'CreatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, notes: $notes, isOffCycle: $isOffCycle)';
}


}

/// @nodoc
abstract mixin class _$CreatePayPeriodRequestCopyWith<$Res> implements $CreatePayPeriodRequestCopyWith<$Res> {
  factory _$CreatePayPeriodRequestCopyWith(_CreatePayPeriodRequest value, $Res Function(_CreatePayPeriodRequest) _then) = __$CreatePayPeriodRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, DateTime startDate, DateTime endDate, PayPeriodFrequency frequency, String? notes, bool isOffCycle
});




}
/// @nodoc
class __$CreatePayPeriodRequestCopyWithImpl<$Res>
    implements _$CreatePayPeriodRequestCopyWith<$Res> {
  __$CreatePayPeriodRequestCopyWithImpl(this._self, this._then);

  final _CreatePayPeriodRequest _self;
  final $Res Function(_CreatePayPeriodRequest) _then;

/// Create a copy of CreatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? startDate = null,Object? endDate = null,Object? frequency = null,Object? notes = freezed,Object? isOffCycle = null,}) {
  return _then(_CreatePayPeriodRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isOffCycle: null == isOffCycle ? _self.isOffCycle : isOffCycle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$UpdatePayPeriodRequest {

/// Updated name (optional).
 String? get name;/// Updated start date (optional).
 DateTime? get startDate;/// Updated end date (optional).
 DateTime? get endDate;/// Updated frequency (optional).
 PayPeriodFrequency? get frequency;/// Updated status (optional).
 PayPeriodStatus? get status;/// Updated notes (optional).
 String? get notes;
/// Create a copy of UpdatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePayPeriodRequestCopyWith<UpdatePayPeriodRequest> get copyWith => _$UpdatePayPeriodRequestCopyWithImpl<UpdatePayPeriodRequest>(this as UpdatePayPeriodRequest, _$identity);

  /// Serializes this UpdatePayPeriodRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePayPeriodRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,frequency,status,notes);

@override
String toString() {
  return 'UpdatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $UpdatePayPeriodRequestCopyWith<$Res>  {
  factory $UpdatePayPeriodRequestCopyWith(UpdatePayPeriodRequest value, $Res Function(UpdatePayPeriodRequest) _then) = _$UpdatePayPeriodRequestCopyWithImpl;
@useResult
$Res call({
 String? name, DateTime? startDate, DateTime? endDate, PayPeriodFrequency? frequency, PayPeriodStatus? status, String? notes
});




}
/// @nodoc
class _$UpdatePayPeriodRequestCopyWithImpl<$Res>
    implements $UpdatePayPeriodRequestCopyWith<$Res> {
  _$UpdatePayPeriodRequestCopyWithImpl(this._self, this._then);

  final UpdatePayPeriodRequest _self;
  final $Res Function(UpdatePayPeriodRequest) _then;

/// Create a copy of UpdatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? frequency = freezed,Object? status = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PayPeriodStatus?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePayPeriodRequest].
extension UpdatePayPeriodRequestPatterns on UpdatePayPeriodRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePayPeriodRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePayPeriodRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePayPeriodRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  DateTime? startDate,  DateTime? endDate,  PayPeriodFrequency? frequency,  PayPeriodStatus? status,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  DateTime? startDate,  DateTime? endDate,  PayPeriodFrequency? frequency,  PayPeriodStatus? status,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest():
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  DateTime? startDate,  DateTime? endDate,  PayPeriodFrequency? frequency,  PayPeriodStatus? status,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePayPeriodRequest() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.frequency,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePayPeriodRequest extends UpdatePayPeriodRequest {
  const _UpdatePayPeriodRequest({this.name, this.startDate, this.endDate, this.frequency, this.status, this.notes}): super._();
  factory _UpdatePayPeriodRequest.fromJson(Map<String, dynamic> json) => _$UpdatePayPeriodRequestFromJson(json);

/// Updated name (optional).
@override final  String? name;
/// Updated start date (optional).
@override final  DateTime? startDate;
/// Updated end date (optional).
@override final  DateTime? endDate;
/// Updated frequency (optional).
@override final  PayPeriodFrequency? frequency;
/// Updated status (optional).
@override final  PayPeriodStatus? status;
/// Updated notes (optional).
@override final  String? notes;

/// Create a copy of UpdatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePayPeriodRequestCopyWith<_UpdatePayPeriodRequest> get copyWith => __$UpdatePayPeriodRequestCopyWithImpl<_UpdatePayPeriodRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdatePayPeriodRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePayPeriodRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,frequency,status,notes);

@override
String toString() {
  return 'UpdatePayPeriodRequest(name: $name, startDate: $startDate, endDate: $endDate, frequency: $frequency, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$UpdatePayPeriodRequestCopyWith<$Res> implements $UpdatePayPeriodRequestCopyWith<$Res> {
  factory _$UpdatePayPeriodRequestCopyWith(_UpdatePayPeriodRequest value, $Res Function(_UpdatePayPeriodRequest) _then) = __$UpdatePayPeriodRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, DateTime? startDate, DateTime? endDate, PayPeriodFrequency? frequency, PayPeriodStatus? status, String? notes
});




}
/// @nodoc
class __$UpdatePayPeriodRequestCopyWithImpl<$Res>
    implements _$UpdatePayPeriodRequestCopyWith<$Res> {
  __$UpdatePayPeriodRequestCopyWithImpl(this._self, this._then);

  final _UpdatePayPeriodRequest _self;
  final $Res Function(_UpdatePayPeriodRequest) _then;

/// Create a copy of UpdatePayPeriodRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? frequency = freezed,Object? status = freezed,Object? notes = freezed,}) {
  return _then(_UpdatePayPeriodRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as PayPeriodFrequency?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PayPeriodStatus?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
