import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../pay_periods/presentation/providers/pay_periods_provider.dart';
import '../../../payroll/data/models/pay_period_model.dart';
import '../../data/models/gov_submission_model.dart';
import '../../data/providers/gov_submissions_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/download_utils.dart';

class GovSubmissionsPage extends ConsumerStatefulWidget {
  const GovSubmissionsPage({super.key});

  @override
  ConsumerState<GovSubmissionsPage> createState() => _GovSubmissionsPageState();
}

class _GovSubmissionsPageState extends ConsumerState<GovSubmissionsPage> {
  PayPeriod? _selectedPayPeriod;
  bool _isGenerating = false;
  String _generatingType = '';

  @override
  Widget build(BuildContext context) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final submissionsAsync = ref.watch(govSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Submissions'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(govSubmissionsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pay Period Selector
          _buildPayPeriodSelector(context, payPeriodsAsync),
          const SizedBox(height: 16),

          // Generate Buttons
          if (_selectedPayPeriod != null) _buildGenerateButtons(context),

          const SizedBox(height: 16),

          // Submissions List
          Expanded(
            child: _buildSubmissionsList(context, submissionsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildPayPeriodSelector(BuildContext context, AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Pay Period',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          payPeriodsAsync.when(
            data: (periods) {
              final finalized = periods.where((p) => p.status == 'finalized').toList();
              if (finalized.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No finalized pay periods. Finalize a payroll to generate files.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return DropdownButtonFormField<PayPeriod>(
                initialValue: _selectedPayPeriod,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('Choose a pay period'),
                items: finalized.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text('${DateFormat('MMM yyyy').format(p.startDate)} - ${p.name}'),
                )).toList(),
                onChanged: (value) => setState(() => _selectedPayPeriod = value),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Files',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenerateCard('KRA P10', Icons.account_balance, Colors.blue, 'kra')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenerateCard('SHIF', Icons.health_and_safety, Colors.green, 'shif')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenerateCard('NSSF', Icons.security, Colors.orange, 'nssf')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateCard(String label, IconData icon, Color color, String type) {
    final isLoading = _isGenerating && _generatingType == type;

    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading || _isGenerating ? null : () => _generateFile(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateFile(String type) async {
    if (_selectedPayPeriod == null) return;

    setState(() {
      _isGenerating = true;
      _generatingType = type;
    });

    try {
      switch (type) {
        case 'kra':
          await ApiService().gov.generateKraP10(_selectedPayPeriod!.id);
          break;
        case 'shif':
          await ApiService().gov.generateShif(_selectedPayPeriod!.id);
          break;
        case 'nssf':
          await ApiService().gov.generateNssf(_selectedPayPeriod!.id);
          break;
      }

      ref.invalidate(govSubmissionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} file generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = '';
        });
      }
    }
  }

  Widget _buildSubmissionsList(BuildContext context, AsyncValue<List<GovSubmission>> submissionsAsync) {
    return submissionsAsync.when(
      data: (submissions) {
        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No submissions yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a pay period and generate files above',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) => _SubmissionCard(
            submission: submissions[index],
            onDownload: () => _downloadFile(submissions[index]),
            onConfirm: () => _showConfirmDialog(submissions[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _downloadFile(GovSubmission submission) async {
    try {
      final bytes = await ApiService().gov.downloadFile(submission.id);
      await DownloadUtils.downloadFile(
        bytes: bytes,
        filename: submission.fileName ?? 'download.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showConfirmDialog(GovSubmission submission) async {
    final refController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the reference number from the government portal:'),
            const SizedBox(height: 16),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && refController.text.isNotEmpty) {
      try {
        await ApiService().gov.confirmSubmission(submission.id, refController.text);
        ref.invalidate(govSubmissionsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission confirmed'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  final GovSubmission submission;
  final VoidCallback onDownload;
  final VoidCallback onConfirm;

  const _SubmissionCard({
    required this.submission,
    required this.onDownload,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(submission.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getTypeIcon(submission.type), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.type.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        submission.fileName ?? 'No file',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: submission.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.people,
                  label: '${submission.employeeCount ?? 0} employees',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.payments,
                  label: 'KES ${NumberFormat('#,###').format(submission.totalAmount ?? 0)}',
                ),
              ],
            ),
            if (submission.referenceNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Ref: ${submission.referenceNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withAlpha(128)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (submission.status != GovSubmissionStatus.confirmed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(GovSubmissionType type) {
    switch (type) {
      case GovSubmissionType.kraP10:
        return Colors.blue;
      case GovSubmissionType.shif:
        return Colors.green;
      case GovSubmissionType.nssf:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(GovSubmissionType type) {
    switch (type) {
      case GovSubmissionType.kraP10:
        return Icons.account_balance;
      case GovSubmissionType.shif:
        return Icons.health_and_safety;
      case GovSubmissionType.nssf:
        return Icons.security;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final GovSubmissionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case GovSubmissionStatus.generated:
        return Colors.blue;
      case GovSubmissionStatus.uploaded:
        return Colors.orange;
      case GovSubmissionStatus.confirmed:
        return Colors.green;
      case GovSubmissionStatus.error:
        return Colors.red;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
