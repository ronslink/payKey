/// User role enum
enum UserRole {
  admin,
  user,
  employer,
  worker;

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'USER':
      case 'EMPLOYER':
        return UserRole.employer;
      case 'WORKER':
        return UserRole.worker;
      default:
        return UserRole.employer;
    }
  }

  bool get isWorker => this == UserRole.worker;
  bool get isEmployer => this == UserRole.employer || this == UserRole.user || this == UserRole.admin;
}

/// Employee profile response
class EmployeeProfile {
  final String userId;
  final String? workerId;
  final String? employerId;
  final UserRole role;

  const EmployeeProfile({
    required this.userId,
    this.workerId,
    this.employerId,
    required this.role,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      userId: json['userId'] as String,
      workerId: json['workerId'] as String?,
      employerId: json['employerId'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'EMPLOYER'),
    );
  }
}

/// Leave balance response
class LeaveBalance {
  final String workerId;
  final String workerName;
  final int year;
  final int totalAnnualLeaves;
  final int usedAnnualLeaves;
  final int remainingAnnualLeaves;
  final int sickLeaves;
  final int pendingLeaves;

  const LeaveBalance({
    required this.workerId,
    required this.workerName,
    required this.year,
    required this.totalAnnualLeaves,
    required this.usedAnnualLeaves,
    required this.remainingAnnualLeaves,
    required this.sickLeaves,
    required this.pendingLeaves,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      workerId: json['workerId'] as String,
      workerName: json['workerName'] as String,
      year: json['year'] as int,
      totalAnnualLeaves: json['totalAnnualLeaves'] as int? ?? 21,
      usedAnnualLeaves: json['usedAnnualLeaves'] as int? ?? 0,
      remainingAnnualLeaves: json['remainingAnnualLeaves'] as int? ?? 21,
      sickLeaves: json['sickLeaves'] as int? ?? 0,
      pendingLeaves: json['pendingLeaves'] as int? ?? 0,
    );
  }

  double get usagePercentage {
    if (totalAnnualLeaves == 0) return 0;
    return (usedAnnualLeaves / totalAnnualLeaves) * 100;
  }
}

/// Invite status response
class InviteStatus {
  final bool hasAccount;
  final bool hasInvite;
  final DateTime? inviteExpiry;

  const InviteStatus({
    required this.hasAccount,
    required this.hasInvite,
    this.inviteExpiry,
  });

  factory InviteStatus.fromJson(Map<String, dynamic> json) {
    return InviteStatus(
      hasAccount: json['hasAccount'] as bool? ?? false,
      hasInvite: json['hasInvite'] as bool? ?? false,
      inviteExpiry: json['inviteExpiry'] != null
          ? DateTime.parse(json['inviteExpiry'] as String)
          : null,
    );
  }

  bool get isInviteExpired {
    if (inviteExpiry == null) return false;
    return DateTime.now().isAfter(inviteExpiry!);
  }
}

/// Invite code generation response
class InviteCode {
  final String inviteCode;
  final DateTime expiresAt;

