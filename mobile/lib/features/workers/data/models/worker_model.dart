import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker_model.freezed.dart';
part 'worker_model.g.dart';

@freezed
abstract class WorkerModel with _$WorkerModel {
  const factory WorkerModel({
    required String id,
    required String name,
    required String phoneNumber,
    required double salaryGross,
    DateTime? startDate,
    DateTime? dateOfBirth,
    required bool isActive,
    @Default('FIXED') String employmentType,
    double? hourlyRate,
    String? propertyId,
    String? email,
    String? idNumber,
    String? kraPin,
    String? nssfNumber,
    String? nhifNumber,
    String? jobTitle,
    @Default(0.0) double housingAllowance,
    @Default(0.0) double transportAllowance,
    @Default('MONTHLY') String paymentFrequency,
    @Default('MPESA') String paymentMethod,
    String? mpesaNumber,
    String? bankName,
    String? bankAccount,
    String? notes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    DateTime? terminatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkerModel;

  factory WorkerModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerModelFromJson(json);
}

@freezed
abstract class CreateWorkerRequest with _$CreateWorkerRequest {
  const factory CreateWorkerRequest({
    required String name,
    required String phoneNumber,
    required double salaryGross,
    DateTime? startDate,
    DateTime? dateOfBirth,
    @Default('FIXED') String employmentType,
    double? hourlyRate,
    String? propertyId,
    String? email,
    String? idNumber,
    String? kraPin,
    String? nssfNumber,
    String? nhifNumber,
    String? jobTitle,
    double? housingAllowance,
    double? transportAllowance,
    String? paymentFrequency,
    String? paymentMethod,
    String? mpesaNumber,
    String? bankName,
    String? bankAccount,
    String? notes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) = _CreateWorkerRequest;

  factory CreateWorkerRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkerRequestFromJson(json);
}

@freezed
abstract class UpdateWorkerRequest with _$UpdateWorkerRequest {
  const factory UpdateWorkerRequest({
    String? name,
    String? phoneNumber,
    double? salaryGross,
    DateTime? startDate,
    DateTime? dateOfBirth,
    String? employmentType,
    double? hourlyRate,
    String? propertyId,
    bool? isActive,
    String? email,
    String? idNumber,
    String? kraPin,
    String? nssfNumber,
    String? nhifNumber,
    String? jobTitle,
    double? housingAllowance,
    double? transportAllowance,
    String? paymentFrequency,
    String? paymentMethod,
    String? mpesaNumber,
    String? bankName,
    String? bankAccount,
    String? notes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) = _UpdateWorkerRequest;

  factory UpdateWorkerRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkerRequestFromJson(json);
}
