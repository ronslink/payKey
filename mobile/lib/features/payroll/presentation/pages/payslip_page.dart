import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PayslipPage extends ConsumerWidget {
  final String payslipId;

  const PayslipPage({super.key, required this.payslipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch payslip details using payslipId
    // For now, we'll use mock data
    final mockPayslip = {
      'period': 'October 2023',
      'employee': 'Jane Doe',
      'basicSalary': 25000.0,
      'allowances': 5000.0,
      'grossPay': 30000.0,
      'nssf': 1080.0,
      'nhif': 900.0,
      'paye': 4500.0,
      'netPay': 23520.0,
    };

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading PDF...')),
              );
            },
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
                    color: Colors.black .withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    mockPayslip['employee'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mockPayslip['period'] as String,
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
                        'KES ${(mockPayslip['netPay'] as double).toStringAsFixed(2)}',
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
                    color: Colors.black .withValues(alpha: 0.05),
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
                  _buildRow('Basic Salary', mockPayslip['basicSalary'] as double),
                  _buildRow('Allowances', mockPayslip['allowances'] as double),
                  const Divider(height: 32),
                  _buildRow('Gross Pay', mockPayslip['grossPay'] as double, isBold: true),
                  
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
                  _buildRow('NSSF', mockPayslip['nssf'] as double),
                  _buildRow('NHIF', mockPayslip['nhif'] as double),
                  _buildRow('PAYE', mockPayslip['paye'] as double),
                  const Divider(height: 32),
                  _buildRow(
                    'Total Deductions', 
                    ((mockPayslip['nssf'] as double) + (mockPayslip['nhif'] as double) + (mockPayslip['paye'] as double)), 
                    isBold: true
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
