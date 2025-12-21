import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_provider.dart';
import '../../../payments/presentation/providers/transactions_provider.dart';
import '../../data/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';

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
  bool _isVerifying = true;
  FundVerificationResult? _verificationResult;
  Map<String, dynamic>? _batchResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyFunds();
  }

  Future<void> _verifyFunds() async {
    setState(() => _isVerifying = true);
    try {
      final repo = ref.read(payrollRepositoryProvider);
      final result = await repo.verifyFunds(widget.payPeriodId);
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verificationResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = 'Failed to verify funds: $e';
        });
      }
    }
  }

  // MODERN M-PESA TOPUP SHEET
  void _showTopupDialog() {
    final shortfall = _verificationResult?.shortfall ?? 0;
    final defaultAmount = (shortfall > 0 ? shortfall : 1000).ceil().toDouble();
    
    final controller = TextEditingController(text: defaultAmount.toStringAsFixed(0));
    final phoneController = TextEditingController(text: '07'); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D632).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Color(0xFF00D632), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Up Wallet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'via M-Pesa',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Amount Input
            const Text('Amount to Load', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'KES ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Phone Input
            const Text('M-Pesa Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: '07XX...',
                prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),

            // Dev Note Badge
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.developer_mode, size: 14, color: Colors.amber),
                    SizedBox(width: 6),
                    Text(
                      'DEV MODE: Simulates instant top-up',
                      style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final amount = double.tryParse(controller.text) ?? defaultAmount;
                  await _performDevTopup(amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D632),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm & Pay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _performDevTopup(double amount) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initiating Top Up...')),
    );

    try {
      final repo = ref.read(payrollRepositoryProvider);
      // Simulate STK Push delay
      await Future.delayed(const Duration(seconds: 1));
      
      final result = await repo.devTopup(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! New balance: ${result['newBalance']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Re-verify funds after topup
        await _verifyFunds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top Up Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processPayroll() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Call processPayroll which returns PayrollProcessingResult
      final result = await ref.read(payrollProvider.notifier).processPayroll(
            widget.workerIds,
            widget.payPeriodId,
          );
      
      // Refresh transactions list
      await ref.read(transactionsProvider.notifier).fetchTransactions();
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          // Convert PayrollProcessingResult to Map for results page
          _batchResult = {
            'successCount': result.successCount,
            'failureCount': result.failureCount,
            'totalProcessed': result.totalProcessed,
            'failedWorkerIds': result.failedWorkerIds,
            'batchId': result.batchId,
            // Generate simplified results list from counts
            'results': List.generate(
              result.totalProcessed,
              (i) => {
                'success': i < result.successCount,
                'workerName': 'Worker ${i + 1}',
                'netPay': 0.0,
                'error': i >= result.successCount ? 'Payment failed' : null,
              },
            ),
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking wallet balance...'),
            ],
          ),
        ),
      );
    }

    if (_batchResult != null) {
      return _buildResultsPage();
    }

    // Safe fallback if calculation failed but verification finished
    final verification = _verificationResult ?? const FundVerificationResult(
      requiredAmount: 0,
      availableBalance: 0,
      canProceed: false,
      shortfall: 0,
      workerCount: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payroll'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Wallet Balance Card
            _WalletBalanceCard(
              verification: verification,
              onTopUp: _showTopupDialog,
            ),
            const SizedBox(height: 24),

            // 2. Payroll Summary
            const Text(
              'Payroll Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Total Workers', '${widget.workerIds.length}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    const Text('Funds Allocation:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('• Net Pay Transfers (M-Pesa)'),
                    const Text('• Tax Remittance (KRA)'),
                    const Text('• Statutory Deductions (NSSF/NHIF)'),
                  ],
                ),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

             const SizedBox(height: 32),

             if (_isProcessing)
               const Column(
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Processing payments...'),
                   Text('Please do not close this screen', style: TextStyle(color: Colors.grey, fontSize: 12)),
                 ],
               )
             else
               Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   ElevatedButton(
                     onPressed: verification.canProceed ? _processPayroll : null,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: Colors.green,
                       foregroundColor: Colors.white,
                       disabledBackgroundColor: Colors.grey.shade300,
                     ),
                     child: Text(
                       verification.canProceed 
                         ? 'Confirm & Pay ${verification.formattedRequired}' 
                         : 'Insufficient Funds',
                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     ),
                   ),
                   if (!verification.canProceed)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: _showTopupDialog, 
                        icon: const Icon(Icons.add_card),
                        label: const Text('Top Up Wallet Now'),
                      ),
                    ),
                 ],
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildResultsPage() {
    final result = _batchResult!;
    final successCount = result['successCount'] as int;
    final failureCount = result['failureCount'] as int;
    final results = result['results'] as List<dynamic>;
    final allSuccess = failureCount == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Results'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Column(
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: allSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allSuccess ? Icons.check_rounded : Icons.priority_high_rounded,
                    size: 48,
                    color: allSuccess ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  allSuccess ? 'All Payments Initiated' : 'Payments Completed with Errors',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  allSuccess 
                    ? 'Workers will receive M-Pesa notifications shortly.'
                    : '$successCount successful, $failureCount failed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          const Divider(),

          // Worker List
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = results[index];
                final success = item['success'] as bool;
                final name = item['workerName'] as String;
                final netPay = (item['netPay'] as num?)?.toDouble() ?? 0.0;
                final error = item['error'] ?? 'Unknown error';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: success ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      success ? Icons.check : Icons.close,
                      color: success ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: success 
                    ? Text('Net Pay: KES ${NumberFormat("#,##0").format(netPay)}')
                    : Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  trailing: success 
                    ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                    : null,
                );
              },
            ),
          ),

          // Footer Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   ref.read(payrollProvider.notifier).reset();
                   ref.read(selectedWorkersProvider.notifier).set({});
                   context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.black, // Primary Action
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final FundVerificationResult verification;
  final VoidCallback onTopUp;

  const _WalletBalanceCard({
    required this.verification,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final isSufficient = verification.canProceed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSufficient ? Colors.grey.shade200 : Colors.red.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSufficient ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2), // Green-50 or Red-50
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Wallet Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  verification.formattedBalance,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                if (!isSufficient)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Shortfall: ${verification.formattedShortfall}',
                        style: const TextStyle(
                          color: Colors.red, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Cost Breakdown
          Padding(
             padding: const EdgeInsets.all(20),
             child: Column(
               children: [
                 _row('Total Payroll Cost', verification.formattedRequired, isBold: true),
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 12),
                   child: Divider(height: 1),
                 ),
                 if (isSufficient)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sufficient funds available',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                 else
                   Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Insufficient funds',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: onTopUp,
                        child: const Text('Top Up'),
                      ),
                    ],
                   ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: Colors.grey.shade700, 
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal
        )),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 16 : 14
        )),
      ],
    );
  }
}
