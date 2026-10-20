import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/utils/pay_period_utils.dart';
import '../widgets/payroll_widgets.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/widgets/feature_gate.dart';
import '../../../../main.dart';

/// Modern payroll management page with premium design
class PayrollPage extends ConsumerStatefulWidget {
  const PayrollPage({super.key});

  @override
  ConsumerState<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends ConsumerState<PayrollPage>
    with SingleTickerProviderStateMixin {
  PayPeriodStatus? _selectedStatus;
  bool _isInitializing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    final payPeriodsState = _selectedStatus == null
        ? ref.watch(payPeriodsProvider)
        : ref.watch(payPeriodsByStatusProvider(_selectedStatus!));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(child: _buildHeroHeader(payPeriodsState)),

            // Status Filter Tabs
            SliverToBoxAdapter(child: _buildStatusTabs()),

            // Quick Actions
            SliverToBoxAdapter(child: _buildQuickActions(context)),

            // Active Payroll Alert (if any)
            SliverToBoxAdapter(
              child: payPeriodsState.when(
                data: (periods) => _buildActivePayrollAlert(context, periods),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // Show Initialize New Year card when applicable
            SliverToBoxAdapter(
              child: ref
                  .watch(payPeriodsProvider)
                  .when(
                    data: (periods) => _buildInitializeYearCard(periods),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedStatus == null
                            ? 'All Pay Periods'
                            : '${_getStatusLabel(_selectedStatus!)} Periods',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_selectedStatus == null) {
                          ref.invalidate(payPeriodsProvider);
                        } else {
                          ref.invalidate(
                            payPeriodsByStatusProvider(_selectedStatus!),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Pay Periods List
            payPeriodsState.when(
              data: (periods) => _buildPayPeriodsList(context, periods),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _buildErrorState(error),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AsyncValue<List<PayPeriod>> payPeriodsState) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payroll',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Management',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats Row
            payPeriodsState.when(
              data: (periods) => _buildStatsRow(periods),
              loading: () => _buildStatsRowLoading(),
              error: (_, _) => _buildStatsRowLoading(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<PayPeriod> periods) {
    final activePeriods = periods
        .where(
          (p) =>
              p.status == PayPeriodStatus.active ||
              p.status == PayPeriodStatus.processing,
        )
        .length;
    final completedPeriods = periods
        .where(
          (p) =>
              p.status == PayPeriodStatus.completed ||
              p.status == PayPeriodStatus.closed,
        )
        .length;
    final totalNet = periods.fold<double>(
      0,
      (sum, p) => sum + (p.totalNetAmount ?? 0),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatItem(
          icon: Icons.hourglass_top_rounded,
          label: 'Active',
          value: activePeriods.toString(),
        ),
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: completedPeriods.toString(),
        ),
        _buildStatItem(
          icon: Icons.payments_rounded,
          label: 'Total Paid',
          value: _formatAmount(totalNet),
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatItem(
          icon: Icons.hourglass_top_rounded,
          label: 'Active',
          value: '--',
        ),
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: '--',
        ),
        _buildStatItem(
          icon: Icons.payments_rounded,
          label: 'Total Paid',
          value: '--',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    final statuses = [null, ...PayPeriodStatus.values];

    return Container(
      height: 24 + MediaQuery.textScalerOf(context).scale(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          final label = status == null ? 'All' : _getStatusLabel(status);

          return GestureDetector(
            onTap: () => setState(() => _selectedStatus = status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : context.borderDefault,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            _buildActionCard(
              icon: Icons.play_circle_fill_rounded,
              title: 'Run Payroll',
              subtitle: 'Regular cycle',
              accentColor: const Color(0xFF059669),
              onTap: () => context.push('/payroll/run'),
            ),
            _buildActionCard(
              icon: Icons.bolt_rounded,
              title: 'Off-Cycle',
              subtitle: 'On-demand run',
              accentColor: const Color(0xFFD97706),
              onTap: () => context.push('/payroll/off-cycle'),
            ),
            _buildActionCard(
              icon: Icons.history_rounded,
              title: 'History',
              subtitle: 'Past payrolls',
              accentColor: const Color(0xFF2563EB),
              onTap: () =>
                  setState(() => _selectedStatus = PayPeriodStatus.completed),
            ),
          ];
          if (constraints.maxWidth <
              360 * MediaQuery.textScalerOf(context).scale(1)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  actions[index],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(child: actions[index]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
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
            color: context.surfacePrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePayrollAlert(
    BuildContext context,
    List<PayPeriod> periods,
  ) {
    final activePeriod = periods.firstWhere(
      (p) =>
          p.status == PayPeriodStatus.active ||
          p.status == PayPeriodStatus.processing,
      orElse: () => periods.isNotEmpty
          ? periods.first
          : PayPeriod(
              id: '',
              name: '',
              frequency: PayPeriodFrequency.monthly,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              status: PayPeriodStatus.draft,
            ),
    );

    if (activePeriod.id.isEmpty ||
        (activePeriod.status != PayPeriodStatus.active &&
            activePeriod.status != PayPeriodStatus.processing)) {
      return const SizedBox.shrink();
    }

    final progress =
        (activePeriod.processedWorkers ?? 0) /
        (activePeriod.totalWorkers ?? 1).clamp(1, double.infinity);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/payroll/review/${activePeriod.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Payroll In Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              activePeriod.status.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activePeriod.name,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.iconMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 6,
                backgroundColor: context.borderMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  '${activePeriod.processedWorkers ?? 0}/${activePeriod.totalWorkers ?? 0} workers',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                Text(
                  'Net: KES ${_formatAmount(activePeriod.totalNetAmount ?? 0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows Initialize Year card when:
  /// 1. Current year has no periods at all
  /// 2. All current year periods are completed/closed and we're near year end or in new year
  Widget _buildInitializeYearCard(List<PayPeriod> periods) {
    final yearToInitialize = PayPeriodUtils.getYearToInitialize(periods);

    if (yearToInitialize != null) {
      final subtitle = yearToInitialize == DateTime.now().year
          ? 'No pay periods for $yearToInitialize'
          : 'Ready for $yearToInitialize payroll';

      return InitializePayPeriodsCard(
        year: yearToInitialize,
        subtitle: subtitle,
        onPressed: () => _initializeYearSpecific(yearToInitialize),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _initializeYearSpecific(int year) async {
    setState(() => _isInitializing = true);

    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31);

      final existingPeriods = ref.read(payPeriodsProvider).value ?? [];
      if (existingPeriods.any((p) => p.startDate.year == year)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pay periods already exist for $year'),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final repo = ref.read(payPeriodRepositoryProvider);
      await repo.generatePayPeriods(
        frequency: 'MONTHLY',
        startDate: startOfYear,
        endDate: endOfYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated payroll periods for $year'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.invalidate(payPeriodsProvider);
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 403) {
          showFeatureUpgradeDialog(
            context,
            featureName: 'Payroll Initialization',
            requiredTier: 'GOLD',
            onUpgrade: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settingsSubscription);
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Widget _buildPayPeriodsList(BuildContext context, List<PayPeriod> periods) {
    if (periods.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPayPeriodCard(context, periods[index]),
          childCount: periods.length,
        ),
      ),
    );
  }

  Widget _buildPayPeriodCard(BuildContext context, PayPeriod period) {
    final statusColor = _getStatusColor(period.status);

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderDefault),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/payroll/review/${period.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(period.status),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: context.iconMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDateRange(
                                    period.startDate,
                                    period.endDate,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (period.status == PayPeriodStatus.draft &&
                        period.isOffCycle) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmAndDelete(context, period),
                        tooltip: 'Delete Draft',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(period.status, statusColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildMiniStat(
                        Icons.people_outline_rounded,
                        '${period.totalWorkers ?? 0}',
                        'Workers',
                      ),
                      _buildMiniStat(
                        Icons.attach_money_rounded,
                        _formatAmount(period.totalGrossAmount ?? 0),
                        'Gross',
                      ),
                      _buildMiniStat(
                        Icons.account_balance_wallet_outlined,
                        _formatAmount(period.totalNetAmount ?? 0),
                        'Net',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Only off-cycle draft periods can be swiped to delete
    if (period.status != PayPeriodStatus.draft || !period.isOffCycle) {
      return cardContent;
    }

    return Dismissible(
      key: Key(period.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Draft?'),
            content: const Text(
              'Are you sure you want to delete this draft pay period?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await ref
              .read(payPeriodsProvider.notifier)
              .deletePayPeriod(period.id);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Pay period deleted')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
            ref.invalidate(payPeriodsProvider);
          }
        }
      },
      child: cardContent,
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PayPeriodStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, PayPeriod period) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text(
          'Are you sure you want to delete this draft pay period?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(payPeriodsProvider.notifier).deletePayPeriod(period.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pay period deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        ref.invalidate(payPeriodsProvider);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 48,
              color: context.iconMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Pay Periods',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initialize your payroll calendar to get started',
            style: TextStyle(fontSize: 14, color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedStatus ==
              null) // Only show initialize button when viewing all
            _isInitializing
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _initializeYear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Initialize ${DateTime.now().year}'),
                  ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 13, color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedStatus == null) {
                    ref.invalidate(payPeriodsProvider);
                  } else {
                    ref.invalidate(
                      payPeriodsByStatusProvider(_selectedStatus!),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return const Color(0xFF9CA3AF);
      case PayPeriodStatus.active:
        return const Color(0xFF3B82F6);
      case PayPeriodStatus.processing:
        return const Color(0xFFF59E0B);
      case PayPeriodStatus.completed:
        return const Color(0xFF10B981);
      case PayPeriodStatus.closed:
        return const Color(0xFF6366F1);
      case PayPeriodStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return Icons.edit_note_rounded;
      case PayPeriodStatus.active:
        return Icons.play_circle_outline_rounded;
      case PayPeriodStatus.processing:
        return Icons.sync_rounded;
      case PayPeriodStatus.completed:
        return Icons.check_circle_outline_rounded;
      case PayPeriodStatus.closed:
        return Icons.lock_outline_rounded;
      case PayPeriodStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusLabel(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return 'Draft';
      case PayPeriodStatus.active:
        return 'Active';
      case PayPeriodStatus.processing:
        return 'Processing';
      case PayPeriodStatus.completed:
        return 'Completed';
      case PayPeriodStatus.closed:
        return 'Closed';
      case PayPeriodStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }

  Future<void> _initializeYear() async {
    setState(() => _isInitializing = true);

    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31);

      final existingPeriods = ref.read(payPeriodsProvider).value ?? [];
      if (existingPeriods.any((p) => p.startDate.year == now.year)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pay periods already exist for this year'),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final repo = ref.read(payPeriodRepositoryProvider);
      await repo.generatePayPeriods(
        frequency: 'MONTHLY',
        startDate: startOfYear,
        endDate: endOfYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated payroll periods for ${now.year}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.invalidate(payPeriodsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }
}
