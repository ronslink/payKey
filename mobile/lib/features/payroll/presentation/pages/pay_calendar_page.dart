import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';

class PayCalendarPage extends ConsumerWidget {
  const PayCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Calendar'),
      ),
      body: payPeriodsAsync.when(
        data: (payPeriods) {
          if (payPeriods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No pay periods found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _createNewPayPeriod(context, ref),
                    child: const Text('Start New Pay Period'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: payPeriods.length,
            itemBuilder: (context, index) {
              final period = payPeriods[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(period.name),
                  subtitle: Text(
                    '${DateFormat('MMM d').format(period.startDate)} - ${DateFormat('MMM d').format(period.endDate)}',
                  ),
                  trailing: _buildStatusChip(period.status),
                  onTap: () {
                    if (period.status == PayPeriodStatus.active) {
                      context.push('/payroll/run/${period.id}');
                    } else {
                      // TODO: Navigate to Tax Report
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tax Report coming soon')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPayPeriod(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(PayPeriodStatus status) {
    Color color;
    switch (status) {
      case PayPeriodStatus.active:
        color = Colors.green;
        break;
      case PayPeriodStatus.processing:
        color = Colors.orange;
        break;
      case PayPeriodStatus.closed:
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Future<void> _createNewPayPeriod(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    
    // Simple dialog to confirm creation for current month
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Pay Period'),
        content: Text(
          'Create pay period for ${DateFormat('MMMM yyyy').format(now)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final request = CreatePayPeriodRequest(
        name: DateFormat('MMMM yyyy').format(now),
        startDate: startDate,
        endDate: endDate,
        frequency: PayPeriodFrequency.monthly,
      );
      await ref.read(payPeriodsProvider.notifier).createPayPeriod(request);
    }
  }
}
