import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/workers_provider.dart';
import '../../data/models/worker_model.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../payroll/data/repositories/payroll_repository.dart';
import '../../../employee_portal/presentation/widgets/invite_worker_dialog.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

abstract class _AppColors {
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textBody = Color(0xFF374151);
  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1E40AF);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const border = Color(0xFFE5E7EB);
}

abstract class _Spacing {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

// =============================================================================
// FORMATTERS
// =============================================================================

/// Utility class for formatting worker-related data.
abstract class WorkerFormatters {
  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  static String currency(double amount) => 'KES ${_currencyFormat.format(amount)}';

  static String date(DateTime date) => _dateFormat.format(date);

  static String employmentType(String type) {
    return switch (type) {
      'FIXED' => 'Fixed Salary',
      'HOURLY' => 'Hourly Rate',
      _ => type,
    };
  }

  static String paymentFrequency(String frequency) {
    return switch (frequency) {
      'MONTHLY' => 'Monthly',
      'WEEKLY' => 'Weekly',
      'BIWEEKLY' => 'Bi-Weekly',
      _ => frequency,
    };
  }

  static String paymentMethod(String method) {
    return switch (method) {
      'MPESA' => 'M-Pesa',
      'BANK' => 'Bank Transfer',
      'CASH' => 'Cash',
      _ => method,
    };
  }
}

// =============================================================================
// MAIN PAGE
// =============================================================================

class WorkerDetailPage extends ConsumerStatefulWidget {
  final String workerId;

  const WorkerDetailPage({
    super.key,
    required this.workerId,
  });

  @override
  ConsumerState<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends ConsumerState<WorkerDetailPage> {
  AsyncValue<List<WorkerPaymentHistoryItem>> _history = const AsyncValue.loading();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workersProvider.notifier).loadWorkers();
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
      if (!mounted) return;
      setState(() => _history = const AsyncValue.loading());
      try {
        final repo = ref.read(payrollRepositoryProvider);
        final data = await repo.getWorkerHistory(widget.workerId);
        if (mounted) setState(() => _history = AsyncValue.data(data));
      } catch (e, st) {
        if (mounted) setState(() => _history = AsyncValue.error(e, st));
      }
  }

