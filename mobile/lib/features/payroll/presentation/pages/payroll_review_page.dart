import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/models/payroll_model.dart';
import '../../data/repositories/pay_period_repository.dart';
import '../../data/repositories/payroll_repository.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../../core/network/api_service.dart';


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
  bool isLoading = false;
  bool isGeneratingPayslips = false;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _taxSummary;
  List<PayrollCalculation> _payrollItems = [];

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
      final payrollRepo = ref.read(payrollRepositoryProvider);
      
      // Load statistics
      Map<String, dynamic>? stats;
      try {
        stats = await repository.getPayPeriodStatistics(widget.payPeriodId);
      } catch (e) {
        print('Failed to load statistics: $e');
        // Continue without statistics
      }
      
      // Load draft items
      List<PayrollCalculation> items = [];
      try {
        items = await payrollRepo.getDraftPayroll(widget.payPeriodId);
      } catch (e) {
        print('No draft items found or error loading them: $e');
      }

      if (mounted) {
        setState(() {
          _statistics = stats;
          _payrollItems = items;
          // Extract tax summary if available
          if (stats != null && stats.containsKey('taxSummary')) {
            _taxSummary = stats['taxSummary'] as Map<String, dynamic>?;
          }
        });
      }
    } catch (e) {
      print('Failed to load payroll data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payroll data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showAddWorkersDialog() async {
    final workersAsync = ref.read(workersProvider);
    
    // Extract workers from AsyncValue
    final workers = workersAsync.when(
      data: (data) => data,
      loading: () => <WorkerModel>[],
      error: (_, __) => <WorkerModel>[],
    );
    
    // Filter out workers already in the payroll
    final existingWorkerIds = _payrollItems.map((item) => item.workerId).toSet();
    final availableWorkers = workers.where((w) => !existingWorkerIds.contains(w.id)).toList();

    if (!mounted) return;

    if (availableWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All active workers are already added to this payroll.')),
      );
      return;
    }

    final selectedWorkers = <String>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Workers'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableWorkers.length,
              itemBuilder: (context, index) {
                final worker = availableWorkers[index];
                final isSelected = selectedWorkers.contains(worker.id);
                return CheckboxListTile(
                  title: Text(worker.name),
                  subtitle: Text(worker.jobTitle ?? 'No Job Title'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedWorkers.add(worker.id);
                      } else {
                        selectedWorkers.remove(worker.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedWorkers.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _addWorkersToPayroll(selectedWorkers.toList());
                    },
              child: Text('Add (${selectedWorkers.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWorkersToPayroll(List<String> workerIds) async {
    setState(() => isLoading = true);
    try {
      final payrollRepo = ref.read(payrollRepositoryProvider);
      
      // 1. Calculate initial payroll for selected workers
      final calculations = await payrollRepo.calculatePayroll(
        workerIds,
        startDate: _payPeriod!.startDate,
        endDate: _payPeriod!.endDate,
      );
      
      // 2. Prepare items for saving
      final itemsToSave = calculations.map((calc) => {
        'workerId': calc.workerId,
        'grossSalary': calc.grossSalary,
        'bonuses': calc.bonuses,
        'otherEarnings': calc.otherEarnings,
        'otherDeductions': calc.otherDeductions,
      }).toList();

      // 3. Save to draft
      await payrollRepo.saveDraftPayroll(widget.payPeriodId, itemsToSave);
      
      // 4. Refresh data
      await _loadPayrollData();
      await _loadPayPeriod(); // To update totals on the pay period itself

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${workerIds.length} workers to payroll')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add workers: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _generatePayslips() async {
    if (_payPeriod == null) return;

    setState(() => isGeneratingPayslips = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      await repository.generatePayslips(widget.payPeriodId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payslips generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPayrollData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate payslips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGeneratingPayslips = false);
      }
    }
  }

  Future<void> _prepareTaxSubmission() async {
    if (_payPeriod == null) return;

    setState(() => isLoading = true);
    try {
      // Navigate to tax page with pre-filled data
      if (mounted) {
        context.push('/taxes?payPeriodId=${widget.payPeriodId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare tax submission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _exportToAccounting() async {
    if (_payPeriod == null) return;

    try {
      // Fetch journal entries
      final apiService = ApiService();
      final response = await apiService.dio.post(
        '/accounting/journal-entries/${widget.payPeriodId}',
      );

      if (mounted) {
        _showAccountingExportDialog(response.data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load journal entries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAccountingExportDialog(Map<String, dynamic> journalData) {
    final entries = journalData['entries'] as List;
    final totalDebits = journalData['totalDebits'] as num;
    final totalCredits = journalData['totalCredits'] as num;
    final isBalanced = journalData['isBalanced'] as bool;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export to Accounting',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Journal entries for this pay period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Debit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Credit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...entries.map((entry) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry['accountName'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          entry['account'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry['debit'] > 0
                                          ? NumberFormat.currency(
                                              symbol: 'KES ',
                                              decimalDigits: 2,
                                            ).format(entry['debit'])
                                          : '-',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      entry['credit'] > 0
                                          ? NumberFormat.currency(
                                              symbol: 'KES ',
                                              decimalDigits: 2,
                                            ).format(entry['credit'])
                                          : '-',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                                border: Border(
                                  top: BorderSide(
                                    color: Color(0xFF111827),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'TOTALS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      NumberFormat.currency(
                                        symbol: 'KES ',
                                        decimalDigits: 2,
                                      ).format(totalDebits),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      NumberFormat.currency(
                                        symbol: 'KES ',
                                        decimalDigits: 2,
                                      ).format(totalCredits),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBalanced ? Icons.check_circle : Icons.error,
                              color: isBalanced
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isBalanced
                                  ? 'Journal entries are balanced'
                                  : 'Warning: Entries not balanced',
                              style: TextStyle(
                                color: isBalanced
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isBalanced
                          ? () => _downloadCSV()
                          : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Download CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Future<void> _downloadCSV() async {
    try {
      final apiService = ApiService();
      final response = await apiService.exportPayrollToCSV(widget.payPeriodId);
      
      final csvData = response.data['data'] as String;
      final filename = response.data['filename'] as String;

      // In a real app, you would use a package like 'path_provider' and 'share_plus'
      // to save and share the file. For now, we'll just show a success message.
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Exported successfully: $filename'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open file or navigate to accounting page
                context.push('/accounting');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _transitionToNextStage() async {
    if (_payPeriod == null) return;

    setState(() => isLoading = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      PayPeriod updatedPeriod;

      switch (_payPeriod!.status) {
        case PayPeriodStatus.draft:
          await repository.activatePayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.active:
          await repository.processPayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.processing:
          await repository.completePayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.completed:
          await repository.closePayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        default:
          // For completed or closed periods, stay on review page
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
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
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

                // Tax Summary (if completed)
                if (_payPeriod!.status == PayPeriodStatus.completed || 
                    _payPeriod!.status == PayPeriodStatus.closed)
                  _buildTaxSummarySection(),

                if (_payPeriod!.status == PayPeriodStatus.completed || 
                    _payPeriod!.status == PayPeriodStatus.closed)
                  const SizedBox(height: 24),

                // Individual Records
                _buildRecordsSection(),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          );
        },
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
                        '${dateFormat.format(_payPeriod!.startDate)} - ${dateFormat.format(_payPeriod!.endDate)}',
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
      case PayPeriodStatus.active:
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
        color: color.withValues(alpha: 0.1),
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



  Widget _buildSummarySection() {
    final stats = _statistics;
    if (stats == null) return const SizedBox.shrink();
    
    final statsData = stats['statistics'] as Map<String, dynamic>?;
    if (statsData == null) return const SizedBox.shrink();
    
    final numberFormat = NumberFormat('#,###.00');

    // Helper to safely get numeric value
    num getNumValue(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

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
                    '${statsData['totalWorkers'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Processed',
                    '${statsData['processedPayments'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pending',
                    '${statsData['pendingPayments'] ?? 0}',
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
                        'KES ${numberFormat.format(getNumValue(statsData['totalGrossAmount']))}',
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
                        'KES ${numberFormat.format(getNumValue(statsData['totalNetAmount']))}',
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    final isDraft = _payPeriod?.status == PayPeriodStatus.draft;
    final numberFormat = NumberFormat('#,###.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payroll Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isDraft)
                  ElevatedButton.icon(
                    onPressed: _showAddWorkersDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Workers'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_payrollItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No workers added yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      if (isDraft) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showAddWorkersDialog,
                          child: const Text('Add Workers Now'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _payrollItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _payrollItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.workerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Gross: KES ${numberFormat.format(item.grossSalary)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Net: KES ${numberFormat.format(item.netPay)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Tax: KES ${numberFormat.format(item.taxBreakdown.totalDeductions)}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool canGeneratePayslips = _payPeriod!.status == PayPeriodStatus.completed;
    final bool canPrepareTax = _payPeriod!.status == PayPeriodStatus.completed || 
                                _payPeriod!.status == PayPeriodStatus.closed;
    
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isLoading || _payPeriod!.status == PayPeriodStatus.closed)
                    ? null
                    : _transitionToNextStage,
                icon: const Icon(Icons.skip_next),
                label: Text(_getNextStageButtonText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getNextStageColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (canGeneratePayslips)
              const SizedBox(height: 12),
            if (canGeneratePayslips)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGeneratingPayslips ? null : _generatePayslips,
                  icon: isGeneratingPayslips
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.receipt_long),
                  label: const Text('Generate Payslips'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (canPrepareTax)
              const SizedBox(height: 12),
            if (canPrepareTax)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _prepareTaxSubmission,
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Prepare Tax Submission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (canPrepareTax)
              const SizedBox(height: 12),
            if (canPrepareTax)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportToAccounting,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Export to Accounting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
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

  Widget _buildTaxSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                const Text(
                  'Tax Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_taxSummary != null)
              _buildTaxRow('PAYE', _taxSummary!['paye'] ?? 0.0),
            if (_taxSummary != null)
              const Divider(),
            if (_taxSummary != null)
              _buildTaxRow('NHIF', _taxSummary!['nhif'] ?? 0.0),
            if (_taxSummary != null)
              const Divider(),
            if (_taxSummary != null)
              _buildTaxRow('NSSF', _taxSummary!['nssf'] ?? 0.0),
            if (_taxSummary != null)
              const Divider(),
            if (_taxSummary != null)
              _buildTaxRow('Total Tax', _taxSummary!['total'] ?? 0.0, isBold: true),
            if (_taxSummary == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tax summary will be available after payroll completion',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, dynamic amount, {bool isBold = false}) {
    final numberFormat = NumberFormat('#,###.00');
    
    // Safe conversion from any type (int, double, String)
    double value = 0.0;
    if (amount is num) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'KES ${numberFormat.format(value)}',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF8B5CF6) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStageButtonText() {
    switch (_payPeriod!.status) {
      case PayPeriodStatus.draft:
        return 'Activate Period';
      case PayPeriodStatus.active:
        return 'Process Payroll';
      case PayPeriodStatus.processing:
        return 'Complete Period';
      case PayPeriodStatus.completed:
        return 'Close Period';
      case PayPeriodStatus.closed:
        return 'Period Closed';
      default:
        return 'Continue';
    }
  }

  Color _getNextStageColor() {
    switch (_payPeriod!.status) {
      case PayPeriodStatus.draft:
        return Colors.blue;
      case PayPeriodStatus.active:
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
