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
