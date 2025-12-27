import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class SubscriptionManagementPage extends ConsumerStatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  ConsumerState<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends ConsumerState<SubscriptionManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(subscriptionPlansProvider);
      ref.invalidate(userSubscriptionProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(subscriptionPlansProvider);
    final userSubState = ref.watch(userSubscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Plans & Pricing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(subscriptionPlansProvider);
              ref.invalidate(userSubscriptionProvider);
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: plansState.when(
        data: (plans) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionPlansProvider);
            ref.invalidate(userSubscriptionProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Subscription Status Card
                userSubState.when(
                  data: (userSub) => _buildCurrentPlanCard(context, userSub),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Header Section
                _buildHeaderSection(context),

                const SizedBox(height: 24),

                // Plans Grid
                ...plans.map((plan) => _buildPlanCard(
                      context,
                      plan,
                      userSubState.value,
                    )),

                const SizedBox(height: 32),

                // Trust & Security Badge
                _buildTrustBadge(context),

                const SizedBox(height: 24),

                // FAQ Section
                _buildFAQSection(context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, Subscription? subscription) {
    if (subscription == null) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rocket_launch, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Your Journey',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a plan that fits your needs',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isActive = subscription.status.toLowerCase() == 'active';
    final color = isActive ? Colors.green : Colors.orange;
    final planColor = _getPlanColor(subscription.plan.tier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPlanIcon(subscription.plan.tier),
                    color: planColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            subscription.plan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscription.status.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/subscriptions/details'),
                  child: const Text('Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Workers',
                  '${subscription.plan.workerLimit}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  'Renews',
                  _formatShortDate(subscription.endDate),
                  Icons.calendar_today,
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  'Amount',
                  '\$${subscription.plan.priceUSD.toStringAsFixed(0)}',
                  Icons.payments,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.workspace_premium, color: Colors.indigo.shade600, size: 48),
            const SizedBox(height: 12),
            Text(
              'Simple, Transparent Pricing',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that fits your team. No hidden fees, cancel anytime.',
              style: TextStyle(
                color: Colors.indigo.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, SubscriptionPlan plan, Subscription? currentSub) {
    final isCurrentPlan = currentSub?.plan.tier == plan.tier;
    final color = _getPlanColor(plan.tier);
    final isPopular = plan.isPopular;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Popular Banner
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: color,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Plan Icon and Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getPlanIcon(plan.tier), color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            _getPlanSubtitle(plan.tier),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan.priceUSD.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/month',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ KES ${plan.priceKES.toInt()}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Features
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: color, size: 14),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? color : Colors.white,
                      foregroundColor: isPopular ? Colors.white : color,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: isPopular ? 2 : 0,
                      side: isCurrentPlan ? null : BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : (plan.tier == 'FREE' ? 'Get Started Free' : 'Start 14-Day Trial'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  Widget _buildTrustBadge(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Secure Payments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildTrustItem(Icons.credit_card, 'Stripe'),
                _buildTrustItem(Icons.phone_android, 'M-Pesa'),
                _buildTrustItem(Icons.lock, 'SSL Encrypted'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '14-day free trial • Cancel anytime • No hidden fees',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.green.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.green.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'q': 'Can I change my plan later?',
        'a': 'Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately.',
      },
      {
        'q': 'What happens when my trial ends?',
        'a': 'You\'ll be automatically switched to your selected plan. We\'ll notify you before any charges.',
      },
      {
        'q': 'Is there a long-term commitment?',
        'a': 'No! All plans are month-to-month. Cancel anytime with no penalties.',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...faqs.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq['q']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faq['a']!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(subscriptionPlansProvider);
                ref.invalidate(userSubscriptionProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    // Relay returnPath if present in current URL
    final returnPath = GoRouterState.of(context).uri.queryParameters['returnPath'];
    final path = returnPath != null && returnPath.isNotEmpty
        ? '/subscriptions/payment?returnPath=${Uri.encodeComponent(returnPath)}'
        : '/subscriptions/payment';
    context.push(path, extra: plan);
  }

  String _formatShortDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
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

  IconData _getPlanIcon(String tier) {
    switch (tier.toUpperCase()) {
      case 'FREE':
        return Icons.card_giftcard;
      case 'BASIC':
        return Icons.star_border;
      case 'GOLD':
        return Icons.star;
      case 'PLATINUM':
        return Icons.diamond;
      default:
        return Icons.workspace_premium;
    }
  }

  String _getPlanSubtitle(String tier) {
    switch (tier.toUpperCase()) {
      case 'FREE':
        return 'For individuals just starting out';
      case 'BASIC':
        return 'Essential tools for small teams';
      case 'GOLD':
        return 'For growing teams needing more';
      case 'PLATINUM':
        return 'The ultimate management solution';
      default:
        return 'Flexible plan for your needs';
    }
  }
}