/// Compliance status for a worker
class ComplianceStatus {
  final bool hasNssf;
  final bool hasNhif;
  final bool hasKraPin;

  const ComplianceStatus({
    required this.hasNssf,
    required this.hasNhif,
    this.hasKraPin = true,
  });

  /// Whether there are any compliance issues
  bool get hasIssues => !hasNssf || !hasNhif;

  /// Get human-readable description of issues
  String? get issueDescription {
    if (!hasNssf && !hasNhif) {
      return 'Missing NSSF & NHIF';
    }
    if (!hasNssf) return 'Missing NSSF';
    if (!hasNhif) return 'Missing NHIF';
    return null;
  }

  /// Create from worker model
  factory ComplianceStatus.fromWorker(dynamic worker) {
    return ComplianceStatus(
      hasNssf: worker.nssfNumber != null,
      hasNhif: worker.nhifNumber != null,
      hasKraPin: worker.kraPin != null,
    );
  }
}

/// Utility for checking worker compliance
class ComplianceChecker {
  ComplianceChecker._();

  /// Check if worker has compliance issues
  static bool hasIssues(dynamic worker) {
    return worker.nssfNumber == null || worker.nhifNumber == null;
  }

  /// Get compliance status for a worker
  static ComplianceStatus getStatus(dynamic worker) {
    return ComplianceStatus.fromWorker(worker);
  }

  /// Count workers with compliance issues
  static int countWithIssues(List<dynamic> workers) {
    return workers.where((w) => hasIssues(w)).length;
  }
}
