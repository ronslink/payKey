import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../time_tracking/presentation/pages/time_tracking_page.dart';
import '../providers/leave_management_provider.dart';
import 'leave_request_form_page.dart';
import 'leave_requests_list_page.dart';
import 'leave_balance_page.dart';

class LeaveManagementPage extends ConsumerStatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  ConsumerState<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends ConsumerState<LeaveManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time & Leave Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/time-tracking/history'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Time Tracking',
            ),
            Tab(
              icon: Icon(Icons.beach_access),
              text: 'Leave Requests',
            ),
            Tab(
              icon: Icon(Icons.account_balance_wallet),
              text: 'Leave Balance',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Time Tracking Tab (existing functionality)
          _buildTimeTrackingTab(workersState),
          // Leave Requests Tab
          _buildLeaveRequestsTab(),
          // Leave Balance Tab
          _buildLeaveBalanceTab(),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingTab(AsyncValue<List<dynamic>> workersState) {
    return const TimeTrackingPage(); // This would be the existing time tracking page
  }

  Widget _buildLeaveRequestsTab() {
    return Column(
      children: [
        // Worker Selection
        _buildWorkerSelection(),
        // Leave Requests List
        Expanded(
          child: LeaveRequestsListPage(selectedWorkerId: _selectedWorkerId),
        ),
      ],
    );
  }

  Widget _buildLeaveBalanceTab() {
    return Column(
      children: [
        // Worker Selection
        _buildWorkerSelection(),
        // Leave Balance Display
        Expanded(
          child: LeaveBalancePage(selectedWorkerId: _selectedWorkerId),
        ),
      ],
    );
  }

  Widget _buildWorkerSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Worker',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final workersState = ref.watch(workersProvider);
                  return workersState.when(
                    data: (workers) {
                      final activeWorkers = workers.where((w) => w.isActive).toList();
                      
                      if (activeWorkers.isEmpty) {
                        return const Text('No active workers available');
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedWorkerId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a worker for leave management',
                        ),
                        items: activeWorkers.map((worker) {
                          return DropdownMenuItem(
                            value: worker.id,
                            child: Text(worker.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedWorkerId = value);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Error: ${error.toString()}'),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedWorkerId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateLeaveRequestDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Request Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateLeaveRequestDialog() {
    if (_selectedWorkerId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeaveRequestFormPage(
          workerId: _selectedWorkerId!,
          onSubmitted: () {
            // Refresh leave requests when a new request is created
            ref.read(leaveManagementProvider.notifier).loadLeaveRequests();
          },
        ),
      ),
    );
  }
}
