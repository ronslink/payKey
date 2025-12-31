import '../models/time_tracking_model.dart';

/// Mock data for Time Tracking feature preview mode.
/// 
/// This data is shown to users who don't have PLATINUM subscription
/// but are viewing the Time Tracking feature in preview mode.
class TimeTrackingMockData {
  /// Sample time entries for preview mode
  static List<TimeEntry> get timeEntries => [
    TimeEntry(
      id: 'preview-entry-001',
      userId: 'preview-user',
      workerId: 'preview-worker-001',
      clockInTime: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      clockOutTime: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      clockInLatitude: -1.2921,
      clockInLongitude: 36.8219,
      clockOutLatitude: -1.2921,
      clockOutLongitude: 36.8219,
      totalHours: 5.0,
      status: TimeEntryStatus.completed,
      notes: 'Sample completed shift - This is preview data',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      propertyId: 'preview-property-001',
    ),
    TimeEntry(
      id: 'preview-entry-002',
      userId: 'preview-user',
      workerId: 'preview-worker-002',
      clockInTime: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      clockOutTime: null,
      clockInLatitude: -1.2921,
      clockInLongitude: 36.8219,
      totalHours: null,
      status: TimeEntryStatus.inProgress,
      notes: 'Sample active shift - This is preview data',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      propertyId: 'preview-property-001',
    ),
    TimeEntry(
      id: 'preview-entry-003',
      userId: 'preview-user',
      workerId: 'preview-worker-001',
      clockInTime: DateTime.now().subtract(const Duration(days: 1, hours: 9)).toIso8601String(),
      clockOutTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
      clockInLatitude: -4.3167,
      clockInLongitude: 39.5833,
      clockOutLatitude: -4.3167,
      clockOutLongitude: 39.5833,
      totalHours: 8.0,
      status: TimeEntryStatus.completed,
      notes: 'Full day shift (yesterday) - This is preview data',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 9)).toIso8601String(),
      propertyId: 'preview-property-002',
    ),
  ];

  /// Get entries filtered by worker (returns all for preview)
  static List<TimeEntry> getEntriesForWorker(String workerId) => 
      timeEntries.where((e) => e.workerId == workerId).toList();

  /// Active entry for preview (simulates a worker currently clocked in)
  static TimeEntry? getActiveEntry(String workerId) =>
      timeEntries.where((e) => e.status == TimeEntryStatus.inProgress).firstOrNull;
}
