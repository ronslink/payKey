import 'package:freezed_annotation/freezed_annotation.dart';

part 'gov_submission_model.freezed.dart';
part 'gov_submission_model.g.dart';

enum GovSubmissionType {
  @JsonValue('KRA_P10')
  kraP10,
  @JsonValue('SHIF')
  shif,
  @JsonValue('NSSF')
  nssf,
}

enum GovSubmissionStatus {
  @JsonValue('GENERATED')
  generated,
  @JsonValue('UPLOADED')
  uploaded,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('ERROR')
  error,
}

@freezed
abstract class GovSubmission with _$GovSubmission {
  const factory GovSubmission({
    required String id,
    required String userId,
    required String payPeriodId,
    required GovSubmissionType type,
    required GovSubmissionStatus status,
    String? filePath,
    String? fileName,
    String? referenceNumber,
    String? notes,
    double? totalAmount,
    int? employeeCount,
    DateTime? uploadedAt,
    DateTime? confirmedAt,
    DateTime? createdAt,
  }) = _GovSubmission;

  factory GovSubmission.fromJson(Map<String, dynamic> json) =>
      _$GovSubmissionFromJson(json);
}

extension GovSubmissionTypeExtension on GovSubmissionType {
  String get displayName {
    switch (this) {
      case GovSubmissionType.kraP10:
        return 'KRA P10';
      case GovSubmissionType.shif:
        return 'SHIF';
      case GovSubmissionType.nssf:
        return 'NSSF';
    }
  }

  String get description {
    switch (this) {
      case GovSubmissionType.kraP10:
        return 'Pay As You Earn (PAYE) return for KRA iTax';
      case GovSubmissionType.shif:
        return 'Social Health Insurance Fund contributions';
      case GovSubmissionType.nssf:
        return 'National Social Security Fund SF24 return';
    }
  }
}

extension GovSubmissionStatusExtension on GovSubmissionStatus {
  String get displayName {
    switch (this) {
      case GovSubmissionStatus.generated:
        return 'Ready to Upload';
      case GovSubmissionStatus.uploaded:
        return 'Uploaded';
      case GovSubmissionStatus.confirmed:
        return 'Confirmed';
      case GovSubmissionStatus.error:
        return 'Error';
    }
  }
}
