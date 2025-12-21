import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/report_models.dart';

enum ReportType {
  payrollSummary,
  statutory,
  musterRoll,
  p9Report,
}

class ReportParams {
  final ReportType type;
  final String? payPeriodId;
  final int? year;

  ReportParams({
    this.type = ReportType.payrollSummary,
    this.payPeriodId,
    this.year,
  });

  ReportParams copyWith({ReportType? type, String? payPeriodId, int? year}) {
    return ReportParams(
      type: type ?? this.type,
      payPeriodId: payPeriodId ?? this.payPeriodId,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportParams &&
        other.type == type &&
        other.payPeriodId == payPeriodId &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(type, payPeriodId, year);
}

class ReportParamsNotifier extends Notifier<ReportParams> {
  @override
  ReportParams build() {
    return ReportParams(
      year: DateTime.now().year,
    );
  }

  void update(ReportParams params) {
    state = params;
  }
}

final reportParamsProvider = NotifierProvider<ReportParamsNotifier, ReportParams>(ReportParamsNotifier.new);

final reportDataProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final params = ref.watch(reportParamsProvider);
  final api = ApiService();

  // For P9 report, we need a year, not a pay period
  if (params.type == ReportType.p9Report) {
    final year = params.year ?? DateTime.now().year;
    final response = await api.reports.getP9Reports(year);
    final data = response.data as List;
    return data.map((e) => P9Report.fromJson(e)).toList();
  }

  // For other reports, we need a pay period
  if (params.payPeriodId == null) {
    return null; // Not ready to fetch
  }

  switch (params.type) {
    case ReportType.payrollSummary:
      final response = await api.reports.getPayrollSummary(params.payPeriodId!);
      return PayrollSummaryReport.fromJson(response.data);
    case ReportType.statutory:
      final response = await api.reports.getStatutoryReport(params.payPeriodId!);
      return StatutoryReport.fromJson(response.data);
    case ReportType.musterRoll:
      // Muster roll shares structure with payroll summary for now
      final response = await api.reports.getMusterRoll(params.payPeriodId!);
      return PayrollSummaryReport.fromJson(response.data);
    case ReportType.p9Report:
      // Already handled above
      return null;
  }
});

/// Provider specifically for P9 reports list
final p9ReportsProvider = FutureProvider.family<List<P9Report>, int>((ref, year) async {
  final api = ApiService();
  final workerId = ref.watch(selectedP9WorkerIdProvider);
  
  final response = await api.reports.getP9Reports(year, workerId: workerId);
  final data = response.data as List;
  return data.map((e) => P9Report.fromJson(e)).toList();
});

class SelectedP9WorkerIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void set(String? value) => state = value;
}

/// Selected worker ID for filtering P9 reports
final selectedP9WorkerIdProvider = NotifierProvider<SelectedP9WorkerIdNotifier, String?>(SelectedP9WorkerIdNotifier.new);

class SelectedP9YearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  
  void set(int value) => state = value;
}

/// Selected year for P9 reports
final selectedP9YearProvider = NotifierProvider<SelectedP9YearNotifier, int>(SelectedP9YearNotifier.new);

class SelectedP9WorkerNotifier extends Notifier<P9Report?> {
  @override
  P9Report? build() => null;
  
  void set(P9Report? value) => state = value;
}

/// Selected worker for P9 detail view
final selectedP9WorkerProvider = NotifierProvider<SelectedP9WorkerNotifier, P9Report?>(SelectedP9WorkerNotifier.new);
