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
  ConsumerState<TerminateWorkerPage> createState() => _TerminateWorkerPageState();
}

class _TerminateWorkerPageState extends ConsumerState<TerminateWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  
  TerminationReason _selectedReason = TerminationReason.resignation;
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
    // Auto-calculate on init
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
        setState(() {
          _calculation = calc;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating final payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
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
      );

      await repository.terminateWorker(
        workerId: widget.workerId,
        request: request,
      );

      if (mounted) {
        // Invalidate workers list to refresh status
        ref.invalidate(workersProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker terminated successfully')),
        );
        context.pop(); // Go back to details or list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to terminate worker: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Terminate Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Termination Details'),
              const SizedBox(height: 16),
              
              // Date Picker
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Termination Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Reason Dropdown
              DropdownButtonFormField<TerminationReason>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: TerminationReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
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
                onChanged: (val) => _noticePeriod = int.tryParse(val) ?? 0,
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
                onChanged: (val) => _severancePay = double.tryParse(val) ?? 0,
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

              _buildSectionTitle('Final Payment Preview'),
              const SizedBox(height: 8),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.bold,
        color: Colors.black87
      ),
    );
  }

  Widget _buildCalculationPreview(FinalPaymentCalculation calc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow('Prorated Salary', calc.proratedSalary),
            _buildRow('Unused Leave', calc.unusedLeavePayout),
            _buildRow('Severance (Calc)', calc.severancePay),
            const Divider(),
            _buildRow('Total Gross', calc.proratedSalary + calc.unusedLeavePayout + calc.severancePay, isBold: true),
            _buildRow('Tax Deductions', -calc.taxDeductions, color: Colors.red),
            const Divider(),
            _buildRow('Net Pay', calc.totalFinalPayment + _severancePay, isBold: true, color: Colors.green, fontSize: 18),
            if (_severancePay > 0)
               Text(
                 '(Includes manual severance of KES $_severancePay)',
                 style: const TextStyle(fontSize: 12, color: Colors.grey),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double amount, {bool isBold = false, Color? color, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
