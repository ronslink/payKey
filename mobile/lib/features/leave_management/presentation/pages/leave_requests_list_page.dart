import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/leave_request_model.dart';
import '../providers/leave_management_provider.dart';

class LeaveRequestsListPage extends ConsumerWidget {
  final String? selectedWorkerId;

  const LeaveRequestsListPage({
    super.key,
    this.selectedWorkerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveRequestsState = ref.watch(leaveManagementProvider);
    return Column(
      children: [
        // Filter and Actions
        _buildActionsBar(context, ref),
        
        // Leave Requests List
        Expanded(
          child: leaveRequestsState.when(
            data: (leaveRequests) {
              final filteredRequests = selectedWorkerId != null
                  ? leaveRequests.where((r) => r.workerId == selectedWorkerId).toList()
                  : leaveRequests;
              
              if (filteredRequests.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(leaveManagementProvider.notifier).loadLeaveRequests();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    return _buildLeaveRequestCard(context, ref, request);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading leave requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(leaveManagementProvider.notifier).loadLeaveRequests();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedWorkerId != null 
                  ? 'Leave Requests (Filtered)'
                  : 'All Leave Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(leaveManagementProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.beach_access,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No leave requests found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedWorkerId != null
                ? 'This worker hasn\'t made any leave requests yet'
                : 'No leave requests have been made',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard(BuildContext context, WidgetRef ref, LeaveRequestModel request) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(request.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRequestDetails(context, ref, request),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with worker name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.workerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      request.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // Leave Type and Duration
              Row(
                children: [
                  Icon(
                    _getLeaveTypeIcon(request.leaveType),
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLeaveTypeDisplayName(request.leaveType),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${request.totalDays} day${request.totalDays != 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // Date Range
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM dd').format(DateTime.parse(request.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(request.endDate))}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons (for pending requests)
              if (request.status == 'PENDING')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showRejectDialog(context, ref, request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveRequest(context, ref, request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getLeaveTypeIcon(String leaveType) {
    switch (leaveType) {
      case 'ANNUAL':
        return Icons.beach_access;
      case 'SICK':
        return Icons.sick;
      case 'MATERNITY':
        return Icons.pregnant_woman;
      case 'PATERNITY':
        return Icons.man;
      case 'EMERGENCY':
        return Icons.emergency;
      case 'UNPAID':
        return Icons.money_off;
      default:
        return Icons.access_time;
    }
  }

  String _getLeaveTypeDisplayName(String leaveType) {
    switch (leaveType) {
      case 'ANNUAL':
        return 'Annual Leave';
      case 'SICK':
        return 'Sick Leave';
      case 'MATERNITY':
        return 'Maternity Leave';
      case 'PATERNITY':
        return 'Paternity Leave';
      case 'EMERGENCY':
        return 'Emergency Leave';
      case 'UNPAID':
        return 'Unpaid Leave';
      default:
        return leaveType;
    }
  }

  void _showRequestDetails(BuildContext context, WidgetRef ref, LeaveRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(request: request),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, LeaveRequestModel request) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject leave request for ${request.workerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Provide a reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(leaveManagementProvider.notifier)
                  .approveLeaveRequest(request.id, false, comments: controller.text.trim().isEmpty ? null : controller.text.trim());
              
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leave request rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, WidgetRef ref, LeaveRequestModel request) async {
    try {
      await ref.read(leaveManagementProvider.notifier)
          .approveLeaveRequest(request.id, true, comments: null);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  final LeaveRequestModel request;

  const _RequestDetailsSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Leave Request Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailRow(context, 'Worker', request.workerName),
                    _buildDetailRow(context, 'Leave Type', _getLeaveTypeDisplayName(request.leaveType)),
                    _buildDetailRow(context, 'Start Date', DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(request.startDate))),
                    _buildDetailRow(context, 'End Date', DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(request.endDate))),
                    _buildDetailRow(context, 'Total Days', '${request.totalDays}'),
                    _buildDetailRow(context, 'Status', request.status, color: _getStatusColor(request.status)),
                    _buildDetailRow(context, 'Paid Leave', request.paidLeave ? 'Yes' : 'No'),
                    if (request.paidLeave && request.dailyPayRate != null)
                      _buildDetailRow(context, 'Daily Rate', '\$${request.dailyPayRate!.toStringAsFixed(2)}'),
                    if (request.reason.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Reason',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    if (request.emergencyContact != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(context, 'Name', request.emergencyContact!),
                      if (request.emergencyPhone != null)
                        _buildDetailRow(context, 'Phone', request.emergencyPhone!),
                    ],
                    if (request.rejectionReason != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rejection Reason',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.rejectionReason!,
                              style: const TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildDetailRow(context, 'Requested On', DateFormat('MMM dd, yyyy').format(DateTime.parse(request.createdAt))),
                    if (request.approvedAt != null)
                      _buildDetailRow(context, 'Processed On', DateFormat('MMM dd, yyyy').format(DateTime.parse(request.approvedAt!))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getLeaveTypeDisplayName(String leaveType) {
    switch (leaveType) {
      case 'ANNUAL':
        return 'Annual Leave';
      case 'SICK':
        return 'Sick Leave';
      case 'MATERNITY':
        return 'Maternity Leave';
      case 'PATERNITY':
        return 'Paternity Leave';
      case 'EMERGENCY':
        return 'Emergency Leave';
      case 'UNPAID':
        return 'Unpaid Leave';
      default:
        return leaveType;
    }
  }
}