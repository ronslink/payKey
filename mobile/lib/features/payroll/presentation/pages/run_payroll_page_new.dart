import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Domain imports
import '../../data/models/pay_period_model.dart';
import '../../data/utils/pay_period_utils.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../pay_periods/presentation/providers/pay_periods_provider.dart';
import '../../../workers/presentation/providers/workers_provider.dart';

import '../../data/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';

// Local imports
import '../constants/payroll_constants.dart';
import '../utils/worker_hours_controller_manager.dart';
import '../widgets/payroll_widgets.dart';
import '../widgets/worker_payroll_card.dart';
import '../widgets/payroll_dialogs.dart';
import '../utils/payroll_calculator.dart';
// import '../models/payroll_confirm_state.dart';
// import '../widgets/payment_results_page.dart';

/// Run Payroll page - Employee inputs flow (Step 1 of 3)
/// 
/// This page allows users to:
/// - Select a pay period
/// - Enter hours/overtime for each worker
/// - Choose between automated (skip review) or manual review flow
/// - Save as draft or run payroll
class RunPayrollPageNew extends ConsumerStatefulWidget {
  final String? payPeriodId;

  const RunPayrollPageNew({
    super.key,
    this.payPeriodId,
  });

  @override
  ConsumerState<RunPayrollPageNew> createState() => _RunPayrollPageNewState();
}

class _RunPayrollPageNewState extends ConsumerState<RunPayrollPageNew> {
  // State
  PayPeriod? _selectedPayPeriod;
  int _expandedWorkerIndex = -1;
  bool _isAutomatedMode = true;
  bool _isProcessing = false;
  bool _isWorkersSectionExpanded = false;
  final Set<String> _selectedWorkerIds = {};
  bool _selectionInitialized = false;

  // Controllers and utilities
  final _controllerManager = WorkerHoursControllerManager();
  final _currencyFormatter = NumberFormat('#,###');

  bool get _isPeriodClosed {
    if (_selectedPayPeriod == null) return false;
    return _selectedPayPeriod!.status == PayPeriodStatus.completed || 
           _selectedPayPeriod!.status == PayPeriodStatus.closed;
  }

