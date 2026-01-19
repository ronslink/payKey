
import 'package:flutter/material.dart';
import '../constants/payroll_confirm_constants.dart';

class TopupSelectionSheet extends StatefulWidget {
  final double defaultAmount;
  final Function(double amount, String phone) onMpesaConfirm;
  final Function(double amount) onCheckoutConfirm;
  final Function(double amount) onStripeConfirm; // New

  const TopupSelectionSheet({
    super.key,
    required this.defaultAmount,
    required this.onMpesaConfirm,
    required this.onCheckoutConfirm,
    required this.onStripeConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required double shortfall,
    required Function(double amount, String phone) onMpesaConfirm,
    required Function(double amount) onCheckoutConfirm,
    required Function(double amount) onStripeConfirm,
  }) {

    final defaultAmount = shortfall > 0
        ? shortfall.ceilToDouble()
        : 1000.0;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopupSelectionSheet(
        defaultAmount: defaultAmount,
        onMpesaConfirm: onMpesaConfirm,
        onCheckoutConfirm: onCheckoutConfirm,
        onStripeConfirm: onStripeConfirm,
      ),
    );
  }

  @override
  State<TopupSelectionSheet> createState() => _TopupSelectionSheetState();
}

class _TopupSelectionSheetState extends State<TopupSelectionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Length 3
    _amountController = TextEditingController(
      text: widget.defaultAmount.toStringAsFixed(0),
    );
    _phoneController = TextEditingController(
      text: '07', // Default prefix
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    Navigator.of(context).pop();
    final amount = double.tryParse(_amountController.text) ?? widget.defaultAmount;
    
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Text(
            'Top Up Wallet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1B5E20), // M-Pesa Green approx
            tabs: const [
              Tab(text: 'M-Pesa'),
              Tab(text: 'Checkout'),
              Tab(text: 'Global/SEPA'),
            ],
          ),
          const SizedBox(height: 24),
          _buildAmountField(),
          const SizedBox(height: 24),
          SizedBox(
            height: 100, // Fixed height for tab content
            child: TabBarView(
              controller: _tabController,
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
            prefixText: 'KES ',
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

  Widget _buildCheckoutInfo() {
     return const Center(
       child: Text(
         'You will be redirected to complete payment via Card or PesaLink.',
         textAlign: TextAlign.center,
         style: TextStyle(color: Colors.grey),
       ),
     );
  }

  Widget _buildStripeInfo() {
     return const Center(
       child: Text(
         'Pay with Card, SEPA, or Apple/Google Pay via Stripe.',
         textAlign: TextAlign.center,
         style: TextStyle(color: Colors.grey),
       ),
     );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Proceed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
