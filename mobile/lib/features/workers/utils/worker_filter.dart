import '../constants/workers_constants.dart';
import 'compliance_checker.dart';

/// Filter state for workers list
class WorkerFilterState {
  final WorkerFilter statusFilter;
  final String? propertyId;
  final String searchQuery;

  const WorkerFilterState({
    this.statusFilter = WorkerFilter.all,
    this.propertyId,
    this.searchQuery = '',
  });

  WorkerFilterState copyWith({
    WorkerFilter? statusFilter,
    String? propertyId,
    String? searchQuery,
    bool clearPropertyId = false,
  }) {
    return WorkerFilterState(
      statusFilter: statusFilter ?? this.statusFilter,
      propertyId: clearPropertyId ? null : (propertyId ?? this.propertyId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Whether any filters are active
  bool get hasActiveFilters =>
      statusFilter != WorkerFilter.all ||
      propertyId != null ||
      searchQuery.isNotEmpty;

  /// Reset all filters
  WorkerFilterState reset() => const WorkerFilterState();
}

/// Worker filtering utility
class WorkerFilterer {
  WorkerFilterer._();

  /// Apply all filters to a list of workers
  static List<T> apply<T>(
    List<T> workers,
    WorkerFilterState filters, {
    required String Function(T) getName,
    required String? Function(T) getKraPin,
    required String Function(T) getPhoneNumber,
    required String? Function(T) getJobTitle,
    required String? Function(T) getPropertyId,
    required bool Function(T) getIsActive,
    required bool Function(T) hasComplianceIssue,
  }) {
    var filtered = workers;

    // Search filter
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filtered = filtered.where((w) {
        return getName(w).toLowerCase().contains(query) ||
            (getKraPin(w)?.toLowerCase() ?? '').contains(query) ||
            getPhoneNumber(w).contains(query) ||
            (getJobTitle(w)?.toLowerCase() ?? '').contains(query);
      }).toList();
    }

    // Property filter
    if (filters.propertyId != null) {
      filtered = filtered.where((w) => getPropertyId(w) == filters.propertyId).toList();
    }

    // Status filter
    switch (filters.statusFilter) {
      case WorkerFilter.active:
        filtered = filtered.where((w) => getIsActive(w)).toList();
        break;
      case WorkerFilter.inactive:
        filtered = filtered.where((w) => !getIsActive(w)).toList();
        break;
      case WorkerFilter.pending:
        filtered = filtered.where((w) => hasComplianceIssue(w)).toList();
        break;
      case WorkerFilter.all:
        break;
    }

    return filtered;
  }

  /// Simplified apply for WorkerModel (when you have the actual type)
  static List<dynamic> applyToWorkers(
    List<dynamic> workers,
    WorkerFilterState filters,
  ) {
    return apply(
      workers,
      filters,
      getName: (w) => w.name as String,
      getKraPin: (w) => w.kraPin as String?,
      getPhoneNumber: (w) => w.phoneNumber as String,
      getJobTitle: (w) => w.jobTitle as String?,
      getPropertyId: (w) => w.propertyId as String?,
      getIsActive: (w) => w.isActive as bool,
      hasComplianceIssue: (w) => ComplianceChecker.hasIssues(w),
    );
  }
}

/// Worker statistics
class WorkerStats {
  final int total;
  final int active;
  final int pending;

  const WorkerStats({
    required this.total,
    required this.active,
    required this.pending,
  });

  const WorkerStats.empty()
      : total = 0,
        active = 0,
        pending = 0;

  factory WorkerStats.fromWorkers(List<dynamic> workers) {
    return WorkerStats(
      total: workers.length,
      active: workers.where((w) => w.isActive as bool).length,
      pending: ComplianceChecker.countWithIssues(workers),
    );
  }
}