  @override
  void dispose() {
    _controllerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final workersAsync = ref.watch(workersProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          PayrollProgressIndicator(
            currentStep: PayrollConstants.employeeInputStep,
            totalSteps: PayrollConstants.totalProgressSteps,
            stepLabel: 'Step 1: Employee Inputs',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(context, payPeriodsAsync),
                  _buildWorkersSection(context, workersAsync),
                ],
              ),
            ),
          ),
          _buildBottomActions(context, workersAsync.when(data: (w) => w, loading: () => [], error: (_, _) => [])),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => context.pop(),
      ),
      title: const Text('Run Payroll'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          tooltip: 'Navigate',
          onSelected: (value) {
            switch (value) {
              case 'home':
                context.go('/home');
                break;
              case 'finance':
                context.push('/finance');
                break;
              case 'workers':
                context.push('/workers');
                break;
              case 'taxes':
                context.push('/taxes');
                break;
              case 'settings':
                context.push('/settings');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'home',
              child: Row(
                children: [
                  Icon(Icons.home_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Home'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'finance',
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Finance'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'workers',
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Workers'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'taxes',
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Taxes'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpSnackbar(context),
        ),
      ],
    );
  }

  void _showHelpSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Enter hours for each employee, then click Review Payroll to continue',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PERIOD SELECTOR
  // ============================================================

  Widget _buildPeriodSelector(
    BuildContext context,
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(context, 'PAY PERIOD'),
          const SizedBox(height: 8),
          _buildPeriodDropdown(context, payPeriodsAsync),
          const SizedBox(height: 8),
          TaxStatusBadge(taxYear: PayrollConstants.currentTaxYear),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
    );
  }

  Widget _buildPeriodDropdown(
    BuildContext context,
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: payPeriodsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (err, stack) => _buildErrorRow('Error loading periods: ${err.toString().length > 50 ? err.toString().substring(0, 50) : err}'),
        data: (periods) => _buildPeriodDropdownContent(context, periods),
      ),
    );
  }

  Widget _buildErrorRow(String message) {
    return Row(
      children: [
        const Icon(Icons.error, color: Colors.red),
        const SizedBox(width: 8),
        Text(message),
      ],
    );
  }

  Widget _buildPeriodDropdownContent(
    BuildContext context,
    List<PayPeriod> periods,
  ) {
    // Use centralized logic to determine if initialization is needed
    final yearToInitialize = PayPeriodUtils.getYearToInitialize(periods);
    
    if (yearToInitialize != null) {
      debugPrint('Dropdown: Suggesting init for year $yearToInitialize');
      // Case 1: Initialize Current/Next Year if suggested by utils
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            InitializePayPeriodsCard(
            year: yearToInitialize,
            subtitle: yearToInitialize == DateTime.now().year 
                ? 'No pay periods for $yearToInitialize' 
                : 'Ready for $yearToInitialize payroll',
            onPressed: () => _handleInitializeYear(context, yearToInitialize),
          ),
          const SizedBox(height: 8),
          if (periods.isNotEmpty)
            _buildPeriodDropdownWidget(context, periods),
        ],
      );
    }

    // Logic: Show periods from the last 36 months + any future periods
    // This allows access to history across year boundaries (e.g. accessing Jan 2025 from Mar 2026)
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - 36, 1);
    
    // Filter periods within the window
    List<PayPeriod> visiblePeriods = periods.where((p) {
      // Include if it starts after the cutoff (last 15 months)
      // OR if it's active/processing/draft (don't hide active work)
      final isRecent = p.startDate.isAfter(cutoffDate);
      final isActiveWork = !['CLOSED', 'CANCELLED'].contains(p.status.name.toUpperCase());
      return isRecent || isActiveWork;
    }).toList();
    
    debugPrint('Dropdown: All Periods: ${periods.length}, Visible: ${visiblePeriods.length}');
    if (visiblePeriods.isNotEmpty) {
      debugPrint('Dropdown: First Visible: ${visiblePeriods.first.name}, Last: ${visiblePeriods.last.name}');
    }
    
    // Sort: open/draft periods first by date ascending, then closed periods by date descending
    final closedStatuses2 = ['CLOSED', 'COMPLETED'];
    visiblePeriods.sort((a, b) {
      final aIsClosed = closedStatuses2.contains(a.status.name.toUpperCase());
      final bIsClosed = closedStatuses2.contains(b.status.name.toUpperCase());
      
      if (aIsClosed != bIsClosed) {
        // Open periods come first
        return aIsClosed ? 1 : -1;
      }
      
      if (aIsClosed) {
        // Both closed: newest first (for viewing history)
        return b.startDate.compareTo(a.startDate);
      } else {
        // Both open: oldest first (show next due period first)
        return a.startDate.compareTo(b.startDate);
      }
    });

    if (visiblePeriods.isEmpty && yearToInitialize == null) {
      return Text(
        'No pay periods available',
        style: TextStyle(color: Colors.orange.shade700),
      );
    }

    // Default: Show dropdown if we have periods, even if we showed the init card above (it's handled in the init block now if yearToInitialize was set)
    // But if yearToInitialize was NULL, we just show the dropdown here.
    return _buildPeriodDropdownWidget(context, visiblePeriods);
  }

  Widget _buildPeriodDropdownWidget(BuildContext context, List<PayPeriod> periods) {
    // Auto-select first period if none selected
    _autoSelectFirstPeriod(periods);

    // Use ID-based lookup to avoid object equality issues
    final selectedId = _selectedPayPeriod?.id ?? periods.first.id;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        isExpanded: true,
        items: periods.map((period) {
          final isClosed = ['CLOSED', 'COMPLETED', 'FINALIZED'].contains(period.status.name.toUpperCase());
          return DropdownMenuItem<String>(
            value: period.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    period.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isClosed ? Colors.grey : null,
                        ),
                  ),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Closed',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? selectedId) {
          if (selectedId != null) {
            final period = periods.firstWhere((p) => p.id == selectedId);
            setState(() {
              _selectedPayPeriod = period;
              _controllerManager.clearDaysWorkedControllers();
            });
          }
        },
      ),
    );
  }


  void _autoSelectFirstPeriod(List<PayPeriod> periods) {
    if (_selectedPayPeriod == null && periods.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // If a specific ID was requested, try to find it
          if (widget.payPeriodId != null) {
            try {
              final requested = periods.firstWhere((p) => p.id == widget.payPeriodId);
              setState(() {
                _selectedPayPeriod = requested;
                _controllerManager.clearDaysWorkedControllers();
              });
              return;
            } catch (_) {
              // Period not found, fall back to default behavior
            }
          }
          setState(() {
            _selectedPayPeriod = periods.first;
            _controllerManager.clearDaysWorkedControllers();
          });
        }
      });
    }
  }

  // ============================================================
  // WORKERS SECTION
  // ============================================================

  Widget _buildWorkersSection(
    BuildContext context,
    AsyncValue<List<WorkerModel>> workersAsync,
  ) {
    return workersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Failed to load workers: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (workers) => _buildWorkersList(context, workers),
    );
  }

  Widget _buildWorkersList(BuildContext context, List<WorkerModel> workers) {
    if (_selectedPayPeriod == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Select a pay period to view employee inputs'),
        ),
      );
    }

    if (workers.isEmpty) {
      return NoWorkersEmptyState(
        onAddWorker: () => context.push('/workers/add'),
      );
    }

    // Sync controllers with current worker list
    _controllerManager.syncWithWorkers(workers.map((w) => w.id).toList());

    // Initialize selection if needed
    if (!_selectionInitialized && workers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedWorkerIds.addAll(workers.map((w) => w.id));
            _selectionInitialized = true;
          });
        }
      });
    }

    return Column(
      children: [
        _buildWorkersHeader(context, workers),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: workers.asMap().entries.map((entry) {
                return _buildWorkerCard(context, entry.key, entry.value);
              }).toList(),
            ),
          ),
          crossFadeState: _isWorkersSectionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildWorkersHeader(BuildContext context, List<WorkerModel> workers) {
    final count = workers.length;
    final allSelected = _selectedWorkerIds.length == count && count > 0;

    return InkWell(
      onTap: () => setState(() => _isWorkersSectionExpanded = !_isWorkersSectionExpanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedWorkerIds.addAll(workers.map((w) => w.id));
                      } else {
                        _selectedWorkerIds.clear();
                      }
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Text(
                  'Employee Inputs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isWorkersSectionExpanded 
                      ? Icons.keyboard_arrow_up_rounded 
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            Text(
              '${_selectedWorkerIds.length} / $count Selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, int index, WorkerModel worker) {
    final isHourly = worker.employmentType == EmploymentType.hourly;
    
    // Calculate total days in the selected pay period
    final periodStart = _selectedPayPeriod?.startDate ?? DateTime.now();
    final periodEnd = _selectedPayPeriod?.endDate ?? DateTime.now();
    final totalDaysInPeriod = periodEnd.difference(periodStart).inDays + 1;

    return WorkerPayrollCard(
      worker: worker,
      isExpanded: _expandedWorkerIndex == index,
      isSelected: _selectedWorkerIds.contains(worker.id),
      onSelectionChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedWorkerIds.add(worker.id);
          } else {
            _selectedWorkerIds.remove(worker.id);
          }
        });
      },
      hoursController: _controllerManager.getHoursController(
        worker.id,
        isHourly: isHourly,
      ),
      overtimeController: _controllerManager.getOvertimeController(worker.id),
      bonusesController: _controllerManager.getBonusesController(worker.id),
      deductionsController: _controllerManager.getDeductionsController(worker.id),
      daysWorkedController: _controllerManager.getDaysWorkedController(
        worker.id,
        worker: worker,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
      totalDaysInPeriod: totalDaysInPeriod,
      isPartialPeriod: _controllerManager.isPartialPeriod(worker.id),
      formatter: _currencyFormatter,
      onTap: () => setState(() {
        _expandedWorkerIndex = _expandedWorkerIndex == index ? -1 : index;
      }),
      onInputChanged: () => setState(() {}),
    );
  }


  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions(BuildContext context, List<WorkerModel> workers) {
    final isDisabled =
        _selectedPayPeriod == null || workers.isEmpty || _isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAutomationToggle(context),
            const SizedBox(height: 12),
            _buildActionButtons(context, workers, isDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
          value: _isAutomatedMode,
          onChanged: _isProcessing
              ? null
              : (value) => setState(() => _isAutomatedMode = value),
          activeThumbColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          _isAutomatedMode ? 'Automated (Skip Review)' : 'Manual Review',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<WorkerModel> workers,
    bool isDisabled,
  ) {
    // Also disable if no workers selected
    final effectivelyDisabled = isDisabled || _selectedWorkerIds.isEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: effectivelyDisabled ? null : () => _handleSaveDraft(workers),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Draft'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: effectivelyDisabled ? null : () => _handleRunPayroll(workers),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPeriodClosed 
                          ? Icons.visibility 
                          : (_isAutomatedMode ? Icons.bolt : Icons.arrow_forward),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_isPeriodClosed 
                        ? 'View Summary' 
                        : (_isAutomatedMode ? 'Run Payroll' : 'Review Payroll')),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUSINESS LOGIC HANDLERS
  // ============================================================

  Future<void> _handleInitializeYear(BuildContext context, int year) async {
    final confirmed = await InitializeYearDialog.show(context, year);
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final startDate = dateFormatter.format(DateTime(year, 1, 1));
      final endDate = dateFormatter.format(DateTime(year, 12, 31));

      await ref.read(payPeriodsProvider.notifier).generatePayPeriods(
            frequency: PayPeriodFrequency.monthly,
            startDate: startDate,
            endDate: endDate,
          );

      ref.invalidate(payPeriodsProvider);

      if (mounted) {
        _showSuccessSnackbar('Pay periods for $year created successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSaveDraft(List<WorkerModel> workers) async {
    if (_selectedPayPeriod == null || workers.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final payrollRepo = ref.read(payrollRepositoryProvider);

      final selectedWorkers = workers.where((w) => _selectedWorkerIds.contains(w.id)).toList();
      final calculations = await payrollRepo.calculatePayroll(
        selectedWorkers.map((w) => w.id).toList(),
        startDate: _selectedPayPeriod!.startDate,
        endDate: _selectedPayPeriod!.endDate,
      );

      final itemsToSave = _buildPayrollItems(calculations, selectedWorkers);
      await payrollRepo.saveDraftPayroll(_selectedPayPeriod!.id, itemsToSave);

      if (mounted) {
        _showSuccessSnackbar('Draft saved for ${selectedWorkers.length} workers');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error saving draft: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRunPayroll(List<WorkerModel> workers) async {
    if (_selectedPayPeriod == null || workers.isEmpty) return;

    // If period is already closed/completed, just go to review/summary
    if (_isPeriodClosed) {
      _navigateToReview(workers);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final payrollRepo = ref.read(payrollRepositoryProvider);

      // Calculate payroll
      final selectedWorkers = workers.where((w) => _selectedWorkerIds.contains(w.id)).toList();
      final calculations = await payrollRepo.calculatePayroll(
        selectedWorkers.map((w) => w.id).toList(),
        startDate: _selectedPayPeriod!.startDate,
        endDate: _selectedPayPeriod!.endDate,
      );

      // Save draft first (required before finalization)
      final itemsToSave = _buildPayrollItems(calculations, selectedWorkers);
      await payrollRepo.saveDraftPayroll(_selectedPayPeriod!.id, itemsToSave);

      if (!mounted) return;

      if (_isAutomatedMode) {
        await _processAutomatedPayroll(selectedWorkers);
      } else {
        _navigateToReview(selectedWorkers);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processAutomatedPayroll(List<WorkerModel> workers) async {
    // Automated mode simply skips the Review Page.
    // We still must go to the Confirmation Page to verify IntaSend funds and disburse.
    
    if (!mounted) return;
    
    context.pushNamed(
      'payrollConfirm',
      pathParameters: {'id': _selectedPayPeriod!.id},
      extra: workers.map((w) => w.id).toList(),
    );
  }


  void _navigateToReview(List<WorkerModel> workers) {
    context.push(
      '/payroll/review/${_selectedPayPeriod!.id}',
      extra: workers,
    );
  }

  List<Map<String, dynamic>> _buildPayrollItems(
    List<PayrollCalculation> calculations,
    List<WorkerModel> workers,
  ) {
    final periodStart = _selectedPayPeriod?.startDate ?? DateTime.now();
    final periodEnd = _selectedPayPeriod?.endDate ?? DateTime.now();
    final totalDaysInPeriod = periodEnd.difference(periodStart).inDays + 1;
    
    return calculations.map((calc) {
      final worker = workers.firstWhere((w) => w.id == calc.workerId);
      final hours = _controllerManager.getHours(worker.id);
      final overtime = _controllerManager.getOvertime(worker.id);
      final bonuses = _controllerManager.getBonuses(worker.id);
      final deductions = _controllerManager.getDeductions(worker.id);
      final daysWorked = _controllerManager.getDaysWorked(worker.id);
      
      // Calculate proration factor
      final isHourly = worker.employmentType == EmploymentType.hourly;
      final prorationFactor = isHourly ? 1.0 : daysWorked / totalDaysInPeriod;

      // Re-calculate Gross (Base + Overtime) based on inputs with proration
      final grossPay = PayrollCalculator.calculateEstimatedPay(
        worker: worker,
        hours: hours,
        overtime: overtime,
        prorationFactor: prorationFactor,
      );

      return {
        'workerId': calc.workerId,
        'grossSalary': grossPay,
        'bonuses': bonuses,
        'otherEarnings': calc.otherEarnings,
        'otherDeductions': deductions,
        'daysWorked': daysWorked,
        'totalDaysInPeriod': totalDaysInPeriod,
      };
    }).toList();
  }


  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
