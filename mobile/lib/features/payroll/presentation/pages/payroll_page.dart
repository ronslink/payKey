import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';

class PayrollPage extends ConsumerStatefulWidget {
  const PayrollPage({super.key});

  @override
  ConsumerState<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends ConsumerState<PayrollPage> {
  PayPeriodStatus? _selectedStatus = PayPeriodStatus.active;
  
  @override
  Widget build(BuildContext context) {
    final payPeriodsState = _selectedStatus == null
        ? ref.watch(payPeriodsProvider)
        : ref.watch(payPeriodsByStatusProvider(_selectedStatus!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedStatus == null) {
                ref.refresh(payPeriodsProvider);
              } else {
                ref.refresh(payPeriodsByStatusProvider(_selectedStatus!));
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Section with Primary Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context: context,
                          title: 'Run Payroll',
                          subtitle: 'Process new payroll',
                          icon: Icons.play_circle_filled,
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push('/payroll/run'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context: context,
                          title: 'Review Payroll',
                          subtitle: 'View active periods',
                          icon: Icons.fact_check,
                          color: const Color(0xFF10B981),
                          onTap: () => _navigateToActivePayPeriod(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Active Pay Period Summary
          SliverToBoxAdapter(
            child: payPeriodsState.when(
              data: (payPeriods) {
                final activePeriods = payPeriods.where(
                  (p) => p.status == PayPeriodStatus.active || 
                         p.status == PayPeriodStatus.processing
                ).toList();
                
                if (activePeriods.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Active Pay Periods',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...activePeriods.map((period) => _buildActivePeriodCard(context, period)),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Pay Periods List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Pay Periods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<PayPeriodStatus?>(
                    value: _selectedStatus,
                    hint: const Text('Filter'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      ...PayPeriodStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (status) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Pay Periods List
          payPeriodsState.when(
            data: (payPeriods) {
              if (payPeriods.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pay periods found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_selectedStatus == null) {
                              ref.refresh(payPeriodsProvider);
                            } else {
                              ref.refresh(payPeriodsByStatusProvider(_selectedStatus!));
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final period = payPeriods[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(period.status).withValues(alpha: 0.2),
                            child: Icon(
                              _getStatusIcon(period.status),
                              color: _getStatusColor(period.status),
                            ),
                          ),
                          title: Text(
                            period.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${period.startDate} - ${period.endDate}'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Gross: KES ${(period.totalGrossAmount ?? 0.0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Net: KES ${(period.totalNetAmount ?? 0.0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Workers: ${period.totalWorkers ?? 0} | Processed: ${period.processedWorkers ?? 0}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: _buildStatusBadge(period.status),
                          onTap: () {
                            context.push('/payroll/review/${period.id}');
                          },
                        ),
                      );
                    },
                    childCount: payPeriods.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading pay periods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedStatus == null) {
                            ref.refresh(payPeriodsProvider);
                          } else {
                            ref.refresh(payPeriodsByStatusProvider(_selectedStatus!));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePeriodCard(BuildContext context, PayPeriod period) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(period.status).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/payroll/review/${period.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      period.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(period.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${period.startDate} - ${period.endDate}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Workers', '${period.processedWorkers ?? 0}/${period.totalWorkers ?? 0}'),
                  _buildMetric('Gross', 'KES ${(period.totalGrossAmount ?? 0.0).toStringAsFixed(0)}'),
                  _buildMetric('Net', 'KES ${(period.totalNetAmount ?? 0.0).toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PayPeriodStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1.5,
        ),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return Colors.grey;
      case PayPeriodStatus.active:
        return const Color(0xFF3B82F6);
      case PayPeriodStatus.processing:
        return const Color(0xFFF59E0B);
      case PayPeriodStatus.completed:
        return const Color(0xFF10B981);
      case PayPeriodStatus.closed:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return Icons.edit_note;
      case PayPeriodStatus.active:
        return Icons.play_circle;
      case PayPeriodStatus.processing:
        return Icons.sync;
      case PayPeriodStatus.completed:
        return Icons.check_circle;
      case PayPeriodStatus.closed:
        return Icons.lock;
      default:
        return Icons.circle;
    }
  }

  void _navigateToActivePayPeriod(BuildContext context) {
    final payPeriodsState = ref.read(payPeriodsByStatusProvider(PayPeriodStatus.active));
    
    payPeriodsState.whenData((periods) {
      if (periods.isNotEmpty) {
        context.push('/payroll/review/${periods.first.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active pay periods found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }
}
