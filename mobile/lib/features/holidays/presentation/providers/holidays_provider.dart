import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/holiday_model.dart';
import '../../data/repositories/holidays_repository.dart';

final holidaysProvider = FutureProvider<List<HolidayModel>>((ref) async {
  final repository = ref.watch(holidaysRepositoryProvider);
  return repository.getHolidays();
});

final currentMonthHolidaysProvider = Provider<AsyncValue<List<HolidayModel>>>((ref) {
  final holidaysAsync = ref.watch(holidaysProvider);
  
  return holidaysAsync.whenData((holidays) {
    final now = DateTime.now();
    return holidays.where((h) {
      // Check if it's in the current month/year
      // Or if it's recurring and in the current month
      final isSameMonth = h.date.month == now.month;
      final isSameYear = h.date.year == now.year;
      
      if (h.isRecurring) {
        return isSameMonth;
      }
      return isSameMonth && isSameYear;
    }).toList();
  });
});
