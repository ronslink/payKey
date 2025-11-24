import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/payroll_model.dart';
import '../providers/payroll_provider.dart';

class PayrollReviewPage extends ConsumerStatefulWidget {
  final String payPeriodId;

  const PayrollReviewPage({super.key, required this.payPeriodId});

  @override
  ConsumerState<PayrollReviewPage> createState() => _PayrollReviewPageState();
}

class _PayrollReviewPageState extends ConsumerState<PayrollReviewPage> {
  @override
  void initState() {
    super.initState();
    // Save as draft immediately to ensure we have records with IDs for editing
    Future.microtask(() {
      ref.read(payrollProvider.notifier).saveDraftPayroll(widget.payPeriodId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final payrollState = ref.watch(payrollProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Payroll'),
      ),
      body: payrollState.when(
        data: (calculations) {
          if (calculations.isEmpty) {
            return const Center(child: Text('No calculations available'));
          }

          final totalGross = calculations.fold<double>(
            0,
            (sum, calc) => sum + calc.grossSalary + calc.bonuses + calc.otherEarnings,
          );
          final totalDeductions = calculations.fold<double>(
            0,
            (sum, calc) => sum + calc.taxBreakdown.totalDeductions + calc.otherDeductions,
          );
          final totalNet = calculations.fold<double>(
            0,
            (sum, calc) => sum + calc.netPay,
          );

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Payroll Summary',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow('Total Gross:', totalGross),
                      _SummaryRow('Total Deductions:', totalDeductions, isNegative: true),
                      const Divider(),
                      _SummaryRow('Total Net Pay:', totalNet, isTotal: true),
                      const SizedBox(height: 8),
                      Text(
                        '${calculations.length} worker(s)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Workers List
              Expanded(
                child: ListView.builder(
                  itemCount: calculations.length,
                  itemBuilder: (context, index) {
                    final calc = calculations[index];
                    return _WorkerPayrollCard(
                      calculation: calc,
                      onSave: (gross, bonuses, earnings, deductions) {
                        ref.read(payrollProvider.notifier).updateWorkerPayroll(
                              workerId: calc.workerId,
                              grossSalary: gross,
                              bonuses: bonuses,
                              otherEarnings: earnings,
                              otherDeductions: deductions,
                            );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(payrollProvider.notifier).saveDraftPayroll(widget.payPeriodId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: payrollState.whenOrNull(
        data: (calculations) => calculations.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref.read(payrollProvider.notifier).finalizePayroll(widget.payPeriodId);
                        if (context.mounted) {
                          // Navigate to payment or success page
                          // For now, just show success and go back or to history
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payroll Finalized Successfully')),
                          );
                          context.go('/payroll'); // Or wherever appropriate
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error finalizing payroll: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm & Pay'),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isNegative;
  final bool isTotal;

  const _SummaryRow(
    this.label,
    this.amount, {
    this.isNegative = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerPayrollCard extends StatefulWidget {
  final PayrollCalculation calculation;
  final Function(double, double, double, double) onSave;

  const _WorkerPayrollCard({
    required this.calculation,
    required this.onSave,
  });

  @override
  State<_WorkerPayrollCard> createState() => _WorkerPayrollCardState();
}

class _WorkerPayrollCardState extends State<_WorkerPayrollCard> {
  bool _isExpanded = false;
  bool _isEditMode = false;

  late TextEditingController _grossSalaryController;
  late TextEditingController _bonusesController;
  late TextEditingController _otherEarningsController;
  late TextEditingController _otherDeductionsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _grossSalaryController = TextEditingController(
      text: widget.calculation.grossSalary.toString(),
    );
    _bonusesController = TextEditingController(
      text: widget.calculation.bonuses.toString(),
    );
    _otherEarningsController = TextEditingController(
      text: widget.calculation.otherEarnings.toString(),
    );
    _otherDeductionsController = TextEditingController(
      text: widget.calculation.otherDeductions.toString(),
    );
  }

  @override
  void didUpdateWidget(_WorkerPayrollCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditMode && widget.calculation != oldWidget.calculation) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _grossSalaryController.dispose();
    _bonusesController.dispose();
    _otherEarningsController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calculation;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(calc.workerName[0].toUpperCase()),
            ),
            title: Text(calc.workerName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gross: KES ${calc.grossSalary.toStringAsFixed(2)}'),
                Text(
                  'Net Pay: KES ${calc.netPay.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEditMode && calc.status == 'draft')
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() {
                      _isEditMode = true;
                      _isExpanded = true;
                    }),
                  ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          if (_isExpanded)
            _isEditMode ? _buildEditForm() : _buildReadOnlyView(calc),
        ],
      ),
    );
  }

  Widget _buildReadOnlyView(PayrollCalculation calc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tax Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _TaxRow('Gross Salary:', calc.grossSalary),
          if (calc.bonuses > 0) _TaxRow('Bonuses:', calc.bonuses),
          if (calc.otherEarnings > 0) _TaxRow('Other Earnings:', calc.otherEarnings),
          const Divider(),
          _TaxRow('NSSF:', calc.taxBreakdown.nssf),
          _TaxRow('NHIF:', calc.taxBreakdown.nhif),
          _TaxRow('Housing Levy:', calc.taxBreakdown.housingLevy),
          _TaxRow('PAYE:', calc.taxBreakdown.paye),
          if (calc.otherDeductions > 0) _TaxRow('Other Deductions:', calc.otherDeductions),
          const Divider(),
          _TaxRow(
            'Total Deductions:',
            calc.taxBreakdown.totalDeductions + calc.otherDeductions,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _grossSalaryController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Gross Salary',
              prefixText: 'KES ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bonusesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bonuses',
              prefixText: 'KES ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otherEarningsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Other Earnings',
              prefixText: 'KES ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otherDeductionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Other Deductions',
              prefixText: 'KES ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _isEditMode = false);
                    _initializeControllers(); // Reset to original values
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save & Recalculate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    final gross = double.tryParse(_grossSalaryController.text) ?? 0;
    final bonuses = double.tryParse(_bonusesController.text) ?? 0;
    final earnings = double.tryParse(_otherEarningsController.text) ?? 0;
    final deductions = double.tryParse(_otherDeductionsController.text) ?? 0;

    widget.onSave(gross, bonuses, earnings, deductions);
    setState(() => _isEditMode = false);
  }
}

class _TaxRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _TaxRow(this.label, this.amount, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
