import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/employee_models.dart';
import '../../../time_tracking/data/models/time_entry_model.dart';

/// Employee Dashboard - main view for employee users
class EmployeeDashboardPage extends ConsumerStatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  ConsumerState<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends ConsumerState<EmployeeDashboardPage> {
  LeaveBalance? _leaveBalance;
  ClockStatus? _clockStatus;
  bool _isLoading = true;
  bool _isClockingIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load leave balance and clock status in parallel
      final results = await Future.wait([
        ApiService().employeePortal.getMyLeaveBalance(),
        _getClockStatus(),
      ]);

      final leaveResponse = results[0];
      if (leaveResponse.statusCode == 200) {
        _leaveBalance = LeaveBalance.fromJson(leaveResponse.data);
      }
    } catch (e) {
      // Error handling - could add error state if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<dynamic> _getClockStatus() async {
    try {
      // Get profile first to get workerId
      final profileResponse = await ApiService().employeePortal.getMyProfile();
      if (profileResponse.statusCode == 200) {
        final profile = EmployeeProfile.fromJson(profileResponse.data);
        if (profile.workerId != null) {
          final statusResponse = await ApiService().timeTracking.getStatus(profile.workerId!);
          if (statusResponse.statusCode == 200) {
            setState(() {
              _clockStatus = ClockStatus.fromJson(statusResponse.data);
            });
          }
        }
      }
    } catch (e) {
      // Clock status is optional, don't fail the whole page
    }
  }

  Future<void> _handleClockAction() async {
    setState(() => _isClockingIn = true);

    try {
      final profileResponse = await ApiService().employeePortal.getMyProfile();
      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to get profile');
      }
      
      final profile = EmployeeProfile.fromJson(profileResponse.data);
      if (profile.workerId == null) {
        throw Exception('Worker ID not found');
      }

      if (_clockStatus?.isClockedIn == true) {
        // Clock out
        await ApiService().timeTracking.clockOut(profile.workerId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clocked out successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Clock in
        await ApiService().timeTracking.clockIn(profile.workerId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clocked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh status
      await _getClockStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isClockingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                    
                    // Clock In/Out Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildClockCard(),
                      ),
                    ),
                    
                    // Leave Balance Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildLeaveCard(),
                      ),
                    ),
                    
                    // Quick Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildQuickActions(),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _leaveBalance?.workerName ?? 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  await ApiService().clearToken();
                  if (mounted) {
                    context.go('/employee/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Today's date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard() {
    final isClockedIn = _clockStatus?.isClockedIn ?? false;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isClockedIn 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isClockedIn ? Icons.timer : Icons.timer_outlined,
                  color: isClockedIn ? Colors.green : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockedIn ? 'Currently Working' : 'Not Clocked In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isClockedIn ? Colors.green : Colors.grey[600],
                      ),
                    ),
                    if (isClockedIn && _clockStatus?.currentEntry != null)
                      Text(
                        'Since ${_formatTime(_clockStatus!.currentEntry!.clockIn)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    if (!isClockedIn)
                      Text(
                        'Today: ${_clockStatus?.todayTotalDisplay ?? '0h 0m'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Clock In/Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isClockingIn ? null : _handleClockAction,
              icon: _isClockingIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isClockedIn ? Icons.stop_circle_outlined : Icons.play_circle_outline),
              label: Text(
                isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn ? Colors.orange : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard() {
    final balance = _leaveBalance;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                balance?.year.toString() ?? DateTime.now().year.toString(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (balance?.usagePercentage ?? 0) / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                (balance?.usagePercentage ?? 0) > 80 
                    ? Colors.orange 
                    : const Color(0xFF6366F1),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLeaveStatItem(
                  'Available',
                  '${balance?.remainingAnnualLeaves ?? 21}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildLeaveStatItem(
                  'Used',
                  '${balance?.usedAnnualLeaves ?? 0}',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildLeaveStatItem(
                  'Total',
                  '${balance?.totalAnnualLeaves ?? 21}',
                  Colors.grey[600]!,
                ),
              ),
            ],
          ),
          if ((balance?.pendingLeaves ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${balance!.pendingLeaves} leave request(s) pending',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Request Leave',
                Icons.event_note,
                const Color(0xFF6366F1),
                () => context.push('/employee/request-leave'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'My Leaves',
                Icons.calendar_view_month,
                const Color(0xFF10B981),
                () => context.push('/employee/my-leaves'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Timesheet',
                Icons.access_time,
                const Color(0xFFF59E0B),
                () => context.push('/employee/timesheet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Payslips',
                Icons.receipt_long,
                const Color(0xFF8B5CF6),
                () => context.push('/employee/payslips'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
