import '../models/pay_period_model.dart';

class PayPeriodUtils {
  /// Determines the most relevant "active" pay period for display.
  /// 
  /// Logic:
  /// 1. Prioritizes the period that encompasses the current date (Today).
  ///    (Only considers 'active' or 'draft' or 'processing' periods).
  /// 2. Future periods (Upcoming).
  /// 3. Fallback: Returns the earliest open/draft period (sorted by start date).
  /// 4. Returns null if no open/draft periods exist.
  static PayPeriod? getNextPayrollPeriod(List<PayPeriod> periods) {
    // Filter for open/draft periods
    final openPeriods = periods
        .where((p) => 
          p.status == PayPeriodStatus.active || 
          p.status == PayPeriodStatus.draft ||
          p.status == PayPeriodStatus.processing
        )
        .toList();
    
    if (openPeriods.isEmpty) return null;

    final now = DateTime.now();
    
    // 1. Try to find CURRENT period (today is within start/end)
    try {
      final current = openPeriods.firstWhere((p) => 
        p.startDate.isBefore(now) && p.endDate.add(const Duration(days: 1)).isAfter(now)
      );
      return current;
    } catch (_) {
      // 2. Try to find FUTURE periods (Upcoming)
      final futurePeriods = openPeriods.where((p) => p.startDate.isAfter(now)).toList();
      if (futurePeriods.isNotEmpty) {
        futurePeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
        return futurePeriods.first;
      }

      // 3. Fallback to earliest open period (Overdue)
      openPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
      return openPeriods.firstOrNull;
    }
  }

  /// Determines if the "Initialize Pay Periods" card should be shown.
  /// 
  /// Logic:
  /// - If any future pay periods exist (Draft/Active/Processing), return NULL (Hide card).
  /// - If NO future periods exist, return the year to initialize.
  ///   - If current year has no periods -> Initialize Current Year.
  ///   - If date is Nov/Dec, and Current Year is done -> Initialize Next Year.
  ///   - If date is Jan, and Next Year is empty -> Initialize Next Year (Current Year).
  static int? getYearToInitialize(List<PayPeriod> allPeriods) {
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = currentYear + 1;

    // Check for ANY future periods (Draft/Active/Processing) regardless of year
    // This assumes if we have future periods, we are good.
    final hasFuturePeriods = allPeriods.any((p) => 
      p.startDate.isAfter(now) && 
      (p.status == PayPeriodStatus.draft || p.status == PayPeriodStatus.active)
    );

    if (hasFuturePeriods) return null;

    // If no future periods, we might need to initialize.
    
    // Check if Current Year has periods
    final currentYearPeriods = allPeriods.where((p) => p.startDate.year == currentYear).toList();
    
    if (currentYearPeriods.isEmpty) {
      return currentYear; // Initialize Current Year (e.g. fresh install)
    }

    // Check if Current Year is fully completed/closed
    // Or if we are approaching end of year
    final nextYearPeriods = allPeriods.where((p) => p.startDate.year == nextYear).toList();
    
    // If we are in Nov/Dec/Jan and Next Year is empty -> Suggest Next Year
    if ((now.month >= 11 || now.month == 1) && nextYearPeriods.isEmpty) {
        return nextYear;
    }

    return null;
  }
}
