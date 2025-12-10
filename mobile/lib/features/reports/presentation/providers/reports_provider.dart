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
}

final reportParamsProvider = StateProvider<ReportParams>((ref) => ReportParams(
      year: DateTime.now().year,
    ));

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

/// Selected worker ID for filtering P9 reports
final selectedP9WorkerIdProvider = StateProvider<String?>((ref) => null);

/// Selected year for P9 reports
final selectedP9YearProvider = StateProvider<int>((ref) => DateTime.now().year);

/// Selected worker for P9 detail view
final selectedP9WorkerProvider = StateProvider<P9Report?>((ref) => null);
