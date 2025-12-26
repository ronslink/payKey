import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/geofence_service.dart';
import '../../data/models/employee_models.dart';

// ============================================================================
// Constants
// ============================================================================

class _DashboardColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const background = Color(0xFFF8FAFC);
  static const text = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF374151);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const successDark = Color(0xFF059669);
}

class _DashboardStyles {
  static const cardRadius = 16.0;
  static const smallRadius = 12.0;
  static const headerRadius = 24.0;
  static const padding = 16.0;
  static const cardPadding = 20.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get smallCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(smallRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

// ============================================================================
// Date/Time Formatting
// ============================================================================

class _DateFormatter {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String formatDate(DateTime date) {
    return '${_days[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

// ============================================================================
// Main Page Widget
// ============================================================================

class EmployeeDashboardPage extends ConsumerStatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  ConsumerState<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends ConsumerState<EmployeeDashboardPage> {
  LeaveBalance? _leaveBalance;
  ClockStatus? _clockStatus;
  List<Map<String, dynamic>> _properties = [];
  String? _selectedPropertyId;
  bool _isLoading = true;
  bool _isClockingIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --------------------------------------------------------------------------
  // Data Loading
  // --------------------------------------------------------------------------

  Future<void> _loadData() async {
    _setLoading(true);
    try {
      // Fetch leave balance, clock status, and properties in parallel
      final leaveBalanceFuture = ApiService().employeePortal.getMyLeaveBalance();
      
      // These are fire-and-forget since they update state internally
      _fetchClockStatus();
      _fetchEmployerProperties();
      
      final leaveResponse = await leaveBalanceFuture;
      if (leaveResponse.statusCode == 200) {
        _leaveBalance = LeaveBalance.fromJson(leaveResponse.data);
      }
    } catch (_) {
      // Silent failure - partial data is acceptable
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchEmployerProperties() async {
    try {
      final response = await ApiService().employeePortal.getEmployerProperties();
      if (response.statusCode == 200 && mounted) {
        final data = response.data as List<dynamic>?;
        setState(() {
          _properties = data?.map((p) => p as Map<String, dynamic>).toList() ?? [];
          // Auto-select if only one property
          if (_properties.length == 1) {
            _selectedPropertyId = _properties.first['id'] as String?;
          }
        });
      }
    } catch (_) {
      // Properties are optional - may fail for non Gold/Platinum
    }
  }

  Future<dynamic> _fetchClockStatus() async {
    try {
      final profileResponse = await ApiService().employeePortal.getMyProfile();
      if (profileResponse.statusCode != 200) return;

      final profile = EmployeeProfile.fromJson(profileResponse.data);
      if (profile.workerId == null) return;

      final statusResponse = await ApiService().timeTracking.getStatus(profile.workerId!);
      if (statusResponse.statusCode == 200 && mounted) {
        setState(() => _clockStatus = ClockStatus.fromJson(statusResponse.data));
      }
    } catch (_) {
      // Clock status is optional
    }
  }

  // --------------------------------------------------------------------------
  // Clock Actions
  // --------------------------------------------------------------------------

  Future<void> _handleClockAction() async {
    final isClockedIn = _clockStatus?.isClockedIn == true;
    
    // Show property selection dialog if clocking in with multiple properties
    if (!isClockedIn && _properties.length > 1 && _selectedPropertyId == null) {
      final selectedId = await _showPropertySelectionDialog();
      if (selectedId == null) return; // User cancelled
      _selectedPropertyId = selectedId;
    }
    
    _setClockingIn(true);
    try {
      final workerId = await _getWorkerId();

      if (isClockedIn) {
        await ApiService().timeTracking.clockOut(workerId);
        await GeofenceService.instance.stopMonitoring();
        _showSnackBar('Clocked out successfully!', Colors.orange);
        _selectedPropertyId = null; // Reset selection
      } else {
        await ApiService().timeTracking.clockIn(
          workerId,
          propertyId: _selectedPropertyId,
        );
        _showSnackBar('Clocked in successfully!', Colors.green);
        
        // Start geofence monitoring if property selected
        if (_selectedPropertyId != null) {
          final prop = _properties.firstWhere(
            (p) => p['id'] == _selectedPropertyId,
            orElse: () => <String, dynamic>{},
          );
          if (prop.isNotEmpty && prop['latitude'] != null && prop['longitude'] != null) {
            await GeofenceService.instance.startMonitoring(
              workerId: workerId,
              propertyId: _selectedPropertyId!,
              propertyName: prop['name'] as String? ?? 'Work Location',
              latitude: (prop['latitude'] as num).toDouble(),
              longitude: (prop['longitude'] as num).toDouble(),
              radiusMeters: ((prop['geofenceRadius'] as num?) ?? 100).toDouble(),
            );
          }
        }
      }

      await _fetchClockStatus();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      _setClockingIn(false);
    }
  }

  Future<String?> _showPropertySelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Work Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _properties.map((prop) {
            return ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF6366F1)),
              title: Text(prop['name'] as String? ?? 'Unknown'),
              subtitle: Text(
                prop['address'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(ctx).pop(prop['id'] as String),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String> _getWorkerId() async {
    final profileResponse = await ApiService().employeePortal.getMyProfile();
    if (profileResponse.statusCode != 200) {
      throw Exception('Failed to get profile');
    }

    final profile = EmployeeProfile.fromJson(profileResponse.data);
    if (profile.workerId == null) {
      throw Exception('Worker ID not found');
    }

    return profile.workerId!;
  }

  // --------------------------------------------------------------------------
  // State Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setClockingIn(bool value) {
    if (mounted) setState(() => _isClockingIn = value);
  }

  void _showSnackBar(String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _handleLogout() async {
    await ApiService().clearToken();
    if (mounted) context.go('/employee/login');
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _DashboardHeader(
                      workerName: _leaveBalance?.workerName,
                      onLogout: _handleLogout,
                    )),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: _DashboardStyles.padding),
                      sliver: SliverToBoxAdapter(
                      child: _ClockCard(
                          clockStatus: _clockStatus,
                          isClockingIn: _isClockingIn,
                          onClockAction: _handleClockAction,
                          properties: _properties,
                          selectedPropertyId: _selectedPropertyId,
                          onPropertyChanged: (id) => setState(() => _selectedPropertyId = id),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(_DashboardStyles.padding),
                      sliver: SliverToBoxAdapter(
                        child: _LeaveBalanceCard(balance: _leaveBalance),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: _DashboardStyles.padding),
                      sliver: const SliverToBoxAdapter(child: _QuickActionsSection()),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// Header Component
// ============================================================================

class _DashboardHeader extends StatelessWidget {
  final String? workerName;
  final VoidCallback onLogout;

  const _DashboardHeader({required this.workerName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DashboardStyles.cardPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DashboardColors.primary, _DashboardColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_DashboardStyles.headerRadius),
          bottomRight: Radius.circular(_DashboardStyles.headerRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(),
          const SizedBox(height: 16),
          _buildDateBadge(),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              workerName ?? 'Employee',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Sign out',
        ),
      ],
    );
  }

  Widget _buildDateBadge() {
    return Container(
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
            _DateFormatter.formatDate(DateTime.now()),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Clock Card Component
// ============================================================================

class _ClockCard extends StatelessWidget {
  final ClockStatus? clockStatus;
  final bool isClockingIn;
  final VoidCallback onClockAction;
  final List<Map<String, dynamic>> properties;
  final String? selectedPropertyId;
  final ValueChanged<String?> onPropertyChanged;

  const _ClockCard({
    required this.clockStatus,
    required this.isClockingIn,
    required this.onClockAction,
    required this.properties,
    required this.selectedPropertyId,
    required this.onPropertyChanged,
  });

  bool get _isClockedIn => clockStatus?.isClockedIn ?? false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(_DashboardStyles.cardPadding),
      decoration: _DashboardStyles.cardDecoration,
      child: Column(
        children: [
          _buildStatus(),
          if (!_isClockedIn && properties.length > 1) ...[
            const SizedBox(height: 16),
            _buildPropertySelector(),
          ],
          const SizedBox(height: 20),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text('Select work location'),
            ],
          ),
          value: selectedPropertyId,
          items: properties.map((prop) {
            return DropdownMenuItem<String>(
              value: prop['id'] as String,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prop['name'] as String? ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onPropertyChanged,
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Row(
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusText()),
      ],
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_isClockedIn ? Colors.green : Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_DashboardStyles.smallRadius),
      ),
      child: Icon(
        _isClockedIn ? Icons.timer : Icons.timer_outlined,
        color: _isClockedIn ? Colors.green : Colors.grey,
        size: 28,
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isClockedIn ? 'Currently Working' : 'Not Clocked In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isClockedIn ? Colors.green : Colors.grey[600],
          ),
        ),
        if (_isClockedIn && clockStatus?.currentEntry != null)
          Text(
            'Since ${_DateFormatter.formatTime(clockStatus!.currentEntry!.clockIn)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        if (!_isClockedIn)
          Text(
            'Today: ${clockStatus?.todayTotalDisplay ?? '0h 0m'}',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isClockingIn ? null : onClockAction,
        icon: isClockingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(_isClockedIn ? Icons.stop_circle_outlined : Icons.play_circle_outline),
        label: Text(
          _isClockedIn ? 'Clock Out' : 'Clock In',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isClockedIn ? Colors.orange : _DashboardColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DashboardStyles.smallRadius),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ============================================================================
// Leave Balance Card Component
// ============================================================================

class _LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance? balance;

  const _LeaveBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DashboardStyles.cardPadding),
      decoration: _DashboardStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildStats(),
          if ((balance?.pendingLeaves ?? 0) > 0) ...[
            const SizedBox(height: 12),
            _buildPendingAlert(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Leave Balance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _DashboardColors.text,
          ),
        ),
        Text(
          (balance?.year ?? DateTime.now().year).toString(),
          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final usagePercent = (balance?.usagePercentage ?? 0) / 100;
    final isHighUsage = (balance?.usagePercentage ?? 0) > 80;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: usagePercent,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          isHighUsage ? Colors.orange : _DashboardColors.primary,
        ),
        minHeight: 10,
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _LeaveStatItem(
          label: 'Available',
          value: '${balance?.remainingAnnualLeaves ?? 21}',
          color: Colors.green,
        )),
        Expanded(child: _LeaveStatItem(
          label: 'Used',
          value: '${balance?.usedAnnualLeaves ?? 0}',
          color: Colors.orange,
        )),
        Expanded(child: _LeaveStatItem(
          label: 'Total',
          value: '${balance?.totalAnnualLeaves ?? 21}',
          color: Colors.grey[600]!,
        )),
      ],
    );
  }

  Widget _buildPendingAlert() {
    return Container(
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
    );
  }
}

class _LeaveStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LeaveStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// ============================================================================
// Quick Actions Section
// ============================================================================

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static const _actions = [
    [
      _QuickActionData('Request Leave', Icons.event_note, _DashboardColors.primary, '/employee/request-leave'),
      _QuickActionData('My Leaves', Icons.calendar_view_month, _DashboardColors.success, '/employee/my-leaves'),
    ],
    [
      _QuickActionData('Timesheet', Icons.access_time, _DashboardColors.warning, '/employee/timesheet'),
      _QuickActionData('Payslips', Icons.receipt_long, _DashboardColors.secondary, '/employee/payslips'),
    ],
    [
      _QuickActionData('P9 Tax Report', Icons.description, _DashboardColors.successDark, '/employee/p9'),
      null, // Placeholder for future action
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _DashboardColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ..._actions.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: row[0] != null
                    ? _QuickActionCard(data: row[0]!)
                    : const SizedBox(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: row[1] != null
                    ? _QuickActionCard(data: row[1]!)
                    : const SizedBox(),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickActionData(this.title, this.icon, this.color, this.route);
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(data.route),
      child: Container(
        padding: const EdgeInsets.all(_DashboardStyles.padding),
        decoration: _DashboardStyles.smallCardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _DashboardColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}