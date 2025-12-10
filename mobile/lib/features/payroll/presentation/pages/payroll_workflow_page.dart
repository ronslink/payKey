import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';

// ============================================================================
// Constants
// ============================================================================

class _WorkflowColors {
  static Color forStatus(PayPeriodStatus status) {
    return switch (status) {
      PayPeriodStatus.draft => Colors.grey.shade600,
      PayPeriodStatus.active => Colors.blue,
      PayPeriodStatus.processing => Colors.orange,
      PayPeriodStatus.completed => Colors.green,
      PayPeriodStatus.closed => Colors.deepPurple,
      _ => Colors.grey,
    };
  }

  static Color forAction(PayPeriodStatusAction action) {
    return switch (action) {
      PayPeriodStatusAction.activate => Colors.blue,
      PayPeriodStatusAction.process => Colors.orange,
      PayPeriodStatusAction.complete => Colors.green,
      PayPeriodStatusAction.close => Colors.red,
      PayPeriodStatusAction.cancel => Colors.red,
      PayPeriodStatusAction.reopen => Colors.blue,
    };
  }

  // Stat card colors
  static const workers = Colors.blue;
  static const processed = Colors.green;
  static const pending = Colors.orange;
  static const gross = Colors.purple;
  static const net = Colors.teal;
}

class _WorkflowStyles {
  static const pagePadding = EdgeInsets.all(16.0);
  static const cardPadding = EdgeInsets.all(16.0);
  static const sectionSpacing = 24.0;
}

// ============================================================================
// Action Configuration
// ============================================================================

class _ActionConfig {
  static String labelFor(PayPeriodStatusAction action) {
    return switch (action) {
      PayPeriodStatusAction.activate => 'Activate Period',
      PayPeriodStatusAction.process => 'Process Payroll',
      PayPeriodStatusAction.complete => 'Complete Period',
      PayPeriodStatusAction.close => 'Close Period',
      PayPeriodStatusAction.cancel => 'Cancel Period',
      PayPeriodStatusAction.reopen => 'Reopen Period',
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
      PayPeriodStatus.completed => [PayPeriodStatusAction.close],
      PayPeriodStatus.closed => [],
      _ => [],
    };
  }
}

// ============================================================================
// Formatters
// ============================================================================

class _Formatters {
  static final date = DateFormat('MMM dd, yyyy');

  static String currency(double value) => 'KES ${value.toStringAsFixed(2)}';

  static String statusLabel(PayPeriodStatus status) =>
      status.name.replaceAll('_', ' ');

  static String frequencyLabel(PayPeriodFrequency frequency) =>
      frequency.name.replaceAll('_', ' ');
}

// ============================================================================
// Workflow Steps Configuration
// ============================================================================

class _WorkflowSteps {
  static const steps = ['Draft', 'Active', 'Processing', 'Completed', 'Closed'];
}

// ============================================================================
// Main Page Widget
// ============================================================================

class PayrollWorkflowPage extends ConsumerStatefulWidget {
  final String payPeriodId;

  const PayrollWorkflowPage({
    super.key,
    required this.payPeriodId,
  });

  @override
  ConsumerState<PayrollWorkflowPage> createState() => _PayrollWorkflowPageState();
}

class _PayrollWorkflowPageState extends ConsumerState<PayrollWorkflowPage> {
  PayPeriod? _payPeriod;
  PayPeriodStatistics? _statistics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --------------------------------------------------------------------------
  // Data Loading
  // --------------------------------------------------------------------------

  Future<void> _loadData() async {
    await Future.wait([
      _loadPayPeriod(),
      _loadStatistics(),
    ]);
  }

  Future<void> _loadPayPeriod() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final payPeriod = await repository.getPayPeriodById(widget.payPeriodId);
      _setPayPeriod(payPeriod);
    } catch (e) {
      _showSnackBar('Failed to load pay period: $e', isError: true);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final stats = await repository.getPayPeriodStatistics(widget.payPeriodId);
      _setStatistics(stats);
    } catch (_) {
      // Statistics might not be available for all periods
    }
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _executeWorkflowAction(PayPeriodStatusAction action) async {
    _setLoading(true);
    try {
      final repository = ref.read(payPeriodRepositoryProvider);
      final updatedPeriod = await _performAction(repository, action);

      _setPayPeriod(updatedPeriod);
      await _loadStatistics();

      _showSnackBar('Pay period ${action.name.toLowerCase()}d successfully');
    } catch (e) {
      _showSnackBar('Failed to ${action.name.toLowerCase()}: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<PayPeriod> _performAction(
    PayPeriodRepository repository,
    PayPeriodStatusAction action,
  ) async {
    return switch (action) {
      PayPeriodStatusAction.activate =>
        await repository.activatePayPeriod(widget.payPeriodId),
      PayPeriodStatusAction.process =>
        await repository.processPayPeriod(widget.payPeriodId),
      PayPeriodStatusAction.complete =>
        await repository.completePayPeriod(widget.payPeriodId),
      PayPeriodStatusAction.close =>
        await repository.closePayPeriod(widget.payPeriodId),
      PayPeriodStatusAction.cancel => await _updateAndRefetch(repository, 'cancel'),
      PayPeriodStatusAction.reopen => await _updateAndRefetch(repository, 'reopen'),
    };
  }

  Future<PayPeriod> _updateAndRefetch(
    PayPeriodRepository repository,
    String status,
  ) async {
    await repository.updatePayPeriodStatus(widget.payPeriodId, status);
    return repository.getPayPeriodById(widget.payPeriodId);
  }

  // --------------------------------------------------------------------------
  // State Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setPayPeriod(PayPeriod? period) {
    if (mounted) setState(() => _payPeriod = period);
  }

  void _setStatistics(PayPeriodStatistics? stats) {
    if (mounted) setState(() => _statistics = stats);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_payPeriod == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payroll Workflow')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: _WorkflowStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(payPeriod: _payPeriod!),
            const SizedBox(height: _WorkflowStyles.sectionSpacing),
            _WorkflowProgressCard(
              currentStatusIndex: PayPeriodStatus.values.indexOf(_payPeriod!.status),
            ),
            const SizedBox(height: _WorkflowStyles.sectionSpacing),
            if (_statistics != null) ...[
              _StatisticsCard(statistics: _statistics!),
              const SizedBox(height: _WorkflowStyles.sectionSpacing),
            ],
            if (_availableActions.isNotEmpty) ...[
              _ActionsCard(
                actions: _availableActions,
                isLoading: _isLoading,
                onAction: _executeWorkflowAction,
              ),
              const SizedBox(height: _WorkflowStyles.sectionSpacing),
            ],
            _QuickActionsCard(payPeriodId: _payPeriod!.id),
          ],
        ),
      ),
    );
  }

  List<PayPeriodStatusAction> get _availableActions =>
      _ActionConfig.availableFor(_payPeriod!.status);

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Payroll Workflow'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
    );
  }
}

