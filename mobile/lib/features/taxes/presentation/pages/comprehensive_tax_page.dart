import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tax_submission_provider.dart';
import '../../data/models/monthly_tax_summary.dart';
import '../providers/tax_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/download_utils.dart';

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
        return _buildFilingTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildCalculatorTab();
      default:
        return _buildFilingTab();
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
            child: _buildTabButton(0, 'Filing'),
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

  // ==========================================================================
  // FILING TAB - Monthly tax filing workflow
  // ==========================================================================
  Widget _buildFilingTab() {
    final summariesAsync = ref.watch(monthlyTaxSummariesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceCard(),
          const SizedBox(height: 20),
          _buildTaxCalendar(),
          const SizedBox(height: 24),
          
          // Filing Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Returns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => ref.refresh(monthlyTaxSummariesProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Monthly Summaries List
          summariesAsync.when(
            data: (summaries) {
              if (summaries.isEmpty) {
                return _buildEmptyFilingState();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summaries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return _buildMonthlyFilingCard(summary);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error loading: $error', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilingState() {
    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tax submissions yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Process payroll to generate tax submissions',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFilingCard(MonthlyTaxSummary summary) {
    final isFiled = summary.status == 'FILED';
    final formatter = NumberFormat('#,##0.00');
    
    return Container(
      decoration: _buildCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.monthName} ${summary.year}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${summary.submissions.length} pay periods',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFiled 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFiled ? 'FILED' : 'PENDING',
                    style: TextStyle(
                      color: isFiled ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tax breakdown
            _buildTaxLine('PAYE', summary.totalPaye, formatter),
            _buildTaxLine('NSSF', summary.totalNssf, formatter),
            _buildTaxLine('SHIF', summary.totalNhif, formatter),
            _buildTaxLine('Housing Levy', summary.totalHousingLevy, formatter),
            const Divider(height: 20),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Tax', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'KES ${formatter.format(summary.totalTax)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDownloadOptions(summary),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!isFiled) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showMarkAsFiledDialog(summary),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark Filed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildTaxLine(String label, double amount, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text('KES ${formatter.format(amount)}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ==========================================================================
  // HISTORY TAB - Shows only filed returns
  // ==========================================================================
  Widget _buildHistoryTab() {
    final summariesAsync = ref.watch(monthlyTaxSummariesProvider);

    return summariesAsync.when(
      data: (summaries) {
        final filedSummaries = summaries.where((s) => s.status == 'FILED').toList();
        
        if (filedSummaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No filed returns yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your filed returns will appear here',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filedSummaries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final summary = filedSummaries[index];
            return _buildHistoryCard(summary);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildHistoryCard(MonthlyTaxSummary summary) {
    final formatter = NumberFormat('#,##0.00');
    
    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.monthName} ${summary.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: KES ${formatter.format(summary.totalTax)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'FILED',
              style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
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
        final shif = data['shif'] == true; // Replaced nhif with shif
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
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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



  // ==========================================================================
  // FILING DIALOGS
  // ==========================================================================
  void _showDownloadOptions(MonthlyTaxSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Download Tax Returns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${summary.monthName} ${summary.year}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildDownloadOption(
              'KRA P10 Return',
              'Submit to iTax portal',
              Icons.description_outlined,
              Colors.blue,
              () => _downloadStatutoryReturn('KRA_P10_CSV', summary),
            ),
            _buildDownloadOption(
              'NSSF Return',
              'Submit to NSSF self-service',
              Icons.table_chart_outlined,
              Colors.green,
              () => _downloadStatutoryReturn('NSSF_RETURN_EXCEL', summary),
            ),
            _buildDownloadOption(
              'SHIF Return',
              'Submit to SHA portal',
              Icons.health_and_safety_outlined,
              Colors.teal,
              () => _downloadStatutoryReturn('SHIF_RETURN_EXCEL', summary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.download, color: Colors.grey),
    );
  }

  Future<void> _downloadStatutoryReturn(String exportType, MonthlyTaxSummary summary) async {
    try {
      _showSnack('Generating ${exportType.replaceAll('_', ' ')}...');
      
      final bytes = await ref
          .read(monthlyTaxSummariesProvider.notifier)
          .downloadReturn(exportType, summary.year, summary.month);

      if (bytes.isEmpty) {
        throw Exception('Download failed: Empty file');
      }

      // Determine file extension based on export type
      String fileName = 'report_$exportType.csv';
      if (exportType.contains('EXCEL')) {
        fileName = 'report_$exportType.csv'; // Still CSV for Excel exports
      } else if (exportType.contains('CSV')) {
        fileName = 'report_$exportType.csv';
      }

      // Save the file using DownloadUtils
      await DownloadUtils.downloadFile(
        filename: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );

      _showSnack('Download complete!');
    } catch (e) {
      _showSnack('Error downloading: $e', isError: true);
    }
  }

  void _showMarkAsFiledDialog(MonthlyTaxSummary summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Filing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark ${summary.monthName} ${summary.year} returns as filed?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
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
                  Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ensure you have submitted all returns to the respective government portals.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFilingCheckItem('KRA P10 Return'),
            _buildFilingCheckItem('NSSF Return'),
            _buildFilingCheckItem('SHIF Return'),
            _buildFilingCheckItem('Housing Levy'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(monthlyTaxSummariesProvider.notifier)
                    .markMonthAsFiled(summary.year, summary.month);
                _showSnack('Returns marked as filed!');
              } catch (e) {
                _showSnack('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Filed'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilingCheckItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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
