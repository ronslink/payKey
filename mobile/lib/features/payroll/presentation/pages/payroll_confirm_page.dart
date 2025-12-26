import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Domain imports
import '../providers/payroll_provider.dart';
import '../providers/pay_period_provider.dart';
import '../constants/payroll_confirm_constants.dart';
import '../models/payroll_confirm_state.dart';
import '../widgets/mpesa_topup_sheet.dart';
import '../widgets/payment_results_page.dart';

// Data imports
// Data imports
import '../../data/repositories/payroll_repository.dart';
// import '../../data/models/payroll_model.dart';

// Worker imports
import '../../../workers/data/repositories/workers_repository.dart';

// Integration imports
import '../../../../integrations/intasend/intasend.dart';
// import '../../../../integrations/intasend/providers/intasend_providers.dart';
// import '../../../../integrations/intasend/services/payment_service.dart';
// ignore: unused_import
import '../../../../integrations/intasend/models/intasend_models.dart' as intasend_model;

/// Payroll confirmation page
class PayrollConfirmPage extends ConsumerStatefulWidget {
  final List<String> workerIds;
  final String payPeriodId;

  const PayrollConfirmPage({
    super.key,
    required this.workerIds,
    required this.payPeriodId,
  });

  @override
  ConsumerState<PayrollConfirmPage> createState() => _PayrollConfirmPageState();
}

class _PayrollConfirmPageState extends ConsumerState<PayrollConfirmPage> {
  PayrollConfirmState _state = const PayrollConfirmState.initial();
  List<WorkerPayout>? _preparedPayouts;
  
