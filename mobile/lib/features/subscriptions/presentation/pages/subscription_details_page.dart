import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/subscription_payment_history_provider.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_payment_record.dart';
import '../../data/repositories/subscription_repository.dart';

class SubscriptionDetailsPage extends ConsumerStatefulWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  ConsumerState<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState
    extends ConsumerState<SubscriptionDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userSubscriptionProvider);
      ref
          .read(subscriptionPaymentHistoryProvider.notifier)
          .loadUserSubscriptionPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSubscriptionAsync = ref.watch(userSubscriptionProvider);
    final paymentHistoryAsync = ref.watch(subscriptionPaymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userSubscriptionProvider);
              ref
                  .read(subscriptionPaymentHistoryProvider.notifier)
                  .loadUserSubscriptionPaymentHistory();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userSubscriptionProvider);
          await ref
              .read(subscriptionPaymentHistoryProvider.notifier)
              .loadUserSubscriptionPaymentHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Card
              userSubscriptionAsync.when(
                data: (subscription) {
                  if (subscription == null) {
                    return _buildNoSubscriptionCard(context);
                  }
                  return _buildSubscriptionCard(context, subscription);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, s) => _buildErrorCard(context, e),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              userSubscriptionAsync.when(
                data: (sub) =>
                    sub != null ? _buildQuickActions(context, sub) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Payment History Section
              _buildPaymentHistorySection(context, paymentHistoryAsync),

              const SizedBox(height: 24),

              // Help & Support Card
              _buildHelpCard(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to a plan to unlock premium features and manage your team more effectively.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/pricing'),
                icon: const Icon(Icons.workspace_premium),
                label: const Text('View Plans'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription) {
    final isActive = subscription.status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;
    final planColor = _getPlanColor(subscription.plan.tier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with Plan Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getPlanIcon(subscription.plan.tier),
                    color: planColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.plan.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.pause_circle,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              subscription.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Workers Limit',
                    '${subscription.plan.workerLimit}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final difference = subscription.endDate.difference(now);
                      final days = difference.inDays;
                      final hours = difference.inHours;
                      
                      String displayValue;
                      Color displayColor;
                      
                      if (difference.isNegative) {
                        displayValue = 'Expired';
                        displayColor = Colors.red;
                      } else if (days == 0) {
                         // Less than 24 hours left
                         if (hours > 0) {
                           displayValue = '$hours Hrs';
                           displayColor = Colors.orange;
                         } else {
                           displayValue = '< 1 Hr';
                           displayColor = Colors.red;
                         }
                      } else {
                        displayValue = '$days';
                        displayColor = days < 7 ? Colors.orange : Colors.green;
                      }
                      
                      return _buildStatCard(
                        context,
                        'Days Left',
                        displayValue,
                        Icons.timer,
                        displayColor,
                      );
                    }
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Monthly Cost',
                    '\$${subscription.plan.priceUSD.toStringAsFixed(0)}',
                    Icons.payments,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Auto Renew',
                    subscription.autoRenew ? 'On' : 'Off',
                    Icons.autorenew,
                    subscription.autoRenew ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Subscription Details
            _buildDetailRow(
                'Plan', subscription.plan.tier.toUpperCase(), planColor),
            _buildDetailRow('Amount Paid',
                '${subscription.currency} ${subscription.amountPaid}', null),
            _buildDetailRow('Start Date',
                DateFormat('MMMM d, yyyy').format(subscription.startDate), null),
            _buildDetailRow('Renewal Date',
                DateFormat('MMMM d, yyyy').format(subscription.endDate), null),

            if (subscription.cancelledAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancelled on ${DateFormat('MMM d, yyyy').format(subscription.cancelledAt!)}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Subscription subscription) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Change Plan',
                    Icons.swap_horiz,
                    Colors.blue,
                    () => context.push('/pricing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Billing',
                    Icons.receipt_long,
                    Colors.green,
                    () => _showBillingInfo(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    subscription.autoRenew ? 'Cancel Auto-Renew' : 'Enable Auto-Renew',
                    subscription.autoRenew ? Icons.cancel : Icons.autorenew,
                    subscription.autoRenew ? Colors.orange : Colors.green,
                    () => _toggleAutoRenew(context, subscription),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Get Support',
                    Icons.support_agent,
                    Colors.purple,
                    () => _showSupportDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection(
      BuildContext context, AsyncValue<List<SubscriptionPaymentRecord>> historyAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Payment History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(subscriptionPaymentHistoryProvider.notifier)
                      .loadUserSubscriptionPaymentHistory(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No payments yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: payments.take(5).map((payment) {
                    return _buildPaymentItem(context, payment);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading history: $e',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, SubscriptionPaymentRecord payment) {
    final isCompleted = payment.status == 'COMPLETED';
    final statusColor = isCompleted ? Colors.green : Colors.orange;
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(payment.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      payment.paymentMethod == 'MPESA'
                          ? Icons.phone_android
                          : Icons.credit_card,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.paymentMethod,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.currency} ${currencyFormat.format(payment.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Subscription Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Upgrade anytime to unlock more features\n'
              '• Payment is processed securely via Stripe/M-Pesa\n'
              '• You can cancel or change plans at any time\n'
              '• Need help? Contact support 24/7',
              style: TextStyle(
                color: Colors.blue.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error, size: 48, color: Colors.red.shade600),
            const SizedBox(height: 12),
            Text(
              'Error Loading Subscription',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(userSubscriptionProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green),
            SizedBox(width: 12),
            Text('Billing Information'),
          ],
        ),
        content: const Text(
          'Manage your billing details, update payment method, and view invoices. '
          'All transactions are processed securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleAutoRenew(BuildContext context, Subscription subscription) {
    if (!subscription.autoRenew) {
      // Enabling auto-renew - simple confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.autorenew, color: Colors.green),
              SizedBox(width: 12),
              Text('Enable Auto-Renew?'),
            ],
          ),
          content: const Text('Your subscription will automatically renew each month.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _performToggle(context, subscription, true, null);
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      return;
    }

    // Disabling auto-renew - Request reason
    final reasonController = TextEditingController();
    final endDateStr = DateFormat('MMMM d, yyyy').format(subscription.endDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Cancel Subscription?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your subscription will remain active until $endDateStr.\n\n'
              'At the end of the billing period, you will be switched to the Free tier.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please tell us why you are leaving:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Too expensive, Switching to another service...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              _performToggle(context, subscription, false, reasonController.text);
            },
            child: const Text('Confirm Cancellation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) => reasonController.dispose());
  }

  Future<void> _performToggle(BuildContext context, Subscription subscription, bool newValue, String? reason) async {
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.toggleAutoRenew(newValue, reason: reason);
      ref.invalidate(userSubscriptionProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue
                ? 'Auto-renewal enabled'
                : 'Auto-renewal disabled. Access continues until end of billing period.'),
            backgroundColor: newValue ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.purple),
            SizedBox(width: 12),
            Text('Get Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with your subscription?'),
            SizedBox(height: 16),
            Text('📧 Email: support@paykey.app'),
            SizedBox(height: 8),
            Text('📞 Phone: +254 700 000 000'),
            SizedBox(height: 8),
            Text('💬 Live chat available 24/7'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
}
