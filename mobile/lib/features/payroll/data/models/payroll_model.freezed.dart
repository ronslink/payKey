// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaxBreakdown {

/// National Social Security Fund contribution
 double get nssf;/// National Hospital Insurance Fund contribution
 double get nhif;/// Affordable Housing Levy (1.5% of gross salary)
 double get housingLevy;/// Pay As You Earn tax
 double get paye;/// Sum of all deductions (nssf + nhif + housingLevy + paye)
 double get totalDeductions;
/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<TaxBreakdown> get copyWith => _$TaxBreakdownCopyWithImpl<TaxBreakdown>(this as TaxBreakdown, _$identity);

  /// Serializes this TaxBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaxBreakdown&&(identical(other.nssf, nssf) || other.nssf == nssf)&&(identical(other.nhif, nhif) || other.nhif == nhif)&&(identical(other.housingLevy, housingLevy) || other.housingLevy == housingLevy)&&(identical(other.paye, paye) || other.paye == paye)&&(identical(other.totalDeductions, totalDeductions) || other.totalDeductions == totalDeductions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nssf,nhif,housingLevy,paye,totalDeductions);

@override
String toString() {
  return 'TaxBreakdown(nssf: $nssf, nhif: $nhif, housingLevy: $housingLevy, paye: $paye, totalDeductions: $totalDeductions)';
}


}

