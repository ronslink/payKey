import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';

/// Dashboard metrics model
class DashboardMetrics {
  final int totalWorkers;
  final int activeWorkers;
  final int pendingLeaveRequests;
  final double totalNetPay;
  final double totalGrossPay;
  final List<RecentTransaction> recentTransactions;

  DashboardMetrics({
    required this.totalWorkers,
    required this.activeWorkers,
    required this.pendingLeaveRequests,
    required this.totalNetPay,
    required this.totalGrossPay,
    required this.recentTransactions,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final workersSummary = json['workersSummary'] ?? {};
    final pendingActions = json['pendingActions'] ?? {};
    
    return DashboardMetrics(
      totalWorkers: workersSummary['total'] ?? 0,
      activeWorkers: workersSummary['active'] ?? 0,
      pendingLeaveRequests: pendingActions['pendingLeaveRequests'] ?? 0,
      totalNetPay: 0, // We'll calculate from pay periods
      totalGrossPay: 0,
      recentTransactions: (json['recentTransactions'] as List? ?? [])
          .map((t) => RecentTransaction.fromJson(t))
          .toList(),
    );
  }
}

class RecentTransaction {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;

  RecentTransaction({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Provider for dashboard metrics from API
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  try {
    final response = await ApiService().get('/reports/dashboard');
    if (response.statusCode == 200) {
      return DashboardMetrics.fromJson(response.data);
    }
    throw Exception('Failed to load dashboard metrics');
  } catch (e) {
    // Return default metrics on error
    return DashboardMetrics(
      totalWorkers: 0,
      activeWorkers: 0,
      pendingLeaveRequests: 0,
      totalNetPay: 0,
      totalGrossPay: 0,
      recentTransactions: [],
    );
  }
});

/// Provider for payroll totals from pay periods
final payrollTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  try {
    final response = await ApiService().get('/payroll/pay-periods');
    if (response.statusCode == 200) {
      final periods = response.data as List? ?? [];
      
      double totalNet = 0;
      double totalGross = 0;
      
      for (var period in periods) {
        if (period['status'] == 'COMPLETED' || period['status'] == 'CLOSED') {
          totalNet += (period['totalNetAmount'] ?? 0).toDouble();
          totalGross += (period['totalGrossAmount'] ?? 0).toDouble();
        }
      }
      
      return {
        'totalNet': totalNet,
        'totalGross': totalGross,
      };
    }
    throw Exception('Failed to load payroll totals');
  } catch (e) {
    return {'totalNet': 0.0, 'totalGross': 0.0};
  }
});

/// Provider for pending tax submissions count
final pendingTaxesProvider = FutureProvider<int>((ref) async {
  try {
    final response = await ApiService().get('/taxes/submissions');
    if (response.statusCode == 200) {
      final submissions = response.data as List? ?? [];
      return submissions.where((s) => s['status'] == 'PENDING').length;
    }
    return 0;
  } catch (e) {
    return 0;
  }
});