  Map<String, String> _workerPhones = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyFunds();
    });
  }

  Future<void> _verifyFunds() async {
    setState(() {
      _state = _state.copyWith(
        status: PayrollConfirmStatus.verifying,
        clearError: true,
      );
    });

    try {
      // 1. Fetch Workers for phone numbers
      final workerRepo = ref.read(workersRepositoryProvider);
      final allWorkers = await workerRepo.getWorkers(); 
      final workers = allWorkers.where((w) => widget.workerIds.contains(w.id)).toList();
      
      _workerPhones = { for (var w in workers) w.id : w.phoneNumber };

      // 2. Calculate payroll
      final repo = ref.read(payrollRepositoryProvider);
      final calculations = await repo.calculatePayroll(widget.workerIds);
      
      // 3. Map to IntaSend WorkerPayout
      final payouts = calculations.map((c) {
        return WorkerPayout(
          workerId: c.workerId,
          name: c.workerName,
          phoneNumber: _workerPhones[c.workerId] ?? '',
          amount: c.netPay,
          narrative: 'Salary',
        );
      }).toList();

      _preparedPayouts = payouts;

      // 4. Verify funds
      final intaSendVerification = await ref.read(fundVerificationProvider(payouts).future);
      
      // 5. Map to UI
      final uiVerification = _convertIntaSendVerification(intaSendVerification);

      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.ready,
            verification: uiVerification,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.error,
            error: 'Failed to verify funds: $e',
          );
        });
      }
    }
  }

  FundVerificationResult _convertIntaSendVerification(intasend_model.FundVerification iv) {
    return FundVerificationResult(
      requiredAmount: iv.requiredAmount,
      availableBalance: iv.availableBalance,
      canProceed: iv.canProceed,
      shortfall: iv.shortfall,
      workerCount: iv.workerCount,
    );
  }

  void _showTopupSheet() {
    final shortfall = _state.verification?.shortfall ?? 0;

    MpesaTopupSheet.show(
      context: context,
      shortfall: shortfall,
      onConfirm: _performTopup,
    );
  }

  Future<void> _performTopup(double amount, String phone) async {
    _showSnackbar(PayrollConfirmSnackbars.loading('Initiating Top Up...'));

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final response = await paymentService.topUpWallet(
        amount: amount,
        phoneNumber: phone,
      );

      if (mounted && response != null) {
        _hideSnackbar();
        
        if (response.isFailed) {
             _showSnackbar(PayrollConfirmSnackbars.error('Top Up Failed: ${response.message}'));
             return;
        }

        _showSnackbar(
          PayrollConfirmSnackbars.success(
            'STK Push Sent! Check your phone to complete payment.',
          ),
        );
        
        await Future.delayed(const Duration(seconds: 15)); 
        await _verifyFunds();
      }
    } catch (e) {
      if (mounted) {
        _hideSnackbar();
        _showSnackbar(PayrollConfirmSnackbars.error('Top Up Failed: $e'));
      }
    }
  }

  Future<void> _processPayroll() async {
    if (_preparedPayouts == null || _preparedPayouts!.isEmpty) {
        _showSnackbar(PayrollConfirmSnackbars.error('No payroll data to process'));
        return;
    }

    setState(() {
      _state = _state.copyWith(
        status: PayrollConfirmStatus.processing,
        clearError: true,
      );
    });

    try {
      final payoutResult = await ref.read(disbursementProvider.notifier).disburseSalaries(
        workers: _preparedPayouts!,
        payPeriod: widget.payPeriodId,
      );

      if (payoutResult == null) {
         throw Exception('Disbursement failed to initiate');
      }

      await ref.read(payrollProvider.notifier).processPayroll(
            widget.workerIds,
            widget.payPeriodId,
            skipPayout: true,
      );

      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(payPeriodsProvider);

      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.completed,
            batchResult: _convertIntaSendResult(payoutResult),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.ready,
            error: e.toString(),
          );
        });
      }
    }
  }

  PayrollBatchResult _convertIntaSendResult(DisbursementResult result) {
    return PayrollBatchResult(
        successCount: result.successCount,
        failureCount: result.failedCount,
        totalProcessed: result.totalCount,
        failedWorkerIds: result.items.where((i) => i.isFailed).map((i) => i.workerId).toList(),
        results: result.items.map((i) => PayrollWorkerResult(
            success: i.isSuccess || i.isPending, 
            workerName: i.workerName,
            netPay: i.amount,
            error: i.error
        )).toList(),
    );
  }

  void _handleBackToHome() {
    context.go('/payroll');
  }

  void _showSnackbar(SnackBar snackbar) {
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  void _hideSnackbar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.hasResults && _state.batchResult != null) {
      return PaymentResultsPage(
        result: _state.batchResult!,
        onBackToHome: _handleBackToHome,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Manual color since theme missing
      appBar: AppBar(
        title: const Text('Confirm Payroll'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildConfirmationPage(),
      bottomNavigationBar: _buildActionSection(_state.verification),
    );
  }

  Widget _buildConfirmationPage() {
    if (_state.isVerifying) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Verification Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyFunds,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final verification = _state.verification;
    if (verification == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWalletCard(
            context: context,
            verification: verification,
            onTopUp: _showTopupSheet,
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(
            context: context,
            verification: verification,
          ),
          const SizedBox(height: 24),
          const Center(child: IntaSendTrustBadge(width: 320)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWalletCard({
    required BuildContext context,
    required FundVerificationResult verification,
    required VoidCallback onTopUp,
  }) {
    final isSufficient = verification.hasSufficientFunds;
    
    return Container(
      decoration: PayrollConfirmTheme.walletCardDecoration(isSufficient: isSufficient),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verification.formattedBalance,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (!isSufficient)
                 ElevatedButton.icon(
                    onPressed: onTopUp,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Top Up'),
                    style: PayrollConfirmTheme.mpesaButtonStyle.copyWith(
                       padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                       backgroundColor: const WidgetStatePropertyAll(PayrollConfirmTheme.mpesaGreen),
                       minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
                       shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    ),
                 ),
            ],
          ),
          if (!isSufficient) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PayrollConfirmTheme.errorBgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      'Insufficient funds. Shortfall: ${verification.formattedShortfall}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required FundVerificationResult verification,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Use Colors.white directly since backgroundColor didn't exist in theme
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PayrollConfirmTheme.cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Payroll Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
           const SizedBox(height: 16),
           _row('Total Net Pay', verification.formattedRequired),
           const Divider(height: 24),
           _row('Workers', '${verification.workerCount}'),
        ],
      ),
    );
  }
  
  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(label, style: const TextStyle(color: Colors.grey)),
         Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionSection(FundVerificationResult? verification) {
    final canProceed = verification?.canProceed ?? false;
    final isProcessing = _state.isProcessing;
    
    if (verification == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canProceed && !isProcessing ? _processPayroll : null,
          style: PayrollConfirmTheme.primaryButtonStyle.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.disabled)) return Colors.grey;
               return PayrollConfirmTheme.successGreen;
            }),
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  canProceed 
                      ? 'Confirm & Pay' 
                      : 'Insufficient Funds',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
