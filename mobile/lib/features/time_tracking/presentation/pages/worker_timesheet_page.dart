import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../data/models/time_tracking_model.dart';
import '../providers/time_tracking_provider.dart';

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

  Map<DateTime, List<TimeEntry>> _groupEntriesByDate(List<TimeEntry> entries) {
    final Map<DateTime, List<TimeEntry>> grouped = {};
    for (var entry in entries) {
      final date = DateTime.parse(entry.clockInTime);
      final key = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(entry);
    }
    return grouped;
  }

  Widget _buildDayCard(DateTime date, List<TimeEntry> entries) {
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

  Widget _buildEntryItem(TimeEntry entry) {
    final startTime = DateFormat('h:mm a').format(DateTime.parse(entry.clockInTime));
    final endTime = entry.clockOutTime != null 
        ? DateFormat('h:mm a').format(DateTime.parse(entry.clockOutTime!))
        : 'Active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.access_time, 
            size: 16, 
            color: entry.clockOutTime == null ? Colors.green : Colors.grey[400]
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
              ],
            ),
          ),
          if (entry.totalHours != null)
            Text(
              '${entry.totalHours!.toStringAsFixed(1)}h',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
