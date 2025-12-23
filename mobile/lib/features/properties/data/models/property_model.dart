import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

@freezed
abstract class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    required String id,
    required String name,
    required String address,
    required String userId,
    @Default(100) int geofenceRadius,
    @Default(true) bool isActive,
    double? latitude,
    double? longitude,
    String? what3words,
    @Default(0) int workerCount, // Computed field often useful in lists
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PropertyModel;

  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);
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
    String? name,
    String? address,
    int? geofenceRadius,
    double? latitude,
    double? longitude,
    String? what3words,
    bool? isActive,
  }) = _UpdatePropertyRequest;

  factory UpdatePropertyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePropertyRequestFromJson(json);
}