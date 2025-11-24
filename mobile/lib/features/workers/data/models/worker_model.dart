import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker_model.freezed.dart';
part 'worker_model.g.dart';

@freezed
class WorkerModel with _$WorkerModel {
  const factory WorkerModel({
    required String id,
    required String name,
    required String phoneNumber,
    required double salaryGross,
    required DateTime startDate,
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
    DateTime? terminatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkerModel;

  factory WorkerModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerModelFromJson(json);
}

@freezed
class CreateWorkerRequest with _$CreateWorkerRequest {
  const factory CreateWorkerRequest({
    required String name,
    required String phoneNumber,
    required double salaryGross,
    required DateTime startDate,
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
  }) = _CreateWorkerRequest;

  factory CreateWorkerRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkerRequestFromJson(json);
}

@freezed
class UpdateWorkerRequest with _$UpdateWorkerRequest {
  const factory UpdateWorkerRequest({
    String? name,
    String? phoneNumber,
    double? salaryGross,
    DateTime? startDate,
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
  }) = _UpdateWorkerRequest;

  factory UpdateWorkerRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkerRequestFromJson(json);
}
