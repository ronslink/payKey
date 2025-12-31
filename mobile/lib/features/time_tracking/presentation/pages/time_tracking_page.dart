import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../workers/data/models/worker_model.dart';
import '../../../subscriptions/presentation/providers/feature_access_provider.dart';
import '../providers/time_tracking_provider.dart';
import '../../data/models/time_tracking_model.dart';
import 'worker_timesheet_page.dart';

class TimeTrackingPage extends ConsumerStatefulWidget {
  final String? selectedWorkerId;

  const TimeTrackingPage({
    super.key,
    this.selectedWorkerId,
  });

  @override
  ConsumerState<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends ConsumerState<TimeTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  String? _selectedLiveWorkerId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedLiveWorkerId = widget.selectedWorkerId;
    
    // Default to current week if no pay period selected
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _selectedDateRange = DateTimeRange(start: startOfWeek, end: endOfWeek);

    // Initial fetch for overview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOverviewData();
      if (_selectedLiveWorkerId != null) {
        ref.read(timeTrackingProvider.notifier).getActiveEntry(_selectedLiveWorkerId!);
      }
    });
  }

  void _fetchOverviewData() {
    if (_selectedDateRange != null) {
      ref.read(allTimeEntriesProvider.notifier).fetchTimeEntries(
            startDate: _selectedDateRange!.start,
            endDate: _selectedDateRange!.end,
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check feature access
    final featureAccess = ref.watch(featureAccessProvider('time_tracking'));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Time Tracking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Live Actions'),
          ],
        ),
      ),
      body: featureAccess.when(
        data: (access) => Column(
          children: [
            // Preview mode banner
            if (access.isPreview)
              _buildPreviewBanner(access.mockNotice ?? 'This is sample data'),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildLiveActionsTab(),
                ],
              ),
            ),
          ],
        ),
        loading: () => Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildLiveActionsTab(),
                ],
              ),
            ),
          ],
        ),
        error: (_, __) => Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildLiveActionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to upgrade screen
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OVERVIEW TAB
  // ===========================================================================

  Widget _buildOverviewTab() {
    final entriesState = ref.watch(allTimeEntriesProvider);
    final workersState = ref.watch(workersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        _fetchOverviewData();
        return ref.refresh(workersProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateFilter(),
            const SizedBox(height: 20),
            entriesState.when(
              data: (entries) {
                return workersState.when(
                  data: (workers) {
                    final workerList = workers;
                    return _buildOverviewContent(entries, workerList);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading workers: $e'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading entries: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    final start = DateFormat('MMM d').format(_selectedDateRange!.start);
    final end = DateFormat('MMM d, y').format(_selectedDateRange!.end);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                '$start - $end',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
                _fetchOverviewData();
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(List<TimeEntry> entries, List<WorkerModel> workers) {
    // aggregation logic
    double totalHours = 0;
    int activeWorkersCount = 0;
    
    // Map workerId -> details
    final Map<String, double> workerHours = {};
    
    for (var entry in entries) {
      if (entry.totalHours != null) {
        totalHours += entry.totalHours!;
        workerHours[entry.workerId] = (workerHours[entry.workerId] ?? 0) + entry.totalHours!;
      }
    }
    
    // Determine active workers (those with hours)
    final workersWithTime = workers.where((w) => workerHours.containsKey(w.id)).toList();
    activeWorkersCount = workersWithTime.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Hours', totalHours.toStringAsFixed(1), Icons.access_time, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Active Workers', '$activeWorkersCount', Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Worker Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (workers.isEmpty)
          const Text('No workers found')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workers.where((w) => w.isActive).length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activeWorkers = workers.where((w) => w.isActive).toList();
              final worker = activeWorkers[index];
              return _buildWorkerListTile(worker, workerHours[worker.id] ?? 0);
            },
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerListTile(WorkerModel worker, double hours) {
    final isSalaried = worker.employmentType == 'FIXED';
    final hasHours = hours > 0;
    
    // Logic:
    // Salaried: Show ONLY Overtime (here assumed as all tracked hours for now, as verified).
    // Hourly: Show Total Hours.
    // If Salaried and no hours, don't show "0h" aggressively, maybe show "Salaried".
    
    String hoursDisplay = '${hours.toStringAsFixed(1)}h';
    Color hoursColor = Colors.black;
    String subtext = 'Total Hours';
    
    if (isSalaried) {
        hoursColor = hasHours ? Colors.orange : Colors.grey;
        subtext = hasHours ? 'Overtime Recorded' : 'Standard Salary';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WorkerTimesheetPage(
            worker: worker,
            startDate: _selectedDateRange!.start,
            endDate: _selectedDateRange!.end,
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSalaried ? Colors.blue.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
              child: Text(
                worker.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: isSalaried ? Colors.blue : Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSalaried ? Colors.blue.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSalaried ? 'SALARIED' : 'HOURLY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSalaried ? Colors.blue : Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hoursDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hoursColor,
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LIVE ACTIONS TAB (Original Logic)
  // ===========================================================================

  Widget _buildLiveActionsTab() {
    final workersState = ref.watch(workersProvider);
    final timeTrackingState = ref.watch(timeTrackingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Worker Selection
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Clock In/Out',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                workersState.when(
                  data: (workers) {
                    final workersList = workers as List<dynamic>;
                    final activeWorkers = workersList
                        .where((w) => w.isActive == true)
                        .toList();

                    return InputDecorator(
                      decoration: InputDecoration(
                        hintText: _selectedLiveWorkerId == null ? 'Select a worker' : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        prefixIcon: const Icon(Icons.person),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLiveWorkerId,
                          isExpanded: true,
                          hint: const Text('Select a worker'),
                          items: activeWorkers.map<DropdownMenuItem<String>>((worker) {
                            return DropdownMenuItem<String>(
                              value: worker.id as String,
                              child: Text(worker.name as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedLiveWorkerId = value);
                            if (value != null) {
                              ref.read(timeTrackingProvider.notifier).getActiveEntry(value);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          
          if (_selectedLiveWorkerId != null) ...[
            const SizedBox(height: 24),
            timeTrackingState.when(
              data: (activeEntry) {
                if (activeEntry == null) {
                  return _buildClockInCard();
                } else {
                  return _buildClockedInCard(activeEntry);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClockInCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
            const Icon(Icons.login, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Ready to Clock In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                ),
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _handleClockIn,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                    child: const Text('CLOCK IN'),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildClockedInCard(TimeEntry entry) {
     return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
            const Icon(Icons.timer, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Clocked In at ${DateFormat('h:mm a').format(DateTime.parse(entry.clockInTime))}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Out Notes',
                    border: OutlineInputBorder(),
                ),
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _handleClockOut(entry),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                    child: const Text('CLOCK OUT'),
                ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleClockIn() async {
    if (_selectedLiveWorkerId == null) return;
    await ref.read(timeTrackingProvider.notifier).clockIn(
          _selectedLiveWorkerId!,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
    _notesController.clear();
  }

  Future<void> _handleClockOut(TimeEntry entry) async {
    await ref.read(timeTrackingProvider.notifier).clockOut(
          entry.id,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
    _notesController.clear();
  }
}