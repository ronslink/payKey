import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';

// Service Provider
final payrollServiceProvider = Provider<PayrollEndpoints>((ref) {
  return ref.watch(apiServiceProvider).payroll;
});

// Models
class FinanceStats {
  final double totalPayroll;
  final double lastMonthPayroll;
  final String trend;
  final bool trendUp;
  final int processedCount;
  final int totalWorkers;
  final double progress; // 0.0 to 1.0
  final DateTime? nextRunDate;

  FinanceStats({
    required this.totalPayroll,
    required this.lastMonthPayroll,
    required this.trend,
    required this.trendUp,
    required this.processedCount,
    required this.totalWorkers,
    required this.progress,
    this.nextRunDate,
  });

  factory FinanceStats.fromJson(Map<String, dynamic> json) {
    // Assuming backend returns { thisMonthTotal, lastMonthTotal, trend, trendUp, processedCount, totalWorkers }
    // We add a calculated nextRunDate (e.g. 25th of current month)
    
    final now = DateTime.now();
    // Logic: Payroll is usually run on 25th. If today > 25th, next is next month 25th.
    DateTime next = DateTime(now.year, now.month, 25);
    if (now.day > 25) {
      next = DateTime(now.year, now.month + 1, 25);
    }
    
    final processed = json['processedCount'] ?? 0;
    final total = json['totalWorkers'] ?? 1;
    final progress = total > 0 ? processed / total : 0.0;
    
    return FinanceStats(
      totalPayroll: (json['thisMonthTotal'] ?? 0).toDouble(),
      lastMonthPayroll: (json['lastMonthTotal'] ?? 0).toDouble(),
      trend: json['trend'] ?? '+0',
      trendUp: json['trendUp'] ?? true,
      processedCount: processed,
      totalWorkers: total,
      progress: progress,
      nextRunDate: next,
    );
  }
}

// Stats Provider
final financeStatsProvider = FutureProvider<FinanceStats>((ref) async {
  final service = ref.watch(payrollServiceProvider);
  final response = await service.getStats();
  return FinanceStats.fromJson(response.data);
});

// Transactions Provider (Mock for now until transaction API exists)
final recentTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Replace with real API call when endpoint exists
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'title': 'Payroll Run - July',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'amount': -1450000.0,
      'status': 'Done',
    },
    {
      'title': 'Deposit from M-Pesa',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'amount': 50000.0,
      'status': 'Done',
    },
  ];
});
