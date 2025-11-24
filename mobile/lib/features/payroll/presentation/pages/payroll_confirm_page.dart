import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/payroll_provider.dart';
import '../../../payments/presentation/providers/transactions_provider.dart';

class PayrollConfirmPage extends ConsumerStatefulWidget {
  final String payPeriodId;
  final List<String> workerIds;

  const PayrollConfirmPage({
    super.key,
    required this.payPeriodId,
    required this.workerIds,
  });

  @override
  ConsumerState<PayrollConfirmPage> createState() => _PayrollConfirmPageState();
}

class _PayrollConfirmPageState extends ConsumerState<PayrollConfirmPage> {
  bool _isProcessing = false;
  Map<String, dynamic>? _batchResult;
  String? _error;

  Future<void> _processPayroll() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await ref.read(payrollProvider.notifier).processPayroll(
            widget.workerIds,
            widget.payPeriodId,
          );
      
      // Refresh transactions list
      await ref.read(transactionsProvider.notifier).fetchTransactions();
      
      // Get the batch result from the provider
      final result = ref.read(payrollProvider).value;
      
      setState(() {
        _isProcessing = false;
        _batchResult = result as Map<String, dynamic>?;
      });

      // Wait a moment then navigate if all succeeded
      if (_batchResult != null && _batchResult!['failureCount'] == 0) {
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          ref.read(payrollProvider.notifier).reset();
          ref.read(selectedWorkersProvider.notifier).state = {};
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_batchResult != null) {
      return _buildResultsPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payroll'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm Payroll Processing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You are about to process payroll for:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.workerIds.length} worker(s)',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Create salary payout transactions'),
                    const Text('• Deduct taxes (PAYE, NSSF, NHIF, Housing Levy)'),
                    const Text('• Send net pay to workers'),
                    const SizedBox(height: 8),
                    const Text(
                      '• Process each worker individually',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing payroll...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a moment',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _processPayroll,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm & Process Payroll'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPage() {
    final result = _batchResult!;
    final successCount = result['successCount'] as int;
    final failureCount = result['failureCount'] as int;
    final results = result['results'] as List<dynamic>;
    final allSuccess = failureCount == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Results'),
        leading: allSuccess
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(payrollProvider.notifier).reset();
                  ref.read(selectedWorkersProvider.notifier).state = {};
                  context.go('/home');
                },
              ),
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            color: allSuccess ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    allSuccess ? Icons.check_circle : Icons.warning,
                    size: 64,
                    color: allSuccess ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    allSuccess
                        ? 'Payroll Processed Successfully!'
                        : 'Payroll Partially Processed',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        label: 'Success',
                        value: successCount.toString(),
                        color: Colors.green,
                      ),
                      if (failureCount > 0)
                        _StatChip(
                          label: 'Failed',
                          value: failureCount.toString(),
                          color: Colors.red,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Individual Results
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final workerResult = results[index];
                final success = workerResult['success'] as bool;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                    ),
                    title: Text(workerResult['workerName'] as String),
                    subtitle: success
                        ? Text(
                            'Net Pay: KES ${(workerResult['netPay'] as num).toStringAsFixed(2)}',
                          )
                        : Text(
                            'Error: ${workerResult['error']}',
                            style: const TextStyle(color: Colors.red),
                          ),
                    trailing: success
                        ? const Chip(
                            label: Text('Paid'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : const Chip(
                            label: Text('Failed'),
                            backgroundColor: Colors.red,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                  ),
                );
              },
            ),
          ),

          // Action Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(payrollProvider.notifier).reset();
                    ref.read(selectedWorkersProvider.notifier).state = {};
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(allSuccess ? 'Done' : 'Back to Home'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
