import '../models/time_entry_model.dart';

/// Mock data for Time Tracking feature preview mode.
///
/// This data is shown to users who don't have a PLATINUM subscription
/// but are viewing the Time Tracking feature in preview mode.
class TimeTrackingMockData {
  /// Sample time entries for preview mode
  static List<TimeEntryModel> get timeEntries => [
        TimeEntryModel(
          id: 'preview-entry-001',
          userId: 'preview-user',
          workerId: 'preview-worker-001',
          clockIn: DateTime.now().subtract(const Duration(hours: 6)),
          clockOut: DateTime.now().subtract(const Duration(hours: 1)),
          clockInLat: -1.2921,
          clockInLng: 36.8219,
          clockOutLat: -1.2921,
          clockOutLng: 36.8219,
          totalHours: 5.0,
          status: TimeEntryStatus.completed,
          notes: 'Sample completed shift - This is preview data',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        TimeEntryModel(
          id: 'preview-entry-002',
          userId: 'preview-user',
          workerId: 'preview-worker-002',
          clockIn: DateTime.now().subtract(const Duration(hours: 3)),
          clockOut: null,
          clockInLat: -1.2921,
          clockInLng: 36.8219,
          totalHours: null,
          status: TimeEntryStatus.active,
          notes: 'Sample active shift - This is preview data',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        TimeEntryModel(
          id: 'preview-entry-003',
          userId: 'preview-user',
          workerId: 'preview-worker-001',
          clockIn: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
          clockOut: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          clockInLat: -4.3167,
          clockInLng: 39.5833,
          clockOutLat: -4.3167,
          clockOutLng: 39.5833,
          totalHours: 8.0,
          status: TimeEntryStatus.completed,
          notes: 'Full day shift (yesterday) - This is preview data',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        ),
      ];

  /// Get entries filtered by worker (returns all for preview)
  static List<TimeEntryModel> getEntriesForWorker(String workerId) =>
      timeEntries.where((e) => e.workerId == workerId).toList();

  /// Active entry for preview (simulates a worker currently clocked in)
  static TimeEntryModel? getActiveEntry(String workerId) {
    final active =
        timeEntries.where((e) => e.status == TimeEntryStatus.active).toList();
    for (final entry in active) {
      if (entry.workerId == workerId) return entry;
    }
    return active.isEmpty ? null : active.first;
  }
}
