import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';

class PayrollWorkflowPage extends ConsumerStatefulWidget {
  final String payPeriodId;
  
  const PayrollWorkflowPage({
    super.key,
    required this.payPeriodId,
  });

  @override
  ConsumerState<PayrollWorkflowPage> createState() => _PayrollWorkflowPageState();
}

class _PayrollWorkflowPageState extends ConsumerState<PayrollWorkflowPage> {
  PayPeriod? _payPeriod;
  bool _isLoading = false;
  PayPeriodStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _loadPayPeriod();
    _loadStatistics();
  }

  Future<void> _loadPayPeriod() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payPeriod = await repository.getPayPeriodById(widget.payPeriodId);
      if (mounted) {
        setState(() {
          _payPeriod = payPeriod;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pay period: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final stats = await repository.getPayPeriodStatistics(widget.payPeriodId);
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
    } catch (e) {
      // Statistics might not be available for all periods
    }
  }

  Future<void> _executeWorkflowAction(PayPeriodStatusAction action) async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      PayPeriod updatedPeriod;

      switch (action) {
        case PayPeriodStatusAction.activate:
          updatedPeriod = await repository.activatePayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatusAction.process:
          updatedPeriod = await repository.processPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatusAction.complete:
          updatedPeriod = await repository.completePayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatusAction.close:
          updatedPeriod = await repository.closePayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatusAction.cancel:
          await repository.updatePayPeriodStatus(widget.payPeriodId, 'cancel');
          updatedPeriod = await repository.getPayPeriodById(widget.payPeriodId);
          break;
        case PayPeriodStatusAction.reopen:
          await repository.updatePayPeriodStatus(widget.payPeriodId, 'reopen');
          updatedPeriod = await repository.getPayPeriodById(widget.payPeriodId);
          break;
      }

      if (mounted) {
        setState(() {
          _payPeriod = updatedPeriod;
        });
        
        // Reload statistics to get updated totals
        await _loadStatistics();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pay period ${action.name.toLowerCase()}d successfully'),
            backgroundColor: Colors.green,
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
      case PayPeriodStatus.active:
        return Colors.blue;
      case PayPeriodStatus.processing:
        return Colors.orange;
      case PayPeriodStatus.completed:
        return Colors.green;
      case PayPeriodStatus.closed:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  List<PayPeriodStatusAction> _getAvailableActions(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return [
          PayPeriodStatusAction.activate,
          PayPeriodStatusAction.close,
        ];
      case PayPeriodStatus.active:
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
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (_payPeriod == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payroll Workflow'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final availableActions = _getAvailableActions(_payPeriod!.status);
    final currentStatusIndex = PayPeriodStatus.values.indexOf(_payPeriod!.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Workflow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPayPeriod();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _payPeriod!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dateFormat.format(_payPeriod!.startDate)} - ${dateFormat.format(_payPeriod!.endDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_payPeriod!.status) .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_payPeriod!.status),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _payPeriod!.status.name.replaceAll('_', ' '),
                            style: TextStyle(
                              color: _getStatusColor(_payPeriod!.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Frequency: ${_payPeriod!.frequency.name.replaceAll('_', ' ')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Workflow Steps
            _buildWorkflowSteps(currentStatusIndex),

            const SizedBox(height: 24),

            // Statistics (if available)
            if (_statistics != null) _buildStatisticsSection(),

            const SizedBox(height: 24),

            // Available Actions
            if (availableActions.isNotEmpty) _buildActionsSection(availableActions),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowSteps(int currentStatusIndex) {
    const steps = [
      'Draft',
      'Active',
      'Processing',
      'Completed',
      'Closed'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index < currentStatusIndex;
              final isCurrent = index == currentStatusIndex;
              final isUpcoming = index > currentStatusIndex;

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? _getStatusColor(PayPeriodStatus.active)
                              : Colors.grey.shade300,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isUpcoming ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(PayPeriodStatus.active) .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          color: _getStatusColor(PayPeriodStatus.active),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = _statistics;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Workers',
                    '${stats.totalWorkers}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Processed',
                    '${stats.processedPayments}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '${stats.pendingPayments}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Gross Total',
                    'KES ${stats.totalGrossAmount.toStringAsFixed(2)}',
                    Icons.monetization_on,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Net Total',
                    'KES ${stats.totalNetAmount.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color .withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildActionsSection(List<PayPeriodStatusAction> availableActions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableActions.map((action) {
                return ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _executeWorkflowAction(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionColor(action),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _getActionLabel(action),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/payroll/run/${_payPeriod!.id}');
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Run Payroll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // View payroll records
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View Records'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(PayPeriodStatusAction action) {
    switch (action) {
      case PayPeriodStatusAction.activate:
        return Colors.blue;
      case PayPeriodStatusAction.process:
        return Colors.orange;
      case PayPeriodStatusAction.complete:
        return Colors.green;
      case PayPeriodStatusAction.close:
        return Colors.red;
      case PayPeriodStatusAction.cancel:
        return Colors.red;
      case PayPeriodStatusAction.reopen:
        return Colors.blue;
    }
  }

  String _getActionLabel(PayPeriodStatusAction action) {
    switch (action) {
      case PayPeriodStatusAction.activate:
        return 'Activate Period';
      case PayPeriodStatusAction.process:
        return 'Process Payroll';
      case PayPeriodStatusAction.complete:
        return 'Complete Period';
      case PayPeriodStatusAction.close:
        return 'Close Period';
      case PayPeriodStatusAction.cancel:
        return 'Cancel Period';
      case PayPeriodStatusAction.reopen:
        return 'Reopen Period';
    }
  }
}