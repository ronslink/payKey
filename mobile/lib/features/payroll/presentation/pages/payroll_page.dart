import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';

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
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: _buildHeroHeader(payPeriodsState),
            ),

            // Status Filter Tabs
            SliverToBoxAdapter(
              child: _buildStatusTabs(),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),

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
              child: payPeriodsState.when(
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
                    Text(
                      _selectedStatus == null 
                          ? 'All Pay Periods' 
                          : '${_getStatusLabel(_selectedStatus!)} Periods',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_selectedStatus == null) {
                          ref.invalidate(payPeriodsProvider);
                        } else {
                          ref.invalidate(payPeriodsByStatusProvider(_selectedStatus!));
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      color: const Color(0xFF6366F1),
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
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
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payroll',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
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
    final activePeriods = periods.where(
      (p) => p.status == PayPeriodStatus.active || p.status == PayPeriodStatus.processing
    ).length;
    final completedPeriods = periods.where(
      (p) => p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed
    ).length;
    final totalNet = periods.fold<double>(
      0, (sum, p) => sum + (p.totalNetAmount ?? 0)
    );

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.hourglass_top_rounded,
          label: 'Active',
          value: activePeriods.toString(),
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: completedPeriods.toString(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            icon: Icons.payments_rounded,
            label: 'Total Paid',
            value: _formatAmount(totalNet),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return Row(
      children: [
        _buildStatItem(icon: Icons.hourglass_top_rounded, label: 'Active', value: '--'),
        const SizedBox(width: 16),
        _buildStatItem(icon: Icons.check_circle_rounded, label: 'Completed', value: '--'),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem(icon: Icons.payments_rounded, label: 'Total Paid', value: '--')),
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
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
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    final statuses = [null, ...PayPeriodStatus.values];
    
    return Container(
      height: 44,
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
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.play_circle_fill_rounded,
              title: 'Run Payroll',
              subtitle: 'Process new cycle',
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () => context.push('/payroll/run'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.history_rounded,
              title: 'View History',
              subtitle: 'Past payrolls',
              gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: () => setState(() => _selectedStatus = PayPeriodStatus.completed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePayrollAlert(BuildContext context, List<PayPeriod> periods) {
    final activePeriod = periods.firstWhere(
      (p) => p.status == PayPeriodStatus.active || p.status == PayPeriodStatus.processing,
      orElse: () => periods.isNotEmpty ? periods.first : PayPeriod(
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

    final progress = (activePeriod.processedWorkers ?? 0) / 
        (activePeriod.totalWorkers ?? 1).clamp(1, double.infinity);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/payroll/review/${activePeriod.id}'),
        borderRadius: BorderRadius.circular(14),
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
                      Row(
                        children: [
                          const Text(
                            'Payroll In Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
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
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${activePeriod.processedWorkers ?? 0}/${activePeriod.totalWorkers ?? 0} workers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Net: KES ${_formatAmount(activePeriod.totalNetAmount ?? 0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
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
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = currentYear + 1;

    // Check if current year has periods
    final currentYearPeriods = periods.where((p) => p.startDate.year == currentYear).toList();
    final nextYearPeriods = periods.where((p) => p.startDate.year == nextYear).toList();

    // Case 1: No periods for current year - show initialize current year
    if (currentYearPeriods.isEmpty && periods.isNotEmpty) {
      return _buildInitCard(currentYear, 'No pay periods for $currentYear');
    }

    // Case 2: All current year periods completed/closed and next year not initialized
    // Show this in November/December or if all periods done
    final allCurrentYearCompleted = currentYearPeriods.isNotEmpty &&
        currentYearPeriods.every((p) =>
            p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed);

    if (allCurrentYearCompleted && nextYearPeriods.isEmpty) {
      // Show in November, December, or if it's January and still no next year periods
      if (now.month >= 11 || now.month == 1) {
        return _buildInitCard(nextYear, 'Ready for $nextYear payroll');
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildInitCard(int year, String subtitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Initialize Pay Periods',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _isInitializing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _initializeYearSpecific(year),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Initialize $year'),
                ),
        ],
      ),
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateRange(period.startDate, period.endDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(period.status, statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(
                        Icons.people_outline_rounded,
                        '${period.totalWorkers ?? 0}',
                        'Workers',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFFE5E7EB),
                      ),
                      _buildMiniStat(
                        Icons.attach_money_rounded,
                        _formatAmount(period.totalGrossAmount ?? 0),
                        'Gross',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFFE5E7EB),
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
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6366F1)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Pay Periods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initialize your payroll calendar to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedStatus == null) // Only show initialize button when viewing all
            _isInitializing
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _initializeYear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
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
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedStatus == null) {
                    ref.invalidate(payPeriodsProvider);
                  } else {
                    ref.invalidate(payPeriodsByStatusProvider(_selectedStatus!));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
      default:
        return const Color(0xFF9CA3AF);
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
      default:
        return Icons.circle_outlined;
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
      default:
        return 'Unknown';
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }
}
