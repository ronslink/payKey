// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Property _$PropertyFromJson(Map<String, dynamic> json) {
  return _Property.fromJson(json);
}

/// @nodoc
mixin _$Property {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int get geofenceRadius => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int get workerCount => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Property to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Property
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyCopyWith<Property> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyCopyWith<$Res> {
  factory $PropertyCopyWith(Property value, $Res Function(Property) then) =
      _$PropertyCopyWithImpl<$Res, Property>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String address,
    double? latitude,
    double? longitude,
    int geofenceRadius,
    bool isActive,
    int workerCount,
    String createdAt,
    String updatedAt,
  });
}

/// @nodoc
class _$PropertyCopyWithImpl<$Res, $Val extends Property>
    implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Property
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = null,
    Object? isActive = null,
    Object? workerCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            geofenceRadius: null == geofenceRadius
                ? _value.geofenceRadius
                : geofenceRadius // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            workerCount: null == workerCount
                ? _value.workerCount
                : workerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertyImplCopyWith<$Res>
    implements $PropertyCopyWith<$Res> {
  factory _$$PropertyImplCopyWith(
    _$PropertyImpl value,
    $Res Function(_$PropertyImpl) then,
  ) = __$$PropertyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    String address,
    double? latitude,
    double? longitude,
    int geofenceRadius,
    bool isActive,
    int workerCount,
    String createdAt,
    String updatedAt,
  });
}

/// @nodoc
class __$$PropertyImplCopyWithImpl<$Res>
    extends _$PropertyCopyWithImpl<$Res, _$PropertyImpl>
    implements _$$PropertyImplCopyWith<$Res> {
  __$$PropertyImplCopyWithImpl(
    _$PropertyImpl _value,
    $Res Function(_$PropertyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Property
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = null,
    Object? isActive = null,
    Object? workerCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PropertyImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        geofenceRadius: null == geofenceRadius
            ? _value.geofenceRadius
            : geofenceRadius // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        workerCount: null == workerCount
            ? _value.workerCount
            : workerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertyImpl implements _Property {
  const _$PropertyImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadius = 100,
    this.isActive = true,
    this.workerCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$PropertyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertyImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String address;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final int geofenceRadius;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final int workerCount;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'Property(id: $id, userId: $userId, name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive, workerCount: $workerCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.geofenceRadius, geofenceRadius) ||
                other.geofenceRadius == geofenceRadius) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.workerCount, workerCount) ||
                other.workerCount == workerCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    address,
    latitude,
    longitude,
    geofenceRadius,
    isActive,
    workerCount,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Property
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyImplCopyWith<_$PropertyImpl> get copyWith =>
      __$$PropertyImplCopyWithImpl<_$PropertyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertyImplToJson(this);
  }
}

abstract class _Property implements Property {
  const factory _Property({
    required final String id,
    required final String userId,
    required final String name,
    required final String address,
    final double? latitude,
    final double? longitude,
    final int geofenceRadius,
    final bool isActive,
    final int workerCount,
    required final String createdAt,
    required final String updatedAt,
  }) = _$PropertyImpl;

  factory _Property.fromJson(Map<String, dynamic> json) =
      _$PropertyImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get address;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int get geofenceRadius;
  @override
  bool get isActive;
  @override
  int get workerCount;
  @override
  String get createdAt;
  @override
  String get updatedAt;

  /// Create a copy of Property
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyImplCopyWith<_$PropertyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PropertySummary _$PropertySummaryFromJson(Map<String, dynamic> json) {
  return _PropertySummary.fromJson(json);
}

/// @nodoc
mixin _$PropertySummary {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  int get workerCount => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this PropertySummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PropertySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertySummaryCopyWith<PropertySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertySummaryCopyWith<$Res> {
  factory $PropertySummaryCopyWith(
    PropertySummary value,
    $Res Function(PropertySummary) then,
  ) = _$PropertySummaryCopyWithImpl<$Res, PropertySummary>;
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    int workerCount,
    bool isActive,
  });
}

/// @nodoc
class _$PropertySummaryCopyWithImpl<$Res, $Val extends PropertySummary>
    implements $PropertySummaryCopyWith<$Res> {
  _$PropertySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? workerCount = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            workerCount: null == workerCount
                ? _value.workerCount
                : workerCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertySummaryImplCopyWith<$Res>
    implements $PropertySummaryCopyWith<$Res> {
  factory _$$PropertySummaryImplCopyWith(
    _$PropertySummaryImpl value,
    $Res Function(_$PropertySummaryImpl) then,
  ) = __$$PropertySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    int workerCount,
    bool isActive,
  });
}

