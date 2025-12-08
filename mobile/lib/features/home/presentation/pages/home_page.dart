import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../payroll/presentation/providers/pay_period_provider.dart';
import '../providers/activity_provider.dart';
import '../data/models/activity_model.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../payroll/data/models/pay_period_model.dart';

/// Home page with premium dashboard design
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBusinessSnapshot(workersAsync, payPeriodsAsync),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(context),
              const SizedBox(height: 24),
              _buildRecentActivitySection(activitiesAsync),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildBusinessSnapshot(
    AsyncValue<List<WorkerModel>> workersAsync,
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111827), Color(0xFF374151)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Next Payroll',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Due Soon',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Oct 30, 2025', // Dynamic date would go here
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSnapshotMetric(
                    'Active Workers',
                    workersAsync.when(
                      data: (w) => w.where((x) => x.isActive).length.toString(),
                      loading: () => '-',
                      error: (_, __) => '0',
                    ),
                    Icons.people,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                Expanded(
                  child: _buildSnapshotMetric(
                    'Total Cost (Est)',
                    'KES 0', // Placeholder for actual calc
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionBtn(context, 'Run Payroll', Icons.play_arrow_rounded, Colors.blue, '/payroll')),
            const SizedBox(width: 16),
            Expanded(child: _buildActionBtn(context, 'Add Worker', Icons.person_add_rounded, Colors.green, '/workers/add')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionBtn(context, 'File Taxes', Icons.receipt_long_rounded, Colors.purple, '/tax')),
            const SizedBox(width: 16),
            Expanded(child: _buildActionBtn(context, 'Reports', Icons.bar_chart_rounded, Colors.orange, '/reports')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionBtn(context, 'Attendance', Icons.access_time_rounded, Colors.teal, '/attendance')),
            const SizedBox(width: 16),
            Expanded(child: _buildActionBtn(context, 'Leave', Icons.calendar_month_rounded, Colors.cyan, '/leave')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionBtn(context, 'Properties', Icons.home_rounded, Colors.indigo, '/properties')),
            const SizedBox(width: 16),
            Expanded(child: _buildActionBtn(context, 'Accounting', Icons.account_balance_rounded, Colors.blueGrey, '/accounting')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, Color color, String route) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(AsyncValue<List<Activity>> activitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyActivityState();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(activity);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load activity'),
        ),
      ],
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getActivityIcon(activity.type), size: 18, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  activity.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(activity.timestamp),
            style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'payroll': return Icons.payments_outlined;
      case 'worker': return Icons.person_outline;
      case 'tax': return Icons.receipt_long_outlined;
      default: return Icons.notifications_none;
    }
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
