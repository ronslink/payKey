import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workers_provider.dart';
import '../../data/models/worker_model.dart';

class WorkerDetailPage extends ConsumerStatefulWidget {
  final String workerId;

  const WorkerDetailPage({
    super.key,
    required this.workerId,
  });

  @override
  ConsumerState<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends ConsumerState<WorkerDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load worker details by refreshing the workers list and finding the specific worker
      ref.read(workersProvider.notifier).loadWorkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final worker = workersState.when(
      data: (workers) => workers.firstWhere(
        (w) => w.id == widget.workerId,
        orElse: () => throw Exception('Worker not found'),
      ),
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Worker Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          onPressed: () => context.go('/workers'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.push('/workers/${widget.workerId}/edit', extra: worker);
                  break;
                case 'terminate':
                  context.push('/workers/${widget.workerId}/terminate');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Edit Worker'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'terminate',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Terminate Worker'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: workersState.when(
        data: (workers) {
          try {
            final workerData = workers.firstWhere((w) => w.id == widget.workerId);
            return _buildWorkerDetailContent(workerData, context);
          } catch (e) {
            return _buildNotFoundState();
          }
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Loading worker details...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load worker details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.read(workersProvider.notifier).loadWorkers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerDetailContent(WorkerModel worker, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Header Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      worker.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (worker.jobTitle?.isNotEmpty == true)
                        Text(
                          worker.jobTitle!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: worker.isActive
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              worker.isActive ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: worker.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              worker.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 14,
                                color: worker.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact Information
          _buildDetailSection(
            'Contact Information',
            [
              _buildDetailRow('Phone Number', worker.phoneNumber, Icons.phone),
              if (worker.email?.isNotEmpty == true)
                _buildDetailRow('Email', worker.email!, Icons.email),
              if (worker.idNumber?.isNotEmpty == true)
                _buildDetailRow('ID Number', worker.idNumber!, Icons.credit_card),
            ],
          ),
          const SizedBox(height: 20),

          // Employment Details
          _buildDetailSection(
            'Employment Details',
            [
              _buildDetailRow('Employment Type', _formatEmploymentType(worker.employmentType), Icons.work),
              if (worker.jobTitle?.isNotEmpty == true)
                _buildDetailRow('Job Title', worker.jobTitle!, Icons.badge),
              _buildDetailRow('Payment Frequency', _formatPaymentFrequency(worker.paymentFrequency), Icons.schedule),
              _buildDetailRow('Payment Method', _formatPaymentMethod(worker.paymentMethod), Icons.payment),
              _buildDetailRow('Start Date', _formatDate(worker.startDate), Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 20),

          // Salary Information
          _buildDetailSection(
            'Salary Information',
            [
              _buildDetailRow('Gross Salary', 'KES ${worker.salaryGross.toStringAsFixed(0)}', Icons.attach_money),
              if (worker.housingAllowance > 0)
                _buildDetailRow('Housing Allowance', 'KES ${worker.housingAllowance.toStringAsFixed(0)}', Icons.home),
              if (worker.transportAllowance > 0)
                _buildDetailRow('Transport Allowance', 'KES ${worker.transportAllowance.toStringAsFixed(0)}', Icons.directions_car),
            ],
          ),
          const SizedBox(height: 20),

          // Tax Information
          if (worker.kraPin?.isNotEmpty == true ||
              worker.nssfNumber?.isNotEmpty == true ||
              worker.nhifNumber?.isNotEmpty == true)
            _buildDetailSection(
              'Tax Information',
              [
                if (worker.kraPin?.isNotEmpty == true)
                  _buildDetailRow('KRA PIN', worker.kraPin!, Icons.account_balance),
                if (worker.nssfNumber?.isNotEmpty == true)
                  _buildDetailRow('NSSF Number', worker.nssfNumber!, Icons.security),
                if (worker.nhifNumber?.isNotEmpty == true)
                  _buildDetailRow('NHIF Number', worker.nhifNumber!, Icons.health_and_safety),
              ],
            ),
          const SizedBox(height: 20),

          // Additional Information
          if (worker.notes?.isNotEmpty == true)
            _buildDetailSection(
              'Notes',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    worker.notes!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/workers/${worker.id}/edit', extra: worker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Worker'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: worker.isActive
                      ? () => context.push('/workers/${worker.id}/terminate')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Terminate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_off,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Worker Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This worker may have been deleted or you may not have permission to view their details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/workers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Back to Workers'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatEmploymentType(String employmentType) {
    switch (employmentType) {
      case 'FIXED':
        return 'Fixed Salary';
      case 'HOURLY':
        return 'Hourly Rate';
      default:
        return employmentType;
    }
  }

  String _formatPaymentFrequency(String paymentFrequency) {
    switch (paymentFrequency) {
      case 'MONTHLY':
        return 'Monthly';
      case 'WEEKLY':
        return 'Weekly';
      default:
        return paymentFrequency;
    }
  }

  String _formatPaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'MPESA':
        return 'M-Pesa';
      case 'BANK':
        return 'Bank Transfer';
      case 'CASH':
        return 'Cash';
      default:
        return paymentMethod;
    }
  }
}