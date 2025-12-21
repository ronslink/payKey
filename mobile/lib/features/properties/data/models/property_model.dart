import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

/// Represents a property/location where workers can be assigned.
@freezed
abstract class Property with _$Property {
  const factory Property({
    required String id,
    required String userId,
    required String name,
    required String address,
    double? latitude,
    double? longitude,
    @Default(100) int geofenceRadius,
    @Default(true) bool isActive,
    @Default(0) int workerCount,
    required String createdAt,
    required String updatedAt,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

/// Lightweight summary of a property for list views.
@freezed
abstract class PropertySummary with _$PropertySummary {
  const factory PropertySummary({
    required String id,
    required String name,
    required String address,
    required int workerCount,
    required bool isActive,
  }) = _PropertySummary;

  factory PropertySummary.fromJson(Map<String, dynamic> json) =>
      _$PropertySummaryFromJson(json);
}

/// Request payload for creating a new property.
@freezed
abstract class CreatePropertyRequest with _$CreatePropertyRequest {
  const factory CreatePropertyRequest({
    required String name,
    required String address,
    double? latitude,
    double? longitude,
    @Default(100) int geofenceRadius,
  }) = _CreatePropertyRequest;

  factory CreatePropertyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePropertyRequestFromJson(json);
}

/// Request payload for updating an existing property.
@freezed
abstract class UpdatePropertyRequest with _$UpdatePropertyRequest {
  const factory UpdatePropertyRequest({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? geofenceRadius,
    bool? isActive,
  }) = _UpdatePropertyRequest;

  factory UpdatePropertyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePropertyRequestFromJson(json);
}