import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';
import '../providers/subscription_provider.dart';
import '../../../../integrations/intasend/intasend.dart';

enum PaymentMethod { stripe, mpesa }

class PaymentPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final String? returnPath;

  const PaymentPage({super.key, required this.plan, this.returnPath});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  final _phoneController = TextEditingController(text: '07');
  String? _mpesaPaymentId;
  Timer? _statusPollTimer;
  String? _statusMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiateStripePayment() async {
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final checkoutUrl = await repo.subscribeWithStripe(widget.plan.tier);
      
      if (checkoutUrl.isEmpty) {
        throw Exception('Empty checkout URL received from server');
      }
      
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (launched) {
        if (mounted) _showInstructionsDialog();
      } else {
        final launchedInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (!launchedInApp) {
          throw Exception('Could not launch payment URL');
        }
        if (mounted) _showInstructionsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _initiateMpesaPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initiating request...';
    });

    try {
      // Use Subscription Repository (Backend Integration)
      final repo = ref.read(subscriptionRepositoryProvider);
      final result = await repo.subscribeWithMpesa(
        widget.plan.tier, // Pass tier as ID for backend lookup
        phone,
      );

      if (result.success && result.paymentId != null) {
        setState(() {
          _mpesaPaymentId = result.paymentId;
          _statusMessage = 'Request sent! Check your phone and enter PIN.';
        });
        
        // Start polling for payment status via Backend
        _startStatusPolling();
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startStatusPolling() async {
    if (_mpesaPaymentId == null) return;
    
    // Poll backend for status
    final repo = ref.read(subscriptionRepositoryProvider);
    
    // Create a local timer for this polling session
    int attempts = 0;
    const maxAttempts = 60; // 3 minutes approx (3s interval)
    
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      
      try {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final status = await repo.checkMpesaPaymentStatus(_mpesaPaymentId!);
        
        if (status.isCompleted) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusMessage = null;
            });
            ref.invalidate(userSubscriptionProvider);
            _showSuccessDialog();
          }
        } else if (status.isFailed) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment failed or was cancelled.'), 
                backgroundColor: Colors.red
              ),
            );
          }
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          if (mounted) {
             setState(() {
              _isProcessing = false;
              _statusMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment verification timed out. Please check status later.'), 
                backgroundColor: Colors.orange
              ),
            );
          }
        }
      } catch (e) {
        // Ignore transient errors during polling
        print('Polling error: $e');
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: Text(
          'Your ${widget.plan.name} subscription is now active.\n\n'
          'Thank you for subscribing!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to returnPath if provided, otherwise go to subscriptions
              if (widget.returnPath != null && widget.returnPath!.isNotEmpty) {
                context.go(widget.returnPath!);
              } else {
                context.go('/subscriptions');
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Initiated'),
        content: const Text(
          'We have opened the payment page in your browser.\n\n'
          'Once you complete the payment, please return to this app and click "Refresh" to update your subscription status.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.invalidate(userSubscriptionProvider);
              context.go('/subscriptions');
            },
            child: const Text('Refresh & Check Status'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (_selectedMethod == PaymentMethod.stripe) {
      _initiateStripePayment();
    } else {
      _initiateMpesaPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 32),
            
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // M-Pesa Option
            _buildPaymentMethodCard(
              method: PaymentMethod.mpesa,
              icon: Icons.phone_android,
              iconColor: const Color(0xFF00A651), // M-Pesa green
              title: 'Pay with M-Pesa',
              subtitle: 'KES ${widget.plan.priceKES.toStringAsFixed(0)} - STK Push to your phone',
            ),
            const SizedBox(height: 12),
            
            // Stripe Option
            _buildPaymentMethodCard(
              method: PaymentMethod.stripe,
              icon: Icons.credit_card,
              iconColor: const Color(0xFF635BFF), // Stripe purple
              title: 'Pay with Card',
              subtitle: 'USD \$${widget.plan.priceUSD.toStringAsFixed(2)} - Secure via Stripe',
            ),
            
            // Phone number input for M-Pesa
            if (_selectedMethod == PaymentMethod.mpesa) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: '07XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF00A651)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMethod == PaymentMethod.mpesa 
                    ? const Color(0xFF00A651) 
                    : const Color(0xFF635BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selectedMethod == PaymentMethod.mpesa
                          ? 'Pay KES ${widget.plan.priceKES.toStringAsFixed(0)}'
                          : 'Pay \$${widget.plan.priceUSD.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 24),
            
            // Trust Badge
            if (_selectedMethod == PaymentMethod.mpesa)
              const Center(child: IntaSendTrustBadge(width: 300))
            else
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Payments are secure and encrypted by Stripe',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Card(
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? iconColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor, size: 32),
          title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(subtitle),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: iconColor)
              : Icon(Icons.radio_button_off, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.plan.name, style: const TextStyle(fontSize: 16)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${widget.plan.priceKES.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'USD \$${widget.plan.priceUSD.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Billed Monthly', style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                '${widget.plan.workerLimit} workers',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
