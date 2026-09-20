import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_tracking_model.freezed.dart';
part 'time_tracking_model.g.dart';

enum TimeEntryStatus {
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
}

@freezed
abstract class TimeEntry with _$TimeEntry {
  const factory TimeEntry({
    required String id,
    required String userId,
    required String workerId,
    required String clockInTime,
    String? clockOutTime,
    double? clockInLatitude,
    double? clockInLongitude,
    double? clockOutLatitude,
    double? clockOutLongitude,
    double? totalHours,
    required TimeEntryStatus status,
    String? notes,
    required String createdAt,
    String? propertyId,
  }) = _TimeEntry;

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json);
}

@freezed
abstract class ClockInRequest with _$ClockInRequest {
  const factory ClockInRequest({
    required String workerId,
    required double lat,
    required double lng,
    String? notes,
  }) = _ClockInRequest;

  factory ClockInRequest.fromJson(Map<String, dynamic> json) =>
      _$ClockInRequestFromJson(json);
}

/// Clock-out is addressed by worker, not by time entry: the backend locates the
/// worker's open entry itself, so a timeEntryId was never read from the body.
@freezed
abstract class ClockOutRequest with _$ClockOutRequest {
  const factory ClockOutRequest({
    required String workerId,
    required double lat,
    required double lng,
    String? notes,
  }) = _ClockOutRequest;

  factory ClockOutRequest.fromJson(Map<String, dynamic> json) =>
      _$ClockOutRequestFromJson(json);
}
