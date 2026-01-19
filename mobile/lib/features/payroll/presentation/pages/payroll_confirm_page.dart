import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Domain imports
import '../providers/payroll_provider.dart';
import '../providers/pay_period_provider.dart';
import '../constants/payroll_confirm_constants.dart';
import '../widgets/topup_selection_sheet.dart'; // New sheet
import 'package:url_launcher/url_launcher.dart'; // For Checkout
import '../models/payroll_confirm_state.dart';
import '../widgets/mpesa_topup_sheet.dart';
import '../widgets/payment_results_page.dart';

// Data imports
// Data imports
import '../../data/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';

// Worker imports
import '../../../workers/data/repositories/workers_repository.dart';

// Integration imports
// Integration imports
import 'package:mobile/integrations/intasend/intasend.dart';
import '../../../../integrations/stripe/services/stripe_service.dart'; // Stripe Service


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

    if (widget.workerIds.isEmpty) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.error,
            error: 'No workers selected for payroll',
          );
        });
      }
      return;
    }

    try {
      // 1. Fetch Workers for phone numbers
      final workerRepo = ref.read(workersRepositoryProvider);
      final allWorkers = await workerRepo.getWorkers(); 
      final workers = allWorkers.where((w) => widget.workerIds.contains(w.id)).toList();
      
      _workerPhones = { for (var w in workers) w.id : w.phoneNumber };

      // 2. Calculate payroll
      // FIX: Try to get draft payroll first to respect any user edits (e.g. partial salary)
      final repo = ref.read(payrollRepositoryProvider);
      List<PayrollCalculation> calculations = [];
      
      try {
        final draftItems = await repo.getDraftPayroll(widget.payPeriodId);
        // Filter for selected workers
        calculations = draftItems.where((c) => widget.workerIds.contains(c.workerId)).toList();
      } catch (_) {
        // Fallback to fresh calculation if draft fetch fails
      }

      // If no valid draft items found for selected workers, calculate fresh
      if (calculations.isEmpty) {
        calculations = await repo.calculatePayroll(widget.workerIds);
      }
      
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

  FundVerificationResult _convertIntaSendVerification(FundVerification iv) {
    return FundVerificationResult(
      requiredAmount: iv.requiredAmount,
      availableBalance: iv.availableBalance,
      clearingBalance: iv.clearingBalance,
      canProceed: iv.canProceed,
      shortfall: iv.shortfall,
      workerCount: iv.workerCount,
    );
  }

  void _showTopupSheet() {
    final shortfall = _state.verification?.shortfall ?? 0;

    TopupSelectionSheet.show(
      context: context,
      shortfall: shortfall,
      onMpesaConfirm: _performTopup,
      onCheckoutConfirm: _performCheckoutTopup,
      onStripeConfirm: _performStripeTopup,
    );
  }

  Future<void> _performStripeTopup(double amount) async {
    _showSnackbar(PayrollConfirmSnackbars.loading('Initializing Stripe...'));
    try {
       final stripeService = ref.read(stripeIntegrationServiceProvider);
       // Initialize Sheet (Backend call)
       await stripeService.initPaymentSheet(amount: amount, currency: 'EUR');
       
       if (mounted) _hideSnackbar();
       
       // Present Sheet
       await stripeService.presentPaymentSheet();
       
       if (mounted) {
         _showSnackbar(PayrollConfirmSnackbars.success('Payment successful! Verifying balance...'));
         // Wait for webhook (a bit longer for Stripe?) or optimistically verify
         await Future.delayed(const Duration(seconds: 5)); 
         await _verifyFunds();
       }
    } catch (e) {
       if (mounted) {
         _hideSnackbar();
         // Handle "Cancelled" specific error if possible to just hide snackbar?
         // StripeException usually contains code 'Canceled'.
         // For now, simple error message.
         _showSnackbar(PayrollConfirmSnackbars.error('Payment Error: $e'));
       }
    }
  }

  Future<void> _performCheckoutTopup(double amount) async {
    _showSnackbar(PayrollConfirmSnackbars.loading('Redirecting to Checkout...'));

    try {
      final paymentService = ref.read(paymentServiceProvider);
      // Initiate Checkout
      final url = await paymentService.checkoutTopUp(amount: amount);
      
      if (mounted && url != null) {
         _hideSnackbar();
         
         // Launch URL
         final uri = Uri.parse(url);
         if (await canLaunchUrl(uri)) {
             await launchUrl(uri, mode: LaunchMode.externalApplication);
             
             // Show success message and wait for user to return
             // Ideally we should poll or have a "I have paid" button, but simple delay works for now.
             _showSnackbar(PayrollConfirmSnackbars.success('Checkout opened. Please complete payment and return.'));
             
             // Wait for user to complete payment (e.g., 30s) then verify
             // Optimistic verify after delay
             await Future.delayed(const Duration(seconds: 15)); 
             await _verifyFunds();
         } else {
             _showSnackbar(PayrollConfirmSnackbars.error('Could not launch payment page.'));
         }
      } else {
         if (mounted) {
            _hideSnackbar();
            _showSnackbar(PayrollConfirmSnackbars.error('Failed to generate checkout link.'));
         }
      }
    } catch (e) {
      if (mounted) {
        _hideSnackbar();
        _showSnackbar(PayrollConfirmSnackbars.error('Checkout Error: $e'));
      }
    }
  }

  Future<void> _performTopup(double amount, String phone) async {
    _showSnackbar(PayrollConfirmSnackbars.loading('Initiating Top Up...'));

    try {
      // FIX: Ensure phone number is in 254 format for IntaSend
      String formattedPhone = phone.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('+254')) {
         formattedPhone = formattedPhone.substring(1);
      }

      final paymentService = ref.read(paymentServiceProvider);
      final response = await paymentService.topUpWallet(
        amount: amount,
        phoneNumber: formattedPhone,
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
      // Process payroll via backend API (which handles IntaSend disbursement server-side)
      // skipPayout: false means the backend WILL process the M-Pesa payouts
      await ref.read(payrollProvider.notifier).processPayroll(
            widget.workerIds,
            widget.payPeriodId,
            skipPayout: false, // Backend handles disbursement
      );

      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(payPeriodsProvider);

      // Create a success result for UI display
      final batchResult = PayrollBatchResult(
        successCount: _preparedPayouts!.length,
        failureCount: 0,
        totalProcessed: _preparedPayouts!.length,
        failedWorkerIds: [],
        results: _preparedPayouts!.map((p) => PayrollWorkerResult(
          success: true,
          workerName: p.name,
          netPay: p.amount,
          error: null,
        )).toList(),
      );

      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.completed,
            batchResult: batchResult,
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
    final canCoverWithClearing = !isSufficient && 
        (verification.availableBalance + verification.clearingBalance >= verification.requiredAmount);
    
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
                  if (verification.clearingBalance > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                     ),
                     child: Text(
                        'Clearing: ${verification.formattedClearing}',
                        style: TextStyle(
                           fontSize: 12, 
                           color: Colors.orange.shade800,
                           fontWeight: FontWeight.w500,
                        ),
                     ),
                  ),
                ],
                ],
              ),
              if (!isSufficient && !canCoverWithClearing)
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
            if (canCoverWithClearing)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Funds are clearing. You have enough to cover this payment once settled.',
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PayrollConfirmTheme.errorBgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
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