/// @nodoc
class __$$PropertySummaryImplCopyWithImpl<$Res>
    extends _$PropertySummaryCopyWithImpl<$Res, _$PropertySummaryImpl>
    implements _$$PropertySummaryImplCopyWith<$Res> {
  __$$PropertySummaryImplCopyWithImpl(
    _$PropertySummaryImpl _value,
    $Res Function(_$PropertySummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? workerCount = null,
    Object? isActive = null,
  }) {
    return _then(
      _$PropertySummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        workerCount: null == workerCount
            ? _value.workerCount
            : workerCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertySummaryImpl implements _PropertySummary {
  const _$PropertySummaryImpl({
    required this.id,
    required this.name,
    required this.address,
    required this.workerCount,
    required this.isActive,
  });

  factory _$PropertySummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertySummaryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String address;
  @override
  final int workerCount;
  @override
  final bool isActive;

  @override
  String toString() {
    return 'PropertySummary(id: $id, name: $name, address: $address, workerCount: $workerCount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertySummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.workerCount, workerCount) ||
                other.workerCount == workerCount) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, address, workerCount, isActive);

  /// Create a copy of PropertySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertySummaryImplCopyWith<_$PropertySummaryImpl> get copyWith =>
      __$$PropertySummaryImplCopyWithImpl<_$PropertySummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertySummaryImplToJson(this);
  }
}

abstract class _PropertySummary implements PropertySummary {
  const factory _PropertySummary({
    required final String id,
    required final String name,
    required final String address,
    required final int workerCount,
    required final bool isActive,
  }) = _$PropertySummaryImpl;

  factory _PropertySummary.fromJson(Map<String, dynamic> json) =
      _$PropertySummaryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get address;
  @override
  int get workerCount;
  @override
  bool get isActive;

  /// Create a copy of PropertySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertySummaryImplCopyWith<_$PropertySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatePropertyRequest _$CreatePropertyRequestFromJson(
  Map<String, dynamic> json,
) {
  return _CreatePropertyRequest.fromJson(json);
}

/// @nodoc
mixin _$CreatePropertyRequest {
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int get geofenceRadius => throw _privateConstructorUsedError;

  /// Serializes this CreatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatePropertyRequestCopyWith<CreatePropertyRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatePropertyRequestCopyWith<$Res> {
  factory $CreatePropertyRequestCopyWith(
    CreatePropertyRequest value,
    $Res Function(CreatePropertyRequest) then,
  ) = _$CreatePropertyRequestCopyWithImpl<$Res, CreatePropertyRequest>;
  @useResult
  $Res call({
    String name,
    String address,
    double? latitude,
    double? longitude,
    int geofenceRadius,
  });
}

/// @nodoc
class _$CreatePropertyRequestCopyWithImpl<
  $Res,
  $Val extends CreatePropertyRequest
>
    implements $CreatePropertyRequestCopyWith<$Res> {
  _$CreatePropertyRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            geofenceRadius: null == geofenceRadius
                ? _value.geofenceRadius
                : geofenceRadius // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatePropertyRequestImplCopyWith<$Res>
    implements $CreatePropertyRequestCopyWith<$Res> {
  factory _$$CreatePropertyRequestImplCopyWith(
    _$CreatePropertyRequestImpl value,
    $Res Function(_$CreatePropertyRequestImpl) then,
  ) = __$$CreatePropertyRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String address,
    double? latitude,
    double? longitude,
    int geofenceRadius,
  });
}

/// @nodoc
class __$$CreatePropertyRequestImplCopyWithImpl<$Res>
    extends
        _$CreatePropertyRequestCopyWithImpl<$Res, _$CreatePropertyRequestImpl>
    implements _$$CreatePropertyRequestImplCopyWith<$Res> {
  __$$CreatePropertyRequestImplCopyWithImpl(
    _$CreatePropertyRequestImpl _value,
    $Res Function(_$CreatePropertyRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? address = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = null,
  }) {
    return _then(
      _$CreatePropertyRequestImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        geofenceRadius: null == geofenceRadius
            ? _value.geofenceRadius
            : geofenceRadius // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatePropertyRequestImpl implements _CreatePropertyRequest {
  const _$CreatePropertyRequestImpl({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadius = 100,
  });

  factory _$CreatePropertyRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatePropertyRequestImplFromJson(json);

  @override
  final String name;
  @override
  final String address;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final int geofenceRadius;

  @override
  String toString() {
    return 'CreatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatePropertyRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.geofenceRadius, geofenceRadius) ||
                other.geofenceRadius == geofenceRadius));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    address,
    latitude,
    longitude,
    geofenceRadius,
  );

  /// Create a copy of CreatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatePropertyRequestImplCopyWith<_$CreatePropertyRequestImpl>
  get copyWith =>
      __$$CreatePropertyRequestImplCopyWithImpl<_$CreatePropertyRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatePropertyRequestImplToJson(this);
  }
}

