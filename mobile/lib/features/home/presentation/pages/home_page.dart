import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../payroll/presentation/providers/pay_period_provider.dart';
import '../../../payroll/data/models/pay_period_model.dart';
import '../../../payroll/data/utils/pay_period_utils.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../onboarding/presentation/widgets/guided_tour.dart';
import '../../../onboarding/presentation/providers/tour_progress_provider.dart';
import '../../../onboarding/presentation/models/tour_models.dart';
import '../providers/statutory_deadlines_provider.dart';
import '../../../../integrations/intasend/providers/intasend_providers.dart';
import '../../../settings/providers/settings_provider.dart';
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
  final _settingsKey = GlobalKey();
  final _supportKey = GlobalKey();
  final _deadlinesKey = GlobalKey();
  final _walletKey = GlobalKey();


  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildHeroSection(context, payPeriodsAsync, workersAsync),
                  _buildStatsRow(context, workersAsync, payPeriodsAsync),
                  const SizedBox(height: 16),
                  _buildWalletCard(context),
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
    // Only show if onboarding is completed and we haven't seen this tour.
    // Crucially, showDashboardTourProvider returns false while loading,
    // so no overlay is rendered until SharedPreferences confirms the tour
    // hasn't been completed yet.
    final tourProgress = ref.watch(tourProgressProvider);
    final showTour = tourProgress.isLoaded &&
        tourProgress.onboardingCompleted &&
        !tourProgress.hasSeen(TourKeys.dashboardTour);

    // Temporarily disabled due to Android opacity compositor bug
    return const SizedBox.shrink();

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
        targetKey: _walletKey,
        title: 'Payment Processing',
        description: 'Top up your wallet here. Payments process automatically if funded, or switch to manual in Settings.',
        icon: Icons.account_balance_wallet_outlined,
        position: TourStepPosition.above,
      ),
      TourStep(
        targetKey: _quickActionsKey,
        title: 'Quick Actions',
        description: 'Fast access to common tasks like Leave Management.',
        icon: Icons.bolt,
        position: TourStepPosition.above,
      ),
      TourStep(
        targetKey: _supportKey,
        title: 'Support Tickets',
        description: 'Need help? Create a support ticket here and our team will assist you.',
        icon: Icons.support_agent_rounded,
        position: TourStepPosition.above,
      ),
      TourStep(
        targetKey: _deadlinesKey,
        title: 'Tax Filing & Deadlines',
        description: 'Track statutory deadlines here. We help you stay compliant with KRA, NSSF, and SHIF.',
        icon: Icons.event_note_outlined,
        position: TourStepPosition.above,
      ),
      TourStep(
        targetKey: _settingsKey,
        title: 'Profile & Settings',
        description: 'Update your bank details, M-Pesa phone, and preferences here. Let\'s get started!',
        icon: Icons.settings_outlined,
        position: TourStepPosition.below,
        isLast: true,
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
    final settingsAsync = ref.watch(settingsProvider);
    
    // Fallback to Google Avatar if photoUrl is null but we have a googleId
    final settings = settingsAsync.value;
    final photoUrl = settings?.photoUrl;
    final googleId = settings?.googleId;
    final displayPhotoUrl = photoUrl ?? 
        (googleId != null ? 'https://lh3.googleusercontent.com/a/$googleId' : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final firstName = ref.watch(userFirstNameProvider);
                    return Text(
                      firstName.isEmpty ? 'Jambo! 👋' : 'Jambo, $firstName! 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            key: _settingsKey,
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.go('/settings');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout', style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('Logout', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                             ref.read(authStateProvider.notifier).logout();
                             if (context.mounted) context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: displayPhotoUrl != null ? NetworkImage(displayPhotoUrl) : null,
                  child: displayPhotoUrl == null 
                      ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                      : null,
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context, 
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
    AsyncValue<List<WorkerModel>> workersAsync,
  ) {
    final activePeriod = payPeriodsAsync.when(
      data: (periods) => PayPeriodUtils.getNextPayrollPeriod(periods),
      loading: () => null,
      error: (_, __) => null,
    );

    final periodName = activePeriod?.name ?? 'No Active Payroll';
    
    int daysUntilDue = 0;
    if (activePeriod != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = activePeriod.payDate ?? activePeriod.endDate;
      final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
      daysUntilDue = target.difference(today).inDays;
    }

    // Get active workers count
    final activeWorkers = workersAsync.when(
      data: (workers) => workers.where((w) => w.isActive).toList(),
      loading: () => <WorkerModel>[],
      error: (_, __) => <WorkerModel>[],
    );
    final workerCount = activeWorkers.length;

    return Container(
      key: _payrollKey,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payroll',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            daysUntilDue < 0 
                ? 'Overdue by ${-daysUntilDue} days'
                : daysUntilDue == 0 
                    ? 'Due Today!' 
                    : 'Due in $daysUntilDue days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Show up to 3 worker avatars
              ...List.generate(workerCount.clamp(0, 3), (i) => Align(
                widthFactor: 0.7,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      activeWorkers.isNotEmpty && i < activeWorkers.length
                        ? activeWorkers[i].name.substring(0, 1).toUpperCase()
                        : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              Text(
                workerCount > 3 
                  ? '+ ${workerCount - 3} more workers'
                  : workerCount > 0 ? '$workerCount workers ready' : 'No workers yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/payroll/run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Process Payroll Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
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
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(
            width: 120,
            child: _buildColorfulStatCard(
              icon: Icons.payments_outlined, 
              label: 'Last Payroll', 
              value: 'KES ${formatter.format(lastPayrollNet)}',
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: _buildColorfulStatCard(
              icon: Icons.people_outline, 
              label: 'Employees', 
              value: '$workerCount',
              subtitle: '$activeWorkers Active',
              gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: _buildColorfulStatCard(
              icon: Icons.pending_actions, 
              label: 'Pending', 
              value: '$pendingCount',
              gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    final walletAsync = ref.watch(walletBalanceProvider);

    return Padding(
      key: _walletKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    walletAsync.when(
                      data: (wallet) => Text(
                        wallet.formattedBalance,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 24,
                        width: 100,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Error loading',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/finance/top-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
                child: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
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
          child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildGradientActionCard(
                  icon: Icons.home_work_outlined,
                  label: 'Properties',
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  onTap: () => context.push('/properties'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientActionCard(
                  icon: Icons.access_time_outlined,
                  label: 'Time Tracking',
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  onTap: () => context.push('/time-tracking'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildGradientActionCard(
                  icon: Icons.event_note_outlined,
                  label: 'Leave Mgmt',
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  onTap: () => context.push('/leave'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                key: _supportKey,
                child: _buildGradientActionCard(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  onTap: () => context.push('/support'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientActionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlinesSection(BuildContext context) {
    final deadlinesAsync = ref.watch(statutoryDeadlinesProvider);

    return Column(
      key: _deadlinesKey,
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
          child: deadlinesAsync.when(
            data: (deadlines) => deadlines.isEmpty
              ? _buildEmptyDeadlines(context)
              : Column(
                  children: deadlines.take(3).map((deadline) {
                    final iconData = _getDeadlineIcon(deadline.title);
                    final iconColor = _getDeadlineColor(deadline);
                    final statusLabel = _getDeadlineStatus(deadline);
                    final statusColor = deadline.isPastDue ? Colors.red : 
                      (deadline.daysUntilDue <= 3 ? Colors.orange : Colors.green);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDeadlineItemFromData(
                        context,
                        icon: iconData,
                        iconColor: iconColor,
                        title: deadline.title,
                        subtitle: deadline.description,
                        statusLabel: statusLabel,
                        statusColor: statusColor,
                      ),
                    );
                  }).toList(),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildEmptyDeadlines(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDeadlines(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12),
          Text('No upcoming deadlines'),
        ],
      ),
    );
  }

  IconData _getDeadlineIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('paye')) return Icons.warning_amber_rounded;
    if (lower.contains('nssf')) return Icons.account_balance;
    if (lower.contains('shif') || lower.contains('nhif')) return Icons.health_and_safety;
    if (lower.contains('housing')) return Icons.home;
    return Icons.calendar_today;
  }

  Color _getDeadlineColor(StatutoryDeadline deadline) {
    if (deadline.isPastDue) return Colors.red;
    if (deadline.daysUntilDue <= 3) return Colors.orange;
    final lower = deadline.title.toLowerCase();
    if (lower.contains('paye')) return Colors.red;
    if (lower.contains('nssf')) return Colors.blue;
    if (lower.contains('shif') || lower.contains('nhif')) return Colors.green;
    return Colors.indigo;
  }

  String _getDeadlineStatus(StatutoryDeadline deadline) {
    if (deadline.isPastDue) return 'Overdue!';
    if (deadline.daysUntilDue == 0) return 'Due today';
    if (deadline.daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in ${deadline.daysUntilDue} days';
  }

  Widget _buildDeadlineItemFromData(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
