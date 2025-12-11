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

// ============================================================================
// MAIN PAGE
// ============================================================================

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
  bool _isLoading = false;
  bool _isGeneratingPayslips = false;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _taxSummary;
  List<PayrollCalculation> _payrollItems = [];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadPayPeriod();
    _loadPayrollData();
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadPayPeriod() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payPeriod = await repository.getPayPeriod(widget.payPeriodId);
      if (mounted) {
        setState(() => _payPeriod = payPeriod);
      }
    } catch (e) {
      _showError('Failed to load pay period: $e');
    }
  }

  Future<void> _loadPayrollData() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payrollRepo = ref.read(payrollRepositoryProvider);

      // Load statistics (non-critical, continue on failure)
      Map<String, dynamic>? stats;
      try {
        final statistics = await repository.getPayPeriodStatistics(widget.payPeriodId);
        stats = statistics.toDisplayMap();
      } catch (e) {
        debugPrint('Failed to load statistics: $e');
      }

      // Load draft items (non-critical, continue on failure)
      List<PayrollCalculation> items = [];
      try {
        items = await payrollRepo.getPeriodRecords(widget.payPeriodId);
      } catch (e) {
        debugPrint('No draft items found or error loading them: $e');
      }

      if (mounted) {
        setState(() {
          _statistics = stats;
          _payrollItems = items;
          _taxSummary = stats?['taxSummary'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      debugPrint('Failed to load payroll data: $e');
      _showError('Failed to load payroll data: ${e.toString()}', duration: 5);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadPayPeriod(),
      _loadPayrollData(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Actions: Workers
  // ---------------------------------------------------------------------------

  Future<void> _showAddWorkersDialog() async {
    final workersAsync = ref.read(workersProvider);
    final workers = workersAsync.valueOrNull ?? <WorkerModel>[];

    // Filter out workers already in payroll
    final existingWorkerIds = _payrollItems.map((item) => item.workerId).toSet();
    final availableWorkers =
        workers.where((w) => !existingWorkerIds.contains(w.id)).toList();

    if (!mounted) return;

    if (availableWorkers.isEmpty) {
      _showInfo('All active workers are already added to this payroll.');
      return;
    }

    final selectedWorkers = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _AddWorkersDialog(availableWorkers: availableWorkers),
    );

    if (selectedWorkers != null && selectedWorkers.isNotEmpty) {
      await _addWorkersToPayroll(selectedWorkers.toList());
    }
  }

  Future<void> _addWorkersToPayroll(List<String> workerIds) async {
    setState(() => _isLoading = true);
    try {
      final payrollRepo = ref.read(payrollRepositoryProvider);

      // Calculate initial payroll for selected workers
      final calculations = await payrollRepo.calculatePayroll(
        workerIds,
        startDate: _payPeriod!.startDate,
        endDate: _payPeriod!.endDate,
      );

      // Prepare items for saving
      final itemsToSave = calculations
          .map((calc) => {
                'workerId': calc.workerId,
                'grossSalary': calc.grossSalary,
                'bonuses': calc.bonuses,
                'otherEarnings': calc.otherEarnings,
                'otherDeductions': calc.otherDeductions,
              })
          .toList();

      // Save to draft
      await payrollRepo.saveDraftPayroll(widget.payPeriodId, itemsToSave);

      // Refresh data
      await _refreshAll();

      if (mounted) {
        _showSuccess('Added ${workerIds.length} workers to payroll');
      }
    } catch (e) {
      _showError('Failed to add workers: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Payslips & Tax
  // ---------------------------------------------------------------------------

  Future<void> _generatePayslips() async {
    if (_payPeriod == null) return;

    setState(() => _isGeneratingPayslips = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      await repository.generatePayslips(widget.payPeriodId);

      if (mounted) {
        _showSuccess('Payslips generated successfully');
        await _loadPayrollData();
      }
    } catch (e) {
      _showError('Failed to generate payslips: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPayslips = false);
      }
    }
  }

  Future<void> _prepareTaxSubmission() async {
    if (_payPeriod == null) return;

    setState(() => _isLoading = true);
    try {
      if (mounted) {
        context.push('/taxes?payPeriodId=${widget.payPeriodId}');
      }
    } catch (e) {
      _showError('Failed to prepare tax submission: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Accounting Export
  // ---------------------------------------------------------------------------

  Future<void> _exportToAccounting() async {
    if (_payPeriod == null) return;

    try {
      final apiService = ApiService();
      final response = await apiService.dio.post(
        '/accounting/journal-entries/${widget.payPeriodId}',
      );

      if (mounted) {
        _showAccountingExportDialog(response.data);
      }
    } catch (e) {
      _showError('Failed to load journal entries: $e');
    }
  }

  void _showAccountingExportDialog(Map<String, dynamic> journalData) {
    showDialog(
      context: context,
      builder: (context) => _AccountingExportDialog(
        journalData: journalData,
        onDownload: _downloadCSV,
      ),
    );
  }

  Future<void> _downloadCSV() async {
    try {
      final apiService = ApiService();
      final response = await apiService.exportPayrollToCSV(widget.payPeriodId);

      final filename = response.data['filename'] as String;

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Exported successfully: $filename')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.push('/accounting'),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to export: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Stage Transitions
  // ---------------------------------------------------------------------------

  Future<void> _reopenPayPeriod() async {
    final repository = ref.read(payPeriodRepositoryProvider);
    await repository.reopenPayPeriod(widget.payPeriodId);
  }

  // ---------------------------------------------------------------------------
  // Actions: View Payslip
  // ---------------------------------------------------------------------------

  void _viewPayslip(PayrollCalculation item) {
    if (item.id == null) return;
    context.push('/payroll/payslip/${item.id}', extra: item);
  }

  Future<void> _transitionToNextStage() async {
    if (_payPeriod == null) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payrollRepo = ref.read(payrollRepositoryProvider);
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
          if (_payrollItems.isEmpty) {
            _showError('No payroll records found. Please calculate payroll first.');
            return;
          }
          
          // Check for high value payments that need splitting
          final highValueItems = _payrollItems.where((item) => item.netPay > 150000).toList();
          
          if (highValueItems.isNotEmpty) {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Small Payment Splitting Notice'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The following employees have salaries exceeding the M-Pesa transaction limit of KES 150,000:',
                      ),
                      const SizedBox(height: 12),
                      ...highValueItems.map((item) => Text(
                        '• ${item.workerName}: KES ${item.netPay.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                      const SizedBox(height: 16),
                      const Text(
                        'These payments will be AUTOMATICALLY SPLIT into multiple transactions to ensure successful delivery without any manual action required.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Do you want to proceed?',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Proceed'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;
          }

          // IMPORTANT: Finalize payroll records before completing the period
          await payrollRepo.finalizePayroll(widget.payPeriodId);
          await repository.completePayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.completed:
          await repository.closePayPeriod(widget.payPeriodId);
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        case PayPeriodStatus.closed:
          await _reopenPayPeriod();
          // Period should be updated within _reopenPayPeriod or here
          updatedPeriod = await repository.getPayPeriod(widget.payPeriodId);
          break;
        default:
          return;
      }

      if (mounted) {
        setState(() => _payPeriod = updatedPeriod);
        await _loadPayrollData();

        final statusText = updatedPeriod.status.name.replaceAll('_', ' ').toLowerCase();
        _showSuccess('Successfully transitioned to $statusText');
      }
    } catch (e) {
      _showError('Failed to transition stage: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Edit Payroll Item
  // ---------------------------------------------------------------------------

  Future<void> _editPayrollItem(PayrollCalculation item) async {
    if (item.id == null) return;

    // Check if editable
    if (_payPeriod?.status == PayPeriodStatus.completed ||
        _payPeriod?.status == PayPeriodStatus.closed) {
      _showInfo('Cannot edit items in a finalized period');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditPayrollItemDialog(
        item: item,
        onSave: (updates) => _savePayrollItemUpdates(item.id!, updates),
      ),
    );

    if (result == true) {
      _loadPayrollData();
    }
  }

  Future<void> _savePayrollItemUpdates(
      String itemId, Map<String, dynamic> updates) async {
    final repo = ref.read(payrollRepositoryProvider);
    await repo.updatePayrollItem(itemId, updates);
  }

  // ---------------------------------------------------------------------------
  // Helpers: Snackbars
  // ---------------------------------------------------------------------------

  void _showError(String message, {int duration = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: duration),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_payPeriod == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payroll Review')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${_payPeriod!.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PayrollHeader(payPeriod: _payPeriod!),
            const SizedBox(height: 24),
            if (_statistics != null)
              _PayrollSummaryCard(statistics: _statistics!),
            const SizedBox(height: 24),
            if (_shouldShowTaxSummary)
              _TaxSummaryCard(taxSummary: _taxSummary),
            if (_shouldShowTaxSummary) const SizedBox(height: 24),
            _PayrollRecordsCard(
              payrollItems: _payrollItems,
              isDraft: _payPeriod?.status != PayPeriodStatus.completed && 
                      _payPeriod?.status != PayPeriodStatus.closed,
              canViewPayslips: _payPeriod?.status == PayPeriodStatus.completed || 
                              _payPeriod?.status == PayPeriodStatus.closed,
              onAddWorkers: _showAddWorkersDialog,
              onEditItem: _editPayrollItem,
              onViewPayslip: _viewPayslip,
            ),
            const SizedBox(height: 24),
            _ActionButtonsCard(
              payPeriod: _payPeriod!,
              isLoading: _isLoading,
              isGeneratingPayslips: _isGeneratingPayslips,
              onTransition: _transitionToNextStage,
              onGeneratePayslips: _generatePayslips,
              onPrepareTax: _prepareTaxSubmission,
              onExportAccounting: _exportToAccounting,
              onEditPayroll: () => context.push('/payroll/run/${widget.payPeriodId}'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _shouldShowTaxSummary =>
      _payPeriod!.status == PayPeriodStatus.completed ||
      _payPeriod!.status == PayPeriodStatus.closed;
}

// ============================================================================
// EXTRACTED WIDGETS
// ============================================================================

// -----------------------------------------------------------------------------
// Payroll Header
// -----------------------------------------------------------------------------

class _PayrollHeader extends StatelessWidget {
  final PayPeriod payPeriod;

  const _PayrollHeader({required this.payPeriod});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payPeriod.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(payPeriod.startDate)} - ${dateFormat.format(payPeriod.endDate)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Frequency: ${payPeriod.frequency.name.replaceAll('_', ' ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: payPeriod.status),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Status Badge
// -----------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final PayPeriodStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, displayText) = _getStatusStyle(status);

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

  (Color, String) _getStatusStyle(PayPeriodStatus status) {
    return switch (status) {
      PayPeriodStatus.draft => (Colors.grey.shade600, 'DRAFT'),
      PayPeriodStatus.active => (Colors.blue, 'ACTIVE'),
      PayPeriodStatus.processing => (Colors.orange, 'PROCESSING'),
      PayPeriodStatus.completed => (Colors.green, 'COMPLETED'),
      PayPeriodStatus.closed => (Colors.deepPurple, 'CLOSED'),
      _ => (Colors.grey, status.name),
    };
  }
}

// -----------------------------------------------------------------------------
// Summary Card
// -----------------------------------------------------------------------------

class _PayrollSummaryCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const _PayrollSummaryCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final statsData = statistics['statistics'] as Map<String, dynamic>?;
    if (statsData == null) return const SizedBox.shrink();

    final numberFormat = NumberFormat('#,###.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    title: 'Total Workers',
                    value: '${statsData['totalWorkers'] ?? 0}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    title: 'Processed',
                    value: '${statsData['processedPayments'] ?? 0}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    title: 'Pending',
                    value: '${statsData['pendingPayments'] ?? 0}',
                    icon: Icons.pending,
                    color: Colors.orange,
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
                  child: _AmountColumn(
                    label: 'Total Gross Amount',
                    amount: _toNum(statsData['totalGrossAmount']),
                    numberFormat: numberFormat,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Total Net Amount',
                    amount: _toNum(statsData['totalNetAmount']),
                    numberFormat: numberFormat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final num amount;
  final NumberFormat numberFormat;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        Text(
          'KES ${numberFormat.format(amount)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Tax Summary Card
// -----------------------------------------------------------------------------

class _TaxSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? taxSummary;

  const _TaxSummaryCard({this.taxSummary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFF8B5CF6)),
                SizedBox(width: 8),
                Text(
                  'Tax Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (taxSummary != null) ...[
              _TaxRow(label: 'PAYE', amount: taxSummary!['paye'] ?? 0.0),
              const Divider(),
              _TaxRow(label: 'NHIF', amount: taxSummary!['nhif'] ?? 0.0),
              const Divider(),
              _TaxRow(label: 'NSSF', amount: taxSummary!['nssf'] ?? 0.0),
              const Divider(),
              _TaxRow(
                label: 'Total Tax',
                amount: taxSummary!['total'] ?? 0.0,
                isBold: true,
              ),
            ] else
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
}

class _TaxRow extends StatelessWidget {
  final String label;
  final dynamic amount;
  final bool isBold;

  const _TaxRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###.00');
    final value = _toDouble(amount);

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

  double _toDouble(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }
}

// -----------------------------------------------------------------------------
// Payroll Records Card
// -----------------------------------------------------------------------------

class _PayrollRecordsCard extends StatelessWidget {
  final List<PayrollCalculation> payrollItems;
  final bool isDraft;
  final VoidCallback onAddWorkers;
  final void Function(PayrollCalculation) onEditItem;
  final bool canViewPayslips;
  final void Function(PayrollCalculation)? onViewPayslip;

  const _PayrollRecordsCard({
    required this.payrollItems,
    required this.isDraft,
    required this.onAddWorkers,
    required this.onEditItem,
    this.canViewPayslips = false,
    this.onViewPayslip,
  });

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isDraft)
                  ElevatedButton.icon(
                    onPressed: onAddWorkers,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Workers'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (payrollItems.isEmpty)
              _EmptyRecordsPlaceholder(
                isDraft: isDraft,
                onAddWorkers: onAddWorkers,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payrollItems.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = payrollItems[index];
                  return _PayrollItemTile(
                    item: item,
                    numberFormat: numberFormat,
                    onTap: () => onEditItem(item),
                    showPayslipAction: canViewPayslips,
                    onViewPayslip: () => onViewPayslip?.call(item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecordsPlaceholder extends StatelessWidget {
  final bool isDraft;
  final VoidCallback onAddWorkers;

  const _EmptyRecordsPlaceholder({
    required this.isDraft,
    required this.onAddWorkers,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
                onPressed: onAddWorkers,
                child: const Text('Add Workers Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PayrollItemTile extends StatelessWidget {
  final PayrollCalculation item;
  final NumberFormat numberFormat;
  final VoidCallback onTap;
  final bool showPayslipAction;
  final VoidCallback? onViewPayslip;

  const _PayrollItemTile({
    required this.item,
    required this.numberFormat,
    required this.onTap,
    this.showPayslipAction = false,
    this.onViewPayslip,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.workerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Gross: KES ${numberFormat.format(item.grossSalary)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
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
          if (showPayslipAction) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Color(0xFF6B7280)),
              onPressed: onViewPayslip,
              tooltip: 'View Payslip',
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Action Buttons Card
// -----------------------------------------------------------------------------

class _ActionButtonsCard extends StatelessWidget {
  final PayPeriod payPeriod;
  final bool isLoading;
  final bool isGeneratingPayslips;
  final VoidCallback onTransition;
  final VoidCallback onGeneratePayslips;
  final VoidCallback onPrepareTax;
  final VoidCallback onExportAccounting;
  final VoidCallback onEditPayroll;

  const _ActionButtonsCard({
    required this.payPeriod,
    required this.isLoading,
    required this.isGeneratingPayslips,
    required this.onTransition,
    required this.onGeneratePayslips,
    required this.onPrepareTax,
    required this.onExportAccounting,
    required this.onEditPayroll,
  });

  @override
  Widget build(BuildContext context) {
    final canGeneratePayslips = payPeriod.status == PayPeriodStatus.completed;
    final canPrepareTax = payPeriod.status == PayPeriodStatus.completed ||
        payPeriod.status == PayPeriodStatus.closed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Transition Button
            _ActionButton(
              onPressed: isLoading ? null : onTransition,
              icon: Icons.skip_next,
              label: _getNextStageButtonText(),
              backgroundColor: _getNextStageColor(),
            ),

            // Generate Payslips
            if (canGeneratePayslips) ...[
              const SizedBox(height: 12),
              _ActionButton(
                onPressed: isGeneratingPayslips ? null : onGeneratePayslips,
                icon: Icons.receipt_long,
                label: 'Generate Payslips',
                backgroundColor: const Color(0xFF10B981),
                isLoading: isGeneratingPayslips,
              ),
            ],

            // Tax & Accounting buttons
            if (canPrepareTax) ...[
              const SizedBox(height: 12),
              _ActionButton(
                onPressed: onPrepareTax,
                icon: Icons.account_balance,
                label: 'Prepare Tax Submission',
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                onPressed: onExportAccounting,
                icon: Icons.file_download_outlined,
                label: 'Export to Accounting',
                backgroundColor: const Color(0xFF06B6D4),
              ),
            ],

            // Edit Payroll
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEditPayroll,
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
    return switch (payPeriod.status) {
      PayPeriodStatus.draft => 'Activate Period',
      PayPeriodStatus.active => 'Process Payroll',
      PayPeriodStatus.processing => 'Complete Period',
      PayPeriodStatus.completed => 'Close Period',
      PayPeriodStatus.closed => 'Reopen Period',
      _ => 'Continue',
    };
  }

  Color _getNextStageColor() {
    return switch (payPeriod.status) {
      PayPeriodStatus.draft => Colors.blue,
      PayPeriodStatus.active => Colors.orange,
      PayPeriodStatus.processing => Colors.green,
      PayPeriodStatus.completed => Colors.deepPurple,
      PayPeriodStatus.closed => Colors.red.shade400,
      _ => Colors.grey,
    };
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final bool isLoading;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ============================================================================
// DIALOGS
// ============================================================================

// -----------------------------------------------------------------------------
// Add Workers Dialog
// -----------------------------------------------------------------------------

class _AddWorkersDialog extends StatefulWidget {
  final List<WorkerModel> availableWorkers;

  const _AddWorkersDialog({required this.availableWorkers});

  @override
  State<_AddWorkersDialog> createState() => _AddWorkersDialogState();
}

class _AddWorkersDialogState extends State<_AddWorkersDialog> {
  final Set<String> _selectedWorkers = {};

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedWorkers.addAll(widget.availableWorkers.map((w) => w.id));
      } else {
        _selectedWorkers.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedWorkers.length == widget.availableWorkers.length && 
                       widget.availableWorkers.isNotEmpty;

    return AlertDialog(
      title: const Text('Add Workers'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.availableWorkers.isNotEmpty)
              CheckboxListTile(
                title: const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                value: allSelected,
                onChanged: _toggleSelectAll,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableWorkers.length,
                itemBuilder: (context, index) {
                  final worker = widget.availableWorkers[index];
                  final isSelected = _selectedWorkers.contains(worker.id);
                  return CheckboxListTile(
                    title: Text(worker.name),
                    subtitle: Text(worker.jobTitle ?? 'No Job Title'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedWorkers.add(worker.id);
                        } else {
                          _selectedWorkers.remove(worker.id);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedWorkers.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedWorkers),
          child: Text('Add (${_selectedWorkers.length})'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Edit Payroll Item Dialog
// -----------------------------------------------------------------------------

class _EditPayrollItemDialog extends StatefulWidget {
  final PayrollCalculation item;
  final Future<void> Function(Map<String, dynamic> updates) onSave;

  const _EditPayrollItemDialog({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditPayrollItemDialog> createState() => _EditPayrollItemDialogState();
}

class _EditPayrollItemDialogState extends State<_EditPayrollItemDialog> {
  late final TextEditingController _bonusesCtrl;
  late final TextEditingController _earningsCtrl;
  late final TextEditingController _deductionsCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bonusesCtrl = TextEditingController(text: widget.item.bonuses.toString());
    _earningsCtrl =
        TextEditingController(text: widget.item.otherEarnings.toString());
    _deductionsCtrl =
        TextEditingController(text: widget.item.otherDeductions.toString());
  }

  @override
  void dispose() {
    _bonusesCtrl.dispose();
    _earningsCtrl.dispose();
    _deductionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final updates = {
        'bonuses': double.tryParse(_bonusesCtrl.text) ?? 0,
        'otherEarnings': double.tryParse(_earningsCtrl.text) ?? 0,
        'otherDeductions': double.tryParse(_deductionsCtrl.text) ?? 0,
      };

      await widget.onSave(updates);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.item.workerName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bonusesCtrl,
              decoration: const InputDecoration(
                labelText: 'Bonuses',
                prefixText: 'KES ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _earningsCtrl,
              decoration: const InputDecoration(
                labelText: 'Other Earnings',
                prefixText: 'KES ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deductionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Other Deductions',
                prefixText: 'KES ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Accounting Export Dialog
// -----------------------------------------------------------------------------

class _AccountingExportDialog extends StatelessWidget {
  final Map<String, dynamic> journalData;
  final VoidCallback onDownload;

  const _AccountingExportDialog({
    required this.journalData,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final entries = journalData['entries'] as List;
    final totalDebits = journalData['totalDebits'] as num;
    final totalCredits = journalData['totalCredits'] as num;
    final isBalanced = journalData['isBalanced'] as bool;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogHeader(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JournalEntriesTable(
                      entries: entries,
                      totalDebits: totalDebits,
                      totalCredits: totalCredits,
                    ),
                    const SizedBox(height: 16),
                    _BalanceIndicator(isBalanced: isBalanced),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _DialogActions(
              isBalanced: isBalanced,
              onCancel: () => Navigator.of(context).pop(),
              onDownload: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Journal entries for this pay period',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      ],
    );
  }
}

class _JournalEntriesTable extends StatelessWidget {
  final List entries;
  final num totalDebits;
  final num totalCredits;

  const _JournalEntriesTable({
    required this.entries,
    required this.totalDebits,
    required this.totalCredits,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
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
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Debit',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Credit',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Entries
          ...entries.map((entry) => _JournalEntryRow(
                entry: entry,
                currencyFormat: currencyFormat,
              )),

          // Totals
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFF111827), width: 2),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'TOTALS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    currencyFormat.format(totalDebits),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    currencyFormat.format(totalCredits),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final NumberFormat currencyFormat;

  const _JournalEntryRow({
    required this.entry,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
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
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  entry['account'],
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              entry['debit'] > 0 ? currencyFormat.format(entry['debit']) : '-',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry['credit'] > 0
                  ? currencyFormat.format(entry['credit'])
                  : '-',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceIndicator extends StatelessWidget {
  final bool isBalanced;

  const _BalanceIndicator({required this.isBalanced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBalanced ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
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
    );
  }
}

class _DialogActions extends StatelessWidget {
  final bool isBalanced;
  final VoidCallback onCancel;
  final VoidCallback onDownload;

  const _DialogActions({
    required this.isBalanced,
    required this.onCancel,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
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
            onPressed: isBalanced ? onDownload : null,
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
    );
  }
}