// ============================================================================
// Header Card
// ============================================================================

class _HeaderCard extends StatelessWidget {
  final PayPeriod payPeriod;

  const _HeaderCard({required this.payPeriod});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: _WorkflowStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildInfo()),
                _StatusBadge(status: payPeriod.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Frequency: ${_Formatters.frequencyLabel(payPeriod.frequency)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payPeriod.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${_Formatters.date.format(payPeriod.startDate)} - ${_Formatters.date.format(payPeriod.endDate)}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
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

  Color get _color => _WorkflowColors.forStatus(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 2),
      ),
      child: Text(
        _Formatters.statusLabel(status),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ============================================================================
// Workflow Progress Card
// ============================================================================

class _WorkflowProgressCard extends StatelessWidget {
  final int currentStatusIndex;

  const _WorkflowProgressCard({required this.currentStatusIndex});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: _WorkflowStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Workflow Progress'),
            const SizedBox(height: 16),
            ..._WorkflowSteps.steps.asMap().entries.map((entry) {
              return _WorkflowStepRow(
                index: entry.key,
                label: entry.value,
                currentStatusIndex: currentStatusIndex,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStepRow extends StatelessWidget {
  final int index;
  final String label;
  final int currentStatusIndex;

  const _WorkflowStepRow({
    required this.index,
    required this.label,
    required this.currentStatusIndex,
  });

  bool get _isCompleted => index < currentStatusIndex;
  bool get _isCurrent => index == currentStatusIndex;
  bool get _isUpcoming => index > currentStatusIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildIndicator(),
          const SizedBox(width: 12),
          Expanded(child: _buildLabel()),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isCompleted
            ? Colors.green
            : _isCurrent
                ? _WorkflowColors.forStatus(PayPeriodStatus.active)
                : Colors.grey.shade300,
      ),
      child: _isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: _isCurrent ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildLabel() {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: _isCurrent ? FontWeight.bold : FontWeight.normal,
        color: _isUpcoming ? Colors.grey.shade600 : Colors.black,
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_isCurrent) {
      return _StepBadge(
        label: 'Current',
        color: _WorkflowColors.forStatus(PayPeriodStatus.active),
      );
    }
    if (_isCompleted) {
      return const _StepBadge(label: 'Completed', color: Colors.green);
    }
    return const SizedBox.shrink();
  }
}

class _StepBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StepBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================================
// Statistics Card
// ============================================================================

class _StatisticsCard extends StatelessWidget {
  final PayPeriodStatistics statistics;

  const _StatisticsCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: _WorkflowStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Payroll Statistics'),
            const SizedBox(height: 16),
            _buildTopRow(),
            const SizedBox(height: 16),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Workers',
            value: '${statistics.totalWorkers}',
            icon: Icons.people,
            color: _WorkflowColors.workers,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Processed',
            value: '${statistics.processedPayments}',
            icon: Icons.check_circle,
            color: _WorkflowColors.processed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: '${statistics.pendingPayments}',
            icon: Icons.pending,
            color: _WorkflowColors.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Gross Total',
            value: _Formatters.currency(statistics.totalGrossAmount),
            icon: Icons.monetization_on,
            color: _WorkflowColors.gross,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Net Total',
            value: _Formatters.currency(statistics.totalNetAmount),
            icon: Icons.account_balance_wallet,
            color: _WorkflowColors.net,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
// Actions Card
// ============================================================================

class _ActionsCard extends StatelessWidget {
  final List<PayPeriodStatusAction> actions;
  final bool isLoading;
  final Future<void> Function(PayPeriodStatusAction) onAction;

  const _ActionsCard({
    required this.actions,
    required this.isLoading,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: _WorkflowStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Available Actions'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map((action) => _ActionButton(
                        action: action,
                        isLoading: isLoading,
                        onPressed: () => onAction(action),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PayPeriodStatusAction action;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _WorkflowColors.forAction(action),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        _ActionConfig.labelFor(action),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================================================================
// Quick Actions Card
// ============================================================================

class _QuickActionsCard extends StatelessWidget {
  final String payPeriodId;

  const _QuickActionsCard({required this.payPeriodId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: _WorkflowStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.play_circle_outline,
                    label: 'Run Payroll',
                    color: Colors.blue,
                    onPressed: () => context.push('/payroll/run/$payPeriodId'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.list_alt,
                    label: 'View Records',
                    color: Colors.green,
                    onPressed: () {
                      // View payroll records
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// ============================================================================
// Shared Components
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}