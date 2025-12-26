import 'package:flutter/material.dart';
import '../constants/payroll_confirm_constants.dart';
import '../models/payroll_confirm_state.dart';

/// Wallet balance card showing verification status
class WalletBalanceCard extends StatelessWidget {
  final FundVerificationResult verification;
  final VoidCallback onTopUp;

  const WalletBalanceCard({
    super.key,
    required this.verification,
    required this.onTopUp,
  });

  bool get _isSufficient => verification.canProceed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PayrollConfirmTheme.walletCardDecoration(
        isSufficient: _isSufficient,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCostBreakdown(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isSufficient
            ? PayrollConfirmTheme.successBgLight
            : PayrollConfirmTheme.errorBgLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PayrollConfirmTheme.cardBorderRadius - 2),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Current Wallet Balance',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verification.formattedBalance,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!_isSufficient) _buildShortfallBadge(),
        ],
      ),
    );
  }

  Widget _buildShortfallBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: PayrollConfirmTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Shortfall: ${verification.formattedShortfall}',
          style: const TextStyle(
            color: PayrollConfirmTheme.errorRed,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildRow(
            'Total Payroll Cost',
            verification.formattedRequired,
            isBold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _isSufficient ? _buildSufficientStatus() : _buildInsufficientStatus(),
        ],
      ),
    );
  }

  Widget _buildSufficientStatus() {
    return const Row(
      children: [
        Icon(Icons.check_circle, color: PayrollConfirmTheme.successGreen, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sufficient funds available',
            style: TextStyle(
              color: PayrollConfirmTheme.successGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsufficientStatus() {
    return Row(
      children: [
        const Icon(Icons.cancel, color: PayrollConfirmTheme.errorRed, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Insufficient funds',
            style: TextStyle(
              color: PayrollConfirmTheme.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onTopUp,
          child: const Text('Top Up'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

/// Payroll summary card
class PayrollSummaryCard extends StatelessWidget {
  final int workerCount;

  const PayrollSummaryCard({
    super.key,
    required this.workerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
            _buildSummaryRow('Total Workers', '$workerCount'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            const Text(
              'Funds Allocation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Net Pay Transfers (M-Pesa)'),
            const Text('• Tax Remittance (KRA)'),
            const Text('• Statutory Deductions (NSSF/NHIF)'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

/// Error display widget
class PayrollErrorBanner extends StatelessWidget {
  final String error;

  const PayrollErrorBanner({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: PayrollConfirmTheme.errorRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: PayrollConfirmTheme.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Processing indicator
class PayrollProcessingIndicator extends StatelessWidget {
  const PayrollProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Processing payments...'),
        Text(
          'Please do not close this screen',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

/// Verification loading state
class VerificationLoadingState extends StatelessWidget {
  const VerificationLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Confirm and pay button
class ConfirmPayButton extends StatelessWidget {
  final bool canProceed;
  final String formattedAmount;
  final VoidCallback? onPressed;
  final VoidCallback? onTopUp;

  const ConfirmPayButton({
    super.key,
    required this.canProceed,
    required this.formattedAmount,
    this.onPressed,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: canProceed ? onPressed : null,
          style: PayrollConfirmTheme.primaryButtonStyle,
          child: Text(
            canProceed ? 'Confirm & Pay $formattedAmount' : 'Insufficient Funds',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (!canProceed && onTopUp != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add_card),
              label: const Text('Top Up Wallet Now'),
            ),
          ),
      ],
    );
  }
}
