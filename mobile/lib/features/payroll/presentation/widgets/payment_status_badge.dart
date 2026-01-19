import 'package:flutter/material.dart';

/// Reusable widget showing payment status with color-coded badge
/// Matches the design language of TaxStatusBadge in payroll_widgets.dart
class PaymentStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 12 : 14,
            color: config.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: config.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusConfig(
          icon: Icons.schedule,
          label: 'Pending',
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
        );
      case 'processing':
        return _StatusConfig(
          icon: Icons.sync,
          label: 'Processing',
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade700,
        );
      case 'clearing':
        return _StatusConfig(
          icon: Icons.hourglass_empty,
          label: 'Clearing',
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade700,
        );
      case 'paid':
      case 'success':
      case 'complete':
        return _StatusConfig(
          icon: Icons.check_circle,
          label: 'Paid',
          backgroundColor: Colors.green.shade50,
          textColor: Colors.green.shade700,
        );
      case 'failed':
        return _StatusConfig(
          icon: Icons.error_outline,
          label: 'Failed',
          backgroundColor: Colors.red.shade50,
          textColor: Colors.red.shade700,
        );
      default:
        return _StatusConfig(
          icon: Icons.help_outline,
          label: status,
          backgroundColor: Colors.grey.shade50,
          textColor: Colors.grey.shade700,
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusConfig({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
