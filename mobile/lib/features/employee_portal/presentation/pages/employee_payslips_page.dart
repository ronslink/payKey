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
  int _selectedYear = DateTime.now().year;
  Set<int> _availableYears = {};
  bool _isLoading = true;
  String? _error;
  List<EmployeePayslip>? _payslips;

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
      final profileResponse = await ApiService().employeePortal.getMyProfile();
      if (profileResponse.statusCode != 200) throw Exception('Failed to get profile');

      final profile = EmployeeProfile.fromJson(profileResponse.data);
      if (profile.workerId == null) throw Exception('Worker ID not found');

      final response = await ApiService().payroll.getPayslipsForWorker(profile.workerId!);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _payslips = data.map((e) => EmployeePayslip.fromJson(e)).toList();
          _payslips!.sort((a, b) => b.payDate.compareTo(a.payDate));
          
          // Extract available years
          _availableYears = _payslips!.map((p) => p.payDate.year).toSet();
          if (_availableYears.isEmpty) {
            _availableYears.add(DateTime.now().year);
          }
          // Ensure selected year is available
          if (!_availableYears.contains(_selectedYear) && _availableYears.isNotEmpty) {
            _selectedYear = _availableYears.first; // Default to most recent (sorted)
          }
          
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Payslips',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
            ElevatedButton(onPressed: _loadPayslips, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_payslips == null || _payslips!.isEmpty) {
      return _buildEmptyState();
    }

    // Filter payslips by selected year
    final filteredPayslips = _payslips!.where((p) => p.payDate.year == _selectedYear).toList();

    return Column(
      children: [
        _buildYearSelector(),
        Expanded(
          child: filteredPayslips.isEmpty
              ? _buildEmptyState(message: 'No payslips for $_selectedYear')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredPayslips.length,
                  itemBuilder: (context, index) => _buildPayslipCard(filteredPayslips[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({String message = 'No Payslips Found'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final years = _availableYears.toList()..sort((a, b) => b.compareTo(a));
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: years.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedYear;
          return ChoiceChip(
            label: Text(year.toString()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedYear = year);
            },
            selectedColor: const Color(0xFF6366F1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayslipCard(EmployeePayslip payslip) {
    final monthName = _getMonthAbbr(payslip.payDate);
    final day = payslip.payDate.day.toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showPayslipDetails(payslip),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date Box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthName,
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payslip.periodName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  Gross: ${_formatAmountSimplified(payslip.grossPay)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${_formatAmountSimplified(payslip.netPay)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }
  
  String _formatAmountSimplified(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
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
