// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkerDocument _$WorkerDocumentFromJson(Map<String, dynamic> json) =>
    _WorkerDocument(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
      name: json['name'] as String,
      url: json['url'] as String,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WorkerDocumentToJson(_WorkerDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workerId': instance.workerId,
      'type': _$DocumentTypeEnumMap[instance.type]!,
      'name': instance.name,
      'url': instance.url,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.idCopy: 'ID_COPY',
  DocumentType.contract: 'CONTRACT',
  DocumentType.certificate: 'CERTIFICATE',
  DocumentType.taxDocument: 'TAX_DOCUMENT',
  DocumentType.other: 'OTHER',
};
