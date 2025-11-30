import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/services/accounting_service.dart';
import '../../../payroll/presentation/providers/pay_period_provider.dart';

class AccountingPage extends ConsumerStatefulWidget {
  const AccountingPage({super.key});

  @override
  ConsumerState<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends ConsumerState<AccountingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedPayPeriodId;
  bool _isExporting = false;
  bool _showMappings = false;
  Map<String, dynamic>? _accountMappings;
  
  final Map<String, TextEditingController> _mappingControllers = {
    'SALARY_EXPENSE': TextEditingController(text: '6100'),
    'PAYE_LIABILITY': TextEditingController(text: '2110'),
    'NSSF_LIABILITY': TextEditingController(text: '2120'),
    'NHIF_LIABILITY': TextEditingController(text: '2130'),
    'HOUSING_LEVY_LIABILITY': TextEditingController(text: '2140'),
    'CASH_BANK': TextEditingController(text: '1010'),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadAccountMappings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _mappingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAccountMappings() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getAccountMappings();
      if (mounted && response.data['mappings'] != null) {
        setState(() {
          _accountMappings = response.data['mappings'];
          // Update controllers with loaded mappings
          for (var mapping in (_accountMappings!['mappings'] ?? [])) {
            final category = mapping['category'];
            if (_mappingControllers.containsKey(category)) {
              _mappingControllers[category]!.text = mapping['accountCode'];
            }
          }
        });
      }
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  Future<void> _saveAccountMappings() async {
    try {
      final apiService = ApiService();
      final mappings = _mappingControllers.entries.map((entry) => {
        'category': entry.key,
        'accountCode': entry.value.text,
        'accountName': _getAccountName(entry.key),
      }).toList();

      await apiService.saveAccountMappings({'mappings': mappings});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Account mappings saved successfully'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mappings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAccountName(String category) {
    switch (category) {
      case 'SALARY_EXPENSE':
        return 'Salaries and Wages';
      case 'PAYE_LIABILITY':
        return 'PAYE Payable';
      case 'NSSF_LIABILITY':
        return 'NSSF Payable';
      case 'NHIF_LIABILITY':
        return 'NHIF Payable';
      case 'HOUSING_LEVY_LIABILITY':
        return 'Housing Levy Payable';
      case 'CASH_BANK':
        return 'Cash at Bank';
      default:
        return category;
    }
  }

  Future<void> _exportPayroll() async {
    if (_selectedPayPeriodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pay period'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final apiService = ApiService();
      final response = await apiService.exportPayrollToCSV(_selectedPayPeriodId!);
      
      final filename = response.data['filename'] as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Exported: $filename')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Accounting Integration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickExportSection(payPeriodsAsync),
            const SizedBox(height: 24),
            _buildAccountMappingsSection(),
            const SizedBox(height: 24),
            _buildIntegrationInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportSection(AsyncValue payPeriodsAsync) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Export',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Export payroll to CSV format',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            payPeriodsAsync.when(
              data: (payPeriods) {
                final completedPeriods = payPeriods
                    .where((p) => p.status.toString().contains('COMPLETED') || 
                                  p.status.toString().contains('CLOSED'))
                    .toList();

                if (completedPeriods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No completed pay periods available for export',
                            style: TextStyle(color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Pay Period',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPayPeriodId,
                      decoration: InputDecoration(
                        hintText: 'Choose a pay period to export',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      items: completedPeriods.map((period) {
                        final startDate = DateFormat('MMM d').format(period.startDate);
                        final endDate = DateFormat('MMM d, y').format(period.endDate);
                        return DropdownMenuItem(
                          value: period.id,
                          child: Text('$startDate - $endDate'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPayPeriodId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportPayroll,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(_isExporting ? 'Exporting...' : 'Export to CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _selectedPayPeriodId == null
                              ? null
                              : () {
                                  context.push('/payroll/review/$_selectedPayPeriodId');
                                },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Preview'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountMappingsSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      )),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Mappings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure your chart of accounts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showMappings ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () {
                    setState(() => _showMappings = !_showMappings);
                  },
                ),
              ],
            ),
            if (_showMappings) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              ..._mappingControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAccountName(entry.key),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Text(
                              entry.key.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: 'Account Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset to defaults
                        _mappingControllers['SALARY_EXPENSE']!.text = '6100';
                        _mappingControllers['PAYE_LIABILITY']!.text = '2110';
                        _mappingControllers['NSSF_LIABILITY']!.text = '2120';
                        _mappingControllers['NHIF_LIABILITY']!.text = '2130';
                        _mappingControllers['HOUSING_LEVY_LIABILITY']!.text = '2140';
                        _mappingControllers['CASH_BANK']!.text = '1010';
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reset to Defaults'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAccountMappings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save Mappings'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationInfoSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      )),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF06B6D4).withOpacity(0.1),
              const Color(0xFF0891B2).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF06B6D4).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF06B6D4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Supported Formats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormatItem(
              'CSV (Excel Compatible)',
              'Compatible with Excel and most accounting software',
              Icons.check_circle,
              const Color(0xFF10B981),
              true,
            ),
            const SizedBox(height: 12),
            _buildFormatItem(
              'QuickBooks Online',
              'Direct integration coming soon',
              Icons.schedule,
              const Color(0xFF6B7280),
              false,
            ),
            const SizedBox(height: 12),
            _buildFormatItem(
              'Xero',
              'Direct integration coming soon',
              Icons.schedule,
              const Color(0xFF6B7280),
              false,
            ),
            const SizedBox(height: 12),
            _buildFormatItem(
              'Sage',
              'Sage-compatible format coming soon',
              Icons.schedule,
              const Color(0xFF6B7280),
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatItem(
    String title,
    String description,
    IconData icon,
    Color color,
    bool available,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: available ? const Color(0xFF111827) : const Color(0xFF6B7280),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        if (available)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ),
      ],
    );
  }
}