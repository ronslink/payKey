import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workers/presentation/providers/workers_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'leave_requests_list_page.dart';
import 'leave_balance_page.dart';

class LeaveDashboardPage extends ConsumerStatefulWidget {
  const LeaveDashboardPage({super.key});

  @override
  ConsumerState<LeaveDashboardPage> createState() => _LeaveDashboardPageState();
}

class _LeaveDashboardPageState extends ConsumerState<LeaveDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Leave Management', 
          style: TextStyle(
            color: AppColors.textPrimary, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Requests', icon: Icon(Icons.description)),
            Tab(text: 'Balances', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const LeaveRequestsListPage(),
          const WorkerBalancesView(),
        ],
      ),
    );
  }
}

class WorkerBalancesView extends ConsumerWidget {
  const WorkerBalancesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersProvider);

    return workersAsync.when(
      data: (workers) {
        if (workers.isEmpty) {
          return const Center(
            child: Text(
              'No workers found', 
              style: TextStyle(color: AppColors.textTertiary)
            )
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final worker = workers[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text(worker.jobTitle ?? 'Worker', style: const TextStyle(color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                     appBar: AppBar(
                       title: Text('${worker.name} Balance'),
                       backgroundColor: AppColors.surface,
                       foregroundColor: AppColors.textPrimary,
                       elevation: 0,
                     ),
                     body: LeaveBalancePage(selectedWorkerId: worker.id)
                   )));
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
    );
  }
}