/// @nodoc
abstract mixin class $TaxBreakdownCopyWith<$Res>  {
  factory $TaxBreakdownCopyWith(TaxBreakdown value, $Res Function(TaxBreakdown) _then) = _$TaxBreakdownCopyWithImpl;
@useResult
$Res call({
 double nssf, double nhif, double housingLevy, double paye, double totalDeductions
});




}
/// @nodoc
class _$TaxBreakdownCopyWithImpl<$Res>
    implements $TaxBreakdownCopyWith<$Res> {
  _$TaxBreakdownCopyWithImpl(this._self, this._then);

  final TaxBreakdown _self;
  final $Res Function(TaxBreakdown) _then;

/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nssf = null,Object? nhif = null,Object? housingLevy = null,Object? paye = null,Object? totalDeductions = null,}) {
  return _then(_self.copyWith(
nssf: null == nssf ? _self.nssf : nssf // ignore: cast_nullable_to_non_nullable
as double,nhif: null == nhif ? _self.nhif : nhif // ignore: cast_nullable_to_non_nullable
as double,housingLevy: null == housingLevy ? _self.housingLevy : housingLevy // ignore: cast_nullable_to_non_nullable
as double,paye: null == paye ? _self.paye : paye // ignore: cast_nullable_to_non_nullable
as double,totalDeductions: null == totalDeductions ? _self.totalDeductions : totalDeductions // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TaxBreakdown].
extension TaxBreakdownPatterns on TaxBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaxBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaxBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _TaxBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaxBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double nssf,  double nhif,  double housingLevy,  double paye,  double totalDeductions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
return $default(_that.nssf,_that.nhif,_that.housingLevy,_that.paye,_that.totalDeductions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double nssf,  double nhif,  double housingLevy,  double paye,  double totalDeductions)  $default,) {final _that = this;
switch (_that) {
case _TaxBreakdown():
return $default(_that.nssf,_that.nhif,_that.housingLevy,_that.paye,_that.totalDeductions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double nssf,  double nhif,  double housingLevy,  double paye,  double totalDeductions)?  $default,) {final _that = this;
switch (_that) {
case _TaxBreakdown() when $default != null:
return $default(_that.nssf,_that.nhif,_that.housingLevy,_that.paye,_that.totalDeductions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaxBreakdown extends TaxBreakdown {
  const _TaxBreakdown({required this.nssf, required this.nhif, required this.housingLevy, required this.paye, required this.totalDeductions}): super._();
  factory _TaxBreakdown.fromJson(Map<String, dynamic> json) => _$TaxBreakdownFromJson(json);

/// National Social Security Fund contribution
@override final  double nssf;
/// National Hospital Insurance Fund contribution
@override final  double nhif;
/// Affordable Housing Levy (1.5% of gross salary)
@override final  double housingLevy;
/// Pay As You Earn tax
@override final  double paye;
/// Sum of all deductions (nssf + nhif + housingLevy + paye)
@override final  double totalDeductions;

/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaxBreakdownCopyWith<_TaxBreakdown> get copyWith => __$TaxBreakdownCopyWithImpl<_TaxBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaxBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaxBreakdown&&(identical(other.nssf, nssf) || other.nssf == nssf)&&(identical(other.nhif, nhif) || other.nhif == nhif)&&(identical(other.housingLevy, housingLevy) || other.housingLevy == housingLevy)&&(identical(other.paye, paye) || other.paye == paye)&&(identical(other.totalDeductions, totalDeductions) || other.totalDeductions == totalDeductions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nssf,nhif,housingLevy,paye,totalDeductions);

@override
String toString() {
  return 'TaxBreakdown(nssf: $nssf, nhif: $nhif, housingLevy: $housingLevy, paye: $paye, totalDeductions: $totalDeductions)';
}


}

/// @nodoc
abstract mixin class _$TaxBreakdownCopyWith<$Res> implements $TaxBreakdownCopyWith<$Res> {
  factory _$TaxBreakdownCopyWith(_TaxBreakdown value, $Res Function(_TaxBreakdown) _then) = __$TaxBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double nssf, double nhif, double housingLevy, double paye, double totalDeductions
});




}
/// @nodoc
class __$TaxBreakdownCopyWithImpl<$Res>
    implements _$TaxBreakdownCopyWith<$Res> {
  __$TaxBreakdownCopyWithImpl(this._self, this._then);

  final _TaxBreakdown _self;
  final $Res Function(_TaxBreakdown) _then;

/// Create a copy of TaxBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nssf = null,Object? nhif = null,Object? housingLevy = null,Object? paye = null,Object? totalDeductions = null,}) {
  return _then(_TaxBreakdown(
nssf: null == nssf ? _self.nssf : nssf // ignore: cast_nullable_to_non_nullable
as double,nhif: null == nhif ? _self.nhif : nhif // ignore: cast_nullable_to_non_nullable
as double,housingLevy: null == housingLevy ? _self.housingLevy : housingLevy // ignore: cast_nullable_to_non_nullable
as double,paye: null == paye ? _self.paye : paye // ignore: cast_nullable_to_non_nullable
as double,totalDeductions: null == totalDeductions ? _self.totalDeductions : totalDeductions // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PayrollCalculation {

/// Unique identifier. Null for new/unsaved calculations.
 String? get id;/// Reference to the worker this calculation belongs to.
 String get workerId;/// Worker's display name (denormalized for convenience).
 String get workerName;/// Base salary before any additions or deductions.
 double get grossSalary;/// Additional bonus payments.
 double get bonuses;/// Other earnings (allowances, overtime, etc.).
 double get otherEarnings;/// Additional deductions (loans, advances, etc.).
 double get otherDeductions;/// Breakdown of statutory tax deductions.
 TaxBreakdown get taxBreakdown;/// Final amount payable to worker.
 double get netPay;/// Current status in the payroll workflow.
 String get status;/// Whether this calculation has been manually edited.
 bool get isEdited;
/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollCalculationCopyWith<PayrollCalculation> get copyWith => _$PayrollCalculationCopyWithImpl<PayrollCalculation>(this as PayrollCalculation, _$identity);

  /// Serializes this PayrollCalculation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollCalculation&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.bonuses, bonuses) || other.bonuses == bonuses)&&(identical(other.otherEarnings, otherEarnings) || other.otherEarnings == otherEarnings)&&(identical(other.otherDeductions, otherDeductions) || other.otherDeductions == otherDeductions)&&(identical(other.taxBreakdown, taxBreakdown) || other.taxBreakdown == taxBreakdown)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.status, status) || other.status == status)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,workerName,grossSalary,bonuses,otherEarnings,otherDeductions,taxBreakdown,netPay,status,isEdited);

@override
String toString() {
  return 'PayrollCalculation(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, bonuses: $bonuses, otherEarnings: $otherEarnings, otherDeductions: $otherDeductions, taxBreakdown: $taxBreakdown, netPay: $netPay, status: $status, isEdited: $isEdited)';
}


}

/// @nodoc
abstract mixin class $PayrollCalculationCopyWith<$Res>  {
  factory $PayrollCalculationCopyWith(PayrollCalculation value, $Res Function(PayrollCalculation) _then) = _$PayrollCalculationCopyWithImpl;
@useResult
$Res call({
 String? id, String workerId, String workerName, double grossSalary, double bonuses, double otherEarnings, double otherDeductions, TaxBreakdown taxBreakdown, double netPay, String status, bool isEdited
});


$TaxBreakdownCopyWith<$Res> get taxBreakdown;

}
/// @nodoc
class _$PayrollCalculationCopyWithImpl<$Res>
    implements $PayrollCalculationCopyWith<$Res> {
  _$PayrollCalculationCopyWithImpl(this._self, this._then);

  final PayrollCalculation _self;
  final $Res Function(PayrollCalculation) _then;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? workerId = null,Object? workerName = null,Object? grossSalary = null,Object? bonuses = null,Object? otherEarnings = null,Object? otherDeductions = null,Object? taxBreakdown = null,Object? netPay = null,Object? status = null,Object? isEdited = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,grossSalary: null == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double,bonuses: null == bonuses ? _self.bonuses : bonuses // ignore: cast_nullable_to_non_nullable
as double,otherEarnings: null == otherEarnings ? _self.otherEarnings : otherEarnings // ignore: cast_nullable_to_non_nullable
as double,otherDeductions: null == otherDeductions ? _self.otherDeductions : otherDeductions // ignore: cast_nullable_to_non_nullable
as double,taxBreakdown: null == taxBreakdown ? _self.taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,netPay: null == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<$Res> get taxBreakdown {
  
  return $TaxBreakdownCopyWith<$Res>(_self.taxBreakdown, (value) {
    return _then(_self.copyWith(taxBreakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [PayrollCalculation].
extension PayrollCalculationPatterns on PayrollCalculation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollCalculation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollCalculation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollCalculation value)  $default,){
final _that = this;
switch (_that) {
case _PayrollCalculation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollCalculation value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollCalculation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String workerId,  String workerName,  double grossSalary,  double bonuses,  double otherEarnings,  double otherDeductions,  TaxBreakdown taxBreakdown,  double netPay,  String status,  bool isEdited)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollCalculation() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.bonuses,_that.otherEarnings,_that.otherDeductions,_that.taxBreakdown,_that.netPay,_that.status,_that.isEdited);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String workerId,  String workerName,  double grossSalary,  double bonuses,  double otherEarnings,  double otherDeductions,  TaxBreakdown taxBreakdown,  double netPay,  String status,  bool isEdited)  $default,) {final _that = this;
switch (_that) {
case _PayrollCalculation():
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.bonuses,_that.otherEarnings,_that.otherDeductions,_that.taxBreakdown,_that.netPay,_that.status,_that.isEdited);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String workerId,  String workerName,  double grossSalary,  double bonuses,  double otherEarnings,  double otherDeductions,  TaxBreakdown taxBreakdown,  double netPay,  String status,  bool isEdited)?  $default,) {final _that = this;
switch (_that) {
case _PayrollCalculation() when $default != null:
return $default(_that.id,_that.workerId,_that.workerName,_that.grossSalary,_that.bonuses,_that.otherEarnings,_that.otherDeductions,_that.taxBreakdown,_that.netPay,_that.status,_that.isEdited);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollCalculation extends PayrollCalculation {
  const _PayrollCalculation({this.id, required this.workerId, required this.workerName, required this.grossSalary, this.bonuses = 0, this.otherEarnings = 0, this.otherDeductions = 0, required this.taxBreakdown, required this.netPay, this.status = PayrollStatus.draft, this.isEdited = false}): super._();
  factory _PayrollCalculation.fromJson(Map<String, dynamic> json) => _$PayrollCalculationFromJson(json);

/// Unique identifier. Null for new/unsaved calculations.
@override final  String? id;
/// Reference to the worker this calculation belongs to.
@override final  String workerId;
/// Worker's display name (denormalized for convenience).
@override final  String workerName;
/// Base salary before any additions or deductions.
@override final  double grossSalary;
/// Additional bonus payments.
@override@JsonKey() final  double bonuses;
/// Other earnings (allowances, overtime, etc.).
@override@JsonKey() final  double otherEarnings;
/// Additional deductions (loans, advances, etc.).
@override@JsonKey() final  double otherDeductions;
/// Breakdown of statutory tax deductions.
@override final  TaxBreakdown taxBreakdown;
/// Final amount payable to worker.
@override final  double netPay;
/// Current status in the payroll workflow.
@override@JsonKey() final  String status;
/// Whether this calculation has been manually edited.
@override@JsonKey() final  bool isEdited;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollCalculationCopyWith<_PayrollCalculation> get copyWith => __$PayrollCalculationCopyWithImpl<_PayrollCalculation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollCalculationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollCalculation&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.bonuses, bonuses) || other.bonuses == bonuses)&&(identical(other.otherEarnings, otherEarnings) || other.otherEarnings == otherEarnings)&&(identical(other.otherDeductions, otherDeductions) || other.otherDeductions == otherDeductions)&&(identical(other.taxBreakdown, taxBreakdown) || other.taxBreakdown == taxBreakdown)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.status, status) || other.status == status)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,workerName,grossSalary,bonuses,otherEarnings,otherDeductions,taxBreakdown,netPay,status,isEdited);

@override
String toString() {
  return 'PayrollCalculation(id: $id, workerId: $workerId, workerName: $workerName, grossSalary: $grossSalary, bonuses: $bonuses, otherEarnings: $otherEarnings, otherDeductions: $otherDeductions, taxBreakdown: $taxBreakdown, netPay: $netPay, status: $status, isEdited: $isEdited)';
}


}

/// @nodoc
abstract mixin class _$PayrollCalculationCopyWith<$Res> implements $PayrollCalculationCopyWith<$Res> {
  factory _$PayrollCalculationCopyWith(_PayrollCalculation value, $Res Function(_PayrollCalculation) _then) = __$PayrollCalculationCopyWithImpl;
@override @useResult
$Res call({
 String? id, String workerId, String workerName, double grossSalary, double bonuses, double otherEarnings, double otherDeductions, TaxBreakdown taxBreakdown, double netPay, String status, bool isEdited
});


@override $TaxBreakdownCopyWith<$Res> get taxBreakdown;

}
/// @nodoc
class __$PayrollCalculationCopyWithImpl<$Res>
    implements _$PayrollCalculationCopyWith<$Res> {
  __$PayrollCalculationCopyWithImpl(this._self, this._then);

  final _PayrollCalculation _self;
  final $Res Function(_PayrollCalculation) _then;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? workerId = null,Object? workerName = null,Object? grossSalary = null,Object? bonuses = null,Object? otherEarnings = null,Object? otherDeductions = null,Object? taxBreakdown = null,Object? netPay = null,Object? status = null,Object? isEdited = null,}) {
  return _then(_PayrollCalculation(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,grossSalary: null == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double,bonuses: null == bonuses ? _self.bonuses : bonuses // ignore: cast_nullable_to_non_nullable
as double,otherEarnings: null == otherEarnings ? _self.otherEarnings : otherEarnings // ignore: cast_nullable_to_non_nullable
as double,otherDeductions: null == otherDeductions ? _self.otherDeductions : otherDeductions // ignore: cast_nullable_to_non_nullable
as double,taxBreakdown: null == taxBreakdown ? _self.taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,netPay: null == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxBreakdownCopyWith<$Res> get taxBreakdown {
  
  return $TaxBreakdownCopyWith<$Res>(_self.taxBreakdown, (value) {
    return _then(_self.copyWith(taxBreakdown: value));
  });
}
}


/// @nodoc
mixin _$PayrollRequest {

/// List of worker IDs to calculate payroll for.
 List<String> get workerIds;
/// Create a copy of PayrollRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollRequestCopyWith<PayrollRequest> get copyWith => _$PayrollRequestCopyWithImpl<PayrollRequest>(this as PayrollRequest, _$identity);

  /// Serializes this PayrollRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollRequest&&const DeepCollectionEquality().equals(other.workerIds, workerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(workerIds));

@override
String toString() {
  return 'PayrollRequest(workerIds: $workerIds)';
}


}

/// @nodoc
abstract mixin class $PayrollRequestCopyWith<$Res>  {
  factory $PayrollRequestCopyWith(PayrollRequest value, $Res Function(PayrollRequest) _then) = _$PayrollRequestCopyWithImpl;
@useResult
$Res call({
 List<String> workerIds
});




}
/// @nodoc
class _$PayrollRequestCopyWithImpl<$Res>
    implements $PayrollRequestCopyWith<$Res> {
  _$PayrollRequestCopyWithImpl(this._self, this._then);

  final PayrollRequest _self;
  final $Res Function(PayrollRequest) _then;

/// Create a copy of PayrollRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workerIds = null,}) {
  return _then(_self.copyWith(
workerIds: null == workerIds ? _self.workerIds : workerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollRequest].
extension PayrollRequestPatterns on PayrollRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollRequest value)  $default,){
final _that = this;
switch (_that) {
case _PayrollRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> workerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollRequest() when $default != null:
return $default(_that.workerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> workerIds)  $default,) {final _that = this;
switch (_that) {
case _PayrollRequest():
return $default(_that.workerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> workerIds)?  $default,) {final _that = this;
switch (_that) {
case _PayrollRequest() when $default != null:
return $default(_that.workerIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollRequest extends PayrollRequest {
  const _PayrollRequest({required final  List<String> workerIds}): _workerIds = workerIds,super._();
  factory _PayrollRequest.fromJson(Map<String, dynamic> json) => _$PayrollRequestFromJson(json);

/// List of worker IDs to calculate payroll for.
 final  List<String> _workerIds;
/// List of worker IDs to calculate payroll for.
@override List<String> get workerIds {
  if (_workerIds is EqualUnmodifiableListView) return _workerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workerIds);
}


/// Create a copy of PayrollRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollRequestCopyWith<_PayrollRequest> get copyWith => __$PayrollRequestCopyWithImpl<_PayrollRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollRequest&&const DeepCollectionEquality().equals(other._workerIds, _workerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_workerIds));

@override
String toString() {
  return 'PayrollRequest(workerIds: $workerIds)';
}


}

/// @nodoc
abstract mixin class _$PayrollRequestCopyWith<$Res> implements $PayrollRequestCopyWith<$Res> {
  factory _$PayrollRequestCopyWith(_PayrollRequest value, $Res Function(_PayrollRequest) _then) = __$PayrollRequestCopyWithImpl;
@override @useResult
$Res call({
 List<String> workerIds
});




}
/// @nodoc
class __$PayrollRequestCopyWithImpl<$Res>
    implements _$PayrollRequestCopyWith<$Res> {
  __$PayrollRequestCopyWithImpl(this._self, this._then);

  final _PayrollRequest _self;
  final $Res Function(_PayrollRequest) _then;

/// Create a copy of PayrollRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workerIds = null,}) {
  return _then(_PayrollRequest(
workerIds: null == workerIds ? _self._workerIds : workerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$PayrollSummary {

/// Individual payroll calculations.
 List<PayrollCalculation> get calculations;/// Sum of all gross salaries.
 double get totalGross;/// Sum of all deductions.
 double get totalDeductions;/// Sum of all net pay amounts.
 double get totalNet;
/// Create a copy of PayrollSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollSummaryCopyWith<PayrollSummary> get copyWith => _$PayrollSummaryCopyWithImpl<PayrollSummary>(this as PayrollSummary, _$identity);

  /// Serializes this PayrollSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollSummary&&const DeepCollectionEquality().equals(other.calculations, calculations)&&(identical(other.totalGross, totalGross) || other.totalGross == totalGross)&&(identical(other.totalDeductions, totalDeductions) || other.totalDeductions == totalDeductions)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(calculations),totalGross,totalDeductions,totalNet);

@override
String toString() {
  return 'PayrollSummary(calculations: $calculations, totalGross: $totalGross, totalDeductions: $totalDeductions, totalNet: $totalNet)';
}


}

/// @nodoc
abstract mixin class $PayrollSummaryCopyWith<$Res>  {
  factory $PayrollSummaryCopyWith(PayrollSummary value, $Res Function(PayrollSummary) _then) = _$PayrollSummaryCopyWithImpl;
@useResult
$Res call({
 List<PayrollCalculation> calculations, double totalGross, double totalDeductions, double totalNet
});




}
/// @nodoc
class _$PayrollSummaryCopyWithImpl<$Res>
    implements $PayrollSummaryCopyWith<$Res> {
  _$PayrollSummaryCopyWithImpl(this._self, this._then);

  final PayrollSummary _self;
  final $Res Function(PayrollSummary) _then;

/// Create a copy of PayrollSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calculations = null,Object? totalGross = null,Object? totalDeductions = null,Object? totalNet = null,}) {
  return _then(_self.copyWith(
calculations: null == calculations ? _self.calculations : calculations // ignore: cast_nullable_to_non_nullable
as List<PayrollCalculation>,totalGross: null == totalGross ? _self.totalGross : totalGross // ignore: cast_nullable_to_non_nullable
as double,totalDeductions: null == totalDeductions ? _self.totalDeductions : totalDeductions // ignore: cast_nullable_to_non_nullable
as double,totalNet: null == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PayrollSummary].
extension PayrollSummaryPatterns on PayrollSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayrollSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayrollSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayrollSummary value)  $default,){
final _that = this;
switch (_that) {
case _PayrollSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayrollSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PayrollSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PayrollCalculation> calculations,  double totalGross,  double totalDeductions,  double totalNet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayrollSummary() when $default != null:
return $default(_that.calculations,_that.totalGross,_that.totalDeductions,_that.totalNet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PayrollCalculation> calculations,  double totalGross,  double totalDeductions,  double totalNet)  $default,) {final _that = this;
switch (_that) {
case _PayrollSummary():
return $default(_that.calculations,_that.totalGross,_that.totalDeductions,_that.totalNet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PayrollCalculation> calculations,  double totalGross,  double totalDeductions,  double totalNet)?  $default,) {final _that = this;
switch (_that) {
case _PayrollSummary() when $default != null:
return $default(_that.calculations,_that.totalGross,_that.totalDeductions,_that.totalNet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayrollSummary extends PayrollSummary {
  const _PayrollSummary({required final  List<PayrollCalculation> calculations, required this.totalGross, required this.totalDeductions, required this.totalNet}): _calculations = calculations,super._();
  factory _PayrollSummary.fromJson(Map<String, dynamic> json) => _$PayrollSummaryFromJson(json);

/// Individual payroll calculations.
 final  List<PayrollCalculation> _calculations;
/// Individual payroll calculations.
@override List<PayrollCalculation> get calculations {
  if (_calculations is EqualUnmodifiableListView) return _calculations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_calculations);
}

/// Sum of all gross salaries.
@override final  double totalGross;
/// Sum of all deductions.
@override final  double totalDeductions;
/// Sum of all net pay amounts.
@override final  double totalNet;

/// Create a copy of PayrollSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollSummaryCopyWith<_PayrollSummary> get copyWith => __$PayrollSummaryCopyWithImpl<_PayrollSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollSummary&&const DeepCollectionEquality().equals(other._calculations, _calculations)&&(identical(other.totalGross, totalGross) || other.totalGross == totalGross)&&(identical(other.totalDeductions, totalDeductions) || other.totalDeductions == totalDeductions)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_calculations),totalGross,totalDeductions,totalNet);

@override
String toString() {
  return 'PayrollSummary(calculations: $calculations, totalGross: $totalGross, totalDeductions: $totalDeductions, totalNet: $totalNet)';
}


}

/// @nodoc
abstract mixin class _$PayrollSummaryCopyWith<$Res> implements $PayrollSummaryCopyWith<$Res> {
  factory _$PayrollSummaryCopyWith(_PayrollSummary value, $Res Function(_PayrollSummary) _then) = __$PayrollSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<PayrollCalculation> calculations, double totalGross, double totalDeductions, double totalNet
});




}
/// @nodoc
class __$PayrollSummaryCopyWithImpl<$Res>
    implements _$PayrollSummaryCopyWith<$Res> {
  __$PayrollSummaryCopyWithImpl(this._self, this._then);

  final _PayrollSummary _self;
  final $Res Function(_PayrollSummary) _then;

/// Create a copy of PayrollSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calculations = null,Object? totalGross = null,Object? totalDeductions = null,Object? totalNet = null,}) {
  return _then(_PayrollSummary(
calculations: null == calculations ? _self._calculations : calculations // ignore: cast_nullable_to_non_nullable
as List<PayrollCalculation>,totalGross: null == totalGross ? _self.totalGross : totalGross // ignore: cast_nullable_to_non_nullable
as double,totalDeductions: null == totalDeductions ? _self.totalDeductions : totalDeductions // ignore: cast_nullable_to_non_nullable
as double,totalNet: null == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
