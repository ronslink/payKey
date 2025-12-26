import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../pay_periods/presentation/providers/pay_periods_provider.dart';
// Use the canonical Freezed-based PayPeriod model
import '../../../payroll/data/models/pay_period_model.dart';

class PayrollHistoryTab extends ConsumerWidget {
  const PayrollHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payPeriodsState = ref.watch(payPeriodsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payroll History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'View past payroll periods and their status.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),
          payPeriodsState.when(
            data: (payPeriods) {
              if (payPeriods.isEmpty) {
                return _buildEmptyState();
              }
              
              // Sort by start date descending
              final sortedPeriods = [...payPeriods]
                ..sort((a, b) => b.startDate.compareTo(a.startDate));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPeriods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildHistoryItem(context, sortedPeriods[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Text('Error loading history: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No payroll history found',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, PayPeriod period) {
    final dateFormat = DateFormat('MMM d');
    final dateFormatYear = DateFormat('MMM d, y');
    final startDate = dateFormat.format(period.startDate);
    final endDate = dateFormatYear.format(period.endDate);
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    
    switch (period.status) {
      case PayPeriodStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      case PayPeriodStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
      case PayPeriodStatus.active:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
      case PayPeriodStatus.closed:
        statusColor = Colors.purple;
        statusIcon = Icons.lock;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt_long, color: statusColor, size: 24),
        ),
        title: Text(
          period.name.isNotEmpty ? period.name : 'Pay Period',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$startDate - $endDate'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  period.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // TODO: Navigate to details if needed
        },
      ),
    );
  }
}
