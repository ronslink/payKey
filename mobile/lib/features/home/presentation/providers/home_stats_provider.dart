
class HomeStats {
  final WorkerStats workerStats;
  final PayrollStats payrollStats;

  HomeStats({required this.workerStats, required this.payrollStats});
}

class WorkerStats {
  final int totalWorkers;
  final int newWorkersThisMonth;
  final String trend;
  final bool trendUp;

  WorkerStats({
    required this.totalWorkers,
    required this.newWorkersThisMonth,
    required this.trend,
    required this.trendUp,
  });

  factory WorkerStats.fromJson(Map<String, dynamic> json) {
    return WorkerStats(
      totalWorkers: json['totalWorkers'] ?? 0,
      newWorkersThisMonth: json['newWorkersThisMonth'] ?? 0,
      trend: json['trend'] ?? '',
      trendUp: json['trendUp'] ?? true,
    );
  }
}

class PayrollStats {
  final double thisMonthTotal;
  final double lastMonthTotal;
  final String trend;
  final bool trendUp;
  final int processedCount;

  PayrollStats({
    required this.thisMonthTotal,
    required this.lastMonthTotal,
    required this.trend,
    required this.trendUp,
    required this.processedCount,
  });

  factory PayrollStats.fromJson(Map<String, dynamic> json) {
    return PayrollStats(
      thisMonthTotal: (json['thisMonthTotal'] ?? 0).toDouble(),
      lastMonthTotal: (json['lastMonthTotal'] ?? 0).toDouble(),
      trend: json['trend'] ?? '',
      trendUp: json['trendUp'] ?? true,
      processedCount: json['processedCount'] ?? 0,
    );
  }
}

// Note: homeStatsProvider commented out as getWorkerStats and getPayrollStats
// methods were removed from ApiService. Implement these endpoints if needed.
/*
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final apiService = ApiService();
  
  final workerStatsResponse = await apiService.getWorkerStats();
  final payrollStatsResponse = await apiService.getPayrollStats();

  return HomeStats(
    workerStats: WorkerStats.fromJson(workerStatsResponse.data),
    payrollStats: PayrollStats.fromJson(payrollStatsResponse.data),
  );
});
*/