  Future<void> _downloadPayslip(String recordId, String periodName) async {
      try {
          final repo = ref.read(payrollRepositoryProvider);
          final bytes = await repo.downloadPayslip(recordId);
          
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/payslip_$periodName.pdf');
          await file.writeAsBytes(bytes);
          
          await OpenFilex.open(file.path);
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to open payslip: $e')),
              );
          }
      }
  }

  // ---------------------------------------------------------------------------
  // Data Access
  // ---------------------------------------------------------------------------

  WorkerModel? _findWorker(List<WorkerModel> workers) {
    try {
      return workers.firstWhere((w) => w.id == widget.workerId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _navigateBack() => context.go('/workers');

  void _navigateToEdit(WorkerModel worker) {
    context.push('/workers/${widget.workerId}/edit', extra: worker);
  }

  void _navigateToTerminate() {
    context.push('/workers/${widget.workerId}/terminate');
  }

  Future<void> _refreshWorker() async {
    await ref.read(workersProvider.notifier).loadWorkers();
  }

  void _handleMenuAction(String action, WorkerModel? worker) {
    switch (action) {
      case 'edit':
        if (worker != null) _navigateToEdit(worker);
        break;
      case 'terminate':
        _navigateToTerminate();
        break;
      case 'invite':
        if (worker != null) {
          showInviteWorkerDialog(
            context,
            workerId: worker.id,
            workerName: worker.name,
            workerPhone: worker.phoneNumber,
            workerEmail: worker.email,
          );
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);

    // Get worker for app bar actions
    final worker = workersState.whenOrNull(
      data: (workers) => _findWorker(workers),
    );

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: _buildAppBar(worker),
      body: workersState.when(
        data: (workers) {
          final workerData = _findWorker(workers);
          if (workerData == null) {
            return _NotFoundState(onBack: _navigateBack);
          }
          return _WorkerDetailContent(
            worker: workerData,
            onEdit: () => _navigateToEdit(workerData),
            onTerminate: _navigateToTerminate,
            history: _history,
            onDownloadPayslip: _downloadPayslip,
          );
        },
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: _refreshWorker,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WorkerModel? worker) {
    return AppBar(
      backgroundColor: _AppColors.surface,
      foregroundColor: _AppColors.textPrimary,
      elevation: 0,
      title: const Text(
        'Worker Details',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _AppColors.textSecondary),
        onPressed: _navigateBack,
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _AppColors.textSecondary),
          onSelected: (action) => _handleMenuAction(action, worker),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'invite',
              child: _MenuItemRow(
                icon: Icons.person_add,
                label: 'Invite to App',
                color: Color(0xFF6366F1),
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: _MenuItemRow(
                icon: Icons.edit,
                label: 'Edit Worker',
                color: _AppColors.primary,
              ),
            ),
            PopupMenuItem(
              value: 'terminate',
              child: _MenuItemRow(
                icon: Icons.cancel,
                label: 'Terminate Worker',
                color: _AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// CONTENT
// =============================================================================

class _WorkerDetailContent extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onEdit;
  final VoidCallback onTerminate;

  const _WorkerDetailContent({
    required this.worker,
    required this.onEdit,
    required this.onTerminate,
    required this.history,
    required this.onDownloadPayslip,
  });

  final AsyncValue<List<WorkerPaymentHistoryItem>> history;
  final Function(String, String) onDownloadPayslip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkerHeader(worker: worker),
          const SizedBox(height: _Spacing.xl),
          _ContactSection(worker: worker),
          const SizedBox(height: _Spacing.xl),
          _EmploymentSection(worker: worker),
          const SizedBox(height: _Spacing.xl),
          _SalarySection(worker: worker),
          const SizedBox(height: _Spacing.xl),
          if (_hasTaxInfo) ...[
            _TaxSection(worker: worker),
            const SizedBox(height: _Spacing.xl),
          ],
          _PaymentHistorySection(
              history: history,
              onDownload: onDownloadPayslip,
          ),
          const SizedBox(height: _Spacing.xl),
          if (worker.notes?.isNotEmpty == true) ...[
            _NotesSection(notes: worker.notes!),
            const SizedBox(height: _Spacing.xl),
          ],
          _ActionButtons(
            isActive: worker.isActive,
            onEdit: onEdit,
            onTerminate: onTerminate,
          ),
        ],
      ),
    );
  }

  bool get _hasTaxInfo =>
      worker.kraPin?.isNotEmpty == true ||
      worker.nssfNumber?.isNotEmpty == true ||
      worker.nhifNumber?.isNotEmpty == true;
}

// =============================================================================
// HEADER
// =============================================================================

class _WorkerHeader extends StatelessWidget {
  final WorkerModel worker;

  const _WorkerHeader({required this.worker});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(_Spacing.xxl),
      child: Row(
        children: [
          _Avatar(name: worker.name, size: 80),
          const SizedBox(width: _Spacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _AppColors.textPrimary,
                  ),
                ),
                if (worker.jobTitle?.isNotEmpty == true) ...[
                  const SizedBox(height: _Spacing.xs),
                  Text(
                    worker.jobTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: _Spacing.md),
                _StatusBadge(isActive: worker.isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DETAIL SECTIONS
// =============================================================================

class _ContactSection extends StatelessWidget {
  final WorkerModel worker;

  const _ContactSection({required this.worker});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Contact Information',
      rows: [
        _DetailRowData('Phone Number', worker.phoneNumber, Icons.phone),
        if (worker.email?.isNotEmpty == true)
          _DetailRowData('Email', worker.email!, Icons.email),
        if (worker.idNumber?.isNotEmpty == true)
          _DetailRowData('ID Number', worker.idNumber!, Icons.credit_card),
      ],
    );
  }
}

class _EmploymentSection extends StatelessWidget {
  final WorkerModel worker;

  const _EmploymentSection({required this.worker});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Employment Details',
      rows: [
        _DetailRowData(
          'Employment Type',
          WorkerFormatters.employmentType(worker.employmentType),
          Icons.work,
        ),
        if (worker.jobTitle?.isNotEmpty == true)
          _DetailRowData('Job Title', worker.jobTitle!, Icons.badge),
        _DetailRowData(
          'Payment Frequency',
          WorkerFormatters.paymentFrequency(worker.paymentFrequency),
          Icons.schedule,
        ),
        _DetailRowData(
          'Payment Method',
          WorkerFormatters.paymentMethod(worker.paymentMethod),
          Icons.payment,
        ),
        _DetailRowData(
          'Start Date',
          WorkerFormatters.date(worker.startDate),
          Icons.calendar_today,
        ),
      ],
    );
  }
}

class _SalarySection extends StatelessWidget {
  final WorkerModel worker;

  const _SalarySection({required this.worker});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Salary Information',
      rows: [
        _DetailRowData(
          'Gross Salary',
          WorkerFormatters.currency(worker.salaryGross),
          Icons.attach_money,
        ),
        if (worker.housingAllowance > 0)
          _DetailRowData(
            'Housing Allowance',
            WorkerFormatters.currency(worker.housingAllowance),
            Icons.home,
          ),
        if (worker.transportAllowance > 0)
          _DetailRowData(
            'Transport Allowance',
            WorkerFormatters.currency(worker.transportAllowance),
            Icons.directions_car,
          ),
      ],
    );
  }
}

class _TaxSection extends StatelessWidget {
  final WorkerModel worker;

  const _TaxSection({required this.worker});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Tax Information',
      rows: [
        if (worker.kraPin?.isNotEmpty == true)
          _DetailRowData('KRA PIN', worker.kraPin!, Icons.account_balance),
        if (worker.nssfNumber?.isNotEmpty == true)
          _DetailRowData('NSSF Number', worker.nssfNumber!, Icons.security),
        if (worker.nhifNumber?.isNotEmpty == true)
          _DetailRowData('NHIF Number', worker.nhifNumber!, Icons.health_and_safety),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _Spacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_Spacing.lg),
            decoration: BoxDecoration(
              color: _AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _AppColors.border),
            ),
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistorySection extends StatelessWidget {
  final AsyncValue<List<WorkerPaymentHistoryItem>> history;
  final Function(String, String) onDownload;

  const _PaymentHistorySection({
    required this.history,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
            'Payment History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _Spacing.lg),
          history.when(
            data: (items) {
                if (items.isEmpty) {
                    return const Text('No payment history found.');
                }
                return Column(
                    children: items.map((item) => _PaymentHistoryRow(
                        item: item,
                        onDownload: () => onDownload(item.id, item.payPeriodName),
                    )).toList(),
                );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading history: $e', style: const TextStyle(color: _AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
    final WorkerPaymentHistoryItem item;
    final VoidCallback onDownload;
    
    const _PaymentHistoryRow({required this.item, required this.onDownload});
    
    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
                children: [
                    const Icon(Icons.receipt_long, color: _AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(item.payPeriodName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                    DateFormat('MMM d, yyyy').format(item.periodStart),
                                    style: const TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                                ),
                            ],
                        ),
                    ),
                    Text(
                        NumberFormat.currency(symbol: 'KES ').format(item.netPay),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        icon: const Icon(Icons.download, color: _AppColors.primary),
                        onPressed: onDownload,
                    ),
                ],
            ),
        );
    }
}

