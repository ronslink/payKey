// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkerModel _$WorkerModelFromJson(Map<String, dynamic> json) => _WorkerModel(
  id: json['id'] as String,
  name: json['name'] as String,
  phoneNumber: json['phoneNumber'] as String,
  salaryGross: (json['salaryGross'] as num).toDouble(),
  startDate: DateTime.parse(json['startDate'] as String),
  isActive: json['isActive'] as bool,
  employmentType: json['employmentType'] as String? ?? 'FIXED',
  hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
  propertyId: json['propertyId'] as String?,
  email: json['email'] as String?,
  idNumber: json['idNumber'] as String?,
  kraPin: json['kraPin'] as String?,
  nssfNumber: json['nssfNumber'] as String?,
  nhifNumber: json['nhifNumber'] as String?,
  jobTitle: json['jobTitle'] as String?,
  housingAllowance: (json['housingAllowance'] as num?)?.toDouble() ?? 0.0,
  transportAllowance: (json['transportAllowance'] as num?)?.toDouble() ?? 0.0,
  paymentFrequency: json['paymentFrequency'] as String? ?? 'MONTHLY',
  paymentMethod: json['paymentMethod'] as String? ?? 'MPESA',
  mpesaNumber: json['mpesaNumber'] as String?,
  bankName: json['bankName'] as String?,
  bankAccount: json['bankAccount'] as String?,
  notes: json['notes'] as String?,
  emergencyContactName: json['emergencyContactName'] as String?,
  emergencyContactPhone: json['emergencyContactPhone'] as String?,
  emergencyContactRelationship: json['emergencyContactRelationship'] as String?,
  terminatedAt: json['terminatedAt'] == null
      ? null
      : DateTime.parse(json['terminatedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WorkerModelToJson(_WorkerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'salaryGross': instance.salaryGross,
      'startDate': instance.startDate.toIso8601String(),
      'isActive': instance.isActive,
      'employmentType': instance.employmentType,
      'hourlyRate': instance.hourlyRate,
      'propertyId': instance.propertyId,
      'email': instance.email,
      'idNumber': instance.idNumber,
      'kraPin': instance.kraPin,
      'nssfNumber': instance.nssfNumber,
      'nhifNumber': instance.nhifNumber,
      'jobTitle': instance.jobTitle,
      'housingAllowance': instance.housingAllowance,
      'transportAllowance': instance.transportAllowance,
      'paymentFrequency': instance.paymentFrequency,
      'paymentMethod': instance.paymentMethod,
      'mpesaNumber': instance.mpesaNumber,
      'bankName': instance.bankName,
      'bankAccount': instance.bankAccount,
      'notes': instance.notes,
      'emergencyContactName': instance.emergencyContactName,
      'emergencyContactPhone': instance.emergencyContactPhone,
      'emergencyContactRelationship': instance.emergencyContactRelationship,
      'terminatedAt': instance.terminatedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_CreateWorkerRequest _$CreateWorkerRequestFromJson(Map<String, dynamic> json) =>
    _CreateWorkerRequest(
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      salaryGross: (json['salaryGross'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      employmentType: json['employmentType'] as String? ?? 'FIXED',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      propertyId: json['propertyId'] as String?,
      email: json['email'] as String?,
      idNumber: json['idNumber'] as String?,
      kraPin: json['kraPin'] as String?,
      nssfNumber: json['nssfNumber'] as String?,
      nhifNumber: json['nhifNumber'] as String?,
      jobTitle: json['jobTitle'] as String?,
      housingAllowance: (json['housingAllowance'] as num?)?.toDouble(),
      transportAllowance: (json['transportAllowance'] as num?)?.toDouble(),
      paymentFrequency: json['paymentFrequency'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      mpesaNumber: json['mpesaNumber'] as String?,
      bankName: json['bankName'] as String?,
      bankAccount: json['bankAccount'] as String?,
      notes: json['notes'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          json['emergencyContactRelationship'] as String?,
    );

Map<String, dynamic> _$CreateWorkerRequestToJson(
  _CreateWorkerRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'phoneNumber': instance.phoneNumber,
  'salaryGross': instance.salaryGross,
  'startDate': instance.startDate.toIso8601String(),
  'employmentType': instance.employmentType,
  'hourlyRate': instance.hourlyRate,
  'propertyId': instance.propertyId,
  'email': instance.email,
  'idNumber': instance.idNumber,
  'kraPin': instance.kraPin,
  'nssfNumber': instance.nssfNumber,
  'nhifNumber': instance.nhifNumber,
  'jobTitle': instance.jobTitle,
  'housingAllowance': instance.housingAllowance,
  'transportAllowance': instance.transportAllowance,
  'paymentFrequency': instance.paymentFrequency,
  'paymentMethod': instance.paymentMethod,
  'mpesaNumber': instance.mpesaNumber,
  'bankName': instance.bankName,
  'bankAccount': instance.bankAccount,
  'notes': instance.notes,
  'emergencyContactName': instance.emergencyContactName,
  'emergencyContactPhone': instance.emergencyContactPhone,
  'emergencyContactRelationship': instance.emergencyContactRelationship,
};

_UpdateWorkerRequest _$UpdateWorkerRequestFromJson(Map<String, dynamic> json) =>
    _UpdateWorkerRequest(
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      salaryGross: (json['salaryGross'] as num?)?.toDouble(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      employmentType: json['employmentType'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      propertyId: json['propertyId'] as String?,
      isActive: json['isActive'] as bool?,
      email: json['email'] as String?,
      idNumber: json['idNumber'] as String?,
      kraPin: json['kraPin'] as String?,
      nssfNumber: json['nssfNumber'] as String?,
      nhifNumber: json['nhifNumber'] as String?,
      jobTitle: json['jobTitle'] as String?,
      housingAllowance: (json['housingAllowance'] as num?)?.toDouble(),
      transportAllowance: (json['transportAllowance'] as num?)?.toDouble(),
      paymentFrequency: json['paymentFrequency'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      mpesaNumber: json['mpesaNumber'] as String?,
      bankName: json['bankName'] as String?,
      bankAccount: json['bankAccount'] as String?,
      notes: json['notes'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          json['emergencyContactRelationship'] as String?,
    );

Map<String, dynamic> _$UpdateWorkerRequestToJson(
  _UpdateWorkerRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'phoneNumber': instance.phoneNumber,
  'salaryGross': instance.salaryGross,
  'startDate': instance.startDate?.toIso8601String(),
  'employmentType': instance.employmentType,
  'hourlyRate': instance.hourlyRate,
  'propertyId': instance.propertyId,
  'isActive': instance.isActive,
  'email': instance.email,
  'idNumber': instance.idNumber,
  'kraPin': instance.kraPin,
  'nssfNumber': instance.nssfNumber,
  'nhifNumber': instance.nhifNumber,
  'jobTitle': instance.jobTitle,
  'housingAllowance': instance.housingAllowance,
  'transportAllowance': instance.transportAllowance,
  'paymentFrequency': instance.paymentFrequency,
  'paymentMethod': instance.paymentMethod,
  'mpesaNumber': instance.mpesaNumber,
  'bankName': instance.bankName,
  'bankAccount': instance.bankAccount,
  'notes': instance.notes,
  'emergencyContactName': instance.emergencyContactName,
  'emergencyContactPhone': instance.emergencyContactPhone,
  'emergencyContactRelationship': instance.emergencyContactRelationship,
};
