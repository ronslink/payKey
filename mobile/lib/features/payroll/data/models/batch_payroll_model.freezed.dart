// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch_payroll_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkerPayrollResult {

 String get workerId; String get workerName; bool get success; double? get grossSalary; double? get netPay; String? get transactionId; String? get error;
/// Create a copy of WorkerPayrollResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerPayrollResultCopyWith<WorkerPayrollResult> get copyWith => _$WorkerPayrollResultCopyWithImpl<WorkerPayrollResult>(this as WorkerPayrollResult, _$identity);

  /// Serializes this WorkerPayrollResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerPayrollResult&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.success, success) || other.success == success)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,workerName,success,grossSalary,netPay,transactionId,error);

@override
String toString() {
  return 'WorkerPayrollResult(workerId: $workerId, workerName: $workerName, success: $success, grossSalary: $grossSalary, netPay: $netPay, transactionId: $transactionId, error: $error)';
}


}

/// @nodoc
abstract mixin class $WorkerPayrollResultCopyWith<$Res>  {
  factory $WorkerPayrollResultCopyWith(WorkerPayrollResult value, $Res Function(WorkerPayrollResult) _then) = _$WorkerPayrollResultCopyWithImpl;
@useResult
$Res call({
 String workerId, String workerName, bool success, double? grossSalary, double? netPay, String? transactionId, String? error
});




}
/// @nodoc
class _$WorkerPayrollResultCopyWithImpl<$Res>
    implements $WorkerPayrollResultCopyWith<$Res> {
  _$WorkerPayrollResultCopyWithImpl(this._self, this._then);

  final WorkerPayrollResult _self;
  final $Res Function(WorkerPayrollResult) _then;

/// Create a copy of WorkerPayrollResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workerId = null,Object? workerName = null,Object? success = null,Object? grossSalary = freezed,Object? netPay = freezed,Object? transactionId = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,grossSalary: freezed == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double?,netPay: freezed == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double?,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerPayrollResult].
extension WorkerPayrollResultPatterns on WorkerPayrollResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerPayrollResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerPayrollResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerPayrollResult value)  $default,){
final _that = this;
switch (_that) {
case _WorkerPayrollResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerPayrollResult value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerPayrollResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workerId,  String workerName,  bool success,  double? grossSalary,  double? netPay,  String? transactionId,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerPayrollResult() when $default != null:
return $default(_that.workerId,_that.workerName,_that.success,_that.grossSalary,_that.netPay,_that.transactionId,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workerId,  String workerName,  bool success,  double? grossSalary,  double? netPay,  String? transactionId,  String? error)  $default,) {final _that = this;
switch (_that) {
case _WorkerPayrollResult():
return $default(_that.workerId,_that.workerName,_that.success,_that.grossSalary,_that.netPay,_that.transactionId,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workerId,  String workerName,  bool success,  double? grossSalary,  double? netPay,  String? transactionId,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _WorkerPayrollResult() when $default != null:
return $default(_that.workerId,_that.workerName,_that.success,_that.grossSalary,_that.netPay,_that.transactionId,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkerPayrollResult implements WorkerPayrollResult {
  const _WorkerPayrollResult({required this.workerId, required this.workerName, required this.success, this.grossSalary, this.netPay, this.transactionId, this.error});
  factory _WorkerPayrollResult.fromJson(Map<String, dynamic> json) => _$WorkerPayrollResultFromJson(json);

@override final  String workerId;
@override final  String workerName;
@override final  bool success;
@override final  double? grossSalary;
@override final  double? netPay;
@override final  String? transactionId;
@override final  String? error;

/// Create a copy of WorkerPayrollResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerPayrollResultCopyWith<_WorkerPayrollResult> get copyWith => __$WorkerPayrollResultCopyWithImpl<_WorkerPayrollResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkerPayrollResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerPayrollResult&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.success, success) || other.success == success)&&(identical(other.grossSalary, grossSalary) || other.grossSalary == grossSalary)&&(identical(other.netPay, netPay) || other.netPay == netPay)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workerId,workerName,success,grossSalary,netPay,transactionId,error);

@override
String toString() {
  return 'WorkerPayrollResult(workerId: $workerId, workerName: $workerName, success: $success, grossSalary: $grossSalary, netPay: $netPay, transactionId: $transactionId, error: $error)';
}


}

/// @nodoc
abstract mixin class _$WorkerPayrollResultCopyWith<$Res> implements $WorkerPayrollResultCopyWith<$Res> {
  factory _$WorkerPayrollResultCopyWith(_WorkerPayrollResult value, $Res Function(_WorkerPayrollResult) _then) = __$WorkerPayrollResultCopyWithImpl;
@override @useResult
$Res call({
 String workerId, String workerName, bool success, double? grossSalary, double? netPay, String? transactionId, String? error
});




}
/// @nodoc
class __$WorkerPayrollResultCopyWithImpl<$Res>
    implements _$WorkerPayrollResultCopyWith<$Res> {
  __$WorkerPayrollResultCopyWithImpl(this._self, this._then);

  final _WorkerPayrollResult _self;
  final $Res Function(_WorkerPayrollResult) _then;

/// Create a copy of WorkerPayrollResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workerId = null,Object? workerName = null,Object? success = null,Object? grossSalary = freezed,Object? netPay = freezed,Object? transactionId = freezed,Object? error = freezed,}) {
  return _then(_WorkerPayrollResult(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,grossSalary: freezed == grossSalary ? _self.grossSalary : grossSalary // ignore: cast_nullable_to_non_nullable
as double?,netPay: freezed == netPay ? _self.netPay : netPay // ignore: cast_nullable_to_non_nullable
as double?,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BatchPayrollResult {

 int get totalWorkers; int get successCount; int get failureCount; double get totalGross; double get totalNet; List<WorkerPayrollResult> get results; String get processedAt;
/// Create a copy of BatchPayrollResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchPayrollResultCopyWith<BatchPayrollResult> get copyWith => _$BatchPayrollResultCopyWithImpl<BatchPayrollResult>(this as BatchPayrollResult, _$identity);

  /// Serializes this BatchPayrollResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchPayrollResult&&(identical(other.totalWorkers, totalWorkers) || other.totalWorkers == totalWorkers)&&(identical(other.successCount, successCount) || other.successCount == successCount)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.totalGross, totalGross) || other.totalGross == totalGross)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalWorkers,successCount,failureCount,totalGross,totalNet,const DeepCollectionEquality().hash(results),processedAt);

@override
String toString() {
  return 'BatchPayrollResult(totalWorkers: $totalWorkers, successCount: $successCount, failureCount: $failureCount, totalGross: $totalGross, totalNet: $totalNet, results: $results, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class $BatchPayrollResultCopyWith<$Res>  {
  factory $BatchPayrollResultCopyWith(BatchPayrollResult value, $Res Function(BatchPayrollResult) _then) = _$BatchPayrollResultCopyWithImpl;
@useResult
$Res call({
 int totalWorkers, int successCount, int failureCount, double totalGross, double totalNet, List<WorkerPayrollResult> results, String processedAt
});




}
/// @nodoc
class _$BatchPayrollResultCopyWithImpl<$Res>
    implements $BatchPayrollResultCopyWith<$Res> {
  _$BatchPayrollResultCopyWithImpl(this._self, this._then);

  final BatchPayrollResult _self;
  final $Res Function(BatchPayrollResult) _then;

/// Create a copy of BatchPayrollResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalWorkers = null,Object? successCount = null,Object? failureCount = null,Object? totalGross = null,Object? totalNet = null,Object? results = null,Object? processedAt = null,}) {
  return _then(_self.copyWith(
totalWorkers: null == totalWorkers ? _self.totalWorkers : totalWorkers // ignore: cast_nullable_to_non_nullable
as int,successCount: null == successCount ? _self.successCount : successCount // ignore: cast_nullable_to_non_nullable
as int,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,totalGross: null == totalGross ? _self.totalGross : totalGross // ignore: cast_nullable_to_non_nullable
as double,totalNet: null == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as double,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<WorkerPayrollResult>,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchPayrollResult].
extension BatchPayrollResultPatterns on BatchPayrollResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchPayrollResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchPayrollResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchPayrollResult value)  $default,){
final _that = this;
switch (_that) {
case _BatchPayrollResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchPayrollResult value)?  $default,){
final _that = this;
switch (_that) {
case _BatchPayrollResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalWorkers,  int successCount,  int failureCount,  double totalGross,  double totalNet,  List<WorkerPayrollResult> results,  String processedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchPayrollResult() when $default != null:
return $default(_that.totalWorkers,_that.successCount,_that.failureCount,_that.totalGross,_that.totalNet,_that.results,_that.processedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalWorkers,  int successCount,  int failureCount,  double totalGross,  double totalNet,  List<WorkerPayrollResult> results,  String processedAt)  $default,) {final _that = this;
switch (_that) {
case _BatchPayrollResult():
return $default(_that.totalWorkers,_that.successCount,_that.failureCount,_that.totalGross,_that.totalNet,_that.results,_that.processedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalWorkers,  int successCount,  int failureCount,  double totalGross,  double totalNet,  List<WorkerPayrollResult> results,  String processedAt)?  $default,) {final _that = this;
switch (_that) {
case _BatchPayrollResult() when $default != null:
return $default(_that.totalWorkers,_that.successCount,_that.failureCount,_that.totalGross,_that.totalNet,_that.results,_that.processedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BatchPayrollResult implements BatchPayrollResult {
  const _BatchPayrollResult({required this.totalWorkers, required this.successCount, required this.failureCount, required this.totalGross, required this.totalNet, required final  List<WorkerPayrollResult> results, required this.processedAt}): _results = results;
  factory _BatchPayrollResult.fromJson(Map<String, dynamic> json) => _$BatchPayrollResultFromJson(json);

@override final  int totalWorkers;
@override final  int successCount;
@override final  int failureCount;
@override final  double totalGross;
@override final  double totalNet;
 final  List<WorkerPayrollResult> _results;
@override List<WorkerPayrollResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  String processedAt;

/// Create a copy of BatchPayrollResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchPayrollResultCopyWith<_BatchPayrollResult> get copyWith => __$BatchPayrollResultCopyWithImpl<_BatchPayrollResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchPayrollResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchPayrollResult&&(identical(other.totalWorkers, totalWorkers) || other.totalWorkers == totalWorkers)&&(identical(other.successCount, successCount) || other.successCount == successCount)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.totalGross, totalGross) || other.totalGross == totalGross)&&(identical(other.totalNet, totalNet) || other.totalNet == totalNet)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalWorkers,successCount,failureCount,totalGross,totalNet,const DeepCollectionEquality().hash(_results),processedAt);

@override
String toString() {
  return 'BatchPayrollResult(totalWorkers: $totalWorkers, successCount: $successCount, failureCount: $failureCount, totalGross: $totalGross, totalNet: $totalNet, results: $results, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class _$BatchPayrollResultCopyWith<$Res> implements $BatchPayrollResultCopyWith<$Res> {
  factory _$BatchPayrollResultCopyWith(_BatchPayrollResult value, $Res Function(_BatchPayrollResult) _then) = __$BatchPayrollResultCopyWithImpl;
@override @useResult
$Res call({
 int totalWorkers, int successCount, int failureCount, double totalGross, double totalNet, List<WorkerPayrollResult> results, String processedAt
});




}
/// @nodoc
class __$BatchPayrollResultCopyWithImpl<$Res>
    implements _$BatchPayrollResultCopyWith<$Res> {
  __$BatchPayrollResultCopyWithImpl(this._self, this._then);

  final _BatchPayrollResult _self;
  final $Res Function(_BatchPayrollResult) _then;

/// Create a copy of BatchPayrollResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalWorkers = null,Object? successCount = null,Object? failureCount = null,Object? totalGross = null,Object? totalNet = null,Object? results = null,Object? processedAt = null,}) {
  return _then(_BatchPayrollResult(
totalWorkers: null == totalWorkers ? _self.totalWorkers : totalWorkers // ignore: cast_nullable_to_non_nullable
as int,successCount: null == successCount ? _self.successCount : successCount // ignore: cast_nullable_to_non_nullable
as int,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,totalGross: null == totalGross ? _self.totalGross : totalGross // ignore: cast_nullable_to_non_nullable
as double,totalNet: null == totalNet ? _self.totalNet : totalNet // ignore: cast_nullable_to_non_nullable
as double,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<WorkerPayrollResult>,processedAt: null == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
