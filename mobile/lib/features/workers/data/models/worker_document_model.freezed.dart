// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_document_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkerDocument {

 String get id; String get workerId; DocumentType get type; String get name; String get url; int? get fileSize; String? get mimeType; DateTime? get expiresAt; String? get notes; DateTime? get createdAt;
/// Create a copy of WorkerDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerDocumentCopyWith<WorkerDocument> get copyWith => _$WorkerDocumentCopyWithImpl<WorkerDocument>(this as WorkerDocument, _$identity);

  /// Serializes this WorkerDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,type,name,url,fileSize,mimeType,expiresAt,notes,createdAt);

@override
String toString() {
  return 'WorkerDocument(id: $id, workerId: $workerId, type: $type, name: $name, url: $url, fileSize: $fileSize, mimeType: $mimeType, expiresAt: $expiresAt, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WorkerDocumentCopyWith<$Res>  {
  factory $WorkerDocumentCopyWith(WorkerDocument value, $Res Function(WorkerDocument) _then) = _$WorkerDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String workerId, DocumentType type, String name, String url, int? fileSize, String? mimeType, DateTime? expiresAt, String? notes, DateTime? createdAt
});




}
/// @nodoc
class _$WorkerDocumentCopyWithImpl<$Res>
    implements $WorkerDocumentCopyWith<$Res> {
  _$WorkerDocumentCopyWithImpl(this._self, this._then);

  final WorkerDocument _self;
  final $Res Function(WorkerDocument) _then;

/// Create a copy of WorkerDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workerId = null,Object? type = null,Object? name = null,Object? url = null,Object? fileSize = freezed,Object? mimeType = freezed,Object? expiresAt = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerDocument].
extension WorkerDocumentPatterns on WorkerDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerDocument value)  $default,){
final _that = this;
switch (_that) {
case _WorkerDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerDocument value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workerId,  DocumentType type,  String name,  String url,  int? fileSize,  String? mimeType,  DateTime? expiresAt,  String? notes,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerDocument() when $default != null:
return $default(_that.id,_that.workerId,_that.type,_that.name,_that.url,_that.fileSize,_that.mimeType,_that.expiresAt,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workerId,  DocumentType type,  String name,  String url,  int? fileSize,  String? mimeType,  DateTime? expiresAt,  String? notes,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WorkerDocument():
return $default(_that.id,_that.workerId,_that.type,_that.name,_that.url,_that.fileSize,_that.mimeType,_that.expiresAt,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workerId,  DocumentType type,  String name,  String url,  int? fileSize,  String? mimeType,  DateTime? expiresAt,  String? notes,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkerDocument() when $default != null:
return $default(_that.id,_that.workerId,_that.type,_that.name,_that.url,_that.fileSize,_that.mimeType,_that.expiresAt,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkerDocument implements WorkerDocument {
  const _WorkerDocument({required this.id, required this.workerId, required this.type, required this.name, required this.url, this.fileSize, this.mimeType, this.expiresAt, this.notes, this.createdAt});
  factory _WorkerDocument.fromJson(Map<String, dynamic> json) => _$WorkerDocumentFromJson(json);

@override final  String id;
@override final  String workerId;
@override final  DocumentType type;
@override final  String name;
@override final  String url;
@override final  int? fileSize;
@override final  String? mimeType;
@override final  DateTime? expiresAt;
@override final  String? notes;
@override final  DateTime? createdAt;

/// Create a copy of WorkerDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerDocumentCopyWith<_WorkerDocument> get copyWith => __$WorkerDocumentCopyWithImpl<_WorkerDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkerDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workerId,type,name,url,fileSize,mimeType,expiresAt,notes,createdAt);

@override
String toString() {
  return 'WorkerDocument(id: $id, workerId: $workerId, type: $type, name: $name, url: $url, fileSize: $fileSize, mimeType: $mimeType, expiresAt: $expiresAt, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WorkerDocumentCopyWith<$Res> implements $WorkerDocumentCopyWith<$Res> {
  factory _$WorkerDocumentCopyWith(_WorkerDocument value, $Res Function(_WorkerDocument) _then) = __$WorkerDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String workerId, DocumentType type, String name, String url, int? fileSize, String? mimeType, DateTime? expiresAt, String? notes, DateTime? createdAt
});




}
/// @nodoc
class __$WorkerDocumentCopyWithImpl<$Res>
    implements _$WorkerDocumentCopyWith<$Res> {
  __$WorkerDocumentCopyWithImpl(this._self, this._then);

  final _WorkerDocument _self;
  final $Res Function(_WorkerDocument) _then;

/// Create a copy of WorkerDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workerId = null,Object? type = null,Object? name = null,Object? url = null,Object? fileSize = freezed,Object? mimeType = freezed,Object? expiresAt = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_WorkerDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
