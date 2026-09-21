import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../data/models/time_entry_model.dart';
import '../../data/repositories/time_tracking_repository.dart';
import '../providers/time_tracking_provider.dart';
import '../widgets/time_entry_sheets.dart';

class WorkerTimesheetPage extends ConsumerStatefulWidget {
  final WorkerModel worker;
  final DateTime startDate;
  final DateTime endDate;

  const WorkerTimesheetPage({
    super.key,
    required this.worker,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<WorkerTimesheetPage> createState() => _WorkerTimesheetPageState();
}

class _WorkerTimesheetPageState extends ConsumerState<WorkerTimesheetPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      
      ref.read(workerTimeEntriesProvider.notifier).fetchTimeEntries(
        workerId: widget.worker.id,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesState = ref.watch(workerTimeEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.worker.name, style: const TextStyle(fontSize: 18)),
            Text(
              '${DateFormat('MMM d').format(widget.startDate)} - ${DateFormat('MMM d').format(widget.endDate)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: entriesState.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          // Group entries by date
          final groupedEntries = _groupEntriesByDate(entries);
          final sortedDates = groupedEntries.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateEntries = groupedEntries[date]!;
              return _buildDayCard(date, dateEntries);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No time entries found for this period',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<TimeEntryModel>> _groupEntriesByDate(List<TimeEntryModel> entries) {
    final Map<DateTime, List<TimeEntryModel>> grouped = {};
    for (var entry in entries) {
      final date = entry.clockIn.toLocal();
      final key = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(entry);
    }
    return grouped;
  }

  Widget _buildDayCard(DateTime date, List<TimeEntryModel> entries) {
    double totalHours = 0;
    for (var e in entries) {
      if (e.totalHours != null) totalHours += e.totalHours!;
    }
    
    // Check for overtime (assuming > 8 hours is OT, purely visual for now)
    final isOvertime = totalHours > 8;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOvertime ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${totalHours.toStringAsFixed(1)}h Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isOvertime ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map((entry) => _buildEntryItem(entry)),
        ],
      ),
    );
  }

  Widget _buildEntryItem(TimeEntryModel entry) {
    final startTime = DateFormat('h:mm a').format(entry.clockIn.toLocal());
    final endTime = entry.clockOut != null 
        ? DateFormat('h:mm a').format(entry.clockOut!.toLocal())
        : 'Active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.access_time, 
            size: 16, 
            color: entry.clockOut == null ? Colors.green : Colors.grey[400]
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (entry.notes != null)
                  Text(
                    entry.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (entry.isEntered || !entry.payrollIncluded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildPayrollChip(entry),
                  ),
              ],
            ),
          ),
          if (entry.totalHours != null)
            Text(
              '${entry.totalHours!.toStringAsFixed(1)}h',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          PopupMenuButton<String>(
            tooltip: 'Entry actions',
            onSelected: (value) => _handleEntryAction(value, entry),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'correct',
                child: Text('Correct the times'),
              ),
              if (!entry.payrollIncluded)
                const PopupMenuItem(
                  value: 'include',
                  child: Text('Include in pay'),
                ),
              if (!entry.payrollExcluded)
                const PopupMenuItem(
                  value: 'exclude',
                  child: Text('Exclude from pay'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Employers decide here whether hand-recorded hours reach payroll.
  Widget _buildPayrollChip(TimeEntryModel entry) {
    // Preview/mock entries carry no decision; nothing to say about them.
    if (entry.payrollDecision == null) return const SizedBox.shrink();

    final (label, color) = switch (entry.payrollDecision) {
      'PENDING' => ('Waiting for your pay decision', Colors.orange),
      'EXCLUDED' => ('Excluded from pay', Colors.redAccent),
      _ => ('Included in pay', Colors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _handleEntryAction(String action, TimeEntryModel entry) async {
    if (action == 'correct') {
      final saved = await showCorrectTimeSheet(context, ref, entry: entry);
      if (saved) {
        _reload();
        _notify('Correction saved. The hours need your pay decision again.');
      }
      return;
    }

    final include = action == 'include';
    try {
      await ref.read(timeTrackingRepositoryProvider).decidePayroll(
            entryIds: [entry.id],
            include: include,
          );
      _reload();
      _notify(
        include
            ? 'These hours will be paid.'
            : 'These hours were excluded from pay.',
      );
    } on TimeTrackingException catch (e) {
      _notify(e.message);
    }
  }

  void _reload() {
    ref.read(workerTimeEntriesProvider.notifier).fetchTimeEntries(
          workerId: widget.worker.id,
          startDate: widget.startDate,
          endDate: widget.endDate,
        );
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
