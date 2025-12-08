import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/report_models.dart';

enum ReportType {
  payrollSummary,
  statutory,
  musterRoll,
}

class ReportParams {
  final ReportType type;
  final String? payPeriodId;

  ReportParams({this.type = ReportType.payrollSummary, this.payPeriodId});

  ReportParams copyWith({ReportType? type, String? payPeriodId}) {
    return ReportParams(
      type: type ?? this.type,
      payPeriodId: payPeriodId ?? this.payPeriodId,
    );
  }
}

final reportParamsProvider = StateProvider<ReportParams>((ref) => ReportParams());

final reportDataProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final params = ref.watch(reportParamsProvider);
  final api = ApiService();

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
  }
});
