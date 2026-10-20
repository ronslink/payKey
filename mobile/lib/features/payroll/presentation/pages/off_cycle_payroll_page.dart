import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/pay_period_model.dart';
import '../providers/pay_period_provider.dart';

/// Off-Cycle / On-Demand Payroll Page
///
/// Allows an employer to run a payroll outside the normal schedule.
/// Key use cases:
///  - Missed or urgent payments
///  - Paying a subset of workers ad-hoc
///  - Final pay for a terminated worker (via immediate_offcycle mode)
class OffCyclePayrollPage extends ConsumerStatefulWidget {
  /// Optional: pre-select a worker (e.g. when triggered from termination flow)
  final String? preSelectedWorkerId;
  final String? preSelectedWorkerName;

  const OffCyclePayrollPage({
    super.key,
    this.preSelectedWorkerId,
    this.preSelectedWorkerName,
  });

  @override
  ConsumerState<OffCyclePayrollPage> createState() =>
      _OffCyclePayrollPageState();
}

class _OffCyclePayrollPageState extends ConsumerState<OffCyclePayrollPage> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDate;
  late DateTime _endDate;
  String _periodName = '';
  bool _allWorkers = true;
  List<String> _selectedWorkerIds = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _periodName = 'Off-Cycle — ${DateFormat('MMM yyyy').format(now)}';

    if (widget.preSelectedWorkerId != null) {
      _allWorkers = false;
      _selectedWorkerIds = [widget.preSelectedWorkerId!];
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }

    if (!_allWorkers && _selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one worker')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(payPeriodRepositoryProvider);
      final name = _periodName.trim().isEmpty
          ? 'Off-Cycle — ${DateFormat('dd MMM yyyy').format(_startDate)}'
          : _periodName.trim();

      // Create the off-cycle PayPeriod
      final request = CreatePayPeriodRequest(
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        frequency: PayPeriodFrequency.monthly,
        isOffCycle: true,
        notes: 'On-demand off-cycle payroll run',
      );

      final created = await repo.createPayPeriod(request);
      if (!mounted) return;

      // Invalidate list so it refreshes on back
      ref.invalidate(payPeriodsProvider);

      // Navigate to payroll confirm page with the new period
      // Pass worker filter if not all workers
      await context.push(
        '/payroll/confirm/${created.id}',
        extra: {'workerIds': _allWorkers ? <String>[] : _selectedWorkerIds},
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create off-cycle run: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Off-Cycle Payroll')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              _InfoBanner(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFF59E0B),
                message:
                    'An off-cycle run creates a separate pay period outside '
                    'your regular schedule. No duplicate overlap check is '
                    'applied. Payment follows each worker\'s configured method.',
              ),
              const SizedBox(height: 24),

              // Period name
              _SectionTitle('Period Details'),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _periodName,
                decoration: const InputDecoration(
                  labelText: 'Period Name',
                  hintText: 'e.g. Bonus Run March 2026',
                ),
                onChanged: (v) => _periodName = v,
              ),
              const SizedBox(height: 16),

              // Date range
              LayoutBuilder(
                builder: (context, constraints) {
                  final dates = [
                    _DateField(
                      label: 'Start Date',
                      value: _startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                    _DateField(
                      label: 'End Date',
                      value: _endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ];
                  if (constraints.maxWidth <
                      320 * MediaQuery.textScalerOf(context).scale(1)) {
                    return Column(
                      children: [
                        dates.first,
                        const SizedBox(height: 16),
                        dates.last,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: dates.first),
                      const SizedBox(width: 12),
                      Expanded(child: dates.last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Worker selection
              _SectionTitle('Workers'),
              const SizedBox(height: 12),
              if (widget.preSelectedWorkerId != null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('All Workers'),
                  subtitle: const Text(
                    'Include all workers instead of the selected worker',
                  ),
                  value: _allWorkers,
                  onChanged: (v) => setState(() => _allWorkers = v),
                )
              else
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('All Workers'),
                  subtitle: Text(
                    'Review the workers before confirming payroll',
                  ),
                ),

              if (!_allWorkers) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    widget.preSelectedWorkerName ?? 'Selected worker',
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded),
                  label: const Text(
                    'Create & Run Off-Cycle Payroll',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.textPrimary,
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          DateFormat('dd MMM yyyy').format(value),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
