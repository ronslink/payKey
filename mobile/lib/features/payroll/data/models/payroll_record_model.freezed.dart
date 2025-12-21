// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollRecordModel {

 String get id; String get workerId; String get workerName; double get grossSalary; double get netPay; String get payPeriodId; String get paymentStatus; DateTime get createdAt; List<String> get deductions; double get bonuses; double get otherEarnings;
/// Create a copy of PayrollRecordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollRecordModelCopyWith<PayrollRecordModel> get copyWith => _$PayrollRecordModelCopyWithImpl<PayrollRecordModel>(this as PayrollRecordModel, _$identity);

  /// Serializes this PayrollRecordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollRecordModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.payPeriodId, payPeriodId) || other.payPeriodId == payPeriodId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.deductions, deductions)&&(identical(other.bonuses, bonuses) || other.bonuses == bonuses)&&(identical(other.otherEarnings, otherEarnings) || other.otherEarnings == otherEarnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,workerName,grossSalary,netPay,payPeriodId,paymentStatus,createdAt,const DeepCollectionEquality().hash(deductions),bonuses,otherEarnings);

@override
String toString() {
  return 'PayrollRecordModel(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, netPay: $netPay, payPeriodId: $payPeriodId, paymentStatus: $paymentStatus, createdAt: $createdAt, deductions: $deductions, bonuses: $bonuses, otherEarnings: $otherEarnings)';
}


}