  const InviteCode({
    required this.inviteCode,
    required this.expiresAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      inviteCode: json['inviteCode'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Employee login/claim response
class EmployeeAuthResponse {
  final String accessToken;
  final EmployeeUser user;

  const EmployeeAuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory EmployeeAuthResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeAuthResponse(
      accessToken: json['accessToken'] as String,
      user: EmployeeUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class EmployeeUser {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final String? linkedWorkerId;
  final String? employerId;

  const EmployeeUser({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.linkedWorkerId,
    this.employerId,
  });

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    return EmployeeUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'EMPLOYEE'),
      linkedWorkerId: json['linkedWorkerId'] as String?,
      employerId: json['employerId'] as String?,
    );
  }

  String get fullName {
    if (firstName == null && lastName == null) return 'Employee';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
}

/// Clock status for employee dashboard
class ClockStatus {
  final bool isClockedIn;
  final EmployeeTimeEntry? currentEntry;
  final double todayTotal;

  const ClockStatus({
    required this.isClockedIn,
    this.currentEntry,
    required this.todayTotal,
  });

  factory ClockStatus.fromJson(Map<String, dynamic> json) {
    return ClockStatus(
      isClockedIn: json['isClockedIn'] as bool? ?? false,
      currentEntry: json['currentEntry'] != null
          ? EmployeeTimeEntry.fromJson(json['currentEntry'] as Map<String, dynamic>)
          : null,
      todayTotal: parseDouble(json['todayTotal']),
    );
  }

  String get todayTotalDisplay {
    final hours = todayTotal.floor();
    final minutes = ((todayTotal - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

/// Employee time entry model
class EmployeeTimeEntry {
  final String id;
  final String workerId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final double? totalHours;
  final int? breakMinutes;
  final String? notes;
  final String status;

  const EmployeeTimeEntry({
    required this.id,
    required this.workerId,
    required this.clockIn,
    this.clockOut,
    this.totalHours,
    this.breakMinutes,
    this.notes,
    required this.status,
  });

  factory EmployeeTimeEntry.fromJson(Map<String, dynamic> json) {
    return EmployeeTimeEntry(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      clockIn: DateTime.parse(json['clockIn'] as String),
      clockOut: json['clockOut'] != null ? DateTime.parse(json['clockOut'] as String) : null,
      totalHours: json['totalHours'] != null ? parseDouble(json['totalHours']) : null,
      breakMinutes: json['breakMinutes'] as int?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

/// Employee leave request model
class EmployeeLeaveRequest {
  final String id;
  final String workerId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String? reason;
  final String status;
  final DateTime createdAt;

  const EmployeeLeaveRequest({
    required this.id,
    required this.workerId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory EmployeeLeaveRequest.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['startDate'] as String);
    final end = DateTime.parse(json['endDate'] as String);
    return EmployeeLeaveRequest(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      leaveType: json['leaveType'] as String,
      startDate: start,
      endDate: end,
      totalDays: json['totalDays'] as int? ?? (end.difference(start).inDays + 1),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Employee payslip model
class EmployeePayslip {
  final String id;
  final String workerId;
  final String workerName;
  final String? employerName;
  final String periodName;
  final DateTime payDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double basicSalary;
  final double allowances;
  final double overtime;
  final double grossPay;
  final double paye;
  final double nhif;
  final double nssf;
  final double housingLevy;
  final double totalDeductions;
  final double netPay;

  const EmployeePayslip({
    required this.id,
    required this.workerId,
    required this.workerName,
    this.employerName,
    required this.periodName,
    required this.payDate,
    this.periodStart,
    this.periodEnd,
    required this.basicSalary,
    required this.allowances,
    required this.overtime,
    required this.grossPay,
    required this.paye,
    required this.nhif,
    required this.nssf,
    required this.housingLevy,
    required this.totalDeductions,
    required this.netPay,
  });


  factory EmployeePayslip.fromJson(Map<String, dynamic> json) {
    final payPeriod = json['payPeriod'] as Map<String, dynamic>?;
    final taxBreakdown = json['taxBreakdown'] as Map<String, dynamic>?;
    final deductions = json['deductions'] as Map<String, dynamic>?;
    final worker = json['worker'] as Map<String, dynamic>?;

    return EmployeePayslip(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      workerName: worker?['name'] as String? ?? json['workerName'] as String? ?? 'Employee',
      employerName: json['employerName'] as String?,
      periodName: payPeriod?['name'] as String? ?? json['periodName'] as String? ?? 'Pay Period',
      payDate: DateTime.parse(json['payDate'] as String? ?? payPeriod?['paymentDate'] as String? ?? DateTime.now().toIso8601String()),
      periodStart: json['periodStart'] != null ? DateTime.parse(json['periodStart'] as String) : null,
      periodEnd: json['periodEnd'] != null ? DateTime.parse(json['periodEnd'] as String) : null,
      basicSalary: parseDouble(json['grossSalary']),
      allowances: parseDouble(json['bonuses']) + parseDouble(json['otherEarnings']),
      overtime: parseDouble(json['overtimePay']),
      grossPay: parseDouble(json['grossSalary']),
      paye: parseDouble(taxBreakdown?['paye']),
      nhif: parseDouble(taxBreakdown?['nhif']) + parseDouble(taxBreakdown?['shif']),
      nssf: parseDouble(taxBreakdown?['nssf']),
      housingLevy: parseDouble(taxBreakdown?['housingLevy']),
      totalDeductions: parseDouble(taxBreakdown?['totalTax']) + parseDouble(deductions?['totalDeductions']),
      netPay: parseDouble(json['netSalary']),
    );
  }
}

double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
