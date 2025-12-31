import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/tax_provider.dart';
import '../../../workers/presentation/providers/workers_provider.dart';

/// Tax Management page with the new design
class TaxPageNew extends ConsumerWidget {
  const TaxPageNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxSubmissionsAsync = ref.watch(payrollTaxSubmissionsProvider);
    final summariesAsync = ref.watch(monthlyTaxSummariesProvider);
    final workersAsync = ref.watch(workersProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tax Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compliance card
            _buildComplianceCard(context, workersAsync, now),
            
            // Quick actions
            _buildQuickActions(context),
            
            // Statutory breakdown
            _buildStatutorySection(context, summariesAsync),
            
            // Upcoming deadlines
            _buildDeadlinesSection(context, now),
            
            // Recent submissions
            _buildSubmissionsSection(context, taxSubmissionsAsync),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard(
    BuildContext context, 
    AsyncValue<List<dynamic>> workersAsync,
    DateTime now,
  ) {
    final formatter = NumberFormat('#,###');
    
    // Calculate compliance status from workers
    final workers = workersAsync.when(
      data: (w) => w,
      loading: () => <dynamic>[],
      error: (_, _) => <dynamic>[],
    );
    
    final totalWorkers = workers.length;
    final compliantWorkers = workers.where((w) => w.kraPin != null).length;
    final compliancePercent = totalWorkers > 0 ? compliantWorkers / totalWorkers : 0.0;
    
    // Calculate upcoming tax due (20th of next month)
    DateTime nextDue = DateTime(now.year, now.month + 1, 20);
    if (now.day > 20) {
      nextDue = DateTime(now.year, now.month + 2, 20);
    }
    final daysUntilDue = nextDue.difference(now).inDays;

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance Health',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        compliancePercent >= 1.0 ? Icons.check_circle : Icons.warning_amber,
                        color: compliancePercent >= 1.0 ? Colors.white : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        compliancePercent >= 1.0 
                          ? 'Excellent' 
                          : compliancePercent >= 0.7 
                            ? 'Good' 
                            : 'Needs Attention',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$compliantWorkers/$totalWorkers KRA Verified',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total Tax Payable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KES ${formatter.format(0)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Next due: ${DateFormat('MMM d, yyyy').format(nextDue)} ($daysUntilDue days)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/taxes/filing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('File Tax Returns'),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context, 
              Icons.description_outlined, 
              'Generate P9', 
              () => context.push('/reports/p9'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context, 
              Icons.send_outlined, 
              'File Returns', 
              () => context.push('/taxes/filing'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context, 
              Icons.upload_file_outlined, 
              'Upload\nReceipt', 
              () => context.push('/taxes/upload'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutorySection(BuildContext context, AsyncValue<List<dynamic>> summariesAsync) {
    final formatter = NumberFormat('#,###');
    
    // Calculate totals from summaries
    final summaries = summariesAsync.when(
      data: (s) => s,
      loading: () => <dynamic>[],
      error: (_, _) => <dynamic>[],
    );
    
    double totalPaye = 0;
    double totalNssf = 0;
    double totalNhif = 0;
    double totalHousingLevy = 0;
    
    for (final summary in summaries) {
      totalPaye += summary.payeAmount ?? 0;
      totalNssf += summary.nssfAmount ?? 0;
      totalNhif += summary.nhifAmount ?? 0;
      totalHousingLevy += summary.housingLevyAmount ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statutory Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/reports'), child: const Text('See All')),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildTaxCard(
                context, 
                Icons.account_balance, 
                'PAYE (Income Tax)', 
                'KES ${formatter.format(totalPaye)}', 
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildTaxCard(
                context, 
                Icons.security, 
                'NSSF (Tier I)', 
                'KES ${formatter.format(totalNssf)}', 
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildTaxCard(
                context, 
                Icons.health_and_safety, 
                'SHIF', 
                'KES ${formatter.format(totalNhif)}', 
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildTaxCard(
                context, 
                Icons.home_outlined, 
                'Housing Levy', 
                'KES ${formatter.format(totalHousingLevy)}', 
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxCard(BuildContext context, IconData icon, String title, String amount, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            title, 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            amount, 
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesSection(BuildContext context, DateTime now) {
    final formatter = DateFormat('MMM');
    
    // Calculate upcoming deadlines
    final payeDue = DateTime(now.year, now.month, 20);
    final nssfDue = DateTime(now.year, now.month, 15);
    final nhifDue = DateTime(now.year, now.month, 10);
    
    final payeDays = payeDue.difference(now).inDays;
    final nssfDays = nssfDue.difference(now).inDays;
    final nhifDays = nhifDue.difference(now).inDays;
    
    final payeStatus = payeDays <= 0 ? 'Overdue' : payeDays <= 5 ? 'Due Soon' : 'Upcoming';
    final payeColor = payeDays <= 0 ? Colors.red : payeDays <= 5 ? Colors.orange : Colors.blue;
    
    final nssfStatus = nssfDays <= 0 ? 'Overdue' : nssfDays <= 5 ? 'Due Soon' : 'Upcoming';
    final nssfColor = nssfDays <= 0 ? Colors.red : nssfDays <= 5 ? Colors.orange : Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Deadlines', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/taxes/calendar'), child: const Text('View Calendar')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildDeadlineRow(
                context, 
                formatter.format(payeDue), 
                '${payeDue.day}', 
                'PAYE Returns', 
                'Submit via KRA iTax Portal',
                payeStatus,
                payeColor,
              ),
              const SizedBox(height: 12),
              _buildDeadlineRow(
                context, 
                formatter.format(nssfDue), 
                '${nssfDue.day}', 
                'NSSF Contribution', 
                'Direct Bank Transfer',
                nssfStatus,
                nssfColor,
              ),
              const SizedBox(height: 12),
              _buildDeadlineRow(
                context, 
                formatter.format(nhifDue), 
                '${nhifDue.day}', 
                'SHIF Payment', 
                'Via SHA self-service portal',
                nhifDays <= 0 ? 'Overdue' : nhifDays <= 5 ? 'Due Soon' : 'Upcoming',
                nhifDays <= 0 ? Colors.red : nhifDays <= 5 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineRow(
    BuildContext context, 
    String month, 
    String day, 
    String title, 
    String subtitle, 
    String status, 
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month, 
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day, 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: statusColor, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle, 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status, 
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsSection(BuildContext context, AsyncValue<List<dynamic>> submissionsAsync) {
    final submissions = submissionsAsync.when(
      data: (s) => s,
      loading: () => <dynamic>[],
      error: (_, _) => <dynamic>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Submissions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => context.push('/taxes/history'),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View All'),
              ),
            ],
          ),
        ),
        submissions.isEmpty
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No tax submissions yet'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/taxes/filing'),
                      icon: const Icon(Icons.send),
                      label: const Text('File First Return'),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: submissions.take(3).map((submission) {
                    return _buildDocumentRow(
                      context,
                      Icons.check_circle,
                      Colors.green,
                      submission['type'] ?? 'Tax Return',
                      'Submitted ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                      'Filed',
                      Colors.green,
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, 
    IconData icon, 
    Color iconColor, 
    String title, 
    String subtitle, 
    String status, 
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle, 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status, 
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
