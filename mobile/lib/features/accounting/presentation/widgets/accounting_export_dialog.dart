import 'package:flutter/material.dart';

class AccountingExportDialog extends StatelessWidget {
  final String payPeriodId;

  const AccountingExportDialog({super.key, required this.payPeriodId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Accounting Data'),
      content: Text('Export data for pay period: \$payPeriodId'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement export logic
            Navigator.of(context).pop();
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
