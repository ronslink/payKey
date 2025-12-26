// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

@freezed
abstract class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    required String id,
    required String name,
    @JsonKey(fromJson: _parseAddress) required String address,
    required String userId,
    @Default(100) int geofenceRadius,
    @Default(true) bool isActive,
    @JsonKey(fromJson: _parseDouble) double? latitude,
    @JsonKey(fromJson: _parseDouble) double? longitude,
    String? what3words,
    @Default(0) int workerCount, // Computed field often useful in lists
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PropertyModel;

  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);
}

String _parseAddress(dynamic value) {
  if (value is String) return value;
  if (value is Map) {
    // Handle 'lat'/'long' or similar objects by extracting meaningful text if possible
    // or just returning a placeholder.
    if (value.containsKey('name')) return value['name'].toString();
    return 'Location Pin'; 
  }
  return '';
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

@freezed
abstract class CreatePropertyRequest with _$CreatePropertyRequest {
  const factory CreatePropertyRequest({
    required String name,
    required String address,
    @Default(100) int geofenceRadius,
    double? latitude,
    double? longitude,
    String? what3words,
  }) = _CreatePropertyRequest;

  factory CreatePropertyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePropertyRequestFromJson(json);
}

@freezed
abstract class UpdatePropertyRequest with _$UpdatePropertyRequest {
  const factory UpdatePropertyRequest({
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) String? address,
    @JsonKey(includeIfNull: false) int? geofenceRadius,
    @JsonKey(includeIfNull: false) double? latitude,
    @JsonKey(includeIfNull: false) double? longitude,
    @JsonKey(includeIfNull: false) String? what3words,
    @JsonKey(includeIfNull: false) bool? isActive,
  }) = _UpdatePropertyRequest;

  factory UpdatePropertyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePropertyRequestFromJson(json);
}