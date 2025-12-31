import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/leave_request_model.dart';
import '../../../subscriptions/presentation/providers/feature_access_provider.dart';
import '../providers/leave_management_provider.dart';

class LeaveBalancePage extends ConsumerStatefulWidget {
  final String? selectedWorkerId;

  const LeaveBalancePage({
    super.key,
    this.selectedWorkerId,
  });

  @override
  ConsumerState<LeaveBalancePage> createState() => _LeaveBalancePageState();
}

class _LeaveBalancePageState extends ConsumerState<LeaveBalancePage> {
  @override
  Widget build(BuildContext context) {
    // Check feature access
    final featureAccess = ref.watch(featureAccessProvider('leave_management'));

    if (widget.selectedWorkerId == null) {
      return _buildNoWorkerSelectedState();
    }

    final leaveBalance = ref.watch(leaveBalanceProvider(widget.selectedWorkerId!));

    return featureAccess.when(
      data: (access) => Column(
        children: [
          // Preview mode banner
          if (access.isPreview)
            _buildPreviewBanner(access.mockNotice ?? 'This is sample data'),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Leave Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  // ignore: unused_result
                  onPressed: () => ref.refresh(leaveBalanceProvider(widget.selectedWorkerId!)),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Balance',
                ),
              ],
            ),
          ),

          // Leave Balance Content
          Expanded(
            child: leaveBalance.when(
              data: (balance) => _buildBalanceContent(context, ref, balance),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading leave balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // ignore: unused_result
                        ref.refresh(leaveBalanceProvider(widget.selectedWorkerId!));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      loading: () => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Leave Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.refresh(leaveBalanceProvider(widget.selectedWorkerId!)),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Balance',
                ),
              ],
            ),
          ),
          Expanded(
            child: leaveBalance.when(
              data: (balance) => _buildBalanceContent(context, ref, balance),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading leave balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Leave Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.refresh(leaveBalanceProvider(widget.selectedWorkerId!)),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Balance',
                ),
              ],
            ),
          ),
          Expanded(
            child: leaveBalance.when(
              data: (balance) => _buildBalanceContent(context, ref, balance),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading leave balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkerSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Worker',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a worker from the dropdown above to view their leave balance',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceContent(BuildContext context, WidgetRef ref, LeaveBalanceModel balance) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.workerName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Year: ${balance.year}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Annual Leave Balance
          _buildLeaveTypeCard(
            context,
            'Annual Leave',
            balance.usedAnnualLeaves,
            balance.totalAnnualLeaves,
            Colors.green,
            Icons.beach_access,
            'Days used out of ${balance.totalAnnualLeaves} allocated days',
          ),

          const SizedBox(height: 16),

          // Sick Leave Card
          _buildLeaveTypeCard(
            context,
            'Sick Leave',
            0, // Currently not tracking sick leaves used
            balance.sickLeaves,
            Colors.orange,
            Icons.sick,
            'Available sick leave days',
            isUnlimited: balance.sickLeaves == -1,
          ),

          const SizedBox(height: 16),

          // Pending Requests
          _buildLeaveTypeCard(
            context,
            'Pending Requests',
            balance.pendingLeaves,
            999, // No limit on pending requests
            Colors.blue,
            Icons.pending,
            'Leave requests awaiting approval',
            showProgress: false,
          ),

          const SizedBox(height: 24),

          // Summary Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Remaining Annual',
                          '${balance.remainingAnnualLeaves}',
                          Icons.calendar_today,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Total Requests',
                          '${balance.usedAnnualLeaves + balance.pendingLeaves}',
                          Icons.list_alt,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to create leave request
                            _showQuickRequestDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Request Leave'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to leave history
                            _showLeaveHistory(context);
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('View History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Usage Tips
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Usage Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Request leave at least 2 weeks in advance for better approval chances\n'
                    '• Annual leave resets on January 1st each year\n'
                    '• Emergency leave can be requested for urgent situations\n'
                    '• Unused annual leave does not carry over to the next year',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard(
    BuildContext context,
    String title,
    int used,
    int total,
    Color color,
    IconData icon,
    String subtitle, {
    bool showProgress = true,
    bool isUnlimited = false,
  }) {
    final theme = Theme.of(context);
    final usagePercentage = total > 0 ? (used / total * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isUnlimited ? '∞' : '$used / $total',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (!isUnlimited && showProgress)
                      Text(
                        '${usagePercentage.toStringAsFixed(0)}% used',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            if (showProgress && !isUnlimited) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: usagePercentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPreviewBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to upgrade screen
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Leave Request'),
        content: const Text('This feature will open the leave request form for quick submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to leave request form
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showLeaveHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave History'),
        content: const Text('This will show the complete leave history for this worker.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}