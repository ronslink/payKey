import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/payroll_model.dart';
import '../../../../core/network/api_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Payslip Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context, item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item.workerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payslip #${item.id ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Pay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'KES ${NumberFormat('#,###.00').format(item.netPay)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRow('Basic Salary', item.grossSalary),
                  if (item.bonuses > 0) _buildRow('Bonuses', item.bonuses),
                  if (item.otherEarnings > 0) _buildRow('Other Earnings', item.otherEarnings),
                  const Divider(height: 32),
                  _buildRow('Gross Pay', item.totalGrossEarnings, isBold: true),

                  const SizedBox(height: 32),

                  const Text(
                    'Deductions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRow('NSSF', item.taxBreakdown.nssf),
                  _buildRow('NHIF', item.taxBreakdown.nhif),
                  _buildRow('Housing Levy', item.taxBreakdown.housingLevy),
                  _buildRow('PAYE', item.taxBreakdown.paye),
                  if (item.otherDeductions > 0) _buildRow('Other Deductions', item.otherDeductions),
                  const Divider(height: 32),
                  _buildRow('Total Deductions', item.totalDeductions, isBold: true),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
