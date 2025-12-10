import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/tax_submission_provider.dart';
import '../../data/models/tax_submission_model.dart';
import '../providers/tax_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/payroll_history_tab.dart';

class ComprehensiveTaxPage extends ConsumerStatefulWidget {
  const ComprehensiveTaxPage({super.key});

  @override
  ConsumerState<ComprehensiveTaxPage> createState() => _ComprehensiveTaxPageState();
}

class _ComprehensiveTaxPageState extends ConsumerState<ComprehensiveTaxPage> {
  int _currentIndex = 0;
  final _salaryController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tax Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildSubmissionsTab();
      case 1:
        return const PayrollHistoryTab();
      case 2:
        return _buildCalculatorTab();
      default:
        return _buildSubmissionsTab();
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'My Returns'),
          ),
          Expanded(
            child: _buildTabButton(1, 'History'),
          ),
          Expanded(
            child: _buildTabButton(2, 'Calculator'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final taxState = ref.watch(taxSubmissionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceCard(),
          const SizedBox(height: 20),
          _buildTaxCalendar(),
          const SizedBox(height: 20),
          _buildActionsSection(),
          const SizedBox(height: 24),
          _buildSubmissionsList(taxState),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaxCalculationCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEW: Tax Calendar Widget
  // ---------------------------------------------------------------------------
  Widget _buildTaxCalendar() {
    final now = DateTime.now();
    final deadlines = [
      {'day': 9, 'title': 'PAYE/NSSF', 'desc': 'Remittance Due'},
      {'day': 20, 'title': 'VAT/TOT', 'desc': 'Filing Deadline'},
      {'day': 30, 'title': 'Income Tax', 'desc': 'Installment Tax'},
    ];

    // Find next deadline
    Map<String, dynamic> nextDeadline = deadlines.first;
    for (var d in deadlines) {
      if (now.day <= (d['day'] as int)) {
        nextDeadline = d;
        break;
      }
    }
    
    // If all passed for this month, show first of next month (simplified visual)
    final deadlineDate = DateTime(now.year, now.month, nextDeadline['day'] as int);
    final daysLeft = deadlineDate.difference(now).inDays;
    final isUrgent = daysLeft <= 3 && daysLeft >= 0;

    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tax Calendar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isUrgent ? Colors.red[200]! : Colors.blue[200]!),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(now),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.red : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${nextDeadline['day']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(now).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Deadline: ${nextDeadline['title']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextDeadline['desc'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft == 0 
                        ? 'Due Today!' 
                        : (daysLeft < 0 ? 'Overdue' : '$daysLeft days remaining'),
                      style: TextStyle(
                        color: isUrgent ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Styles & Widgets
  // ---------------------------------------------------------------------------
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildComplianceCard() {
    final taxNotifier = ref.watch(taxNotifierProvider.notifier);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: taxNotifier.getComplianceStatus(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final kraPin = data['kraPin'] == true;
        final nssf = data['nssf'] == true;
        final shif = data['shif'] == true; // Assuming shif is mapped to nhif key or new key
        final housing = true; // Placeholder for now or fetch if available

        return Container(
          decoration: _buildCardDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Compliance Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildComplianceItem('KRA PIN', kraPin),
                  _buildComplianceItem('NSSF', nssf),
                  _buildComplianceItem('SHIF', shif),
                  _buildComplianceItem('Housing', housing),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplianceItem(String label, bool isCompliant) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompliant ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompliant ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              width: 2,
            ),
          ),
          child: Icon(
            isCompliant ? Icons.check : Icons.priority_high,
            color: isCompliant ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'File Return',
                Icons.file_upload_outlined,
                Colors.blue,
                () => _showNewSubmissionDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Calculate',
                Icons.calculate_outlined,
                Colors.green,
                () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'P9 Reports',
                Icons.description_outlined,
                Colors.orange,
                () => context.push('/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        shadowColor: color.withValues(alpha: 0.1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(AsyncValue<List<TaxSubmissionModel>> taxState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Returns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => ref.refresh(taxSubmissionProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        taxState.when(
          data: (submissions) {
            if (submissions.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: submissions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return _buildSubmissionCard(submission);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error loading returns: $error', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No tax returns yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'File your first return to see it here',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(TaxSubmissionModel submission) {
    final isFiled = submission.status == 'filed';
    final isPaid = submission.status == 'paid';
    final statusColor = (isFiled || isPaid) ? Colors.green : Colors.orange;
    
    return Container(
      decoration: _buildCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSubmissionDetails(submission),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFiled ? Icons.verified : (isPaid ? Icons.check_circle : Icons.pending_actions),
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${submission.taxYear} Tax Return',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Income: KES ${NumberFormat('#,##0').format(submission.income)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (submission.filingDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Filed: ${DateFormat('MMM d, y').format(submission.filingDate!)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${NumberFormat('#,##0').format(submission.taxDue)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        submission.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaxCalculationCard() {
    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calculate, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Income Tax Calculator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _salaryController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Annual Gross Income',
              prefixText: 'KES ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculateTax,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Calculate Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // LOGIC
  // ---------------------------------------------------------------------------
  
  void _calculateTax() async {
    final income = double.tryParse(_salaryController.text) ?? 0;
    if (income <= 0) {
      _showSnack('Please enter a valid income amount', isError: true);
      return;
    }

    try {
      final taxCalculation = await ref.read(taxSubmissionProvider.notifier).calculateTax(income, 0);
      
      // Constants for estimation
      final nssf = income * 0.06; 
      final shif = income * 0.0275; 
      final housingLevy = income * 0.015; 
      
      double taxDue = 0;
      double totalDeductions = nssf + shif + housingLevy;

      if (taxCalculation.isNotEmpty) {
        final submission = taxCalculation.first;
        taxDue = submission.taxDue;
        totalDeductions += submission.deductions;
      } else {
        // Fallback simplified
        taxDue = (income - totalDeductions) * 0.3;
      }
      
      if (!mounted) return;
      _showCalculationResult(income, nssf, shif, housingLevy, taxDue, totalDeductions);

    } catch (e) {
      _showSnack('Failed to calculate tax: $e', isError: true);
    }
  }

  void _showCalculationResult(
    double income, 
    double nssf, 
    double shif, 
    double housingLevy, 
    double taxDue, 
    double totalDeductions
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tax Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildResultRow('Gross Income', income, isBold: true),
            const Divider(height: 32),
            _buildResultRow('NSSF Contribution', nssf),
            _buildResultRow('SHIF (Health)', shif),
            _buildResultRow('Housing Levy', housingLevy),
            _buildResultRow('Total Deductions', totalDeductions, color: Colors.red),
            const Divider(height: 32),
            _buildResultRow('Taxable Income', income - totalDeductions),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Pay (Est)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    'KES ${NumberFormat('#,##0').format(income - totalDeductions - taxDue)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey[800],
          )),
          Text(
            'KES ${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetails(TaxSubmissionModel submission) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${submission.taxYear} Return', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailItem('Status', submission.status.toUpperCase()),
            _buildDetailItem('Annual Income', 'KES ${NumberFormat('#,##0').format(submission.income)}'),
            _buildDetailItem('Total Deductions', 'KES ${NumberFormat('#,##0').format(submission.deductions)}'),
            _buildDetailItem('Taxable Income', 'KES ${NumberFormat('#,##0').format(submission.taxableIncome)}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This marks the return as filed in PayKey. You must still file returns on the KRA iTax portal.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50], 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tax Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(
                    'KES ${NumberFormat('#,##0').format(submission.taxDue)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (submission.status != 'filed' && submission.status != 'paid')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentDialog(submission);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.payment),
                label: const Text('Pay via M-Pesa'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showPaymentDialog(TaxSubmissionModel submission) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pay Tax via M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: KES ${NumberFormat('#,##0').format(submission.taxDue)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '254...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              if (phoneController.text.isEmpty) return;
              Navigator.of(context).pop();
              _showSnack('Initiating payment request to ${phoneController.text}...');
              // Mock payment process
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) _showSnack('Payment request sent! Check your phone.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showNewSubmissionDialog() {
    final incomeController = TextEditingController();
    final deductionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Tax Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Annual Income (KES)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deductionsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Deductions (KES)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              final income = double.tryParse(incomeController.text) ?? 0;
              final deductions = double.tryParse(deductionsController.text) ?? 0;
              
              Navigator.of(context).pop();
              
              final newSubmission = TaxSubmissionModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current-user',
                taxYear: DateTime.now().year.toString(),
                income: income,
                deductions: deductions,
                taxableIncome: income - deductions,
                taxDue: (income - deductions) * 0.3,
                status: 'draft',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await ref.read(taxSubmissionProvider.notifier).submitTaxReturn(newSubmission);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit Return'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
