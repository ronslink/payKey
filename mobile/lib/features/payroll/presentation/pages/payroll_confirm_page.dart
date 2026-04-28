import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Domain imports
import '../providers/payroll_provider.dart';
import '../providers/pay_period_provider.dart';
import '../constants/payroll_confirm_constants.dart';
import '../widgets/topup_selection_sheet.dart'; // New sheet
import 'package:url_launcher/url_launcher.dart'; // For Checkout
import '../models/payroll_confirm_state.dart';
import '../../../settings/providers/settings_provider.dart';

import '../widgets/payment_results_page.dart';
import '../widgets/payroll_processing_dialog.dart';

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
  List<String> _cashWorkerNames = [];
  List<PayrollCalculation> _calculations = [];

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
      final allWorkers = await workerRepo.getWorkers(includeInactive: true); 
      
      final workers = widget.workerIds.isEmpty 
          ? allWorkers 
          : allWorkers.where((w) => widget.workerIds.contains(w.id)).toList();
          
      if (workers.isEmpty) {
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
      
      _workerPhones = { for (var w in workers) w.id : w.phoneNumber };
      
      final actualWorkerIds = workers.map((w) => w.id).toList();
      
      // Track payment methods for UI display
      _cashWorkerNames = workers
          .where((w) => w.paymentMethod.toUpperCase() == 'CASH')
          .map((w) => w.name)
          .toList();

      // 2. Calculate payroll
      // FIX: Try to get draft payroll first to respect any user edits (e.g. partial salary)
      final repo = ref.read(payrollRepositoryProvider);
      List<PayrollCalculation> calculations = [];
      
      try {
        final draftItems = await repo.getDraftPayroll(widget.payPeriodId);
        // Filter for selected workers
        calculations = draftItems.where((c) => actualWorkerIds.contains(c.workerId)).toList();
      } catch (_) {
        // Fallback to fresh calculation if draft fetch fails
      }

      // If no valid draft items found for selected workers, calculate fresh
      if (calculations.isEmpty) {
        calculations = await repo.calculatePayroll(actualWorkerIds);
      }
      
      // 2.5 Save draft payroll so backend has DRAFT records for finalization
      // This is critical for off-cycle flows where no drafts were created yet
      try {
        final existingDrafts = await repo.getDraftPayroll(widget.payPeriodId);
        if (existingDrafts.isEmpty) {
          final draftItems = calculations.map((c) => {
            'workerId': c.workerId,
            'grossSalary': c.grossSalary,
          }).toList();
          await repo.saveDraftPayroll(widget.payPeriodId, draftItems);
        }
      } catch (_) {
        // Non-critical: processPayroll controller also creates drafts as fallback
      }
      
      // 3. Map to IntaSend WorkerPayout
      _calculations = calculations;
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
      // Use backend verification which supports worker filtering
      final verification = await repo.verifyFunds(
        widget.payPeriodId, 
        workerIds: actualWorkerIds,
      );
      
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            status: PayrollConfirmStatus.ready,
            verification: verification,
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

  void _showTopupSheet() {
    final shortfall = _state.verification?.shortfall ?? 0;
    
    // Attempt to get phone number from settings
    final settingsAsync = ref.read(settingsProvider);
    final defaultPhone = settingsAsync.value?.mpesaPhone;

    TopupSelectionSheet.show(
      context: context,
      shortfall: shortfall,
      defaultPhone: defaultPhone,
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
      // Process payroll via backend API (returns jobId for async processing)
      final response = await ref.read(payrollProvider.notifier).processPayroll(
            widget.workerIds,
            widget.payPeriodId,
            skipPayout: false,
      );

      // If we have a jobId, show the progress dialog
      if (response.isAsync && response.jobId != null && mounted) {
        final finalStatus = await showPayrollProcessingDialog(
          context: context,
          jobId: response.jobId!,
          workerCount: _preparedPayouts!.length,
        );

        if (!mounted) return;

        if (finalStatus != null && finalStatus.isCompleted) {
          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(payPeriodsProvider);

          PayrollBatchResult batchResult;
          if (finalStatus.result != null) {
            final payoutData = finalStatus.result!['payoutResults'] as Map<String, dynamic>? ?? finalStatus.result!;
            final processResult = PayrollProcessingResult.fromJson(payoutData);
            batchResult = PayrollBatchResult(
              successCount: processResult.successCount,
              failureCount: processResult.failureCount,
              totalProcessed: processResult.totalCount,
              failedWorkerIds: processResult.failedWorkerIds,
              results: processResult.results.map((r) => PayrollWorkerResult(
                success: r.success,
                workerName: r.workerName,
                netPay: r.netPay ?? 0,
                error: r.error,
              )).toList(),
            );
          } else {
            // Fallback if result is missing
            batchResult = PayrollBatchResult(
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
          }

          setState(() {
            _state = _state.copyWith(
              status: PayrollConfirmStatus.completed,
              batchResult: batchResult,
            );
          });
        } else {
          setState(() {
            _state = _state.copyWith(
              status: PayrollConfirmStatus.ready,
              error: 'Payroll processing failed. Please try again.',
            );
          });
        }
      } else {
        // Immediate completion (shouldn't happen with new async flow, but handle it)
        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(payPeriodsProvider);

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
      }
    } catch (e, stacktrace) {
      debugPrint('PAYROLL CONFIRM ERROR: $e');
      debugPrint('STACKTRACE: $stacktrace');
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
      backgroundColor: context.surfaceMuted,
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
                style: TextStyle(color: context.textSecondary),
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
          // For all-cash payrolls, show cash disbursement card instead of wallet
          if (_isAllCash)
            _buildCashDisbursementCard(context)
          else ...[
            _buildWalletCard(
              context: context,
              verification: verification,
              onTopUp: _showTopupSheet,
            ),
            if (_cashWorkerNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCashPaymentBanner(context),
            ],
          ],
          const SizedBox(height: 24),
          _buildSummaryCard(
            context: context,
            verification: verification,
          ),
          if (!_isAllCash) ...[
            const SizedBox(height: 24),
            const Center(child: IntaSendTrustBadge(width: 320)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Shows a cash disbursement summary for all-cash payrolls.
  /// Lists each worker with their net pay (what to hand over)
  /// and summarizes the employer's statutory tax obligations.
  Widget _buildCashDisbursementCard(BuildContext context) {
    // Calculate total tax obligations from the payroll calculations
    double totalPaye = 0;
    double totalNssf = 0;
    double totalShif = 0;
    double totalHousingLevy = 0;
    double totalNetPay = 0;

    for (final calc in _calculations) {
      totalNetPay += calc.netPay;
      totalPaye += calc.taxBreakdown.paye;
      totalNssf += calc.taxBreakdown.nssf;
      totalShif += calc.taxBreakdown.nhif;
      totalHousingLevy += calc.taxBreakdown.housingLevy;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.payments_outlined, color: Colors.amber.shade800, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Disbursement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hand the amounts below to each worker',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Per-worker amounts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                for (final calc in _calculations) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              calc.workerName.isNotEmpty ? calc.workerName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            calc.workerName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'KES ${calc.netPay.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tax obligations section
          if (totalPaye > 0 || totalNssf > 0 || totalShif > 0 || totalHousingLevy > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Tax Obligations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remit these to the respective authorities',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (totalPaye > 0)
                    _taxRow(context, 'PAYE (KRA)', totalPaye),
                  if (totalNssf > 0)
                    _taxRow(context, 'NSSF', totalNssf),
                  if (totalShif > 0)
                    _taxRow(context, 'SHIF (NHIF)', totalShif),
                  if (totalHousingLevy > 0)
                    _taxRow(context, 'Housing Levy', totalHousingLevy),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taxRow(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 14)),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
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
      decoration: PayrollConfirmTheme.walletCardDecoration(context, isSufficient: isSufficient),
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
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
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
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
      // Use context.surfacePrimary directly since backgroundColor didn't exist in theme
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(PayrollConfirmTheme.cardBorderRadius),
        border: Border.all(color: context.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Payroll Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
           const SizedBox(height: 16),
           _row(context, 'Workers', '${verification.workerCount}'),
           const Divider(height: 24),
           _row(context, 'Net Pay', 'KES ${verification.netPayTotal.toStringAsFixed(2)}'),
           if (verification.estimatedFees > 0) ...[
             const SizedBox(height: 8),
             _row(context, 'M-Pesa Fees (by provider)', verification.formattedFees),
           ],
           const Divider(height: 24),
           _row(context, 'Total Required', verification.formattedRequired, bold: true),
        ],
      ),
    );
  }
  
  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(label, style: TextStyle(
           color: bold ? context.textPrimary : context.textSecondary,
           fontWeight: bold ? FontWeight.bold : FontWeight.normal,
         )),
         Text(value, style: TextStyle(
           fontWeight: FontWeight.bold,
           fontSize: bold ? 16 : 14,
         )),
      ],
    );
  }

  Widget _buildCashPaymentBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                _isAllCash ? 'Cash Payment' : 'Cash Workers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAllCash
                ? 'This is a cash payroll. No wallet deduction required. '
                  'Please disburse cash to your worker(s) and this run '
                  'will be recorded as completed.'
                : '${_cashWorkerNames.join(", ")} will be paid in cash. '
                  'No wallet deduction for cash workers. '
                  'Please disburse their pay manually.',
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isAllCash {
    final payouts = _preparedPayouts;
    return _cashWorkerNames.isNotEmpty &&
        payouts != null &&
        payouts.isNotEmpty &&
        _cashWorkerNames.length == payouts.length;
  }

  Widget _buildActionSection(FundVerificationResult? verification) {
    final canProceed = verification?.canProceed ?? false;
    final isProcessing = _state.isProcessing;
    
    if (verification == null) return const SizedBox.shrink();

    final buttonLabel = canProceed 
        ? (_isAllCash ? 'Confirm & Record' : 'Confirm & Pay')
        : 'Insufficient Funds';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
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
          style: PayrollConfirmTheme.primaryButtonStyle(context).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.disabled)) return context.borderMuted;
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
                  buttonLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
