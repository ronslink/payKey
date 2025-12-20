import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

abstract class _AppColors {
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const primary = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const muted = Color(0xFF9CA3AF);
  static const purple = Color(0xFF8B5CF6);
}

abstract class _Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

// =============================================================================
// MAIN PAGE
// =============================================================================

class PayCalendarPage extends ConsumerWidget {
  const PayCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.surface,
        foregroundColor: _AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Pay Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _AppColors.textSecondary),
            onPressed: () => ref.invalidate(payPeriodsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: payPeriodsAsync.when(
        data: (payPeriods) => _PayPeriodsContent(
          payPeriods: payPeriods,
          onCreateNew: () => _showCreateDialog(context, ref),
        ),
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(payPeriodsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Period'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    // TODO: Fetch user's defaultPayrollFrequency from profile when available
    final result = await showDialog<CreatePayPeriodRequest>(
      context: context,
      builder: (context) => const _CreatePayPeriodDialog(
        defaultFrequency: PayPeriodFrequency.monthly,
      ),
    );

    if (result != null) {
      await ref.read(payPeriodsProvider.notifier).createPayPeriod(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created pay period: ${result.name}'),
            backgroundColor: _AppColors.success,
          ),
        );
      }
    }
  }
}

// =============================================================================
// CONTENT
// =============================================================================

class _PayPeriodsContent extends StatelessWidget {
  final List<PayPeriod> payPeriods;
  final VoidCallback onCreateNew;

  const _PayPeriodsContent({
    required this.payPeriods,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    if (payPeriods.isEmpty) {
      return _EmptyState(onCreateNew: onCreateNew);
    }

    // Group periods by year
    final groupedPeriods = _groupByYear(payPeriods);
    final years = groupedPeriods.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(_Spacing.lg),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final periods = groupedPeriods[year]!;

        return _YearSection(
          year: year,
          periods: periods,
        );
      },
    );
  }

  Map<int, List<PayPeriod>> _groupByYear(List<PayPeriod> periods) {
    final grouped = <int, List<PayPeriod>>{};

    for (final period in periods) {
      final year = period.startDate.year;
      grouped.putIfAbsent(year, () => []).add(period);
    }

    // Sort each year's periods by start date descending
    for (final periods in grouped.values) {
      periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    }

    return grouped;
  }
}

// =============================================================================
// YEAR SECTION
// =============================================================================

class _YearSection extends StatelessWidget {
  final int year;
  final List<PayPeriod> periods;

  const _YearSection({
    required this.year,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _Spacing.sm,
            horizontal: _Spacing.xs,
          ),
          child: Text(
            year.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AppColors.textPrimary,
            ),
          ),
        ),
        ...periods.map((period) => _PayPeriodCard(period: period)),
        const SizedBox(height: _Spacing.lg),
      ],
    );
  }
}

// =============================================================================
// PAY PERIOD CARD
// =============================================================================

class _PayPeriodCard extends StatelessWidget {
  final PayPeriod period;

