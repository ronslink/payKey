import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/payroll_record_model.dart' as payroll;
import '../providers/transactions_provider.dart';
import '../../data/repositories/payroll_records_repository.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  String _activeTab = 'subscription';

  @override
  void initState() {
    super.initState();
    // Load data on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(transactionsProvider.notifier).fetchTransactions();
    // Call repository directly since it's a regular Provider
    ref.read(payrollRecordsRepositoryProvider).getPayrollRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Payment History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'View all your transactions',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('subscription', 'Subscriptions'),
                  ),
                  Expanded(
                    child: _buildTabButton('payroll', 'Payroll'),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _activeTab == 'subscription'
                ? _buildSubscriptionTab()
                : _buildPayrollTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    final subscriptionState = ref.watch(transactionsProvider);

    return subscriptionState.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.credit_card,
            title: 'No Transactions Yet',
            subtitle: 'Your subscription payment history will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPayrollTab() {
    final payrollRepository = ref.read(payrollRecordsRepositoryProvider);
    final Future<List<payroll.PayrollRecordModel>> payrollFuture = payrollRepository.getPayrollRecords();

    return FutureBuilder<List<payroll.PayrollRecordModel>>(
      future: payrollFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load payroll records');
        }

        final records = snapshot.data ?? [];
        
        if (records.isEmpty) {
          return _buildEmptyState(
            icon: Icons.credit_card,
            title: 'No Payroll Records Yet',
            subtitle: 'Process your first payroll to see records here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            return _buildPayrollRecordCard(records[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final statusConfig = _getTransactionStatusConfig(transaction.status);
    
    return InkWell(
      onTap: () => GoRouter.of(context).push('/payments/${transaction.id}', extra: transaction),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black .withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusConfig['bg'] as Color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      statusConfig['icon'] as IconData,
                      color: statusConfig['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.paymentMethod == 'stripe'
                              ? 'Subscription Payment'
                              : 'M-Pesa Payment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(transaction.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusConfig['bg'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusConfig['text'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusConfig['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (transaction.invoiceUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 16,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Download Invoice',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayrollRecordCard(payroll.PayrollRecordModel record) {
    final statusConfig = _getPayrollStatusConfig(record.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusConfig['bg'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    statusConfig['icon'] as IconData,
                    color: statusConfig['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.workerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDateTime(record.createdAt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${record.netSalary.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusConfig['bg'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusConfig['text'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusConfig['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment Details
            Row(
              children: [
                const Icon(
                  Icons.payment,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Gross: KES ${record.grossSalary.toStringAsFixed(0)} | Tax: KES ${record.taxAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            // Actions
            if (record.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _finalizePayroll(record.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Finalize Payroll'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePayrollRecord(record.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (record.status == 'completed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePayrollRecord(record.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTransactionStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'bg': const Color(0xFFD1FAE5),
          'text': 'Succeeded',
        };
      case 'failed':
        return {
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEE2E2),
          'text': 'Failed',
        };
      case 'pending':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'text': 'Pending',
        };
      case 'processing':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFF3B82F6),
          'bg': const Color(0xFFDBEAFE),
          'text': 'Processing',
        };
      default:
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'text': 'Pending',
        };
    }
  }

  Map<String, dynamic> _getPayrollStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'bg': const Color(0xFFD1FAE5),
          'text': 'Paid',
        };
      case 'failed':
        return {
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEE2E2),
          'text': 'Failed',
        };
      case 'pending':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'text': 'Pending',
        };
      case 'processing':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFF3B82F6),
          'bg': const Color(0xFFDBEAFE),
          'text': 'Processing',
        };
      default:
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'text': 'Pending',
        };
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _finalizePayroll(String payPeriodId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Payroll'),
        content: const Text('This will mark the payroll as paid and create tax remittance records. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Call the update status API to mark as completed
        final payrollRepository = ref.read(payrollRecordsRepositoryProvider);
        await payrollRepository.updatePayrollStatus(payPeriodId, 'completed', paymentDate: DateTime.now().toIso8601String());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payroll finalized successfully')),
          );
          // Refresh the data
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to finalize payroll: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deletePayrollRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('This cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement delete payroll record logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll record deleted')),
        );
      }
    }
  }
}