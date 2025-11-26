import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';

class PayrollReviewPage extends ConsumerStatefulWidget {
  final String payPeriodId;
  
  const PayrollReviewPage({
    super.key,
    required this.payPeriodId,
  });

  @override
  ConsumerState<PayrollReviewPage> createState() => _PayrollReviewPageState();
}

class _PayrollReviewPageState extends ConsumerState<PayrollReviewPage> {
  PayPeriod? _payPeriod;
  List<PayrollRecord>? _payrollRecords;
  bool _isLoading = false;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadPayPeriod();
    _loadPayrollData();
  }

  Future<void> _loadPayPeriod() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payPeriod = await repository.getPayPeriod(widget.payPeriodId);
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

  Future<void> _loadPayrollData() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final stats = await repository.getPayPeriodStatistics(widget.payPeriodId);
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
    } catch (e) {
      print('Failed to load payroll data: $e');
    }
  }

  Future<void> _transitionToNextStage() async {
    if (_payPeriod == null) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      PayPeriod updatedPeriod;

      switch (_payPeriod!.status) {
        case PayPeriodStatus.draft:
          updatedPeriod = await repository.activatePayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.open:
          updatedPeriod = await repository.processPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.processing:
          updatedPeriod = await repository.completePayPeriod(widget.payPeriodId);
          break;
        default:
          // For completed or closed periods, navigate to workflow page
          if (mounted) {
            context.push('/payroll/workflow/${widget.payPeriodId}');
          }
          return;
      }

      if (mounted) {
        setState(() {
          _payPeriod = updatedPeriod;
        });
        await _loadPayrollData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transitioned to ${updatedPeriod.status.name.replaceAll('_', ' ').toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto-navigate to workflow page after transition
        if (mounted) {
          context.push('/payroll/workflow/${widget.payPeriodId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transition stage: $e'),
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

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###.00');
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (_payPeriod == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payroll Review'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${_payPeriod!.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPayPeriod();
              _loadPayrollData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            _buildHeader(),

            const SizedBox(height: 24),

            // Summary Statistics
            if (_statistics != null) _buildSummarySection(),

            const SizedBox(height: 24),

            // Individual Records
            _buildRecordsSection(),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
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
                        '${dateFormat.format(DateTime.parse(_payPeriod!.startDate))} - ${dateFormat.format(DateTime.parse(_payPeriod!.endDate))}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
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
                _buildStatusBadge(_payPeriod!.status),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Period Gross',
                    'KES ${_payPeriod?.totalGrossAmount.toStringAsFixed(2) ?? "0.00"}',
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Period Net',
                    'KES ${_payPeriod?.totalNetAmount.toStringAsFixed(2) ?? "0.00"}',
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Workers',
                    '${_payPeriod?.processedWorkers ?? 0}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PayPeriodStatus status) {
    Color color;
    String displayText;

    switch (status) {
      case PayPeriodStatus.draft:
        color = Colors.grey.shade600;
        displayText = 'DRAFT';
        break;
      case PayPeriodStatus.open:
        color = Colors.blue;
        displayText = 'ACTIVE';
        break;
      case PayPeriodStatus.processing:
        color = Colors.orange;
        displayText = 'PROCESSING';
        break;
      case PayPeriodStatus.completed:
        color = Colors.green;
        displayText = 'COMPLETED';
        break;
      case PayPeriodStatus.closed:
        color = Colors.deepPurple;
        displayText = 'CLOSED';
        break;
      default:
        color = Colors.grey;
        displayText = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final stats = _statistics!;
    final numberFormat = NumberFormat('#,###.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Workers',
                    '${stats['statistics']['totalWorkers']}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Processed',
                    '${stats['statistics']['processedPayments']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pending',
                    '${stats['statistics']['pendingPayments']}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Gross Amount'),
                      Text(
                        'KES ${numberFormat.format(stats['statistics']['totalGrossAmount'])}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Net Amount'),
                      Text(
                        'KES ${numberFormat.format(stats['statistics']['totalNetAmount'])}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsSection() {
    // This would typically display individual worker payroll records
    // For now, show a placeholder
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Individual payroll records will be displayed here',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click "View Details" to see worker-by-worker breakdown',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final numberFormat = NumberFormat('#,###.00');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
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
                    onPressed: _isLoading ? null : _transitionToNextStage,
                    icon: const Icon(Icons.skip_next),
                    label: Text(_getNextStageButtonText()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getNextStageColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/payroll/workflow/${widget.payPeriodId}');
                    },
                    icon: const Icon(Icons.timeline),
                    label: const Text('View Workflow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Edit payroll
                  context.push('/payroll/run/${widget.payPeriodId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Edit Payroll'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextStageButtonText() {
    switch (_payPeriod!.status) {
      case PayPeriodStatus.draft:
        return 'Activate Period';
      case PayPeriodStatus.open:
        return 'Process Payroll';
      case PayPeriodStatus.processing:
        return 'Complete Period';
      case PayPeriodStatus.completed:
      case PayPeriodStatus.closed:
        return 'View Workflow';
      default:
        return 'Continue';
    }
  }

  Color _getNextStageColor() {
    switch (_payPeriod!.status) {
      case PayPeriodStatus.draft:
        return Colors.blue;
      case PayPeriodStatus.open:
        return Colors.orange;
      case PayPeriodStatus.processing:
        return Colors.green;
      case PayPeriodStatus.completed:
        return Colors.deepPurple;
      case PayPeriodStatus.closed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
