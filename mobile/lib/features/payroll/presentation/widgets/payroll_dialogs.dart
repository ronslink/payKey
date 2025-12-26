import 'package:flutter/material.dart';

/// Dialog to confirm initializing pay periods for a year
class InitializeYearDialog extends StatelessWidget {
  final int year;

  const InitializeYearDialog({
    super.key,
    required this.year,
  });

  static Future<bool?> show(BuildContext context, int year) {
    return showDialog<bool>(
      context: context,
      builder: (context) => InitializeYearDialog(year: year),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text('Initialize $year'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No pay periods found for $year.'),
          const SizedBox(height: 12),
          Text(
            'This will create 12 monthly pay periods from January $year to December $year.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Generate Periods'),
        ),
      ],
    );
  }
}

/// Dialog shown after successful payroll completion
class PayrollCompleteDialog extends StatelessWidget {
  final int totalProcessed;
  final VoidCallback onReturnHome;
  final VoidCallback onViewFinance;

  const PayrollCompleteDialog({
    super.key,
    required this.totalProcessed,
    required this.onReturnHome,
    required this.onViewFinance,
  });

  static Future<void> show(
    BuildContext context, {
    required int totalProcessed,
    required VoidCallback onReturnHome,
    required VoidCallback onViewFinance,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PayrollCompleteDialog(
        totalProcessed: totalProcessed,
        onReturnHome: onReturnHome,
        onViewFinance: onViewFinance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Payroll Complete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Successfully processed $totalProcessed workers.'),
          const SizedBox(height: 8),
          const Text('• Payslips generated'),
          const Text('• Tax returns filed'),
          const Text('• Records finalized'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onReturnHome();
          },
          child: const Text('Return to Home'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onViewFinance();
          },
          child: const Text('View Finance'),
        ),
      ],
    );
  }
}
