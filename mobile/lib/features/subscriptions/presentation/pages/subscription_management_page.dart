import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../providers/subscription_payment_history_provider.dart';

class SubscriptionManagementPage extends ConsumerStatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  ConsumerState<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends ConsumerState<SubscriptionManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(subscriptionPlansProvider);
      ref.invalidate(userSubscriptionProvider);
      ref.invalidate(subscriptionPaymentHistoryProvider);
    });
  }

  Color _getPlanColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'FREE':
        return const Color(0xFF6B7280);
      case 'BASIC':
        return const Color(0xFF3B82F6);
      case 'GOLD':
        return const Color(0xFFF59E0B);
      case 'PLATINUM':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getPlanSubtitle(String tier) {
    switch (tier.toUpperCase()) {
      case 'FREE':
        return 'For individuals just starting out';
      case 'BASIC':
        return 'Essential tools for small households';
      case 'GOLD':
        return 'For growing teams needing more';
      case 'PLATINUM':
        return 'The ultimate management solution';
      default:
        return 'Flexible plan for your needs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(subscriptionPlansProvider);
    final userSubState = ref.watch(userSubscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Plans & Pricing', style: TextStyle(color: Color(0xFF111827))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: plansState.when(
        data: (plans) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(subscriptionPlansProvider);
              ref.invalidate(userSubscriptionProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                   // Current Subscription Section
                  userSubState.when(
                    data: (userSub) {
                      if (userSub == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.green),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Plan: ${userSub.plan.name}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userSub.status == 'active' 
                                      ? 'Active since ${_formatDate(userSub.startDate)}'
                                      : 'Status: ${userSub.status}',
                                    style: TextStyle(
                                      color: userSub.status == 'active' ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Header
                  const Text(
                    'Simple Pricing for Everyone',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the plan that best fits your needs. No hidden fees.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Plans List
                  ...plans.map((plan) => _buildPlanCard(plan, userSubState)),

                  const SizedBox(height: 32),
                  _buildTrustBadge(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(subscriptionPlansProvider);
                  ref.invalidate(userSubscriptionProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AsyncValue<Subscription?> userSubState) {
    final isCurrentPlan = userSubState.value?.plan.tier == plan.tier;
    final color = _getPlanColor(plan.tier);
    final subtitle = _getPlanSubtitle(plan.tier);
    final isPopular = plan.isPopular;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: color, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      plan.priceUSD.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[900],
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        Text('/mo', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Text(
                  '~ KES ${plan.priceKES.toInt()}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 32),
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(feature, style: TextStyle(color: Colors.grey[700]))),
                    ],
                  ),
                )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? color : Colors.white,
                      foregroundColor: isPopular ? Colors.white : color,
                      disabledBackgroundColor: Colors.grey[100],
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: isPopular ? 4 : 0,
                      side: isCurrentPlan ? null : BorderSide(color: color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Current Plan' : (plan.tier == 'FREE' ? 'Get Started' : 'Start Free Trial'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  void _selectPlan(SubscriptionPlan plan) {
    context.push('/subscriptions/payment', extra: plan);
  }

  Widget _buildTrustBadge() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Secure Payment via Stripe & M-Pesa', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Cancel anytime. 14-day money-back guarantee.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}