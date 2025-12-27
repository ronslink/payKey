import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../payroll/presentation/providers/pay_period_provider.dart';
import '../../../payroll/data/models/pay_period_model.dart';
import '../../../payroll/data/utils/pay_period_utils.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

import '../../../onboarding/presentation/widgets/guided_tour.dart';
import '../../../onboarding/presentation/providers/tour_progress_provider.dart';
import '../../../onboarding/presentation/models/tour_models.dart';

/// New Home page with the redesigned dashboard UI
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _payrollKey = GlobalKey();
  final _workersKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _reportsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildPayrollCard(context, payPeriodsAsync),
                  _buildStatsRow(context, workersAsync, payPeriodsAsync),
                  _buildQuickActionsSection(context),
                  _buildDeadlinesSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildTour(context),
        ],
      ),
    );
  }

  Widget _buildTour(BuildContext context) {
    // Only show if tour provider is loaded and we haven't seen this tour
    final tourProgress = ref.watch(tourProgressProvider);
    final hasSeenTour = ref.watch(hasSeenProvider(TourKeys.dashboardTour));

    if (!tourProgress.isLoaded || hasSeenTour) {
      return const SizedBox.shrink();
    }

    final steps = [
      TourStep(
        targetKey: _payrollKey,
        title: 'Runs Payroll',
        description: 'Process payments, generate payslips, and manage pay periods here.',
        icon: Icons.payments_outlined,
        position: TourStepPosition.below,
      ),
      TourStep(
        targetKey: _workersKey,
        title: 'Manage Workers',
        description: 'Add new employees, view profiles, and track compliance status.',
        icon: Icons.people_outline,
        position: TourStepPosition.below,
      ),
      TourStep(
        targetKey: _quickActionsKey,
        title: 'Quick Actions',
        description: 'Fast access to common tasks like Leave Management and Reports.',
        icon: Icons.bolt,
        position: TourStepPosition.above,
      ),
    ];

    return GuidedTour(
      tourKey: TourKeys.dashboardTour,
      steps: steps,
      onComplete: () => ref.read(tourProgressProvider.notifier).completeTour(TourKeys.dashboardTour),
      onSkip: () => ref.read(tourProgressProvider.notifier).completeTour(TourKeys.dashboardTour),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final firstName = ref.watch(userFirstNameProvider);
                    return Text(
                      firstName.isEmpty ? 'Jambo! 👋' : 'Jambo, $firstName! 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(BuildContext context, AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    final activePeriod = payPeriodsAsync.when(
      data: (periods) => PayPeriodUtils.getNextPayrollPeriod(periods),
      loading: () => null,
      error: (_, _) => null,
    );

    final periodName = activePeriod?.name ?? 'No Active Payroll';
    final daysUntilDue = activePeriod?.payDate?.difference(DateTime.now()).inDays ?? 5;

    return GradientCard(
      key: _payrollKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payroll • $periodName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            daysUntilDue <= 0 ? 'Due Today!' : 'Due in $daysUntilDue days',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...List.generate(3, (i) => Align(
                widthFactor: 0.7,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 16, color: Colors.grey),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              Text('+ others ready', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/payroll/run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Process Payroll Now'),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, 
    AsyncValue<List<WorkerModel>> workersAsync,
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    final workers = workersAsync.when(
      data: (w) => w,
      loading: () => <WorkerModel>[],
      error: (_, _) => <WorkerModel>[],
    );
    final workerCount = workers.length;
    final activeWorkers = workers.where((w) => w.isActive).length;
    
    // Calculate pending (workers with compliance issues)
    final pendingCount = workers.where((w) => 
      w.nssfNumber == null || w.nhifNumber == null || w.kraPin == null
    ).length;

    // Get last completed payroll net pay (most recent) instead of all-time
    final lastPayrollNet = payPeriodsAsync.when(
      data: (periods) {
        final completed = periods.where((p) =>
          p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed
        ).toList();
        if (completed.isEmpty) return 0.0;
        // Sort by end date descending and take the first
        completed.sort((a, b) => b.endDate.compareTo(a.endDate));
        return completed.first.totalNetAmount ?? 0.0;
      },
      loading: () => 0.0,
      error: (_, _) => 0.0,
    );

    final formatter = NumberFormat('#,###');

    return SizedBox(
      key: _workersKey,
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SizedBox(
            width: 140,
            child: StatCard(
              icon: Icons.payments_outlined, 
              label: 'Last Payroll', 
              value: 'KES ${formatter.format(lastPayrollNet)}',
              iconColor: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: StatCard(
              icon: Icons.people_outline, 
              label: 'Employees', 
              value: '$workerCount',
              subtitle: '$activeWorkers Active',
              subtitleColor: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: StatCard(
              icon: Icons.pending_actions, 
              label: 'Pending', 
              value: '$pendingCount',
              iconColor: pendingCount > 0 ? Colors.orange : Colors.green,
              subtitle: pendingCount > 0 ? 'Compliance' : 'All set',
              subtitleColor: pendingCount > 0 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      key: _quickActionsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        QuickActionGrid(
          actions: [
            QuickActionButton(icon: Icons.home_work_outlined, label: 'Properties', onTap: () => context.push('/properties')),
            QuickActionButton(icon: Icons.access_time_outlined, label: 'Time Tracking', onTap: () => context.push('/time-tracking')),
            QuickActionButton(icon: Icons.event_note_outlined, label: 'Leave Mgmt', onTap: () => context.push('/leave')),
            QuickActionButton(icon: Icons.description_outlined, label: 'Reports', onTap: () => context.push('/reports')),
          ],
        ),
      ],
    );
  }

  Widget _buildDeadlinesSection(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statutory Deadlines', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/taxes'), child: const Text('View Calendar')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildDeadlineItem(
                context,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
                title: 'PAYE Tax',
                subtitle: 'Kenya Revenue Authority',
                day: 20,
                month: currentMonth,
                statusLabel: 'Due in ${20 - now.day} days',
                statusColor: now.day <= 20 ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 12),
              _buildDeadlineItem(
                context,
                icon: Icons.account_balance,
                iconColor: Colors.blue,
                title: 'NSSF Contribution',
                subtitle: 'Social Security Fund',
                day: 15,
                month: currentMonth,
                statusLabel: 'Due on 15th',
                statusColor: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildDeadlineItem(
                context,
                icon: Icons.health_and_safety,
                iconColor: Colors.green,
                title: 'SHIF Contribution',
                subtitle: 'Social Health Insurance Fund',
                day: 10,
                month: currentMonth,
                statusLabel: now.day <= 10 ? 'Due soon' : 'Paid',
                statusColor: now.day <= 10 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int day,
    required int month,
    required String statusLabel,
    required Color statusColor,
  }) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
