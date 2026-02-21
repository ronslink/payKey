import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/payments/presentation/providers/payments_provider.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../constants/finance_constants.dart';

class MpesaTopUpPage extends ConsumerStatefulWidget {
  const MpesaTopUpPage({super.key});

  @override
  ConsumerState<MpesaTopUpPage> createState() => _MpesaTopUpPageState();
}

class _MpesaTopUpPageState extends ConsumerState<MpesaTopUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController(); 
  
  // M-Pesa Transaction Limit
  static const int kMpesaMaxAmount = 150000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings?.mpesaPhone != null && settings!.mpesaPhone!.isNotEmpty) {
        setState(() {
          _phoneController.text = settings.mpesaPhone!;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleTopUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final phoneNumber = _phoneController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    try {
      await ref.read(paymentsProvider.notifier).initiatePayment(phoneNumber, amount);

      if (mounted) {
        _showSuccessDialog(phoneNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate top-up: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Request Sent'),
          ],
        ),
        content: Text(
          'An STK Push has been sent to $phone. Please enter your M-Pesa PIN to complete the transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Go back to finance
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentsProvider);
    final isLoading = paymentState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: FinanceTheme.cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Load M-Pesa Funds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter amount to transfer from your M-Pesa to your wallet.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    
                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g. 0712345678',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade50,
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Please enter a phone number';
                         }
                         // Normalize logic handled by backend now, but basic validation helps
                         if (value.length < 9) {
                           return 'Please enter a valid phone number';
                         }
                         return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (KES)',
                        prefixText: 'KES ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        if (amount > kMpesaMaxAmount) {
                          return 'Amount cannot exceed KES 150,000';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleTopUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Top Up Now', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