  const _PayPeriodCard({required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: _Spacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(_Spacing.lg),
          child: Row(
            children: [
              _DateBadge(date: period.startDate),
              const SizedBox(width: _Spacing.lg),
              Expanded(child: _PeriodInfo(period: period)),
              _StatusChip(status: period.status),
              const SizedBox(width: _Spacing.sm),
              const Icon(
                Icons.chevron_right,
                color: _AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (period.status) {
      case PayPeriodStatus.draft:
        // Edit draft period
        context.push('/payroll/period/${period.id}/edit');
        break;
      case PayPeriodStatus.active:
        // Run payroll
        context.push('/payroll/run/${period.id}');
        break;
      case PayPeriodStatus.processing:
        // View processing status
        context.push('/payroll/review/${period.id}');
        break;
      case PayPeriodStatus.completed:
      case PayPeriodStatus.closed:
        // View summary/tax report
        context.push('/payroll/review/${period.id}');
        break;
      case PayPeriodStatus.cancelled:
        // View cancelled period details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This pay period was cancelled')),
        );
        break;
    }
  }
}

// =============================================================================
// CARD COMPONENTS
// =============================================================================

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMM');
    final dayFormat = DateFormat('d');

    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: _Spacing.sm),
      decoration: BoxDecoration(
        color: _AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            monthFormat.format(date).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _AppColors.primary,
            ),
          ),
          Text(
            dayFormat.format(date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodInfo extends StatelessWidget {
  final PayPeriod period;

  const _PeriodInfo({required this.period});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final dateRange =
        '${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: _Spacing.xs),
        Text(
          dateRange,
          style: const TextStyle(
            fontSize: 13,
            color: _AppColors.textSecondary,
          ),
        ),
        if (period.totalWorkers != null && period.totalWorkers! > 0) ...[
          const SizedBox(height: _Spacing.xs),
          Text(
            '${period.totalWorkers} workers',
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PayPeriodStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Spacing.md,
        vertical: _Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getStatusColors(PayPeriodStatus status) {
    return switch (status) {
      PayPeriodStatus.draft => (
          _AppColors.textSecondary,
          Colors.grey.shade100,
        ),
      PayPeriodStatus.active => (
          _AppColors.success,
          _AppColors.success.withValues(alpha: 0.1),
        ),
      PayPeriodStatus.processing => (
          _AppColors.warning,
          _AppColors.warning.withValues(alpha: 0.1),
        ),
      PayPeriodStatus.completed => (
          _AppColors.info,
          _AppColors.info.withValues(alpha: 0.1),
        ),
      PayPeriodStatus.closed => (
          _AppColors.purple,
          _AppColors.purple.withValues(alpha: 0.1),
        ),
      PayPeriodStatus.cancelled => (
          _AppColors.error,
          _AppColors.error.withValues(alpha: 0.1),
        ),
    };
  }
}

// =============================================================================
// STATE WIDGETS
// =============================================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _AppColors.primary),
          SizedBox(height: _Spacing.lg),
          Text(
            'Loading pay periods...',
            style: TextStyle(color: _AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: _AppColors.error,
            ),
            const SizedBox(height: _Spacing.lg),
            const Text(
              'Failed to load pay periods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _AppColors.textSecondary),
            ),
            const SizedBox(height: _Spacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateNew;

  const _EmptyState({required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 50,
                color: _AppColors.primary,
              ),
            ),
            const SizedBox(height: _Spacing.xl),
            const Text(
              'No Pay Periods Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            const Text(
              'Create your first pay period to start\nmanaging payroll for your workers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: _Spacing.xl),
            ElevatedButton.icon(
              onPressed: onCreateNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: _Spacing.xl,
                  vertical: _Spacing.md,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Pay Period'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CREATE DIALOG
// =============================================================================

class _CreatePayPeriodDialog extends StatefulWidget {
  final PayPeriodFrequency? defaultFrequency;
  
  const _CreatePayPeriodDialog({this.defaultFrequency});

  @override
  State<_CreatePayPeriodDialog> createState() => _CreatePayPeriodDialogState();
}

class _CreatePayPeriodDialogState extends State<_CreatePayPeriodDialog> {
  late PayPeriodFrequency _frequency;
  DateTime _selectedMonth = DateTime.now();
  final bool _isCreating = false;
  bool _isOffCycle = false;
  final _customNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _frequency = widget.defaultFrequency ?? PayPeriodFrequency.monthly;
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Text('Create Pay Period'),
          const Spacer(),
          // Off-cycle toggle
          Tooltip(
            message: 'Off-cycle payroll (bonus, advance, etc.)',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Off-cycle', style: TextStyle(fontSize: 12, color: _AppColors.textSecondary)),
                Switch(
                  value: _isOffCycle,
                  onChanged: (value) => setState(() => _isOffCycle = value),
                  activeTrackColor: _AppColors.warning.withValues(alpha: 0.5),
                  thumbColor: WidgetStatePropertyAll(_isOffCycle ? _AppColors.warning : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOffCycle) ...[
            // Custom name for off-cycle
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                labelText: 'Payroll Name',
                hintText: 'e.g., December Bonus, Salary Advance',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: _Spacing.lg),
            Container(
              padding: const EdgeInsets.all(_Spacing.md),
              decoration: BoxDecoration(
                color: _AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: _AppColors.warning),
                  SizedBox(width: _Spacing.sm),
                  Expanded(
                    child: Text(
                      'Off-cycle payrolls are for bonuses, advances, or special payments outside regular pay periods.',
                      style: TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _Spacing.lg),
          ],
          const Text(
            'Frequency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: _Spacing.sm),
          SegmentedButton<PayPeriodFrequency>(
            segments: const [
              ButtonSegment(
                value: PayPeriodFrequency.weekly,
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: PayPeriodFrequency.biWeekly,
                label: Text('Bi-Weekly'),
              ),
              ButtonSegment(
                value: PayPeriodFrequency.monthly,
                label: Text('Monthly'),
              ),
            ],
            selected: {_frequency},
            onSelectionChanged: (selected) {
              setState(() => _frequency = selected.first);
            },
          ),
          const SizedBox(height: _Spacing.lg),
          const Text(
            'Period',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: _Spacing.sm),
          _buildPeriodSelector(),
          const SizedBox(height: _Spacing.lg),
          _buildPreview(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isOffCycle ? _AppColors.warning : _AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isOffCycle ? 'Create Off-Cycle' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final monthFormat = DateFormat('MMMM yyyy');

    return InkWell(
      onTap: _selectMonth,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _Spacing.md,
          vertical: _Spacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: _Spacing.md),
            Text(
              monthFormat.format(_selectedMonth),
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final (startDate, endDate) = _calculateDates();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(_Spacing.md),
      decoration: BoxDecoration(
        color: (_isOffCycle ? _AppColors.warning : _AppColors.primary).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (_isOffCycle ? _AppColors.warning : _AppColors.primary).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isOffCycle) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OFF-CYCLE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: _Spacing.sm),
              ],
              Expanded(
                child: Text(
                  _generateName(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _Spacing.xs),
          Text(
            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const TextStyle(
              fontSize: 13,
              color: _AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  (DateTime, DateTime) _calculateDates() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    return switch (_frequency) {
      PayPeriodFrequency.weekly => (
          _selectedMonth,
          _selectedMonth.add(const Duration(days: 6)),
        ),
      PayPeriodFrequency.biWeekly => (
          _selectedMonth,
          _selectedMonth.add(const Duration(days: 13)),
        ),
      PayPeriodFrequency.monthly => (
          DateTime(year, month, 1),
          DateTime(year, month + 1, 0),
        ),
      PayPeriodFrequency.quarterly => (
          DateTime(year, ((month - 1) ~/ 3) * 3 + 1, 1),
          DateTime(year, ((month - 1) ~/ 3) * 3 + 4, 0),
        ),
      PayPeriodFrequency.yearly => (
          DateTime(year, 1, 1),
          DateTime(year, 12, 31),
        ),
    };
  }

  String _generateName() {
    if (_isOffCycle && _customNameController.text.isNotEmpty) {
      return _customNameController.text;
    }
    
    final monthFormat = DateFormat('MMMM yyyy');
    final weekFormat = DateFormat('MMM d');

    final baseName = switch (_frequency) {
      PayPeriodFrequency.weekly =>
        'Week of ${weekFormat.format(_selectedMonth)}',
      PayPeriodFrequency.biWeekly =>
        'Bi-weekly ${weekFormat.format(_selectedMonth)}',
      PayPeriodFrequency.monthly => monthFormat.format(_selectedMonth),
      PayPeriodFrequency.quarterly =>
        'Q${((_selectedMonth.month - 1) ~/ 3) + 1} ${_selectedMonth.year}',
      PayPeriodFrequency.yearly => 'Year ${_selectedMonth.year}',
    };
    
    return _isOffCycle ? 'Off-Cycle: $baseName' : baseName;
  }

  void _handleCreate() {
    final (startDate, endDate) = _calculateDates();

    final request = CreatePayPeriodRequest(
      name: _generateName(),
      startDate: startDate,
      endDate: endDate,
      frequency: _frequency,
      isOffCycle: _isOffCycle,
    );

    Navigator.pop(context, request);
  }
}