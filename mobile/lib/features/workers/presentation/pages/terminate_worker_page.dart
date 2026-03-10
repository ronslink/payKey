import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/termination_model.dart';
import '../../data/repositories/termination_repository.dart';
import '../providers/workers_provider.dart';

class TerminateWorkerPage extends ConsumerStatefulWidget {
  final String workerId;

  const TerminateWorkerPage({super.key, required this.workerId});

  @override
  ConsumerState<TerminateWorkerPage> createState() =>
      _TerminateWorkerPageState();
}

class _TerminateWorkerPageState extends ConsumerState<TerminateWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  TerminationReason _selectedReason = TerminationReason.resignation;
  FinalPayMode _finalPayMode = FinalPayMode.immediateOffcycle;
  int _noticePeriod = 0;
  double _severancePay = 0;
  final double _outstandingPayments = 0;

  FinalPaymentCalculation? _calculation;
  bool _isLoading = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateFinalPayment();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _calculateFinalPayment();
    }
  }

  Future<void> _calculateFinalPayment() async {
    setState(() {
      _isCalculating = true;
      _calculation = null;
    });
    try {
      final repository = ref.read(terminationRepositoryProvider);
      final calc = await repository.calculateFinalPayment(
        workerId: widget.workerId,
        terminationDate: _dateController.text,
      );
      if (mounted) {
        setState(() => _calculation = calc);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating final payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    }
  }

  Future<void> _submitTermination() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(terminationRepositoryProvider);
      final request = TerminationRequest(
        terminationDate: _dateController.text,
        reason: _selectedReason,
        noticePeriodDays: _noticePeriod,
        severancePay: _severancePay,
        outstandingPayments: _outstandingPayments,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        finalPayMode: _finalPayMode,
      );
      await repository.terminateWorker(
        workerId: widget.workerId,
        request: request,
      );
      if (mounted) {
        ref.invalidate(workersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_finalPayMode == FinalPayMode.immediateOffcycle
                ? 'Worker terminated. Final pay payment is being processed.'
                : _finalPayMode == FinalPayMode.includeInRegular
                    ? 'Worker terminated. Final pay added to next payroll run.'
                    : 'Worker terminated. Final pay marked for manual handling.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to terminate worker: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Terminate Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Termination Details'),
              const SizedBox(height: 16),

              // Date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Termination Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Reason
              DropdownButtonFormField<TerminationReason>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: TerminationReason.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedReason = v);
                },
              ),
              const SizedBox(height: 16),

              // Notice Period
              TextFormField(
                initialValue: '0',
                decoration: const InputDecoration(
                  labelText: 'Notice Period (Days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _noticePeriod = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),

              // Severance
              TextFormField(
                initialValue: '0',
                decoration: const InputDecoration(
                  labelText: 'Severance Pay',
                  border: OutlineInputBorder(),
                  prefixText: 'KES ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _severancePay = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Final Pay Section ───────────────────────────────────────
              _sectionTitle('Final Paycheck Method'),
              const SizedBox(height: 8),
              Text(
                'Choose how to process the final pay for this worker:',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ...FinalPayMode.values.map((mode) {
                final isSelected = _finalPayMode == mode;
                return _FinalPayModeCard(
                  mode: mode,
                  isSelected: isSelected,
                  onTap: () => setState(() => _finalPayMode = mode),
                );
              }),
              const SizedBox(height: 24),

              // ── Final Payment Preview ───────────────────────────────────
              _sectionTitle('Final Payment Preview'),
              const SizedBox(height: 8),
              if (_finalPayMode == FinalPayMode.defer)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Deferred — no automatic payment. '
                          'The paycheck breakdown below is for your reference only.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_finalPayMode == FinalPayMode.immediateOffcycle)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flash_on,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'An off-cycle payroll period will be created and '
                          'payment processed immediately.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Final pay will be added to the next regular '
                          'payroll run for this period.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (_isCalculating)
                const Center(child: CircularProgressIndicator())
              else if (_calculation != null)
                _buildCalculationPreview(_calculation!)
              else
                const Text('Select a date to calculate final payment'),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTermination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRM TERMINATION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );

  Widget _buildCalculationPreview(FinalPaymentCalculation calc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow('Prorated Salary', calc.proratedSalary),
            _buildRow('Unused Leave', calc.unusedLeavePayout),
            _buildRow(
                'Severance (Calc)', calc.severancePay),
            const Divider(),
            _buildRow(
              'Total Gross',
              calc.proratedSalary +
                  calc.unusedLeavePayout +
                  calc.severancePay,
              isBold: true,
            ),
            _buildRow('Tax Deductions', -calc.taxDeductions,
                color: Colors.red),
            const Divider(),
            _buildRow(
              'Net Pay',
              calc.totalFinalPayment + _severancePay,
              isBold: true,
              color: Colors.green,
              fontSize: 18,
            ),
            if (_severancePay > 0)
              Text(
                '(Includes manual severance of KES $_severancePay)',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              )),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Final Pay Mode Card
// ─────────────────────────────────────────────────────────────────────────────

class _FinalPayModeCard extends StatelessWidget {
  final FinalPayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _FinalPayModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case FinalPayMode.immediateOffcycle:
        return Icons.flash_on;
      case FinalPayMode.includeInRegular:
        return Icons.calendar_month;
      case FinalPayMode.defer:
        return Icons.handshake_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : Colors.grey.shade50,
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color:
                  isSelected ? colorScheme.primary : Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
