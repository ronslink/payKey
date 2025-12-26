import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/finance_constants.dart';
import 'finance_widgets.dart';

// Forward declaration - import from your finance provider
// import '../../providers/finance_provider.dart';

/// Stats model for the status card
/// This should match your FinanceStats from the provider
class FinanceStatsDisplay {
  final double totalPayroll;
  final int processedCount;
  final int totalWorkers;
  final double progress;
  final String trend;
  final bool trendUp;
  final DateTime? nextRunDate;

  const FinanceStatsDisplay({
    required this.totalPayroll,
    required this.processedCount,
    required this.totalWorkers,
    required this.progress,
    required this.trend,
    required this.trendUp,
    this.nextRunDate,
  });

  /// Create from your actual FinanceStats model
  factory FinanceStatsDisplay.fromStats(dynamic stats) {
    return FinanceStatsDisplay(
      totalPayroll: stats.totalPayroll?.toDouble() ?? 0,
      processedCount: stats.processedCount ?? 0,
      totalWorkers: stats.totalWorkers ?? 0,
      progress: stats.progress?.toDouble() ?? 0,
      trend: stats.trend ?? '0%',
      trendUp: stats.trendUp ?? false,
      nextRunDate: stats.nextRunDate,
    );
  }
}

/// Finance status card showing payroll summary
class FinanceStatusCard extends StatelessWidget {
  final FinanceStatsDisplay stats;

  const FinanceStatusCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(FinanceTheme.pagePadding),
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: FinanceTheme.statusGradient(primaryColor),
        borderRadius: BorderRadius.circular(FinanceTheme.statusCardBorderRadius),
        boxShadow: FinanceTheme.statusCardShadow(primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildAmount(context),
          const SizedBox(height: 16),
          _buildProgressSection(context),
          const SizedBox(height: 16),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Payroll (This Month)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
        _buildCurrencyBadge(context),
      ],
    );
  }

  Widget _buildCurrencyBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        FinanceConstants.currencyCode,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    return Text(
      formatCurrency(stats.totalPayroll),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            Text(
              '${stats.processedCount}/${stats.totalWorkers} workers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    final isComplete = stats.progress >= 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: stats.progress.clamp(0.0, 1.0),
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(
          isComplete ? FinanceTheme.successColor : Colors.white,
        ),
        minHeight: FinanceTheme.progressBarHeight,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _buildTrendIndicator(context),
        const Spacer(),
        _buildNextRunIndicator(context),
      ],
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.trending_up,
          size: 16,
          color: stats.trendUp
              ? FinanceTheme.trendUpColor
              : FinanceTheme.trendDownColor,
        ),
        const SizedBox(width: 6),
        Text(
          '${stats.trend} from last month',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildNextRunIndicator(BuildContext context) {
    final nextRunText = stats.nextRunDate != null
        ? 'Next: ${DateFormat('MMM d').format(stats.nextRunDate!)}'
        : 'Next run pending';

    return Row(
      children: [
        const Icon(Icons.schedule, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          nextRunText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

/// Loading state for status card
class FinanceStatusCardLoading extends StatelessWidget {
  const FinanceStatusCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(FinanceTheme.pagePadding),
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: FinanceTheme.statusGradient(primaryColor),
        borderRadius: BorderRadius.circular(FinanceTheme.statusCardBorderRadius),
        boxShadow: FinanceTheme.statusCardShadow(primaryColor),
      ),
      child: const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

/// Error state for status card
class FinanceStatusCardError extends StatelessWidget {
  final VoidCallback? onRetry;

  const FinanceStatusCardError({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(FinanceTheme.pagePadding),
      padding: const EdgeInsets.all(FinanceTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: FinanceTheme.statusGradient(primaryColor),
        borderRadius: BorderRadius.circular(FinanceTheme.statusCardBorderRadius),
        boxShadow: FinanceTheme.statusCardShadow(primaryColor),
      ),
      child: SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to load stats',
                style: TextStyle(color: Colors.white),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                  label: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
