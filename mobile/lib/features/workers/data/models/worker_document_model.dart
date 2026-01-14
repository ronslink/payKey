import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker_document_model.freezed.dart';
part 'worker_document_model.g.dart';

enum DocumentType {
  @JsonValue('ID_COPY')
  idCopy,
  @JsonValue('CONTRACT')
  contract,
  @JsonValue('CERTIFICATE')
  certificate,
  @JsonValue('TAX_DOCUMENT')
  taxDocument,
  @JsonValue('OTHER')
  other,
}

@freezed
abstract class WorkerDocument with _$WorkerDocument {
  const factory WorkerDocument({
    required String id,
    required String workerId,
    required DocumentType type,
    required String name,
    required String url,
    int? fileSize,
    String? mimeType,
    DateTime? expiresAt,
    String? notes,
    DateTime? createdAt,
  }) = _WorkerDocument;

  factory WorkerDocument.fromJson(Map<String, dynamic> json) =>
      _$WorkerDocumentFromJson(json);
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.idCopy:
        return 'ID Copy';
      case DocumentType.contract:
        return 'Contract';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.taxDocument:
        return 'Tax Document';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get apiValue {
    switch (this) {
      case DocumentType.idCopy:
        return 'ID_COPY';
      case DocumentType.contract:
        return 'CONTRACT';
      case DocumentType.certificate:
        return 'CERTIFICATE';
      case DocumentType.taxDocument:
        return 'TAX_DOCUMENT';
      case DocumentType.other:
        return 'OTHER';
    }
  }
}
