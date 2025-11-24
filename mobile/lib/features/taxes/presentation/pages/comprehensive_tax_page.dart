import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tax_provider.dart';
import '../../data/models/tax_submission_model.dart';

class ComprehensiveTaxPage extends ConsumerStatefulWidget {
  const ComprehensiveTaxPage({super.key});

  @override
  ConsumerState<ComprehensiveTaxPage> createState() => _ComprehensiveTaxPageState();
}

class _ComprehensiveTaxPageState extends ConsumerState<ComprehensiveTaxPage> {
  int _currentIndex = 0;
  final _salaryController = TextEditingController();
  late Future<Map<String, dynamic>> _complianceFuture;

  @override
  void initState() {
    super.initState();
    _complianceFuture = ref.read(taxNotifierProvider.notifier).getComplianceStatus();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tax Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildComplianceOverview(),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Calculator', 0),
          ),
          Expanded(
            child: _buildTab('Submissions', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return _currentIndex == 0 ? _buildCalculatorTab() : _buildSubmissionsTab();
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tax Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gross Salary (KES)',
                    border: OutlineInputBorder(),
                    prefixText: 'KES ',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _calculateTax,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Calculate Tax'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final taxState = ref.watch(taxNotifierProvider);

    return taxState.when(
      data: (submissions) => _buildSubmissionsList(submissions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSubmissionsList(List<TaxSubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Tax Submissions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your tax submissions will appear here',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(TaxSubmissionModel submission) {
    final statusColor = submission.status == 'filed'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    
    final taxPeriod = DateFormat('MMM yyyy').format(submission.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tax Submission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submission.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                'Period: $taxPeriod',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                'Amount: KES ${NumberFormat('#,##0.00').format(submission.totalTax)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (submission.status != 'filed') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _markAsFiled(submission.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Filed'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load tax data',
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(taxNotifierProvider.notifier).loadSubmissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateTax() async {
    final salary = double.tryParse(_salaryController.text);
    if (salary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid salary amount'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final taxBreakdown = await ref.read(taxNotifierProvider.notifier).calculateTax(salary);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tax Calculation Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gross Salary: KES ${NumberFormat('#,##0').format(salary)}'),
              const SizedBox(height: 16),
              const Text(
                'Tax Breakdown:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...taxBreakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${entry.key}: KES ${NumberFormat('#,##0.00').format(entry.value)}'),
              )),
              const Divider(),
              Text(
                'Total Tax: KES ${NumberFormat('#,##0.00').format(taxBreakdown.values.reduce((a, b) => a + b))}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate tax: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _markAsFiled(String submissionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Filed'),
        content: const Text(
          'Have you filed this tax submission with KRA?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Mark as Filed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(taxNotifierProvider.notifier).markAsFiled(submissionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marked as filed successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as filed: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Widget _buildComplianceOverview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _complianceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Failed to load compliance status', style: TextStyle(color: Colors.red)),
          );
        }

        final complianceStatus = snapshot.data ?? {
          'kraPin': false,
          'nssf': false,
          'nhif': false,
        };

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compliance Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildComplianceItem('KRA PIN', complianceStatus['kraPin'] == true),
                  const SizedBox(width: 12),
                  _buildComplianceItem('NSSF', complianceStatus['nssf'] == true),
                  const SizedBox(width: 12),
                  _buildComplianceItem('NHIF', complianceStatus['nhif'] == true),
                ],
              ),
              const SizedBox(height: 16),
              _buildDeadlineCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplianceItem(String label, bool isCompliant) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isCompliant ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompliant ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isCompliant ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isCompliant ? const Color(0xFF059669) : const Color(0xFFB91C1C),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCompliant ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(taxNotifierProvider.notifier).getTaxDeadlines(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final nextDeadline = snapshot.data!.first;
        final date = DateTime.parse(nextDeadline['dueDate']);
        final formattedDate = DateFormat('MMM dd, yyyy').format(date);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming: ${nextDeadline['title']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      'Due by $formattedDate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tax Calendar'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final item = snapshot.data![index];
                            final itemDate = DateTime.parse(item['dueDate']);
                            return ListTile(
                              leading: const Icon(Icons.event, color: Color(0xFF3B82F6)),
                              title: Text(item['title']),
                              subtitle: Text(item['description']),
                              trailing: Text(
                                DateFormat('MMM dd').format(itemDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        );
      },
    );
  }
}