import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart' as repo;
import '../../data/repositories/pay_period_repository.dart' show PayPeriodStatistics;
import '../../presentation/providers/pay_period_provider.dart';

// ============================================================================
// Constants
// ============================================================================

class _PayPeriodColors {
  static Color forStatus(PayPeriodStatus status) {
    return switch (status) {
      PayPeriodStatus.draft => Colors.grey.shade600,
      PayPeriodStatus.active => Colors.blue,
      PayPeriodStatus.processing => Colors.orange,
      PayPeriodStatus.completed => Colors.green,
      PayPeriodStatus.closed => Colors.deepPurple,
      PayPeriodStatus.cancelled => Colors.red,
    };
  }

  static Color forAction(PayPeriodStatusAction action) {
    return switch (action) {
      PayPeriodStatusAction.activate => Colors.blue,
      PayPeriodStatusAction.process => Colors.orange,
      PayPeriodStatusAction.complete => Colors.green,
      PayPeriodStatusAction.close => Colors.red,
      _ => Colors.grey,
    };
  }
}

class _PayPeriodStyles {
  static const cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const cardPadding = EdgeInsets.all(16.0);
  static const filterPadding = EdgeInsets.all(16.0);
}

// ============================================================================
// Action Configuration
// ============================================================================

class _ActionConfig {
  static String labelFor(PayPeriodStatusAction action, PayPeriodStatus status) {
    return switch (action) {
      PayPeriodStatusAction.activate => 'Activate',
      PayPeriodStatusAction.process => 
          status == PayPeriodStatus.completed ? 'Reopen' : 'Process',
      PayPeriodStatusAction.complete => 'Complete',
      PayPeriodStatusAction.close => 'Close',
      _ => '',
    };
  }

  static List<PayPeriodStatusAction> availableFor(PayPeriodStatus status) {
    return switch (status) {
      PayPeriodStatus.draft => [
          PayPeriodStatusAction.activate,
          PayPeriodStatusAction.close,
        ],
      PayPeriodStatus.active => [
          PayPeriodStatusAction.process,
          PayPeriodStatusAction.close,
        ],
      PayPeriodStatus.processing => [
          PayPeriodStatusAction.complete,
          PayPeriodStatusAction.close,
        ],
      PayPeriodStatus.completed => [
          PayPeriodStatusAction.process, // Reopen
          PayPeriodStatusAction.close
        ],
      PayPeriodStatus.closed => [],
      PayPeriodStatus.cancelled => [],
    };
  }
}

// ============================================================================
// Formatters
// ============================================================================

class _Formatters {
  static final date = DateFormat('MMM dd, yyyy');
  static final number = NumberFormat('#,###.00');

  static String currency(double? value) =>
      'KES ${(value ?? 0.0).toStringAsFixed(2)}';

  static String currencyFormatted(double value) =>
      'KES ${number.format(value)}';

  static String statusLabel(PayPeriodStatus status) =>
      status.name.replaceAll('_', ' ');

  static String frequencyLabel(PayPeriodFrequency frequency) =>
      frequency.name.replaceAll('_', ' ');
}

// ============================================================================
// Main Page Widget
// ============================================================================

class PayPeriodManagementPage extends ConsumerStatefulWidget {
  const PayPeriodManagementPage({super.key});

  @override
  ConsumerState<PayPeriodManagementPage> createState() =>
      _PayPeriodManagementPageState();
}

