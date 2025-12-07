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

/// Home page displaying dashboard with stats, quick actions, and recent activity
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(context),
                  const SizedBox(height: 24),
                  _buildStatsGrid(workersAsync, payPeriodsAsync),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildUpcomingTasks(context),
                  const SizedBox(height: 24),
                  _buildRecentActivity(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111827),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'PayKey',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined, size: 20),
          ),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        )),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF2563EB),
                Color(0xFF1E40AF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6) .withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: TextStyle(
                        color: Colors.white .withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white .withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildStatsGrid(
    AsyncValue<List<WorkerModel>> workersAsync,
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
        )),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Workers',
                    value: _getTotalWorkersValue(workersAsync),
                    icon: Icons.people_outline,
                    color: const Color(0xFF3B82F6),
                    trend: '+2 this month',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Today',
                    value: _getActiveWorkersValue(workersAsync),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    trend: '100%',
                    trendUp: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pay Periods',
                    value: _getPayPeriodsValue(payPeriodsAsync),
                    icon: Icons.calendar_today_outlined,
                    color: const Color(0xFF8B5CF6),
                    trend: 'This month',
                    trendUp: null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending Tasks',
                    value: '3',
                    icon: Icons.task_alt_outlined,
                    color: const Color(0xFFF59E0B),
                    trend: '2 urgent',
                    trendUp: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalWorkersValue(AsyncValue<List<WorkerModel>> workersAsync) {
    return workersAsync.when(
      data: (workers) => workers.length.toString(),
      loading: () => '...',
      error: (_, ___) => '0',
    );
  }

  String _getActiveWorkersValue(AsyncValue<List<WorkerModel>> workersAsync) {
    return workersAsync.when(
      data: (workers) => workers.where((w) => w.isActive).length.toString(),
      loading: () => '...',
      error: (_, ___) => '0',
    );
  }

  String _getPayPeriodsValue(AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return payPeriodsAsync.when(
      data: (periods) => periods.length.toString(),
      loading: () => '...',
      error: (_, ___) => '0',
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool? trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color .withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const Spacer(),
              if (trend != null && trendUp != null)
                _buildTrendIndicator(trendUp),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trend != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  color: _getTrendColor(trendUp),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(bool trendUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendUp ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        trendUp ? Icons.trending_up : Icons.trending_down,
        size: 12,
        color: trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
    );
  }

  Color _getTrendColor(bool? trendUp) {
    if (trendUp == true) return const Color(0xFF10B981);
    if (trendUp == false) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Widget _buildQuickActions(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Run Payroll',
                subtitle: 'Process payments',
                icon: Icons.play_circle_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                onTap: () => context.go('/payroll'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Add Worker',
                subtitle: 'New employee',
                icon: Icons.person_add_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                onTap: () => context.go('/workers/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Accounting',
                subtitle: 'Export payroll',
                icon: Icons.account_balance_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                ),
                onTap: () => context.go('/accounting'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Tax Filing',
                subtitle: 'Manage taxes',
                icon: Icons.receipt_long_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                onTap: () => context.go('/taxes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Reports',
                subtitle: 'View analytics',
                icon: Icons.analytics_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                ),
                onTap: () => context.go('/reports'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Time Tracking',
                subtitle: 'Clock in/out',
                icon: Icons.access_time_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                onTap: () => context.go('/time-tracking'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        )),
        child: _buildEmptyTasks(),
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981) .withValues(alpha: 0.1),
                  const Color(0xFF059669) .withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have no pending tasks.\nWe\'ll notify you when action is needed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activitiesAsync = ref.watch(recentActivitiesProvider);
    final workersAsync = ref.watch(workersProvider);

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyActivityState(workersAsync);
        }
        return _buildActivityList(activities);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState('Error: $error'),
    );
  }

  Widget _buildEmptyActivityState(AsyncValue<List<WorkerModel>> workersAsync) {
    return workersAsync.maybeWhen(
      data: (workers) {
        if (workers.isEmpty) {
          return _buildGettingStarted();
        }
        return _buildEmptyActivity();
      },
      orElse: () => _buildEmptyActivity(),
    );
  }

  Widget _buildActivityList(List<Activity> activities) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.take(5).map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityItem(
                icon: _getActivityIcon(activity.type),
                title: activity.title,
                subtitle: activity.description,
                time: _formatTime(activity.timestamp),
                color: _getActivityColor(activity.type),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6) .withValues(alpha: 0.1),
                  const Color(0xFF2563EB) .withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Activity Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your recent actions will appear here.\nStart by adding workers or processing payroll.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/workers/add'),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Worker'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/payroll'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Payroll'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStarted() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6) .withValues(alpha: 0.1),
            const Color(0xFF8B5CF6) .withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6) .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rocket_launch_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Getting Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChecklistItem(
            title: 'Add your first worker',
            description: 'Set up employee profiles',
            completed: false,
            onTap: () => context.go('/workers/add'),
          ),
          const SizedBox(height: 12),
          _ChecklistItem(
            title: 'Create a pay period',
            description: 'Define your payroll schedule',
            completed: false,
            onTap: () => context.go('/payroll'),
          ),
          const SizedBox(height: 12),
          _ChecklistItem(
            title: 'Process payroll',
            description: 'Calculate and review payments',
            completed: false,
            onTap: () => context.go('/payroll'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  // Activity helper methods
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'payroll':
        return Icons.payments_outlined;
      case 'worker':
        return Icons.person_outline;
      case 'tax':
        return Icons.receipt_long_outlined;
      case 'leave':
        return Icons.event_busy_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'payroll':
        return const Color(0xFF10B981);
      case 'worker':
        return const Color(0xFF3B82F6);
      case 'tax':
        return const Color(0xFF8B5CF6);
      case 'leave':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Reusable widget components
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white .withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final String description;
  final bool completed;
  final VoidCallback onTap;

  const _ChecklistItem({
    required this.title,
    required this.description,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: completed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: completed
                  ? const Color(0xFF10B981) .withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: completed ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: completed
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF111827),
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              if (!completed)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFD1D5DB),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