// =============================================================================
// ACTION BUTTONS
// =============================================================================

class _ActionButtons extends StatelessWidget {
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onTerminate;

  const _ActionButtons({
    required this.isActive,
    required this.onEdit,
    required this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Edit Worker',
            icon: Icons.edit,
            color: _AppColors.primary,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(width: _Spacing.md),
        Expanded(
          child: _ActionButton(
            label: 'Terminate',
            icon: Icons.cancel,
            color: _AppColors.error,
            onPressed: isActive ? onTerminate : null,
          ),
        ),
      ],
    );
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
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_AppColors.primary),
            ),
          ),
          SizedBox(height: _Spacing.lg),
          Text(
            'Loading worker details...',
            style: TextStyle(
              fontSize: 16,
              color: _AppColors.textSecondary,
            ),
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
        padding: const EdgeInsets.all(_Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StateIcon(
              icon: Icons.error_outline,
              backgroundColor: _AppColors.errorLight,
              iconColor: _AppColors.error,
            ),
            const SizedBox(height: _Spacing.lg),
            const Text(
              'Failed to load worker details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: _Spacing.xxl),
            _ActionButton(
              label: 'Try Again',
              color: _AppColors.primary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final VoidCallback onBack;

  const _NotFoundState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StateIcon(
              icon: Icons.person_off,
              backgroundColor: _AppColors.errorLight,
              iconColor: _AppColors.error,
            ),
            const SizedBox(height: _Spacing.lg),
            const Text(
              'Worker Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _Spacing.sm),
            const Text(
              'This worker may have been deleted or you may not\nhave permission to view their details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: _Spacing.xxl),
            _ActionButton(
              label: 'Back to Workers',
              color: _AppColors.primary,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

// -----------------------------------------------------------------------------
// Card Container
// -----------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(_Spacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// Avatar
// -----------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({
    required this.name,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.primary, _AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Status Badge
// -----------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _AppColors.success : _AppColors.error;
    final bgColor = isActive ? _AppColors.successLight : _AppColors.errorLight;
    final label = isActive ? 'Active' : 'Inactive';
    final icon = isActive ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Spacing.md,
        vertical: _Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: _Spacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Detail Section
// -----------------------------------------------------------------------------

class _DetailRowData {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRowData(this.label, this.value, this.icon);
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRowData> rows;

  const _DetailSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _Spacing.lg),
          ...rows.map((row) => _DetailRow(
                label: row.label,
                value: row.value,
                icon: row.icon,
              )),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _Spacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _AppColors.textSecondary),
          const SizedBox(width: _Spacing.md),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// State Icon
// -----------------------------------------------------------------------------

class _StateIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _StateIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 40, color: iconColor),
    );
  }
}

// -----------------------------------------------------------------------------
// Action Button
// -----------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: _Spacing.xxl,
        vertical: _Spacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

// -----------------------------------------------------------------------------
// Menu Item Row
// -----------------------------------------------------------------------------

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuItemRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: _Spacing.sm),
        Text(label),
      ],
    );
  }
}