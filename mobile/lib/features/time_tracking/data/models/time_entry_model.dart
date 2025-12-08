/// Time entry status enum
enum TimeEntryStatus {
  active,
  completed,
  adjusted,
  cancelled;

  static TimeEntryStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return TimeEntryStatus.active;
      case 'COMPLETED':
        return TimeEntryStatus.completed;
      case 'ADJUSTED':
        return TimeEntryStatus.adjusted;
      case 'CANCELLED':
        return TimeEntryStatus.cancelled;
      default:
        return TimeEntryStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case TimeEntryStatus.active:
        return 'Clocked In';
      case TimeEntryStatus.completed:
        return 'Completed';
      case TimeEntryStatus.adjusted:
        return 'Adjusted';
      case TimeEntryStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Model for a time entry (clock in/out record)
class TimeEntryModel {
  final String id;
  final String workerId;
  final String userId;
  final String? recordedById;
  final DateTime clockIn;
  final DateTime? clockOut;
  final double? totalHours;
  final int breakMinutes;
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;
  final TimeEntryStatus status;
  final String? notes;
  final String? adjustmentReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Worker info (when loaded with relation)
  final String? workerName;

  const TimeEntryModel({
    required this.id,
    required this.workerId,
    required this.userId,
    this.recordedById,
    required this.clockIn,
    this.clockOut,
    this.totalHours,
    this.breakMinutes = 0,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    required this.status,
    this.notes,
    this.adjustmentReason,
    required this.createdAt,
    required this.updatedAt,
    this.workerName,
  });

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) {
    return TimeEntryModel(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      userId: json['userId'] as String,
      recordedById: json['recordedById'] as String?,
      clockIn: DateTime.parse(json['clockIn'] as String),
      clockOut: json['clockOut'] != null 
          ? DateTime.parse(json['clockOut'] as String) 
          : null,
      totalHours: json['totalHours'] != null 
          ? double.tryParse(json['totalHours'].toString()) 
          : null,
      breakMinutes: json['breakMinutes'] as int? ?? 0,
      clockInLat: json['clockInLat'] != null 
          ? double.tryParse(json['clockInLat'].toString()) 
          : null,
      clockInLng: json['clockInLng'] != null 
          ? double.tryParse(json['clockInLng'].toString()) 
          : null,
      clockOutLat: json['clockOutLat'] != null 
          ? double.tryParse(json['clockOutLat'].toString()) 
          : null,
      clockOutLng: json['clockOutLng'] != null 
          ? double.tryParse(json['clockOutLng'].toString()) 
          : null,
      status: TimeEntryStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      notes: json['notes'] as String?,
      adjustmentReason: json['adjustmentReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      workerName: json['worker']?['name'] as String?,
    );
  }

  String get durationDisplay {
    if (totalHours == null) {
      // Calculate from clockIn to now
      final duration = DateTime.now().difference(clockIn);
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    final hours = totalHours!.floor();
    final minutes = ((totalHours! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  bool get isClockedIn => status == TimeEntryStatus.active;
}

/// Model for clock-in status response
class ClockStatus {
  final bool isClockedIn;
  final TimeEntryModel? currentEntry;
  final double todayTotal;

  const ClockStatus({
    required this.isClockedIn,
    this.currentEntry,
    required this.todayTotal,
  });

  factory ClockStatus.fromJson(Map<String, dynamic> json) {
    return ClockStatus(
      isClockedIn: json['isClockedIn'] as bool,
      currentEntry: json['currentEntry'] != null
          ? TimeEntryModel.fromJson(json['currentEntry'] as Map<String, dynamic>)
          : null,
      todayTotal: double.tryParse(json['todayTotal'].toString()) ?? 0,
    );
  }

  String get todayTotalDisplay {
    final hours = todayTotal.floor();
    final minutes = ((todayTotal - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

/// Model for live status of a single worker
class WorkerLiveStatus {
  final String workerId;
  final String workerName;
  final bool isClockedIn;
  final DateTime? clockInTime;
  final String duration;

  const WorkerLiveStatus({
    required this.workerId,
    required this.workerName,
    required this.isClockedIn,
    this.clockInTime,
    required this.duration,
  });

  factory WorkerLiveStatus.fromJson(Map<String, dynamic> json) {
    return WorkerLiveStatus(
      workerId: json['workerId'] as String,
      workerName: json['workerName'] as String,
      isClockedIn: json['isClockedIn'] as bool,
      clockInTime: json['clockInTime'] != null
          ? DateTime.parse(json['clockInTime'] as String)
          : null,
      duration: json['duration'] as String? ?? '--',
    );
  }
}

/// Model for attendance summary
class AttendanceSummary {
  final List<WorkerAttendance> workers;
  final AttendanceTotals totals;

  const AttendanceSummary({
    required this.workers,
    required this.totals,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      workers: (json['workers'] as List<dynamic>?)
          ?.map((e) => WorkerAttendance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totals: AttendanceTotals.fromJson(json['totals'] as Map<String, dynamic>),
    );
  }
}

class WorkerAttendance {
  final String workerId;
  final String workerName;
  final int totalDays;
  final double totalHours;
  final int entries;

  const WorkerAttendance({
    required this.workerId,
    required this.workerName,
    required this.totalDays,
    required this.totalHours,
    required this.entries,
  });

  factory WorkerAttendance.fromJson(Map<String, dynamic> json) {
    return WorkerAttendance(
      workerId: json['workerId'] as String,
      workerName: json['workerName'] as String,
      totalDays: json['totalDays'] as int? ?? 0,
      totalHours: double.tryParse(json['totalHours'].toString()) ?? 0,
      entries: json['entries'] as int? ?? 0,
    );
  }
}

class AttendanceTotals {
  final int totalEntries;
  final double totalHours;
  final double averageHoursPerDay;

  const AttendanceTotals({
    required this.totalEntries,
    required this.totalHours,
    required this.averageHoursPerDay,
  });

  factory AttendanceTotals.fromJson(Map<String, dynamic> json) {
    return AttendanceTotals(
      totalEntries: json['totalEntries'] as int? ?? 0,
      totalHours: double.tryParse(json['totalHours'].toString()) ?? 0,
      averageHoursPerDay: double.tryParse(json['averageHoursPerDay'].toString()) ?? 0,
    );
  }
}
