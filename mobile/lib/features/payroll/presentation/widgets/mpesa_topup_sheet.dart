import 'package:flutter/material.dart';
import '../constants/payroll_confirm_constants.dart';

/// M-Pesa top-up bottom sheet
class MpesaTopupSheet extends StatefulWidget {
  final double defaultAmount;
  final Future<void> Function(double amount, String phone) onConfirm;

  const MpesaTopupSheet({
    super.key,
    required this.defaultAmount,
    required this.onConfirm,
  });

  /// Show the topup sheet
  static Future<void> show({
    required BuildContext context,
    required double shortfall,
    required Future<void> Function(double amount, String phone) onConfirm,
  }) {
    final defaultAmount = shortfall > 0
        ? shortfall.ceilToDouble()
        : PayrollConfirmConstants.defaultTopupAmount;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MpesaTopupSheet(
        defaultAmount: defaultAmount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<MpesaTopupSheet> createState() => _MpesaTopupSheetState();
}

class _MpesaTopupSheetState extends State<MpesaTopupSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.defaultAmount.toStringAsFixed(0),
    );
    _phoneController = TextEditingController(
      text: PayrollConfirmConstants.defaultPhonePrefix,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    Navigator.of(context).pop();
    final amount = double.tryParse(_amountController.text) ?? widget.defaultAmount;
    widget.onConfirm(amount, _phoneController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PayrollConfirmTheme.bottomSheetDecoration,
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
          _buildHandle(),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 32),
          _buildAmountField(),
          const SizedBox(height: 24),
          _buildPhoneField(),
          const SizedBox(height: 32),
          _buildConfirmButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PayrollConfirmTheme.mpesaGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: PayrollConfirmTheme.mpesaGreen,
            size: 28,
          ),
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
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount to Load',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '${PayrollConfirmConstants.currencyCode} ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'M-Pesa Phone Number',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
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
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleConfirm,
        style: PayrollConfirmTheme.mpesaButtonStyle,
        child: const Text(
          'Confirm & Pay',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
