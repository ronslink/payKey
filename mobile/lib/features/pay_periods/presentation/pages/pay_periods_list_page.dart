import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// Use the canonical Freezed-based PayPeriod model
import '../../../payroll/data/models/pay_period_model.dart';
import '../providers/pay_periods_provider.dart';

class PayPeriodsListPage extends ConsumerWidget {
  const PayPeriodsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payPeriodsState = ref.watch(payPeriodsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Pay Periods',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF6B7280)),
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6B7280)),
            onPressed: () => context.push('/pay-periods/create'),
          ),
        ],
      ),
      body: payPeriodsState.when(
        data: (payPeriods) => _buildContent(context, ref, payPeriods),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading pay periods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(payPeriodsProvider.notifier).loadPayPeriods(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/pay-periods/create'),
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<PayPeriod> payPeriods) {
    if (payPeriods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: const Color(0xFF6B7280).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pay Periods Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first pay period to get started',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/pay-periods/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Pay Period'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(payPeriodsProvider.notifier).loadPayPeriods(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payPeriods.length,
        itemBuilder: (context, index) {
          final payPeriod = payPeriods[index];
          return _buildPayPeriodCard(context, ref, payPeriod);
        },
      ),
    );
  }

  Widget _buildPayPeriodCard(BuildContext context, WidgetRef ref, PayPeriod payPeriod) {
    final dateFormat = DateFormat('MMM d, y');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/pay-periods/${payPeriod.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payPeriod.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(payPeriod.startDate)} to ${dateFormat.format(payPeriod.endDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payPeriod.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      payPeriod.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(payPeriod.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gross Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'KES ${(payPeriod.totalGrossAmount ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'KES ${(payPeriod.totalNetAmount ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${payPeriod.totalWorkers ?? 0}/${payPeriod.processedWorkers ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    payPeriod.frequency.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      backgroundColor: Color(0xFFF3F4F6),
                    ),
                  ),
                  const Spacer(),
                  if (payPeriod.payDate != null)
                    Text(
                      'Pay: ${dateFormat.format(payPeriod.payDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return const Color(0xFF6B7280);
      case PayPeriodStatus.active:
        return const Color(0xFF10B981);
      case PayPeriodStatus.processing:
        return const Color(0xFFF59E0B);
      case PayPeriodStatus.completed:
        return const Color(0xFF3B82F6);
      case PayPeriodStatus.closed:
        return const Color(0xFFEF4444);
      case PayPeriodStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Pay Periods'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add filter options here
            // This is a simplified version - you'd want to add actual filter controls
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
