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
mixin _$Property {

 String get id; String get userId; String get name; String get address; double? get latitude; double? get longitude; int get geofenceRadius; bool get isActive; int get workerCount; String get createdAt; String get updatedAt;
/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyCopyWith<Property> get copyWith => _$PropertyCopyWithImpl<Property>(this as Property, _$identity);

  /// Serializes this Property to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Property&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,address,latitude,longitude,geofenceRadius,isActive,workerCount,createdAt,updatedAt);

@override
String toString() {
  return 'Property(id: $id, userId: $userId, name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive, workerCount: $workerCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PropertyCopyWith<$Res>  {
  factory $PropertyCopyWith(Property value, $Res Function(Property) _then) = _$PropertyCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, String address, double? latitude, double? longitude, int geofenceRadius, bool isActive, int workerCount, String createdAt, String updatedAt
});




}
/// @nodoc
class _$PropertyCopyWithImpl<$Res>
    implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._self, this._then);

  final Property _self;
  final $Res Function(Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? address = null,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = null,Object? isActive = null,Object? workerCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Property].
extension PropertyPatterns on Property {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Property value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Property() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Property value)  $default,){
final _that = this;
switch (_that) {
case _Property():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Property value)?  $default,){
final _that = this;
switch (_that) {
case _Property() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius,  bool isActive,  int workerCount,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius,  bool isActive,  int workerCount,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Property():
return $default(_that.id,_that.userId,_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius,  bool isActive,  int workerCount,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive,_that.workerCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Property implements Property {
  const _Property({required this.id, required this.userId, required this.name, required this.address, this.latitude, this.longitude, this.geofenceRadius = 100, this.isActive = true, this.workerCount = 0, required this.createdAt, required this.updatedAt});
  factory _Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  String address;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  int geofenceRadius;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  int workerCount;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyCopyWith<_Property> get copyWith => __$PropertyCopyWithImpl<_Property>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Property&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,address,latitude,longitude,geofenceRadius,isActive,workerCount,createdAt,updatedAt);

@override
String toString() {
  return 'Property(id: $id, userId: $userId, name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive, workerCount: $workerCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PropertyCopyWith<$Res> implements $PropertyCopyWith<$Res> {
  factory _$PropertyCopyWith(_Property value, $Res Function(_Property) _then) = __$PropertyCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, String address, double? latitude, double? longitude, int geofenceRadius, bool isActive, int workerCount, String createdAt, String updatedAt
});




}
/// @nodoc
class __$PropertyCopyWithImpl<$Res>
    implements _$PropertyCopyWith<$Res> {
  __$PropertyCopyWithImpl(this._self, this._then);

  final _Property _self;
  final $Res Function(_Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? address = null,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = null,Object? isActive = null,Object? workerCount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Property(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PropertySummary {

 String get id; String get name; String get address; int get workerCount; bool get isActive;
/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertySummaryCopyWith<PropertySummary> get copyWith => _$PropertySummaryCopyWithImpl<PropertySummary>(this as PropertySummary, _$identity);

  /// Serializes this PropertySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,workerCount,isActive);

@override
String toString() {
  return 'PropertySummary(id: $id, name: $name, address: $address, workerCount: $workerCount, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $PropertySummaryCopyWith<$Res>  {
  factory $PropertySummaryCopyWith(PropertySummary value, $Res Function(PropertySummary) _then) = _$PropertySummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, int workerCount, bool isActive
});




}
/// @nodoc
class _$PropertySummaryCopyWithImpl<$Res>
    implements $PropertySummaryCopyWith<$Res> {
  _$PropertySummaryCopyWithImpl(this._self, this._then);

  final PropertySummary _self;
  final $Res Function(PropertySummary) _then;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? workerCount = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertySummary].
extension PropertySummaryPatterns on PropertySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertySummary value)  $default,){
final _that = this;
switch (_that) {
case _PropertySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertySummary value)?  $default,){
final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  int workerCount,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.workerCount,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  int workerCount,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _PropertySummary():
return $default(_that.id,_that.name,_that.address,_that.workerCount,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  int workerCount,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.workerCount,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertySummary implements PropertySummary {
  const _PropertySummary({required this.id, required this.name, required this.address, required this.workerCount, required this.isActive});
  factory _PropertySummary.fromJson(Map<String, dynamic> json) => _$PropertySummaryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String address;
@override final  int workerCount;
@override final  bool isActive;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertySummaryCopyWith<_PropertySummary> get copyWith => __$PropertySummaryCopyWithImpl<_PropertySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.workerCount, workerCount) || other.workerCount == workerCount)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,workerCount,isActive);

@override
String toString() {
  return 'PropertySummary(id: $id, name: $name, address: $address, workerCount: $workerCount, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$PropertySummaryCopyWith<$Res> implements $PropertySummaryCopyWith<$Res> {
  factory _$PropertySummaryCopyWith(_PropertySummary value, $Res Function(_PropertySummary) _then) = __$PropertySummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, int workerCount, bool isActive
});




}
/// @nodoc
class __$PropertySummaryCopyWithImpl<$Res>
    implements _$PropertySummaryCopyWith<$Res> {
  __$PropertySummaryCopyWithImpl(this._self, this._then);

  final _PropertySummary _self;
  final $Res Function(_PropertySummary) _then;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? workerCount = null,Object? isActive = null,}) {
  return _then(_PropertySummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,workerCount: null == workerCount ? _self.workerCount : workerCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CreatePropertyRequest {

 String get name; String get address; double? get latitude; double? get longitude; int get geofenceRadius;
/// Create a copy of CreatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePropertyRequestCopyWith<CreatePropertyRequest> get copyWith => _$CreatePropertyRequestCopyWithImpl<CreatePropertyRequest>(this as CreatePropertyRequest, _$identity);

  /// Serializes this CreatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,geofenceRadius);

@override
String toString() {
  return 'CreatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius)';
}


}

/// @nodoc
abstract mixin class $CreatePropertyRequestCopyWith<$Res>  {
  factory $CreatePropertyRequestCopyWith(CreatePropertyRequest value, $Res Function(CreatePropertyRequest) _then) = _$CreatePropertyRequestCopyWithImpl;
@useResult
$Res call({
 String name, String address, double? latitude, double? longitude, int geofenceRadius
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? address = null,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius)  $default,) {final _that = this;
switch (_that) {
case _CreatePropertyRequest():
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String address,  double? latitude,  double? longitude,  int geofenceRadius)?  $default,) {final _that = this;
switch (_that) {
case _CreatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatePropertyRequest implements CreatePropertyRequest {
  const _CreatePropertyRequest({required this.name, required this.address, this.latitude, this.longitude, this.geofenceRadius = 100});
  factory _CreatePropertyRequest.fromJson(Map<String, dynamic> json) => _$CreatePropertyRequestFromJson(json);

@override final  String name;
@override final  String address;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  int geofenceRadius;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,geofenceRadius);

@override
String toString() {
  return 'CreatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius)';
}


}

/// @nodoc
abstract mixin class _$CreatePropertyRequestCopyWith<$Res> implements $CreatePropertyRequestCopyWith<$Res> {
  factory _$CreatePropertyRequestCopyWith(_CreatePropertyRequest value, $Res Function(_CreatePropertyRequest) _then) = __$CreatePropertyRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, String address, double? latitude, double? longitude, int geofenceRadius
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? address = null,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = null,}) {
  return _then(_CreatePropertyRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: null == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UpdatePropertyRequest {

 String? get name; String? get address; double? get latitude; double? get longitude; int? get geofenceRadius; bool? get isActive;
/// Create a copy of UpdatePropertyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePropertyRequestCopyWith<UpdatePropertyRequest> get copyWith => _$UpdatePropertyRequestCopyWithImpl<UpdatePropertyRequest>(this as UpdatePropertyRequest, _$identity);

  /// Serializes this UpdatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,geofenceRadius,isActive);

@override
String toString() {
  return 'UpdatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $UpdatePropertyRequestCopyWith<$Res>  {
  factory $UpdatePropertyRequestCopyWith(UpdatePropertyRequest value, $Res Function(UpdatePropertyRequest) _then) = _$UpdatePropertyRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? address, double? latitude, double? longitude, int? geofenceRadius, bool? isActive
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? address = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = freezed,Object? isActive = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: freezed == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? address,  double? latitude,  double? longitude,  int? geofenceRadius,  bool? isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? address,  double? latitude,  double? longitude,  int? geofenceRadius,  bool? isActive)  $default,) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest():
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? address,  double? latitude,  double? longitude,  int? geofenceRadius,  bool? isActive)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePropertyRequest() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.geofenceRadius,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePropertyRequest implements UpdatePropertyRequest {
  const _UpdatePropertyRequest({this.name, this.address, this.latitude, this.longitude, this.geofenceRadius, this.isActive});
  factory _UpdatePropertyRequest.fromJson(Map<String, dynamic> json) => _$UpdatePropertyRequestFromJson(json);

@override final  String? name;
@override final  String? address;
@override final  double? latitude;
@override final  double? longitude;
@override final  int? geofenceRadius;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePropertyRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geofenceRadius, geofenceRadius) || other.geofenceRadius == geofenceRadius)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,geofenceRadius,isActive);

@override
String toString() {
  return 'UpdatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$UpdatePropertyRequestCopyWith<$Res> implements $UpdatePropertyRequestCopyWith<$Res> {
  factory _$UpdatePropertyRequestCopyWith(_UpdatePropertyRequest value, $Res Function(_UpdatePropertyRequest) _then) = __$UpdatePropertyRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? address, double? latitude, double? longitude, int? geofenceRadius, bool? isActive
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? address = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? geofenceRadius = freezed,Object? isActive = freezed,}) {
  return _then(_UpdatePropertyRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geofenceRadius: freezed == geofenceRadius ? _self.geofenceRadius : geofenceRadius // ignore: cast_nullable_to_non_nullable
as int?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
