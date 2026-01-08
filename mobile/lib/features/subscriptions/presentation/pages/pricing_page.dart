import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({super.key});

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  @override
  void initState() {
    super.initState();
    // FutureProvider loads automatically
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(subscriptionPlansProvider);
    final subscriptionState = ref.watch(userSubscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: plansState.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 64,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No subscription plans available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                ...plans.map((plan) => _buildPlanCard(plan, subscriptionState)),
                _buildFooter(),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load plans',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      color: Colors.white,
      child: const Column(
        children: [
          SizedBox(height: 24),
          Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select the perfect plan for managing your domestic workers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AsyncValue<Subscription?> userSubscription) {
    final isCurrentPlan = userSubscription.when(
      data: (subscription) => subscription?.plan.tier == plan.tier,
      loading: () => false,
      error: (_, _) => false,
    );
    final isFreeTier = plan.tier == 'free';
    final isPopular = plan.isPopular;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCardBorderColor(plan.tier, isCurrentPlan),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Plan Description
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      plan.priceUSD.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '/month',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                
                // M-Pesa Price
                Text(
                  'or KES ${plan.priceKES.toStringAsFixed(0)} via M-Pesa',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Features
                ...plan.features.map((feature) => 
                  _buildFeature(feature)
                ),
                
                const SizedBox(height: 24),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _handleSelectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(plan.tier, isCurrentPlan),
                      foregroundColor: isCurrentPlan ? const Color(0xFF6B7280) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : isFreeTier
                              ? 'Get Started Free'
                              : 'Upgrade to ${plan.tier}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String featureKey) {
    final featureText = _getFeatureDisplayText(featureKey);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              featureText,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'All plans include 14-day free trial',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cancel anytime',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardBorderColor(String tier, bool isCurrentPlan) {
    if (isCurrentPlan) return const Color(0xFF3B82F6);
    if (tier == 'gold') return const Color(0xFF10B981);
    return const Color(0xFFE5E7EB);
  }

  Color _getButtonColor(String tier, bool isCurrentPlan) {
    if (isCurrentPlan) return const Color(0xFFE5E7EB);
    if (tier == 'free' || tier == 'gold') return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  String _getFeatureDisplayText(String featureKey) {
    switch (featureKey) {
      case 'worker_limit':
        return 'Up to unlimited workers';
      case 'tax_calculations':
        return 'Automatic tax calculations';
      case 'mpesa_payments':
        return 'M-Pesa payments';
      case 'leave_tracking':
        return 'Leave tracking';
      case 'time_tracking':
        return 'Time tracking';
      case 'automatic_tax_payments':
        return 'Automatic tax payments to KRA';
      case 'finance_software_integration':
        return 'Finance software integration';
      case 'multi_property':
        return 'Multi-property management';
      default:
        return featureKey.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _handleSelectPlan(SubscriptionPlan plan) {
    if (plan.tier == 'free') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free plan selected successfully!')),
      );
      return;
    }

    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Upgrade to ${plan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: KES ${NumberFormat('#,##0').format(plan.priceKES)}'),
            const SizedBox(height: 16),
            const Text('Enter M-Pesa phone number for payment:'),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '2547XXXXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneController.text.isEmpty) return;
              
              Navigator.of(dialogContext).pop();
              
              try {
                // Initiate M-Pesa STK Push
                await ref.read(paymentsProvider.notifier).initiatePayment(
                  phoneController.text, 
                  plan.priceKES,
                  accountReference: 'payDome-${plan.name}',
                  transactionDesc: 'Subscription Upgrade',
                );

                if (!mounted) return;
                
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Request Sent'),
                      content: Text(
                        'Please check your phone (${phoneController.text}) to complete the payment of KES ${NumberFormat('#,##0').format(plan.priceKES)}.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
              } catch (e) {
                if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment initiation failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // M-Pesa Green
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay via M-Pesa'),
          ),
        ],
      ),
    );
  }
}