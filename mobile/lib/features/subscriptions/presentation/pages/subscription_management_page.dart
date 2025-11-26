import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class SubscriptionManagementPage extends ConsumerStatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  ConsumerState<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends ConsumerState<SubscriptionManagementPage> {
  @override
  void initState() {
    super.initState();
    // Use ref.refresh to trigger data fetching instead of notifier
    Future.microtask(() {
      ref.refresh(subscriptionPlansProvider);
      ref.refresh(userSubscriptionProvider);
      ref.refresh(subscriptionPaymentHistoryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(subscriptionPlansProvider);
    final userSubState = ref.watch(userSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
      ),
      body: plansState.when(
        data: (plans) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(subscriptionPlansProvider);
              ref.refresh(userSubscriptionProvider);
            },
            child: ListView(
              children: [
                // Current Subscription Section
                userSubState.when(
                  data: (userSub) {
                    return Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Subscription',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (userSub != null) ...[
                              Text('Plan: ${userSub.plan.name}'),
                              Text('Status: ${userSub.status}'),
                              Text('Amount: \$${userSub.amountPaid.toStringAsFixed(2)} ${userSub.currency}'),
                              Text('Started: ${userSub.startDate.day}/${userSub.startDate.month}/${userSub.startDate.year}'),
                            ] else ...[
                              const Text('No active subscription'),
                              const SizedBox(height: 8),
                              const Text(
                                'Upgrade to access more features and workers',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Scroll to plans section
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Scroll down to see available plans')),
                                  );
                                },
                                child: const Text('View Plans'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const Center(child: Text('Error loading subscription')),
                ),

                // Available Plans Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Available Plans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...plans.map((plan) => _buildPlanCard(plan, userSubState)),
              ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, AsyncValue<Subscription?> userSubState) {
    final isCurrentPlan = userSubState.value?.plan.tier == plan.tier;
    final isPopular = plan.isPopular;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '\$${plan.priceUSD.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text('/month'),
              ],
            ),
            const SizedBox(height: 16),
            if (plan.features.isNotEmpty) ...[
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : () => _selectPlan(plan),
                child: Text(isCurrentPlan ? 'Current Plan' : 'Select Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Plan Selection'),
        content: Text('Are you sure you want to select the ${plan.name} plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle plan selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${plan.name} plan selected!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}