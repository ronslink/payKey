import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/presentation/providers/statutory_deadlines_provider.dart';

void main() {
  group('StatutoryDeadline', () {
    test('should parse from JSON correctly', () {
      final json = {
        'title': 'PAYE Remittance',
        'description': 'Pay As You Earn for previous month',
        'dueDate': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      };

      final deadline = StatutoryDeadline.fromJson(json);

      expect(deadline.title, equals('PAYE Remittance'));
      expect(deadline.description, equals('Pay As You Earn for previous month'));
      expect(deadline.daysUntilDue, greaterThanOrEqualTo(4));
      expect(deadline.daysUntilDue, lessThanOrEqualTo(6));
      expect(deadline.isPastDue, isFalse);
    });

    test('should calculate days until due correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final json = {
        'title': 'NSSF Contribution',
        'description': 'Social Security Fund',
        'dueDate': futureDate.toIso8601String(),
      };

      final deadline = StatutoryDeadline.fromJson(json);

      expect(deadline.daysUntilDue, greaterThanOrEqualTo(9));
      expect(deadline.daysUntilDue, lessThanOrEqualTo(11));
      expect(deadline.isPastDue, isFalse);
    });

    test('should detect past due deadlines', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final json = {
        'title': 'Housing Levy',
        'description': 'Affordable Housing Levy',
        'dueDate': pastDate.toIso8601String(),
      };

      final deadline = StatutoryDeadline.fromJson(json);

      expect(deadline.isPastDue, isTrue);
      expect(deadline.daysUntilDue, lessThan(0));
    });

    test('should handle empty or null values gracefully', () {
      final json = <String, dynamic>{
        'title': null,
        'description': null,
        'dueDate': null,
      };

      // Should not throw
      final deadline = StatutoryDeadline.fromJson(json);
      
      expect(deadline.title, equals(''));
      expect(deadline.description, equals(''));
    });

    test('should correctly identify due today', () {
      final today = DateTime.now();
      final json = {
        'title': 'SHIF Contribution',
        'description': 'Social Health Insurance',
        'dueDate': today.toIso8601String(),
      };

      final deadline = StatutoryDeadline.fromJson(json);

      // daysUntilDue should be 0 or -1 depending on time of day
      expect(deadline.daysUntilDue, lessThanOrEqualTo(0));
    });
  });

  group('Statutory Deadlines Use Cases', () {
    test('typical Kenya deadlines include PAYE, NSSF, SHIF', () {
      // Backend returns Kenya-specific deadlines
      final kenyaDeadlines = [
        {'title': 'PAYE Remittance', 'description': 'Pay As You Earn', 'dueDate': '2026-02-09'},
        {'title': 'Housing Levy', 'description': 'Affordable Housing', 'dueDate': '2026-02-09'},
        {'title': 'SHIF/NHIF Contribution', 'description': 'Health Insurance', 'dueDate': '2026-02-09'},
        {'title': 'NSSF Contribution', 'description': 'Social Security', 'dueDate': '2026-02-15'},
      ];

      final deadlines = kenyaDeadlines.map((d) => StatutoryDeadline.fromJson(d)).toList();

      expect(deadlines.length, equals(4));
      expect(deadlines.any((d) => d.title.contains('PAYE')), isTrue);
      expect(deadlines.any((d) => d.title.contains('NSSF')), isTrue);
      expect(deadlines.any((d) => d.title.contains('SHIF') || d.title.contains('NHIF')), isTrue);
    });
  });
}
