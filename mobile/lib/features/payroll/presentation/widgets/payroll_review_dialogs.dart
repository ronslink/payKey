import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/payroll_model.dart';

final _currencyFormatter = NumberFormat('#,###');

/// Dialog explaining payroll calculation methodology
class PayrollHelpDialog extends StatelessWidget {
  const PayrollHelpDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const PayrollHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('About Payroll Calculations (2024)'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              'NSSF (2024 Rates)',
              '• Tier I: 6% of first KES 7,000\n'
                  '• Tier II: 6% of KES 7,001 - 36,000',
            ),
            _buildSection(
              'NHIF/SHIF',
              'Based on gross salary brackets (KES 150 - 1,700/month)',
            ),
            _buildSection(
              'Housing Levy',
              '1.5% of gross salary (effective March 2024)',
            ),
            _buildSection(
              'PAYE Tax Bands',
              '• 0 - 24,000: 10%\n'
                  '• 24,001 - 32,333: 25%\n'
                  '• 32,334 - 500,000: 30%\n'
                  '• 500,001 - 800,000: 32.5%\n'
                  '• Above 800,000: 35%\n'
                  '• Personal Relief: KES 2,400/month',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(content),
        ],
      ),
    );
  }
}

/// Dialog to confirm M-Pesa payment
class MpesaConfirmationDialog extends StatelessWidget {
  final double totalAmount;
  final int workerCount;
  final VoidCallback onConfirm;

  const MpesaConfirmationDialog({
    super.key,
    required this.totalAmount,
    required this.workerCount,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required double totalAmount,
    required int workerCount,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MpesaConfirmationDialog(
        totalAmount: totalAmount,
        workerCount: workerCount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm M-Pesa Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: 16),
          Text(
            'You are about to pay KES ${_currencyFormatter.format(totalAmount)} to $workerCount workers.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          _buildWarningBox(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Proceed'),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.phone_android, size: 48, color: Colors.green),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'A payment request will be sent to your M-Pesa registered phone.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown after payment processing (Success, Partial, or Failure)
class PaymentResultDialog extends StatelessWidget {
  final PayrollProcessingResult result;
  final double totalAmount;
  final VoidCallback onViewFinance;

  const PaymentResultDialog({
    super.key,
    required this.result,
    required this.totalAmount,
    required this.onViewFinance,
  });

  static Future<void> show(
    BuildContext context, {
    required PayrollProcessingResult result,
    required double totalAmount,
    required VoidCallback onViewFinance,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentResultDialog(
        result: result,
        totalAmount: totalAmount,
        onViewFinance: onViewFinance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (result.isFullSuccess) {
      return _buildSuccessDialog(context);
    } else if (result.isPartialSuccess) {
      return _buildPartialSuccessDialog(context);
    } else {
      return _buildFailureDialog(context);
    }
  }

  Widget _buildSuccessDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: _buildIcon(Icons.check_circle, Colors.green),
      title: const Text('Payment Successful!'),
      content: Text(
        'Payroll for ${result.successCount} workers has been processed.\n\n'
        'Total: KES ${_currencyFormatter.format(totalAmount)}',
        textAlign: TextAlign.center,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onViewFinance();
            },
            child: const Text('View Finance'),
          ),
        ),
      ],
    );
  }

  Widget _buildPartialSuccessDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: _buildIcon(Icons.warning_amber_rounded, Colors.orange),
      title: const Text('Partial Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${result.successCount} paid successfully.\n${result.failureCount} failed.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'The following workers could not be paid:',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              itemCount: result.results.length,
              itemBuilder: (context, index) {
                final item = result.results[index];
                if (item.success) return const SizedBox.shrink();
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(item.workerName),
                  subtitle: Text(item.error ?? 'Unknown error', style: const TextStyle(fontSize: 11)),
                  leading: const Icon(Icons.error, color: Colors.red, size: 16),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            onViewFinance();
          },
          child: const Text('View Finance'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // In a real app, logic to retry only failed ones would go here
            // For now we just close, user can try again from list
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildFailureDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: _buildIcon(Icons.error_outline, Colors.red),
      title: const Text('Payment Failed'),
      content: const Text(
        'All payments failed to process.\nPlease check your balance and try again.',
        textAlign: TextAlign.center,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}
