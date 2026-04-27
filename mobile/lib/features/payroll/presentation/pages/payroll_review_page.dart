import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../workers/data/models/worker_model.dart';
import 'package:mobile/features/payroll/data/models/payroll_model.dart';

import '../../data/repositories/payroll_repository.dart';
import '../models/payroll_breakdown.dart';
import '../widgets/payroll_review_widgets.dart';
import '../widgets/payroll_review_dialogs.dart';
import '../providers/payroll_provider.dart';

class PayrollReviewPage extends ConsumerStatefulWidget {
  final String payPeriodId;
  final List<WorkerModel> selectedWorkers;

  const PayrollReviewPage({
    super.key,
    required this.payPeriodId,
    required this.selectedWorkers,
  });

  @override
  ConsumerState<PayrollReviewPage> createState() => _PayrollReviewPageState();
}

class _PayrollReviewPageState extends ConsumerState<PayrollReviewPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  int? _expandedIndex;
  String? _errorMessage;

  // Cached calculations adapted to UI model
  List<PayrollBreakdown> _breakdowns = [];
  PayrollBreakdown _totals = const PayrollBreakdown.empty();
  
  // Keep original calculations for ID mapping
  List<PayrollCalculation> _rawCalculations = [];
  
  // Track if this is a closed/finalized period (read-only view)
  bool _isPeriodClosed = false;

  Map<String, String> _paymentStatuses = {};
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadPayrollData();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    _isPolling = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchPaymentStatuses();
    });
  }

  void _stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchPaymentStatuses() async {
    if (!mounted) return;
    try {
      final repo = ref.read(payrollRepositoryProvider);
      final statuses = await repo.getPaymentStatus(widget.payPeriodId);
      
      if (mounted) {
        setState(() {
          _paymentStatuses = {for (var s in statuses) s.workerId: s.paymentStatus};
        });
        
        // Stop polling if nothing is processing anymore
        if (!statuses.any((s) => s.isProcessing)) {
          _stopPolling();
        }
      }
    } catch (e) {
      // Ignore errors during polling
    }
  }

  Future<void> _loadPayrollData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(payrollRepositoryProvider);
      
      // First try to get draft payroll (for in-progress periods)
      var calculations = await repo.getDraftPayroll(widget.payPeriodId);
      
      // If no draft records, fetch finalized/closed period records
      if (calculations.isEmpty) {
        calculations = await repo.getPeriodRecords(widget.payPeriodId);
      }
      
      if (mounted) {
        setState(() {
          // _rawCalculations = calculations;
          
          // Check if period is closed (data came from finalized records)
          _isPeriodClosed = calculations.isNotEmpty &&
              calculations.every((c) => c.status.toLowerCase() == 'finalized');
          
          // Filter calculations if specific workers were selected
          // This ensures totals and list only reflect the current selection
          if (widget.selectedWorkers.isNotEmpty) {
            final selectedIds = widget.selectedWorkers.map((w) => w.id).toSet();
            calculations = calculations.where((c) => selectedIds.contains(c.workerId)).toList();
          }

          _rawCalculations = calculations;

          // Adapt backend data to UI models
          _breakdowns = calculations.map((c) => PayrollBreakdown.fromCalculation(c)).toList();
          _totals = PayrollBreakdown.totals(_breakdowns);
          
          _isLoading = false;
        });

        // Fetch initial payment statuses
        await _fetchPaymentStatuses();
        
        // Check if we should start polling (if any payments are processing)
        if (mounted && _paymentStatuses.values.any((status) => 
            status.toLowerCase() == 'processing' || status.toLowerCase() == 'clearing')) {
          if (!_isPolling) _startPolling();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _recalculatePayroll() async {
    setState(() => _isLoading = true);
    try {
      // Use the notifier we just updated
      await ref.read(payrollProvider.notifier).recalculatePayroll(widget.payPeriodId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll recalculated with latest tax rates'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload data to show new figures
        _loadPayrollData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recalculation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMpesaConfirmation() {
    // Navigate to PayrollConfirmPage which handles IntaSend integration
    context.pushNamed(
      'payrollConfirm',
      pathParameters: {'id': widget.payPeriodId},
      // Pass the worker IDs that are part of this payroll
      extra: widget.selectedWorkers.map((w) => w.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Payroll'),
        centerTitle: true,
        backgroundColor: context.surfacePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayrollData,
          ),
          if (!_isPeriodClosed)
            IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Recalculate Taxes',
              onPressed: _recalculatePayroll,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => PayrollHelpDialog.show(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading payroll data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPayrollData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_breakdowns.isEmpty) {
      return const Center(
        child: Text('No payroll data found. Please run calculation first.'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PayrollSummaryCard(
                  totals: _totals, 
                  workerCount: widget.selectedWorkers.isNotEmpty 
                      ? widget.selectedWorkers.length 
                      : _breakdowns.length,
                ),
                const SizedBox(height: 24),
                const SectionLabel('BREAKDOWN BY EMPLOYEE'),
                const SizedBox(height: 12),
                if (widget.selectedWorkers.isNotEmpty)
                  ...widget.selectedWorkers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final worker = entry.value;
                    if (index >= _breakdowns.length) return const SizedBox.shrink();
                    
                    return WorkerBreakdownCard(
                      name: worker.name,
                      jobTitle: worker.jobTitle,
                      breakdown: _breakdowns[index],
                      isExpanded: _expandedIndex == index,
                      paymentStatus: _paymentStatuses[worker.id],
                      onTap: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == index ? null : index;
                        });
                      },
                    );
                  })
                else
                  ..._breakdowns.asMap().entries.map((entry) {
                    final index = entry.key;
                    final breakdown = entry.value;
                    // Use name from raw calculation if available
                    final name = index < _rawCalculations.length 
                        ? _rawCalculations[index].workerName 
                        : 'Unknown Employee';
                    
                    return WorkerBreakdownCard(
                      name: name,
                      jobTitle: 'Employee',
                      breakdown: breakdown,
                      isExpanded: _expandedIndex == index,
                      paymentStatus: index < _rawCalculations.length 
                          ? _paymentStatuses[_rawCalculations[index].workerId]
                          : null,
                      onTap: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == index ? null : index;
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
        // Only show payment button for open periods
        if (_isPeriodClosed)
          _buildClosedPeriodSummary()
        else
          PayrollBottomActionBar(
            totalAmount: _totals.netSalary,
            isProcessing: _isProcessing,
            onConfirm: _showMpesaConfirmation,
          ),
      ],
    );
  }

  Widget _buildClosedPeriodSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Period Closed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Total paid: KES ${_totals.netSalary.toStringAsFixed(0)}',
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
