import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/utils/worker_hours_controller_manager.dart';
import 'package:mobile/features/payroll/presentation/constants/payroll_constants.dart';

void main() {
  late WorkerHoursControllerManager manager;

  setUp(() {
    manager = WorkerHoursControllerManager();
  });

  tearDown(() {
    manager.dispose();
  });

  group('WorkerHoursControllerManager', () {
    group('Pay Period Default Hours', () {
      test('should default to 40 hours for weekly period (7 days)', () {
        manager.setPayPeriodDays(7);
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('40'));
      });

      test('should default to 80 hours for bi-weekly period (14 days)', () {
        manager.setPayPeriodDays(14);
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('80'));
      });

      test('should default to 160 hours for monthly period (30 days)', () {
        manager.setPayPeriodDays(30);
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('160'));
      });

      test('should default to 160 hours for 31 day period', () {
        manager.setPayPeriodDays(31);
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('160'));
      });
    });

    group('Attendance Data Integration', () {
      test('should use attendance hours when available for hourly workers', () {
        manager.setPayPeriodDays(30);
        manager.setAttendanceData({'worker-1': 120.5});
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('120.5'));
      });

      test('should fallback to default when no attendance data for worker', () {
        manager.setPayPeriodDays(30);
        manager.setAttendanceData({'worker-other': 100.0});
        
        final controller = manager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('160'));
      });

      test('should clear attendance data when clearAttendanceData is called', () {
        manager.setPayPeriodDays(30);
        manager.setAttendanceData({'worker-1': 120.0});
        manager.clearAttendanceData();
        
        // Create a new controller after clearing
        final newManager = WorkerHoursControllerManager();
        newManager.setPayPeriodDays(30);
        final controller = newManager.getHoursController('worker-1', isHourly: true);
        
        expect(controller.text, equals('160'));
        newManager.dispose();
      });
    });

    group('Overtime Split Logic', () {
      test('should split hours into regular and overtime when exceeding threshold (monthly)', () {
        manager.setPayPeriodDays(30);
        
        // Worker tracked 180 hours - should split to 160 regular + 20 overtime
        manager.setAttendanceData({'worker-1': 180.0});
        
        final hoursController = manager.getHoursController('worker-1', isHourly: true);
        final overtimeController = manager.getOvertimeController('worker-1');
        
        expect(hoursController.text, equals('160.0'));
        expect(overtimeController.text, equals('20.0'));
      });

      test('should split hours into regular and overtime when exceeding threshold (weekly)', () {
        manager.setPayPeriodDays(7);
        
        // Worker tracked 55 hours - should split to 40 regular + 15 overtime
        manager.setAttendanceData({'worker-1': 55.0});
        
        final hoursController = manager.getHoursController('worker-1', isHourly: true);
        final overtimeController = manager.getOvertimeController('worker-1');
        
        expect(hoursController.text, equals('40.0'));
        expect(overtimeController.text, equals('15.0'));
      });

      test('should not create overtime when hours are below threshold', () {
        manager.setPayPeriodDays(30);
        
        // Worker tracked 140 hours - below 160 threshold
        manager.setAttendanceData({'worker-1': 140.0});
        
        final hoursController = manager.getHoursController('worker-1', isHourly: true);
        final overtimeController = manager.getOvertimeController('worker-1');
        
        expect(hoursController.text, equals('140.0'));
        expect(overtimeController.text, equals('0')); // Default 0
      });

      test('should handle exact threshold hours without overtime', () {
        manager.setPayPeriodDays(30);
        
        // Worker tracked exactly 160 hours
        manager.setAttendanceData({'worker-1': 160.0});
        
        final hoursController = manager.getHoursController('worker-1', isHourly: true);
        final overtimeController = manager.getOvertimeController('worker-1');
        
        expect(hoursController.text, equals('160.0'));
        expect(overtimeController.text, equals('0')); // No overtime for exact threshold
      });
    });

    group('Update Existing Controllers', () {
      test('should update existing hours controllers when attendance data is set', () {
        manager.setPayPeriodDays(30);
        
        // First create a controller with default value
        final controller = manager.getHoursController('worker-1', isHourly: true);
        expect(controller.text, equals('160'));
        
        // Now set attendance data - should update existing controller
        manager.setAttendanceData({'worker-1': 100.0});
        
        expect(controller.text, equals('100.0'));
      });

      test('should update existing overtime controllers when attendance data causes overtime', () {
        manager.setPayPeriodDays(30);
        
        // First create controllers
        final hoursController = manager.getHoursController('worker-1', isHourly: true);
        final overtimeController = manager.getOvertimeController('worker-1');
        
        expect(hoursController.text, equals('160'));
        expect(overtimeController.text, equals('0'));
        
        // Set attendance data that exceeds threshold
        manager.setAttendanceData({'worker-1': 200.0});
        
        expect(hoursController.text, equals('160.0'));
        expect(overtimeController.text, equals('40.0'));
      });
    });

    group('Getter Methods', () {
      test('getHours should return correct numeric value', () {
        manager.setPayPeriodDays(30);
        manager.setAttendanceData({'worker-1': 125.5});
        
        // Create controller first
        manager.getHoursController('worker-1', isHourly: true);
        
        final hours = manager.getHours('worker-1');
        
        expect(hours, equals(125.5));
      });

      test('getOvertime should return correct numeric value', () {
        manager.setPayPeriodDays(30);
        manager.setAttendanceData({'worker-1': 180.0});
        
        // Create controller first
        manager.getOvertimeController('worker-1');
        
        final overtime = manager.getOvertime('worker-1');
        
        expect(overtime, equals(20.0));
      });

      test('getHours should return default when no controller exists', () {
        manager.setPayPeriodDays(30);
        
        final hours = manager.getHours('worker-nonexistent');
        
        expect(hours, equals(PayrollConstants.defaultMonthlyHours));
      });
    });
  });
}
