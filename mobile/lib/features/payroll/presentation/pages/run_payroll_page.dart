import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../workers/data/models/worker_model.dart';
import '../providers/pay_period_provider.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/payroll_repository.dart';
import 'payroll_review_page.dart';
import '../providers/payroll_provider.dart';

/// Simplified one-click payroll page
class RunPayrollPage extends ConsumerStatefulWidget {
  final String? payPeriodId;

  const RunPayrollPage({super.key, this.payPeriodId});

  @override
  ConsumerState<RunPayrollPage> createState() => _RunPayrollPageState();
}

class _RunPayrollPageState extends ConsumerState<RunPayrollPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  PayPeriod? _payPeriod;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isAutomated = true; // Default to automated
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
    _initializePayroll();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize: load workers and auto-create pay period if needed
  Future<void> _initializePayroll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(workersProvider.notifier).fetchWorkers();

      final repository = ref.read(payPeriodRepositoryProvider);

      if (widget.payPeriodId != null) {
        // Load specific pay period
        _payPeriod = await repository.getPayPeriodById(widget.payPeriodId!);
      } else {
        // Auto-find or create current month's pay period
        final allPeriods = await repository.getPayPeriods();
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

        // Look for existing period for current month
        final existingPeriod = allPeriods.where((p) =>
            (p.status == PayPeriodStatus.draft ||
                p.status == PayPeriodStatus.active) &&
            p.startDate.month == now.month &&
            p.startDate.year == now.year).firstOrNull;

        if (existingPeriod != null) {
          _payPeriod = existingPeriod;
        } else {
          // Auto-create a new period for current month
          final monthName = DateFormat('MMMM yyyy').format(now);
          _payPeriod = await repository.createPayPeriod(CreatePayPeriodRequest(
            name: 'Payroll - $monthName',
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
            frequency: PayPeriodFrequency.monthly,
          ));
        }
      }

      // Auto-select all active workers
      final workers = ref.read(workersProvider).value ?? [];
      final activeWorkerIds =
          workers.where((w) => w.isActive).map((w) => w.id).toSet();
      ref.read(selectedWorkersProvider.notifier).set(activeWorkerIds);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// One-click: Calculate payroll for all selected workers
  Future<void> _runPayroll() async {
    final selectedWorkers = ref.read(selectedWorkersProvider);
    if (selectedWorkers.isEmpty || _payPeriod == null) return;

    setState(() => _isProcessing = true);

    try {
      final payrollRepo = ref.read(payrollRepositoryProvider);

      // 1. Calculate payroll
      final calculations = await payrollRepo.calculatePayroll(
        selectedWorkers.toList(),
        startDate: _payPeriod!.startDate,
        endDate: _payPeriod!.endDate,
      );

      // 2. Prepare items for saving
      final itemsToSave = calculations
          .map((calc) => {
                'workerId': calc.workerId,
                'grossSalary': calc.grossSalary,
                'bonuses': calc.bonuses,
                'otherEarnings': calc.otherEarnings,
                'otherDeductions': calc.otherDeductions,
              })
          .toList();

      // 3. Save to draft (Required step before finalization)
      await payrollRepo.saveDraftPayroll(_payPeriod!.id, itemsToSave);

      if (!mounted) return;

      // 4. Handle Flow based on Automation Toggle
      if (_isAutomated) {
        // AUTOMATED: Finalize immediately
        final result = await payrollRepo.processPayroll(
          selectedWorkers.toList(),
          _payPeriod!.id,
        );

        if (mounted) {
            // Show Success & Summary
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Payroll Complete'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Successfully processed ${result.totalProcessed} workers.'),
                    const SizedBox(height: 8),
                    const Text('• Payslips generated'),
                    const Text('• Tax returns filed'),
                    const Text('• Records finalized'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to dashboard
                    },
                    child: const Text('Return to Dashboard'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Navigate to Tax Page (using named route if available, or just pop)
                      // Assuming tax route exists or push replacement
                      // tailored for this app's navigation
                      Navigator.of(context).pushReplacement(
                         MaterialPageRoute(
                            builder: (context) => PayrollReviewPage(payPeriodId: _payPeriod!.id),
                         ),
                      );
                    },
                     child: const Text('View Results'),
                  ),
                ],
              ),
            );
        }
      } else {
        // MANUAL: Navigate to review page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PayrollReviewPage(payPeriodId: _payPeriod!.id),
          ),
        );
      }
    } catch (e) {
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0F172A)],
              ),
            ),
          ),

          // Decorative Orb
          Positioned(
            top: -80,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Preparing payroll...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializePayroll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final workersAsync = ref.watch(workersProvider);
    final selectedWorkers = ref.watch(selectedWorkersProvider);

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPayPeriodCard(),
                const SizedBox(height: 20),
                _buildWorkersSummaryCard(workersAsync, selectedWorkers),
                const SizedBox(height: 20),
                _buildWorkersList(workersAsync, selectedWorkers),
              ],
            ),
          ),
        ),
        _buildBottomAction(selectedWorkers),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run Payroll',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'One-click payroll processing',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _initializePayroll,
          ),
        ],
      ),
    );
  }

  Widget _buildPayPeriodCard() {
    return FadeTransition(
      opacity: _animationController,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.calendar_month, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pay Period',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _payPeriod?.name ?? 'Current Month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _payPeriod?.status.name.toUpperCase() ?? 'DRAFT',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDateBadge(
                    'Start', DateFormat('MMM d').format(_payPeriod!.startDate)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.white38, size: 16),
                const SizedBox(width: 12),
                _buildDateBadge(
                    'End', DateFormat('MMM d').format(_payPeriod!.endDate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWorkersSummaryCard(
      AsyncValue<List<WorkerModel>> workersAsync, Set<String> selectedWorkers) {
    return workersAsync.when(
      data: (workers) {
        final activeWorkers = workers.where((w) => w.isActive).toList();
        final totalCost = activeWorkers
            .where((w) => selectedWorkers.contains(w.id))
            .fold<double>(0, (sum, w) => sum + w.salaryGross);

        return _GlassCard(
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  Icons.people,
                  '${selectedWorkers.length}',
                  'Workers',
                  const Color(0xFF3B82F6),
                ),
              ),
              Container(
                  width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
              Expanded(
                child: _buildSummaryStat(
                  Icons.attach_money,
                  NumberFormat.compact().format(totalCost),
                  'Est. Cost',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildWorkersList(
      AsyncValue<List<WorkerModel>> workersAsync, Set<String> selectedWorkers) {
    return workersAsync.when(
      data: (workers) {
        final activeWorkers = workers.where((w) => w.isActive).toList();
        if (activeWorkers.isEmpty) {
          return _GlassCard(
            child: Column(
              children: [
                const Icon(Icons.person_off, color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No active workers',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Workers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final allIds = activeWorkers.map((w) => w.id).toSet();
                      if (selectedWorkers.length == allIds.length) {
                        ref.read(selectedWorkersProvider.notifier).clear();
                      } else {
                        ref.read(selectedWorkersProvider.notifier).set(allIds);
                      }
                    },
                    child: Text(
                      selectedWorkers.length == activeWorkers.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(color: Color(0xFF60A5FA)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activeWorkers.map((worker) => _buildWorkerTile(
                    worker,
                    selectedWorkers.contains(worker.id),
                  )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildWorkerTile(WorkerModel worker, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF3B82F6).withOpacity(0.15)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: () =>
            ref.read(selectedWorkersProvider.notifier).toggle(worker.id),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.2),
          child: Text(
            worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Color(0xFF60A5FA)),
          ),
        ),
        title: Text(worker.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          'KES ${NumberFormat('#,###').format(worker.salaryGross)}',
          style: const TextStyle(color: Color(0xFF10B981)),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) =>
              ref.read(selectedWorkersProvider.notifier).toggle(worker.id),
          activeColor: const Color(0xFF3B82F6),
          checkColor: Colors.white,
          side: const BorderSide(color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildBottomAction(Set<String> selectedWorkers) {
    final isDisabled = selectedWorkers.isEmpty || _isProcessing;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Automation Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch(
                value: _isAutomated,
                onChanged: _isProcessing
                    ? null
                    : (value) => setState(() => _isAutomated = value),
                activeColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                _isAutomated ? 'Automated Run (Skip Review)' : 'Manual Review',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDisabled ? null : _runPayroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF10B981).withOpacity(0.5),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAutomated ? Icons.bolt : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAutomated
                              ? 'Auto-Process ${selectedWorkers.length} Workers'
                              : 'Review ${selectedWorkers.length} Workers',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism card widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