/// @nodoc
abstract mixin class $PayrollRecordModelCopyWith<$Res>  {
  factory $PayrollRecordModelCopyWith(PayrollRecordModel value, $Res Function(PayrollRecordModel) _then) = _$PayrollRecordModelCopyWithImpl;
@useResult
$Res call({
 String id, String workerId, String workerName, double grossSalary, double netPay, String payPeriodId, String paymentStatus, DateTime createdAt, List<String> deductions, double bonuses, double otherEarnings
});




}
/// @nodoc
class _$PayrollRecordModelCopyWithImpl<$Res>
    implements $PayrollRecordModelCopyWith<$Res> {
  _$PayrollRecordModelCopyWithImpl(this._self, this._then);

  final PayrollRecordModel _self;
  final $Res Function(PayrollRecordModel) _then;

/// Create a copy of PayrollRecordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workerId = null,Object? workerName = null,Object? grossSalary = null,Object? netPay = null,Object? payPeriodId = null,Object? paymentStatus = null,Object? createdAt = null,Object? deductions = null,Object? bonuses = null,Object? otherEarnings = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,grossSalary: null == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double,netPay: null == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double,payPeriodId: null == payPeriodId ? _self.payPeriodId : payPeriodId // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deductions: null == deductions ? _self.deductions : deductions // ignore: cast_nullable_to_non_nullable
as List<String>,bonuses: null == bonuses ? _self.bonuses : bonuses // ignore: cast_nullable_to_non_nullable
as double,otherEarnings: null == otherEarnings ? _self.otherEarnings : otherEarnings // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollRecordModel].
extension PayrollRecordModelPatterns on PayrollRecordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollRecordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollRecordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollRecordModel value)  $default,){
final _that = this;
switch (_that) {
case _PayrollRecordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollRecordModel value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollRecordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workerId,  String workerName,  double grossSalary,  double netPay,  String payPeriodId,  String paymentStatus,  DateTime createdAt,  List<String> deductions,  double bonuses,  double otherEarnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollRecordModel() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.netPay,_that.payPeriodId,_that.paymentStatus,_that.createdAt,_that.deductions,_that.bonuses,_that.otherEarnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workerId,  String workerName,  double grossSalary,  double netPay,  String payPeriodId,  String paymentStatus,  DateTime createdAt,  List<String> deductions,  double bonuses,  double otherEarnings)  $default,) {final _that = this;
switch (_that) {
case _PayrollRecordModel():
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.netPay,_that.payPeriodId,_that.paymentStatus,_that.createdAt,_that.deductions,_that.bonuses,_that.otherEarnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workerId,  String workerName,  double grossSalary,  double netPay,  String payPeriodId,  String paymentStatus,  DateTime createdAt,  List<String> deductions,  double bonuses,  double otherEarnings)?  $default,) {final _that = this;
switch (_that) {
case _PayrollRecordModel() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.netPay,_that.payPeriodId,_that.paymentStatus,_that.createdAt,_that.deductions,_that.bonuses,_that.otherEarnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollRecordModel implements PayrollRecordModel {
  const _PayrollRecordModel({required this.id, required this.workerId, required this.workerName, required this.grossSalary, required this.netPay, required this.payPeriodId, required this.paymentStatus, required this.createdAt, final  List<String> deductions = const [], this.bonuses = 0.0, this.otherEarnings = 0.0}): _deductions = deductions;
  factory _PayrollRecordModel.fromJson(Map<String, dynamic> json) => _$PayrollRecordModelFromJson(json);

@override final  String id;
@override final  String workerId;
@override final  String workerName;
@override final  double grossSalary;
@override final  double netPay;
@override final  String payPeriodId;
@override final  String paymentStatus;
@override final  DateTime createdAt;
 final  List<String> _deductions;
@override@JsonKey() List<String> get deductions {
  if (_deductions is EqualUnmodifiableListView) return _deductions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deductions);
}

@override@JsonKey() final  double bonuses;
@override@JsonKey() final  double otherEarnings;

/// Create a copy of PayrollRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollRecordModelCopyWith<_PayrollRecordModel> get copyWith => __$PayrollRecordModelCopyWithImpl<_PayrollRecordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollRecordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollRecordModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.payPeriodId, payPeriodId) || other.payPeriodId == payPeriodId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._deductions, _deductions)&&(identical(other.bonuses, bonuses) || other.bonuses == bonuses)&&(identical(other.otherEarnings, otherEarnings) || other.otherEarnings == otherEarnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,workerName,grossSalary,netPay,payPeriodId,paymentStatus,createdAt,const DeepCollectionEquality().hash(_deductions),bonuses,otherEarnings);

@override
String toString() {
  return 'PayrollRecordModel(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, netPay: $netPay, payPeriodId: $payPeriodId, paymentStatus: $paymentStatus, createdAt: $createdAt, deductions: $deductions, bonuses: $bonuses, otherEarnings: $otherEarnings)';
}


}

/// @nodoc
abstract mixin class _$PayrollRecordModelCopyWith<$Res> implements $PayrollRecordModelCopyWith<$Res> {
  factory _$PayrollRecordModelCopyWith(_PayrollRecordModel value, $Res Function(_PayrollRecordModel) _then) = __$PayrollRecordModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String workerId, String workerName, double grossSalary, double netPay, String payPeriodId, String paymentStatus, DateTime createdAt, List<String> deductions, double bonuses, double otherEarnings
});




}
/// @nodoc
class __$PayrollRecordModelCopyWithImpl<$Res>
    implements _$PayrollRecordModelCopyWith<$Res> {
  __$PayrollRecordModelCopyWithImpl(this._self, this._then);

  final _PayrollRecordModel _self;
  final $Res Function(_PayrollRecordModel) _then;

/// Create a copy of PayrollRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workerId = null,Object? workerName = null,Object? grossSalary = null,Object? netPay = null,Object? payPeriodId = null,Object? paymentStatus = null,Object? createdAt = null,Object? deductions = null,Object? bonuses = null,Object? otherEarnings = null,}) {
  return _then(_PayrollRecordModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,grossSalary: null == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double,netPay: null == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double,payPeriodId: null == payPeriodId ? _self.payPeriodId : payPeriodId // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deductions: null == deductions ? _self._deductions : deductions // ignore: cast_nullable_to_non_nullable
as List<String>,bonuses: null == bonuses ? _self.bonuses : bonuses // ignore: cast_nullable_to_non_nullable
as double,otherEarnings: null == otherEarnings ? _self.otherEarnings : otherEarnings // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