abstract class _CreatePropertyRequest implements CreatePropertyRequest {
  const factory _CreatePropertyRequest({
    required final String name,
    required final String address,
    final double? latitude,
    final double? longitude,
    final int geofenceRadius,
  }) = _$CreatePropertyRequestImpl;

  factory _CreatePropertyRequest.fromJson(Map<String, dynamic> json) =
      _$CreatePropertyRequestImpl.fromJson;

  @override
  String get name;
  @override
  String get address;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int get geofenceRadius;

  /// Create a copy of CreatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatePropertyRequestImplCopyWith<_$CreatePropertyRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

UpdatePropertyRequest _$UpdatePropertyRequestFromJson(
  Map<String, dynamic> json,
) {
  return _UpdatePropertyRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdatePropertyRequest {
  String? get name => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  int? get geofenceRadius => throw _privateConstructorUsedError;
  bool? get isActive => throw _privateConstructorUsedError;

  /// Serializes this UpdatePropertyRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdatePropertyRequestCopyWith<UpdatePropertyRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdatePropertyRequestCopyWith<$Res> {
  factory $UpdatePropertyRequestCopyWith(
    UpdatePropertyRequest value,
    $Res Function(UpdatePropertyRequest) then,
  ) = _$UpdatePropertyRequestCopyWithImpl<$Res, UpdatePropertyRequest>;
  @useResult
  $Res call({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? geofenceRadius,
    bool? isActive,
  });
}

/// @nodoc
class _$UpdatePropertyRequestCopyWithImpl<
  $Res,
  $Val extends UpdatePropertyRequest
>
    implements $UpdatePropertyRequestCopyWith<$Res> {
  _$UpdatePropertyRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = freezed,
    Object? isActive = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            geofenceRadius: freezed == geofenceRadius
                ? _value.geofenceRadius
                : geofenceRadius // ignore: cast_nullable_to_non_nullable
                      as int?,
            isActive: freezed == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdatePropertyRequestImplCopyWith<$Res>
    implements $UpdatePropertyRequestCopyWith<$Res> {
  factory _$$UpdatePropertyRequestImplCopyWith(
    _$UpdatePropertyRequestImpl value,
    $Res Function(_$UpdatePropertyRequestImpl) then,
  ) = __$$UpdatePropertyRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? geofenceRadius,
    bool? isActive,
  });
}

/// @nodoc
class __$$UpdatePropertyRequestImplCopyWithImpl<$Res>
    extends
        _$UpdatePropertyRequestCopyWithImpl<$Res, _$UpdatePropertyRequestImpl>
    implements _$$UpdatePropertyRequestImplCopyWith<$Res> {
  __$$UpdatePropertyRequestImplCopyWithImpl(
    _$UpdatePropertyRequestImpl _value,
    $Res Function(_$UpdatePropertyRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? geofenceRadius = freezed,
    Object? isActive = freezed,
  }) {
    return _then(
      _$UpdatePropertyRequestImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        geofenceRadius: freezed == geofenceRadius
            ? _value.geofenceRadius
            : geofenceRadius // ignore: cast_nullable_to_non_nullable
                  as int?,
        isActive: freezed == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdatePropertyRequestImpl implements _UpdatePropertyRequest {
  const _$UpdatePropertyRequestImpl({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadius,
    this.isActive,
  });

  factory _$UpdatePropertyRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdatePropertyRequestImplFromJson(json);

  @override
  final String? name;
  @override
  final String? address;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final int? geofenceRadius;
  @override
  final bool? isActive;

  @override
  String toString() {
    return 'UpdatePropertyRequest(name: $name, address: $address, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdatePropertyRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.geofenceRadius, geofenceRadius) ||
                other.geofenceRadius == geofenceRadius) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    address,
    latitude,
    longitude,
    geofenceRadius,
    isActive,
  );

  /// Create a copy of UpdatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdatePropertyRequestImplCopyWith<_$UpdatePropertyRequestImpl>
  get copyWith =>
      __$$UpdatePropertyRequestImplCopyWithImpl<_$UpdatePropertyRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdatePropertyRequestImplToJson(this);
  }
}

abstract class _UpdatePropertyRequest implements UpdatePropertyRequest {
  const factory _UpdatePropertyRequest({
    final String? name,
    final String? address,
    final double? latitude,
    final double? longitude,
    final int? geofenceRadius,
    final bool? isActive,
  }) = _$UpdatePropertyRequestImpl;

  factory _UpdatePropertyRequest.fromJson(Map<String, dynamic> json) =
      _$UpdatePropertyRequestImpl.fromJson;

  @override
  String? get name;
  @override
  String? get address;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  int? get geofenceRadius;
  @override
  bool? get isActive;

  /// Create a copy of UpdatePropertyRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePropertyRequestImplCopyWith<_$UpdatePropertyRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