class _PayPeriodManagementPageState
    extends ConsumerState<PayPeriodManagementPage> {
  PayPeriodStatus? _selectedStatusFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(payPeriodsProvider.notifier).loadPayPeriods();
    });
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _executeAction(
    PayPeriodStatusAction action,
    String payPeriodId,
  ) async {
    _setLoading(true);
    try {
      final notifier = ref.read(payPeriodsProvider.notifier);

      await switch (action) {
        PayPeriodStatusAction.activate => notifier.activatePayPeriod(payPeriodId),
        PayPeriodStatusAction.process => notifier.processPayPeriod(payPeriodId),
        PayPeriodStatusAction.complete => notifier.completePayPeriod(payPeriodId),
        PayPeriodStatusAction.close => notifier.closePayPeriod(payPeriodId),
        _ => Future.value(),
      };

      _showSnackBar('Pay period ${action.name.toLowerCase()}d successfully');
    } catch (e) {
      _showSnackBar('Failed to ${action.name.toLowerCase()}: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadStatistics(PayPeriod period) async {
    try {
      final repository = ref.read(repo.payPeriodRepositoryProvider);
      final statistics = await repository.getPayPeriodStatistics(period.id);
      if (context.mounted) {
        _showStatisticsDialog(period.name, statistics);
      }
    } catch (e) {
      _showSnackBar('Failed to load statistics: $e', isError: true);
    }
  }

  void _refreshPayPeriods() {
    ref.read(payPeriodsProvider.notifier).loadPayPeriods();
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _onFilterChanged(PayPeriodStatus? value) {
    setState(() => _selectedStatusFilter = value);
  }

  List<PayPeriod> _filterPeriods(List<PayPeriod> periods) {
    if (_selectedStatusFilter == null) return periods;
    return periods.where((p) => p.status == _selectedStatusFilter).toList();
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final payPeriodsState = ref.watch(payPeriodsProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _StatusFilter(
            selectedStatus: _selectedStatusFilter,
            onChanged: _onFilterChanged,
          ),
          Expanded(
            child: payPeriodsState.when(
              data: (periods) => _buildPeriodsList(_filterPeriods(periods)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(error: error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Pay Period Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/payroll/run'),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshPayPeriods,
        ),
      ],
    );
  }

  Widget _buildPeriodsList(List<PayPeriod> periods) {
    if (periods.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshPayPeriods(),
      child: ListView.builder(
        itemCount: periods.length,
        itemBuilder: (context, index) => _PayPeriodCard(
          period: periods[index],
          isLoading: _isLoading,
          onAction: _executeAction,
          onViewStatistics: _loadStatistics,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Statistics Dialog
  // --------------------------------------------------------------------------

  void _showStatisticsDialog(String periodName, PayPeriodStatistics statistics) {
    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(
        periodName: periodName,
        statistics: statistics,
      ),
    );
  }
}

// ============================================================================
// Status Filter
// ============================================================================

class _StatusFilter extends StatelessWidget {
  final PayPeriodStatus? selectedStatus;
  final ValueChanged<PayPeriodStatus?> onChanged;

  const _StatusFilter({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _PayPeriodStyles.filterPadding,
      child: Row(
        children: [
          const Text(
            'Filter by Status:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdown()),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<PayPeriodStatus?>(
      initialValue: selectedStatus,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Status')),
        ...PayPeriodStatus.values.map((status) => DropdownMenuItem(
              value: status,
              child: Text(_Formatters.statusLabel(status)),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

// ============================================================================
// Pay Period Card
// ============================================================================

class _PayPeriodCard extends StatelessWidget {
  final PayPeriod period;
  final bool isLoading;
  final Future<void> Function(PayPeriodStatusAction, String) onAction;
  final Future<void> Function(PayPeriod) onViewStatistics;

  const _PayPeriodCard({
    required this.period,
    required this.isLoading,
    required this.onAction,
    required this.onViewStatistics,
  });

  List<PayPeriodStatusAction> get _availableActions =>
      _ActionConfig.availableFor(period.status);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: _PayPeriodStyles.cardMargin,
      child: Padding(
        padding: _PayPeriodStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatistics(),
            const SizedBox(height: 16),
            if (_availableActions.isNotEmpty) _buildActions(),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _PeriodInfo(period: period)),
        _StatusBadge(status: period.status),
      ],
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Gross',
            value: _Formatters.currency(period.totalGrossAmount),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Total Net',
            value: _Formatters.currency(period.totalNetAmount),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Workers',
            value: '${period.processedWorkers ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: _availableActions
          .map((action) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _ActionButton(
                  action: action,
                  status: period.status,
                  isLoading: isLoading,
                  onPressed: () => onAction(action, period.id),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.push('/payroll/run/${period.id}'),
          child: const Text('View/Edit'),
        ),
        TextButton(
          onPressed: () => onViewStatistics(period),
          child: const Text('Statistics'),
        ),
      ],
    );
  }
}

// ============================================================================
// Period Info
// ============================================================================

class _PeriodInfo extends StatelessWidget {
  final PayPeriod period;

  const _PeriodInfo({required this.period});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${_Formatters.date.format(period.startDate)} - ${_Formatters.date.format(period.endDate)}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          _Formatters.frequencyLabel(period.frequency),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ============================================================================
// Status Badge
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final PayPeriodStatus status;

  const _StatusBadge({required this.status});

  Color get _color => _PayPeriodColors.forStatus(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color, width: 1),
      ),
      child: Text(
        _Formatters.statusLabel(status),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ============================================================================
// Stat Card
// ============================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Action Button
// ============================================================================

class _ActionButton extends StatelessWidget {
  final PayPeriodStatusAction action;
  final PayPeriodStatus status;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.status,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _PayPeriodColors.forAction(action),
        foregroundColor: Colors.white,
      ),
      child: Text(_ActionConfig.labelFor(action, status)),
    );
  }
}

// ============================================================================
// State Views
// ============================================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No pay periods found', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading pay periods: $error',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Statistics Dialog
// ============================================================================

class _StatisticsDialog extends StatelessWidget {
  final String periodName;
  final PayPeriodStatistics statistics;

  const _StatisticsDialog({
    required this.periodName,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Statistics: $periodName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(label: 'Total Workers', value: '${statistics.totalWorkers}'),
            _StatRow(label: 'Pending Payments', value: '${statistics.pendingPayments}'),
            _StatRow(label: 'Processed Payments', value: '${statistics.processedPayments}'),
            const Divider(),
            _StatRow(
              label: 'Total Gross Amount',
              value: _Formatters.currencyFormatted(statistics.totalGrossAmount),
            ),
            _StatRow(
              label: 'Total Net Amount',
              value: _Formatters.currencyFormatted(statistics.totalNetAmount),
            ),
            _StatRow(
              label: 'Total Tax Amount',
              value: _Formatters.currencyFormatted(statistics.totalTaxAmount),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}