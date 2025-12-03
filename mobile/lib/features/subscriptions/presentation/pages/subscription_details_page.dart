import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/subscription_payment_history_provider.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_payment_record.dart';

class SubscriptionDetailsPage extends ConsumerStatefulWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  ConsumerState<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends ConsumerState<SubscriptionDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Load payment history when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionPaymentHistoryProvider.notifier).loadUserSubscriptionPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSubscriptionAsync = ref.watch(userSubscriptionProvider);
    final paymentHistoryAsync = ref.watch(subscriptionPaymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userSubscriptionProvider);
              ref.read(subscriptionPaymentHistoryProvider.notifier).loadUserSubscriptionPaymentHistory();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userSubscriptionProvider);
          await ref.read(subscriptionPaymentHistoryProvider.notifier).loadUserSubscriptionPaymentHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Plan Card
              userSubscriptionAsync.when(
                data: (subscription) {
                  if (subscription == null) {
                    return _buildNoSubscriptionCard(context);
                  }
                  return _buildSubscriptionCard(context, subscription);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              
              const SizedBox(height: 24),
              
              // Payment History Section
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              paymentHistoryAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No payment history found'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _buildPaymentItem(context, payment);
                    },
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                error: (e, s) => Text('Error loading history: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Active Subscription',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Subscribe to a plan to unlock premium features.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/pricing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription) {
    final statusColor = subscription.status == 'ACTIVE' ? Colors.green : Colors.red;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Plan',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.plan.tier.toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscription.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Plan Name', subscription.plan.name),
            const SizedBox(height: 12),
            _buildInfoRow('Amount', '${subscription.currency} ${subscription.amountPaid}'),
            const SizedBox(height: 12),
            _buildInfoRow('Start Date', DateFormat('MMM d, yyyy').format(subscription.startDate)),
            const SizedBox(height: 12),
            _buildInfoRow('Renews On', DateFormat('MMM d, yyyy').format(subscription.endDate)),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/pricing'),
                child: const Text('Change Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, SubscriptionPaymentRecord payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: payment.status == 'COMPLETED' ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            payment.status == 'COMPLETED' ? Icons.check : Icons.access_time,
            color: payment.status == 'COMPLETED' ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          DateFormat('MMM d, yyyy').format(payment.createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.providerTransactionId),
            if (payment.processedAt != null)
              Text(
                'Paid: ${DateFormat('MMM d, yyyy').format(payment.processedAt!)}',
                style: TextStyle(color: Colors.green[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${payment.currency} ${payment.amount}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              payment.paymentMethod,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
