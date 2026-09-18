import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';

class TopupSelectionSheet extends StatefulWidget {
  final double defaultAmount;
  final Function(double amount, String phone) onMpesaConfirm;
  final Function(double amount) onCheckoutConfirm;
  final Function(double amount) onStripeConfirm;
  final String? defaultPhone;

  const TopupSelectionSheet({
    super.key,
    required this.defaultAmount,
    required this.onMpesaConfirm,
    required this.onCheckoutConfirm,
    required this.onStripeConfirm,
    this.defaultPhone,
  });

  static Future<void> show({
    required BuildContext context,
    required double shortfall,
    required Function(double amount, String phone) onMpesaConfirm,
    required Function(double amount) onCheckoutConfirm,
    required Function(double amount) onStripeConfirm,
    String? defaultPhone,
  }) {
    final defaultAmount = shortfall > 0 ? shortfall.ceilToDouble() : 1000.0;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopupSelectionSheet(
        defaultAmount: defaultAmount,
        onMpesaConfirm: onMpesaConfirm,
        onCheckoutConfirm: onCheckoutConfirm,
        onStripeConfirm: onStripeConfirm,
        defaultPhone: defaultPhone,
      ),
    );
  }

  @override
  State<TopupSelectionSheet> createState() => _TopupSelectionSheetState();
}

class _TopupSelectionSheetState extends State<TopupSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TextEditingController _amountController;
  late final TextEditingController _eurAmountController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _amountController = TextEditingController(
      text: widget.defaultAmount.toStringAsFixed(0),
    );
    // A KES shortfall is never an EUR payment amount.
    _eurAmountController = TextEditingController();
    _phoneController = TextEditingController(
      text: widget.defaultPhone ?? '07', // Default prefix or settings phone
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _eurAmountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isStripe => _tabController.index == 2;
  String get _currency => _isStripe ? 'EUR' : 'KES';
  TextEditingController get _activeAmountController =>
      _isStripe ? _eurAmountController : _amountController;
  double? get _enteredAmount => double.tryParse(_activeAmountController.text);
  bool get _validAmount {
    final amount = _enteredAmount;
    return amount != null &&
        amount.isFinite &&
        amount >= (_isStripe ? 0.5 : 1) &&
        RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(_activeAmountController.text);
  }

  void _handleConfirm() {
    if (!_validAmount) return;
    final amount = _enteredAmount!;
    Navigator.of(context).pop();
    // Request the exact top-up amount. The provider checkout is authoritative
    // for any fee that applies to the merchant's negotiated tariff.

    if (_tabController.index == 0) {
      widget.onMpesaConfirm(amount, _phoneController.text);
    } else if (_tabController.index == 1) {
      widget.onCheckoutConfirm(amount);
    } else {
      widget.onStripeConfirm(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Top Up Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: const Color(0xFF1B5E20), // M-Pesa Green approx
              tabs: const [
                Tab(text: 'M-Pesa'),
                Tab(text: 'Card (KES)'),
                Tab(text: 'EUR (Stripe)'),
              ],
              onTap: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildFeeNotice(),
            const SizedBox(height: 24),
            SizedBox(
              height: 100, // Fixed height for tab content
              child: TabBarView(
                controller: _tabController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe to avoid confusion
                children: [
                  _buildPhoneField(),
                  _buildCheckoutInfo(),
                  _buildStripeInfo(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isStripe ? 'Amount to pay in EUR' : 'Wallet Top-up Amount',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('topup-amount-$_currency'),
          controller: _activeAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}), // Rebuild to update breakdown
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '$_currency ',
            hintText: _isStripe ? 'Enter EUR amount' : null,
            prefixStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
            filled: true,
            fillColor: context.surfaceMuted,
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

  Widget _buildFeeNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: context.iconDefault),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isStripe
                  ? 'You will pay in EUR. Your wallet is credited in KES using '
                        'the exchange rate when payment settles. '
                        'Your bank may charge additional fees.'
                  : 'You are adding KES ${(_enteredAmount ?? 0).toStringAsFixed(2)}. '
                        'Any provider fee will be shown before you confirm payment.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
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
            prefixIcon: Icon(Icons.phone_android, color: context.iconDefault),
            filled: true,
            fillColor: context.surfaceMuted,
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

  Widget _buildCheckoutInfo() {
    return Center(
      child: Text(
        'You will be redirected to complete payment via Card or PesaLink.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.textSecondary),
      ),
    );
  }

  Widget _buildStripeInfo() {
    return Center(
      child: Text(
        'Pay in EUR by card or SEPA. Bank payments may take several days; '
        'your wallet is credited after payment is confirmed.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.textSecondary),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _validAmount ? _handleConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _validAmount
              ? '${_isStripe ? 'Pay' : 'Add'} $_currency ${_enteredAmount!.toStringAsFixed(2)}'
              : 'Enter ${_isStripe ? 'at least EUR 0.50' : 'a KES amount'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
