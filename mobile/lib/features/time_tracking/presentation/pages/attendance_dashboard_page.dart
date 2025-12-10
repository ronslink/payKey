import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/time_entry_model.dart';

// ============================================================================
// Constants
// ============================================================================

class _AttendanceStyles {
  static const pagePadding = EdgeInsets.all(16);
  static const cardRadius = 12.0;
  static const sectionSpacing = 24.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      );
}

// ============================================================================
// Date Formatter
// ============================================================================

class _DateFormatter {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String formatMonth(DateTime date) => '${_months[date.month - 1]} ${date.year}';

  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);
}

// ============================================================================
// Main Page Widget
// ============================================================================

class AttendanceDashboardPage extends ConsumerStatefulWidget {
  const AttendanceDashboardPage({super.key});

  @override
  ConsumerState<AttendanceDashboardPage> createState() => _AttendanceDashboardPageState();
}

class _AttendanceDashboardPageState extends ConsumerState<AttendanceDashboardPage> {
  List<WorkerLiveStatus> _liveStatus = [];
  AttendanceSummary? _summary;
  bool _isLoading = true;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = _DateFormatter.startOfMonth(now);
    _endDate = _DateFormatter.endOfMonth(now);
    _loadData();
  }

  // --------------------------------------------------------------------------
  // Data Loading
  // --------------------------------------------------------------------------

  Future<void> _loadData() async {
    _setLoading(true);

    try {
      final results = await Future.wait([
        ApiService().timeTracking.getLiveStatus(),
        ApiService().timeTracking.getAttendanceSummary(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
        ),
      ]);

      final liveStatusResponse = results[0];
      final summaryResponse = results[1];

      if (liveStatusResponse.statusCode == 200) {
        _liveStatus = (liveStatusResponse.data as List)
            .map((e) => WorkerLiveStatus.fromJson(e))
            .toList();
      }

      if (summaryResponse.statusCode == 200) {
        _summary = AttendanceSummary.fromJson(summaryResponse.data);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _handleClockAction(String workerId, bool isClockedIn) async {
    try {
      if (isClockedIn) {
        await ApiService().timeTracking.clockOut(workerId);
        _showSnackBar('Worker clocked out', AppColors.warning);
      } else {
        await ApiService().timeTracking.clockIn(workerId);
        _showSnackBar('Worker clocked in', AppColors.success);
      }
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showSnackBar(String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // --------------------------------------------------------------------------
  // Computed Properties
  // --------------------------------------------------------------------------

  int get _clockedInCount => _liveStatus.where((w) => w.isClockedIn).length;
  int get _notClockedInCount => _liveStatus.where((w) => !w.isClockedIn).length;
  String get _totalHours => '${_summary?.totals.totalHours.toStringAsFixed(1) ?? '0'}h';

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: _AttendanceStyles.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCardsRow(
                      clockedIn: _clockedInCount,
                      notClockedIn: _notClockedInCount,
                      totalHours: _totalHours,
                    ),
                    const SizedBox(height: _AttendanceStyles.sectionSpacing),
                    _LiveStatusSection(
                      workers: _liveStatus,
                      onClockAction: _handleClockAction,
                    ),
                    const SizedBox(height: _AttendanceStyles.sectionSpacing),
                    _MonthlySummarySection(
                      summary: _summary,
                      startDate: _startDate,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'Time & Attendance',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.accent),
          onPressed: _loadData,
        ),
      ],
    );
  }
}

// ============================================================================
// Summary Cards Row
// ============================================================================

class _SummaryCardsRow extends StatelessWidget {
  final int clockedIn;
  final int notClockedIn;
  final String totalHours;

  const _SummaryCardsRow({
    required this.clockedIn,
    required this.notClockedIn,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Working Now',
            value: '$clockedIn',
            icon: Icons.person,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Not Clocked In',
            value: '$notClockedIn',
            icon: Icons.person_outline,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Total Hours',
            value: totalHours,
            icon: Icons.access_time,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _AttendanceStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Live Status Section
// ============================================================================

class _LiveStatusSection extends StatelessWidget {
  final List<WorkerLiveStatus> workers;
  final Future<void> Function(String, bool) onClockAction;

  const _LiveStatusSection({
    required this.workers,
    required this.onClockAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Container(
          decoration: _AttendanceStyles.cardDecoration,
          child: workers.isEmpty
              ? const _EmptyState(message: 'No workers found')
              : _buildWorkerList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionTitle('Live Status'),
        const _LiveIndicator(),
      ],
    );
  }

  Widget _buildWorkerList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workers.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.background),
      itemBuilder: (context, index) => _WorkerStatusTile(
        worker: workers[index],
        onClockAction: onClockAction,
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Live',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerStatusTile extends StatelessWidget {
  final WorkerLiveStatus worker;
  final Future<void> Function(String, bool) onClockAction;

  const _WorkerStatusTile({
    required this.worker,
    required this.onClockAction,
  });

  bool get _isClockedIn => worker.isClockedIn;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildAvatar(),
      title: Text(
        worker.workerName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _isClockedIn ? 'Working • ${worker.duration}' : 'Not clocked in',
        style: TextStyle(
          color: _isClockedIn ? AppColors.success : AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: _buildClockButton(),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _isClockedIn ? AppColors.successLight : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _isClockedIn ? Icons.person : Icons.person_outline,
        color: _isClockedIn ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildClockButton() {
    return TextButton(
      onPressed: () => onClockAction(worker.workerId, _isClockedIn),
      style: TextButton.styleFrom(
        backgroundColor: _isClockedIn ? AppColors.warningLight : AppColors.successLight,
        foregroundColor: _isClockedIn ? AppColors.warning : AppColors.success,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(_isClockedIn ? 'Clock Out' : 'Clock In'),
    );
  }
}

// ============================================================================
// Monthly Summary Section
// ============================================================================

class _MonthlySummarySection extends StatelessWidget {
  final AttendanceSummary? summary;
  final DateTime startDate;

  const _MonthlySummarySection({
    required this.summary,
    required this.startDate,
  });

  bool get _hasData => summary?.workers.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Container(
          decoration: _AttendanceStyles.cardDecoration,
          child: _hasData ? _buildTable() : const _EmptyState(message: 'No time entries this month'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionTitle('Monthly Summary'),
        Text(
          _DateFormatter.formatMonth(startDate),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        const _TableHeader(),
        ...summary!.workers.map((worker) => _TableRow(worker: worker)),
        _TableTotalsRow(totals: summary!.totals),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_AttendanceStyles.cardRadius)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Worker',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Days',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Hours',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final WorkerAttendance worker;

  const _TableRow({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.background)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              worker.workerName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${worker.totalDays}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${worker.totalHours.toStringAsFixed(1)}h',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableTotalsRow extends StatelessWidget {
  final AttendanceTotals totals;

  const _TableTotalsRow({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_AttendanceStyles.cardRadius),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${totals.totalEntries}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${totals.totalHours.toStringAsFixed(1)}h',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}