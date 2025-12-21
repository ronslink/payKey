import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';
import '../providers/subscription_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const PaymentPage({super.key, required this.plan});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;

  Future<void> _initiateStripePayment() async {
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final checkoutUrl = await repo.subscribeWithStripe(widget.plan.tier);
      
      if (checkoutUrl.isEmpty) {
        throw Exception('Empty checkout URL received from server');
      }
      
      final uri = Uri.parse(checkoutUrl);
      debugPrint('Launching Stripe checkout URL: $checkoutUrl');
      
      // Try to launch the URL directly - don't rely on canLaunchUrl
      // as it can fail on some Android versions with package visibility restrictions
      final launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        // In a real app with deep linking, we would handle the return.
        // For now, we show a dialog explaining what to do.
        if (mounted) {
          _showInstructionsDialog();
        }
      } else {
        // If external browser fails, try in-app browser
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
        
        if (!launchedInApp) {
          throw Exception('Could not launch payment URL: $checkoutUrl');
        }
        
        if (mounted) {
          _showInstructionsDialog();
        }
      }
    } catch (e) {
      debugPrint('Stripe payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
              Navigator.pop(context); // Close dialog
              // Navigate back
              context.pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger refresh
              ref.invalidate(userSubscriptionProvider);
              context.go('/subscriptions');
            },
            child: const Text('Refresh & Check Status'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 32),
            
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: const Icon(Icons.payment, color: Color(0xFF635BFF), size: 32),
                title: const Text('Pay with Stripe'),
                subtitle: const Text('Secure credit card payment via Stripe'),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF635BFF)),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _initiateStripePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF), // Stripe blurple
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay \$${widget.plan.priceUSD.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Payments are secure and encrypted by Stripe',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.plan.name,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '\$${widget.plan.priceUSD.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${widget.plan.priceUSD.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
