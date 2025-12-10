import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';

import '../../data/models/employee_models.dart';

/// Page showing employee's payslips
class EmployeePayslipsPage extends ConsumerStatefulWidget {
  const EmployeePayslipsPage({super.key});

  @override
  ConsumerState<EmployeePayslipsPage> createState() => _EmployeePayslipsPageState();
}

class _EmployeePayslipsPageState extends ConsumerState<EmployeePayslipsPage> {
  List<EmployeePayslip>? _payslips;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayslips();
  }

  Future<void> _loadPayslips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get profile first to get workerId
      final profileResponse = await ApiService().employeePortal.getMyProfile();
      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to get profile');
      }

      final profile = EmployeeProfile.fromJson(profileResponse.data);
      if (profile.workerId == null) {
        throw Exception('Worker ID not found');
      }

      // Get payslips for this worker
      final response = await ApiService().payroll.getPayslipsForWorker(profile.workerId!);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _payslips = data.map((e) => EmployeePayslip.fromJson(e)).toList();
          _payslips!.sort((a, b) => b.payDate.compareTo(a.payDate));
          _isLoading = false;
        });
      } else {
        setState(() {
          _payslips = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Payslips',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: _loadPayslips,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPayslips,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_payslips == null || _payslips!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Payslips Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payslips will appear here after payroll is processed',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayslips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payslips!.length,
        itemBuilder: (context, index) => _buildPayslipCard(_payslips![index]),
      ),
    );
  }

  Widget _buildPayslipCard(EmployeePayslip payslip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPayslipDetails(payslip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payslip.periodName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PAID',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Pay',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KES ${_formatAmount(payslip.netPay)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pay Date',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(payslip.payDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Gross', payslip.grossPay),
                  _buildStatItem('Deductions', payslip.totalDeductions, isDeduction: true),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF6366F1)),
                    onPressed: () => _showPayslipDetails(payslip),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, {bool isDeduction = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        Text(
          '${isDeduction ? '-' : ''}KES ${_formatAmount(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDeduction ? Colors.red : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _showPayslipDetails(EmployeePayslip payslip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payslip.periodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Color(0xFF6366F1)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download feature coming soon')),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  'Pay Date: ${_formatDate(payslip.payDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                
                // Earnings
                _buildSectionHeader('Earnings'),
                _buildDetailRow('Basic Salary', payslip.basicSalary),
                if (payslip.allowances > 0)
                  _buildDetailRow('Allowances', payslip.allowances),
                if (payslip.overtime > 0)
                  _buildDetailRow('Overtime', payslip.overtime),
                _buildDetailRow('Gross Pay', payslip.grossPay, isBold: true),
                
                const SizedBox(height: 16),
                
                // Deductions
                _buildSectionHeader('Deductions'),
                _buildDetailRow('PAYE', payslip.paye, isDeduction: true),
                _buildDetailRow('NHIF', payslip.nhif, isDeduction: true),
                _buildDetailRow('NSSF', payslip.nssf, isDeduction: true),
                if (payslip.housingLevy > 0)
                  _buildDetailRow('Housing Levy', payslip.housingLevy, isDeduction: true),
                _buildDetailRow('Total Deductions', payslip.totalDeductions, isDeduction: true, isBold: true),
                
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Pay',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'KES ${_formatAmount(payslip.netPay)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, {bool isDeduction = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isDeduction ? '-' : ''}KES ${_formatAmount(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isDeduction ? Colors.red : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
