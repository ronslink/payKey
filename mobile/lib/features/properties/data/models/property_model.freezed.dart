// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PropertyModel {

 String get id; String get name; String get address; String get userId; int get geofenceRadius; bool get isActive; double? get latitude; double? get longitude; String? get what3words; int get workerCount;// Computed field often useful in lists
 DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PropertyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyModelCopyWith<PropertyModel> get copyWith => _$PropertyModelCopyWithImpl<PropertyModel>(this as PropertyModel, _$identity);

  /// Serializes this PropertyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,userId,geofenceRadius,isActive,latitude,longitude,what3words,workerCount,createdAt,updatedAt);

@override
String toString() {
  return 'PropertyModel(id: $id, name: $name, address: $address, userId: $userId, geofenceRadius: $geofenceRadius, isActive: $isActive, latitude: $latitude, longitude: $longitude, what3words: $what3words, workerCount: $workerCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PropertyModelCopyWith<$Res>  {
  factory $PropertyModelCopyWith(PropertyModel value, $Res Function(PropertyModel) _then) = _$PropertyModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, String userId, int geofenceRadius, bool isActive, double? latitude, double? longitude, String? what3words, int workerCount, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PropertyModelCopyWithImpl<$Res>
    implements $PropertyModelCopyWith<$Res> {
  _$PropertyModelCopyWithImpl(this._self, this._then);

  final PropertyModel _self;
  final $Res Function(PropertyModel) _then;

/// Create a copy of PropertyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? userId = null,Object? geofenceRadius = null,Object? isActive = null,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,Object? workerCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertyModel].
extension PropertyModelPatterns on PropertyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyModel value)  $default,){
final _that = this;
switch (_that) {
case _PropertyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String userId,  int geofenceRadius,  bool isActive,  double? latitude,  double? longitude,  String? what3words,  int workerCount,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyModel() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.userId,_that.geofenceRadius,_that.isActive,_that.latitude,_that.longitude,_that.what3words,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String userId,  int geofenceRadius,  bool isActive,  double? latitude,  double? longitude,  String? what3words,  int workerCount,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PropertyModel():
return $default(_that.id,_that.name,_that.address,_that.userId,_that.geofenceRadius,_that.isActive,_that.latitude,_that.longitude,_that.what3words,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  String userId,  int geofenceRadius,  bool isActive,  double? latitude,  double? longitude,  String? what3words,  int workerCount,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PropertyModel() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.userId,_that.geofenceRadius,_that.isActive,_that.latitude,_that.longitude,_that.what3words,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertyModel implements PropertyModel {
  const _PropertyModel({required this.id, required this.name, required this.address, required this.userId, this.geofenceRadius = 100, this.isActive = true, this.latitude, this.longitude, this.what3words, this.workerCount = 0, this.createdAt, this.updatedAt});
  factory _PropertyModel.fromJson(Map<String, dynamic> json) => _$PropertyModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String address;
@override final  String userId;
@override@JsonKey() final  int geofenceRadius;
@override@JsonKey() final  bool isActive;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? what3words;
@override@JsonKey() final  int workerCount;
// Computed field often useful in lists
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PropertyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyModelCopyWith<_PropertyModel> get copyWith => __$PropertyModelCopyWithImpl<_PropertyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,userId,geofenceRadius,isActive,latitude,longitude,what3words,workerCount,createdAt,updatedAt);

@override
String toString() {
  return 'PropertyModel(id: $id, name: $name, address: $address, userId: $userId, geofenceRadius: $geofenceRadius, isActive: $isActive, latitude: $latitude, longitude: $longitude, what3words: $what3words, workerCount: $workerCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PropertyModelCopyWith<$Res> implements $PropertyModelCopyWith<$Res> {
  factory _$PropertyModelCopyWith(_PropertyModel value, $Res Function(_PropertyModel) _then) = __$PropertyModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, String userId, int geofenceRadius, bool isActive, double? latitude, double? longitude, String? what3words, int workerCount, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PropertyModelCopyWithImpl<$Res>
    implements _$PropertyModelCopyWith<$Res> {
  __$PropertyModelCopyWithImpl(this._self, this._then);

  final _PropertyModel _self;
  final $Res Function(_PropertyModel) _then;

/// Create a copy of PropertyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? userId = null,Object? geofenceRadius = null,Object? isActive = null,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,Object? workerCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PropertyModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CreatePropertyRequest {

 String get name; String get address; int get geofenceRadius; double? get latitude; double? get longitude; String? get what3words;
/// Create a copy of CreatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePropertyRequestCopyWith<CreatePropertyRequest> get copyWith => _$CreatePropertyRequestCopyWithImpl<CreatePropertyRequest>(this as CreatePropertyRequest, _$identity);

  /// Serializes this CreatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,geofenceRadius,latitude,longitude,what3words);

@override
String toString() {
  return 'CreatePropertyRequest(name: $name, address: $address, geofenceRadius: $geofenceRadius, latitude: $latitude, longitude: $longitude, what3words: $what3words)';
}


}

/// @nodoc
abstract mixin class $CreatePropertyRequestCopyWith<$Res>  {
  factory $CreatePropertyRequestCopyWith(CreatePropertyRequest value, $Res Function(CreatePropertyRequest) _then) = _$CreatePropertyRequestCopyWithImpl;
@useResult
$Res call({
 String name, String address, int geofenceRadius, double? latitude, double? longitude, String? what3words
});




}
/// @nodoc
class _$CreatePropertyRequestCopyWithImpl<$Res>
    implements $CreatePropertyRequestCopyWith<$Res> {
  _$CreatePropertyRequestCopyWithImpl(this._self, this._then);

  final CreatePropertyRequest _self;
  final $Res Function(CreatePropertyRequest) _then;

/// Create a copy of CreatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? address = null,Object? geofenceRadius = null,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatePropertyRequest].
extension CreatePropertyRequestPatterns on CreatePropertyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatePropertyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatePropertyRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreatePropertyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatePropertyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String address,  int geofenceRadius,  double? latitude,  double? longitude,  String? what3words)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String address,  int geofenceRadius,  double? latitude,  double? longitude,  String? what3words)  $default,) {final _that = this;
switch (_that) {
case _CreatePropertyRequest():
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String address,  int geofenceRadius,  double? latitude,  double? longitude,  String? what3words)?  $default,) {final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatePropertyRequest implements CreatePropertyRequest {
  const _CreatePropertyRequest({required this.name, required this.address, this.geofenceRadius = 100, this.latitude, this.longitude, this.what3words});
  factory _CreatePropertyRequest.fromJson(Map<String, dynamic> json) => _$CreatePropertyRequestFromJson(json);

@override final  String name;
@override final  String address;
@override@JsonKey() final  int geofenceRadius;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? what3words;

/// Create a copy of CreatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePropertyRequestCopyWith<_CreatePropertyRequest> get copyWith => __$CreatePropertyRequestCopyWithImpl<_CreatePropertyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatePropertyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,geofenceRadius,latitude,longitude,what3words);

@override
String toString() {
  return 'CreatePropertyRequest(name: $name, address: $address, geofenceRadius: $geofenceRadius, latitude: $latitude, longitude: $longitude, what3words: $what3words)';
}


}

/// @nodoc
abstract mixin class _$CreatePropertyRequestCopyWith<$Res> implements $CreatePropertyRequestCopyWith<$Res> {
  factory _$CreatePropertyRequestCopyWith(_CreatePropertyRequest value, $Res Function(_CreatePropertyRequest) _then) = __$CreatePropertyRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String address, int geofenceRadius, double? latitude, double? longitude, String? what3words
});




}
/// @nodoc
class __$CreatePropertyRequestCopyWithImpl<$Res>
    implements _$CreatePropertyRequestCopyWith<$Res> {
  __$CreatePropertyRequestCopyWithImpl(this._self, this._then);

  final _CreatePropertyRequest _self;
  final $Res Function(_CreatePropertyRequest) _then;

/// Create a copy of CreatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? address = null,Object? geofenceRadius = null,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,}) {
  return _then(_CreatePropertyRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UpdatePropertyRequest {

 String? get name; String? get address; int? get geofenceRadius; double? get latitude; double? get longitude; String? get what3words; bool? get isActive;
/// Create a copy of UpdatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePropertyRequestCopyWith<UpdatePropertyRequest> get copyWith => _$UpdatePropertyRequestCopyWithImpl<UpdatePropertyRequest>(this as UpdatePropertyRequest, _$identity);

  /// Serializes this UpdatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,geofenceRadius,latitude,longitude,what3words,isActive);

@override
String toString() {
  return 'UpdatePropertyRequest(name: $name, address: $address, geofenceRadius: $geofenceRadius, latitude: $latitude, longitude: $longitude, what3words: $what3words, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $UpdatePropertyRequestCopyWith<$Res>  {
  factory $UpdatePropertyRequestCopyWith(UpdatePropertyRequest value, $Res Function(UpdatePropertyRequest) _then) = _$UpdatePropertyRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? address, int? geofenceRadius, double? latitude, double? longitude, String? what3words, bool? isActive
});




}
/// @nodoc
class _$UpdatePropertyRequestCopyWithImpl<$Res>
    implements $UpdatePropertyRequestCopyWith<$Res> {
  _$UpdatePropertyRequestCopyWithImpl(this._self, this._then);

  final UpdatePropertyRequest _self;
  final $Res Function(UpdatePropertyRequest) _then;

/// Create a copy of UpdatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? address = freezed,Object? geofenceRadius = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,Object? isActive = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,geofenceRadius: freezed == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePropertyRequest].
extension UpdatePropertyRequestPatterns on UpdatePropertyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePropertyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePropertyRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePropertyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePropertyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? address,  int? geofenceRadius,  double? latitude,  double? longitude,  String? what3words,  bool? isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? address,  int? geofenceRadius,  double? latitude,  double? longitude,  String? what3words,  bool? isActive)  $default,) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest():
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? address,  int? geofenceRadius,  double? latitude,  double? longitude,  String? what3words,  bool? isActive)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.geofenceRadius,_that.latitude,_that.longitude,_that.what3words,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePropertyRequest implements UpdatePropertyRequest {
  const _UpdatePropertyRequest({this.name, this.address, this.geofenceRadius, this.latitude, this.longitude, this.what3words, this.isActive});
  factory _UpdatePropertyRequest.fromJson(Map<String, dynamic> json) => _$UpdatePropertyRequestFromJson(json);

@override final  String? name;
@override final  String? address;
@override final  int? geofenceRadius;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? what3words;
@override final  bool? isActive;

/// Create a copy of UpdatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePropertyRequestCopyWith<_UpdatePropertyRequest> get copyWith => __$UpdatePropertyRequestCopyWithImpl<_UpdatePropertyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdatePropertyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.what3words, what3words) || other.what3words == what3words)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,geofenceRadius,latitude,longitude,what3words,isActive);

@override
String toString() {
  return 'UpdatePropertyRequest(name: $name, address: $address, geofenceRadius: $geofenceRadius, latitude: $latitude, longitude: $longitude, what3words: $what3words, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$UpdatePropertyRequestCopyWith<$Res> implements $UpdatePropertyRequestCopyWith<$Res> {
  factory _$UpdatePropertyRequestCopyWith(_UpdatePropertyRequest value, $Res Function(_UpdatePropertyRequest) _then) = __$UpdatePropertyRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? address, int? geofenceRadius, double? latitude, double? longitude, String? what3words, bool? isActive
});




}
/// @nodoc
class __$UpdatePropertyRequestCopyWithImpl<$Res>
    implements _$UpdatePropertyRequestCopyWith<$Res> {
  __$UpdatePropertyRequestCopyWithImpl(this._self, this._then);

  final _UpdatePropertyRequest _self;
  final $Res Function(_UpdatePropertyRequest) _then;

/// Create a copy of UpdatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? address = freezed,Object? geofenceRadius = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? what3words = freezed,Object? isActive = freezed,}) {
  return _then(_UpdatePropertyRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,geofenceRadius: freezed == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,what3words: freezed == what3words ? _self.what3words : what3words // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
