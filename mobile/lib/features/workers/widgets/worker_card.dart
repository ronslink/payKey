import 'package:flutter/material.dart';
import '../constants/workers_constants.dart';
import '../utils/compliance_checker.dart';

/// Display data for a worker card
class WorkerCardData {
  final String id;
  final String name;
  final String? jobTitle;
  final bool isActive;
  final ComplianceStatus complianceStatus;

  const WorkerCardData({
    required this.id,
    required this.name,
    this.jobTitle,
    required this.isActive,
    required this.complianceStatus,
  });

  /// Get initials from name
  String get initials {
    if (name.isEmpty) return 'W';
    return name
        .split(' ')
        .where((n) => n.isNotEmpty)
        .take(2)
        .map((n) => n[0])
        .join()
        .toUpperCase();
  }

  /// Create from worker model
  factory WorkerCardData.fromWorker(dynamic worker) {
    return WorkerCardData(
      id: worker.id as String,
      name: worker.name as String,
      jobTitle: worker.jobTitle as String?,
      isActive: worker.isActive as bool,
      complianceStatus: ComplianceStatus.fromWorker(worker),
    );
  }
}

/// Worker card widget
class WorkerCard extends StatelessWidget {
  final WorkerCardData data;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssue = data.complianceStatus.hasIssues;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: WorkersTheme.cardDecoration(hasWarning: hasIssue),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo(context)),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: WorkersTheme.avatarSize,
          height: WorkersTheme.avatarSize,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(WorkersTheme.avatarBorderRadius),
          ),
          child: Center(
            child: Text(
              data.initials,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: WorkersTheme.statusIndicatorSize,
      height: WorkersTheme.statusIndicatorSize,
      decoration: BoxDecoration(
        color: data.isActive ? WorkersTheme.activeColor : WorkersTheme.inactiveColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameRow(context),
        const SizedBox(height: 4),
        Text(
          data.jobTitle ?? 'Employee',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        if (data.complianceStatus.hasIssues) _buildComplianceWarning(),
      ],
    );
  }

  Widget _buildNameRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            data.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = data.isActive ? WorkersTheme.activeColor : WorkersTheme.inactiveColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        data.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildComplianceWarning() {
    final issue = data.complianceStatus.issueDescription;
    if (issue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            size: 14,
            color: WorkersTheme.warningColor.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            issue,
            style: TextStyle(
              fontSize: 11,
              color: WorkersTheme.warningColor.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
