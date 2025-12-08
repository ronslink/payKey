import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/time_entry_model.dart';

/// Attendance dashboard for employers to view live status and manage time entries
class AttendanceDashboardPage extends ConsumerStatefulWidget {
  const AttendanceDashboardPage({super.key});

  @override
  ConsumerState<AttendanceDashboardPage> createState() => _AttendanceDashboardPageState();
}

class _AttendanceDashboardPageState extends ConsumerState<AttendanceDashboardPage> {
  List<WorkerLiveStatus> _liveStatus = [];
  AttendanceSummary? _summary;
  bool _isLoading = true;
  String? _error;

  // Date range for summary
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load live status and summary in parallel
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
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleClockAction(String workerId, bool isClockedIn) async {
    try {
      if (isClockedIn) {
        await ApiService().timeTracking.clockOut(workerId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker clocked out'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        await ApiService().timeTracking.clockIn(workerId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker clocked in'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _loadData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    
                    const SizedBox(height: 24),
                    
                    // Live Status Section
                    _buildLiveStatusSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Monthly Summary Table
                    _buildMonthlySummarySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final clockedIn = _liveStatus.where((w) => w.isClockedIn).length;
    final notClockedIn = _liveStatus.where((w) => !w.isClockedIn).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Working Now',
            clockedIn.toString(),
            Icons.person,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Not Clocked In',
            notClockedIn.toString(),
            Icons.person_outline,
            AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Hours',
            '${_summary?.totals.totalHours.toStringAsFixed(1) ?? '0'}h',
            Icons.access_time,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
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
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: _liveStatus.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No workers found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _liveStatus.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.background),
                  itemBuilder: (context, index) {
                    final worker = _liveStatus[index];
                    return _buildWorkerStatusTile(worker);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkerStatusTile(WorkerLiveStatus worker) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: worker.isClockedIn 
              ? AppColors.successLight
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          worker.isClockedIn ? Icons.person : Icons.person_outline,
          color: worker.isClockedIn ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      title: Text(
        worker.workerName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        worker.isClockedIn 
            ? 'Working • ${worker.duration}'
            : 'Not clocked in',
        style: TextStyle(
          color: worker.isClockedIn ? AppColors.success : AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _handleClockAction(worker.workerId, worker.isClockedIn),
        style: TextButton.styleFrom(
          backgroundColor: worker.isClockedIn 
              ? AppColors.warningLight 
              : AppColors.successLight,
          foregroundColor: worker.isClockedIn ? AppColors.warning : AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(worker.isClockedIn ? 'Clock Out' : 'Clock In'),
      ),
    );
  }

  Widget _buildMonthlySummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_formatMonth(_startDate)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: _summary?.workers.isEmpty ?? true
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No time entries this month',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                    ),
                    // Data rows
                    ...(_summary!.workers.map((worker) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.background),
                        ),
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
                    ))),
                    // Totals row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
                              '${_summary!.totals.totalEntries}',
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
                              '${_summary!.totals.totalHours.toStringAsFixed(1)}h',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
