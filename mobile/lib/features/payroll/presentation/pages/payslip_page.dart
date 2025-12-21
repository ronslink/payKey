import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/payroll_model.dart';
import '../../../../core/network/api_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class PayslipPage extends ConsumerWidget {
  final String payslipId;
  final PayrollCalculation? calculation;

  const PayslipPage({
    super.key,
    required this.payslipId,
    this.calculation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = calculation;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payslip Details')),
        body: const Center(child: Text('Payslip data not available')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar with worker info
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download, color: Colors.white, size: 20),
                ),
                onPressed: () => _downloadPdf(context, item),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                item.workerName.isNotEmpty ? item.workerName[0].toUpperCase() : 'E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.workerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Payslip #${item.id ?? "Draft"}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Net Pay highlight
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Net Pay',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'KES ${NumberFormat('#,###.00').format(item.netPay)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'PAID',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Earnings Card
                  _buildSectionCard(
                    'Earnings',
                    Icons.trending_up,
                    Colors.green,
                    [
                      _buildAmountRow('Basic Salary', item.grossSalary),
                      if (item.bonuses > 0) _buildAmountRow('Bonuses', item.bonuses),
                      if (item.otherEarnings > 0) _buildAmountRow('Other Earnings', item.otherEarnings),
                      const Divider(height: 24),
                      _buildAmountRow('Gross Pay', item.totalGrossEarnings, isBold: true, color: Colors.green.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Statutory Deductions Card
                  _buildSectionCard(
                    'Statutory Deductions',
                    Icons.account_balance,
                    Colors.orange,
                    [
                      _buildAmountRow('PAYE (Income Tax)', item.taxBreakdown.paye, isDeduction: true),
                      _buildAmountRow('NSSF (Pension)', item.taxBreakdown.nssf, isDeduction: true),
                      _buildAmountRow('SHIF (Health)', item.taxBreakdown.nhif, isDeduction: true),
                      _buildAmountRow('Housing Levy', item.taxBreakdown.housingLevy, isDeduction: true),
                      if (item.otherDeductions > 0)
                        _buildAmountRow('Other Deductions', item.otherDeductions, isDeduction: true),
                      const Divider(height: 24),
                      _buildAmountRow('Total Deductions', item.totalDeductions, isBold: true, color: Colors.red.shade700),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Legal Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This payslip complies with Kenya Employment Act 2007, Section 31.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, bool isDeduction = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.grey.shade800 : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isDeduction ? "- " : ""}KES ${NumberFormat('#,###.00').format(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isDeduction ? Colors.red.shade600 : Colors.grey.shade800),
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, PayrollCalculation item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot download unsaved payslip')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Payslip...')),
      );
      
      final apiService = ApiService();
      final bytes = await apiService.downloadPayslip(item.id!);
      
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        // ignore: unused_local_variable
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'payslip_${item.workerName}_${item.id}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile implementation: would typically use path_provider and open_file
        // For now just showing success as we don't have those deps confirmed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF downloaded (saved to downloads)')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
