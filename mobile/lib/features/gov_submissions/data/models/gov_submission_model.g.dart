// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gov_submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GovSubmission _$GovSubmissionFromJson(Map<String, dynamic> json) =>
    _GovSubmission(
      id: json['id'] as String,
      userId: json['userId'] as String,
      payPeriodId: json['payPeriodId'] as String,
      type: $enumDecode(_$GovSubmissionTypeEnumMap, json['type']),
      status: $enumDecode(_$GovSubmissionStatusEnumMap, json['status']),
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      notes: json['notes'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      employeeCount: (json['employeeCount'] as num?)?.toInt(),
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$GovSubmissionToJson(_GovSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'payPeriodId': instance.payPeriodId,
      'type': _$GovSubmissionTypeEnumMap[instance.type]!,
      'status': _$GovSubmissionStatusEnumMap[instance.status]!,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'referenceNumber': instance.referenceNumber,
      'notes': instance.notes,
      'totalAmount': instance.totalAmount,
      'employeeCount': instance.employeeCount,
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$GovSubmissionTypeEnumMap = {
  GovSubmissionType.kraP10: 'KRA_P10',
  GovSubmissionType.shif: 'SHIF',
  GovSubmissionType.nssf: 'NSSF',
};

const _$GovSubmissionStatusEnumMap = {
  GovSubmissionStatus.generated: 'GENERATED',
  GovSubmissionStatus.uploaded: 'UPLOADED',
  GovSubmissionStatus.confirmed: 'CONFIRMED',
  GovSubmissionStatus.error: 'ERROR',
};
