import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';
import '../../presentation/providers/pay_period_provider.dart';

class PayPeriodManagementPage extends ConsumerStatefulWidget {
  const PayPeriodManagementPage({super.key});

  @override
  ConsumerState<PayPeriodManagementPage> createState() =>
      _PayPeriodManagementPageState();
}

class _PayPeriodManagementPageState
    extends ConsumerState<PayPeriodManagementPage> {
  PayPeriodStatus? _selectedStatusFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(payPeriodsProvider.notifier).loadPayPeriods();
    });
  }

  Future<void> _executeAction(
    PayPeriodStatusAction action,
    String payPeriodId,
  ) async {
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(payPeriodsProvider.notifier);

      switch (action) {
        case PayPeriodStatusAction.activate:
          await notifier.activatePayPeriod(payPeriodId);
          break;
        case PayPeriodStatusAction.process:
          await notifier.processPayPeriod(payPeriodId);
          break;
        case PayPeriodStatusAction.complete:
          await notifier.completePayPeriod(payPeriodId);
          break;
        case PayPeriodStatusAction.close:
          await notifier.closePayPeriod(payPeriodId);
          break;
        default:
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pay period ${action.name.toLowerCase()}d successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.name.toLowerCase()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return Colors.grey.shade600;
      case PayPeriodStatus.open:
        return Colors.blue;
      case PayPeriodStatus.processing:
        return Colors.orange;
      case PayPeriodStatus.completed:
        return Colors.green;
      case PayPeriodStatus.closed:
        return Colors.deepPurple;
      case PayPeriodStatus.cancelled:
        return Colors.red;
    }
  }

  List<PayPeriodStatusAction> getAvailableActions(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return [
          PayPeriodStatusAction.activate,
          PayPeriodStatusAction.close,
        ];
      case PayPeriodStatus.open:
        return [
          PayPeriodStatusAction.process,
          PayPeriodStatusAction.close,
        ];
      case PayPeriodStatus.processing:
        return [
          PayPeriodStatusAction.complete,
          PayPeriodStatusAction.close,
        ];
      case PayPeriodStatus.completed:
        return [PayPeriodStatusAction.close];
      case PayPeriodStatus.closed:
        return []; // No actions available for closed periods
      case PayPeriodStatus.cancelled:
        return []; // No actions available for cancelled periods
    }
  }
  @override
  Widget build(BuildContext context) {
    final payPeriodsState = ref.watch(payPeriodsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Period Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/payroll/run');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(payPeriodsProvider.notifier).loadPayPeriods();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filter by Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<PayPeriodStatus?>(
                    initialValue: _selectedStatusFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...PayPeriodStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name.replaceAll('_', ' ')),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatusFilter = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Pay Periods List
          Expanded(
            child: payPeriodsState.when(
              data: (payPeriods) {
                final filteredPeriods = _selectedStatusFilter == null
                    ? payPeriods
                    : payPeriods.where(
                        (p) => p.status == _selectedStatusFilter,
                      ).toList();

                if (filteredPeriods.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pay periods found',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(payPeriodsProvider.notifier).loadPayPeriods();
                  },
                  child: ListView.builder(
                    itemCount: filteredPeriods.length,
                    itemBuilder: (context, index) {
                      final period = filteredPeriods[index];
                      final availableActions =
                          getAvailableActions(period.status);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          period.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          period.frequency.name
                                              .replaceAll('_', ' '),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(period.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _getStatusColor(period.status),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      period.status.name.replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: _getStatusColor(period.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Statistics (if available)
                              Row(
                                children: [
                                  Expanded(
                                    child: buildStatCard(
                                      'Total Gross',
                                      'KES ${period.totalGrossAmount.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: buildStatCard(
                                      'Total Net',
                                      'KES ${period.totalNetAmount.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: buildStatCard(
                                      'Workers',
                                      '${period.processedWorkers ?? 0}',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Actions
                              if (availableActions.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: availableActions.map((action) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(left: 8.0),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => _executeAction(
                                                  action,
                                                  period.id,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              getActionColor(action),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          getActionLabel(action),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                              // Navigation buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      context.push(
                                        '/payroll/run/${period.id}',
                                      );
                                    },
                                    child: const Text('View/Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        final repository = ref.read(
                                          payPeriodRepositoryProvider,
                                        );
                                        final statistics =
                                            await repository.getPayPeriodStatistics(
                                              period.id,
                                            );
                                        if (mounted) {
                                          showStatisticsDialog(
                                            context,
                                            period.name,
                                            statistics,
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to load statistics: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Statistics'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading pay periods: ${error.toString()}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color getActionColor(PayPeriodStatusAction action) {
    switch (action) {
      case PayPeriodStatusAction.activate:
        return Colors.blue;
      case PayPeriodStatusAction.process:
        return Colors.orange;
      case PayPeriodStatusAction.complete:
        return Colors.green;
      case PayPeriodStatusAction.close:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getActionLabel(PayPeriodStatusAction action) {
    switch (action) {
      case PayPeriodStatusAction.activate:
        return 'Activate';
      case PayPeriodStatusAction.process:
        return 'Process';
      case PayPeriodStatusAction.complete:
        return 'Complete';
      case PayPeriodStatusAction.close:
        return 'Close';
      default:
        return '';
    }
  }

  void showStatisticsDialog(
    BuildContext context,
    String periodName,
    Map<String, dynamic> statistics,
  ) {
    final numberFormat = NumberFormat('#,###.00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Statistics: $periodName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildStatRow('Total Workers', '${statistics['totalWorkers']}'),
              buildStatRow(
                'Pending Payments',
                '${statistics['pendingPayments']}',
              ),
              buildStatRow(
                'Processed Payments',
                '${statistics['processedPayments']}',
              ),
              const Divider(),
              buildStatRow(
                'Total Gross Amount',
                'KES ${numberFormat.format(statistics['totalGrossAmount'])}',
              ),
              buildStatRow(
                'Total Net Amount',
                'KES ${numberFormat.format(statistics['totalNetAmount'])}',
              ),
              buildStatRow(
                'Total Tax Amount',
                'KES ${numberFormat.format(statistics['totalTaxAmount'])}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}