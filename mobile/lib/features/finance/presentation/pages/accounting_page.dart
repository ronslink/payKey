import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/download_helper.dart';
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
          for (var mapping in (_accountMappings!['mappings'] ?? [])) {
            final category = mapping['category'];
            if (_mappingControllers.containsKey(category)) {
              _mappingControllers[category]!.text = mapping['accountCode'];
            }
          }
        });
      }
    } catch (e) {
      // Use defaults
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
        _showSnack('Account mappings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to save mappings: $e', isError: true);
      }
    }
  }

  String _getAccountName(String category) {
    switch (category) {
      case 'SALARY_EXPENSE': return 'Salaries and Wages';
      case 'PAYE_LIABILITY': return 'PAYE Payable';
      case 'NSSF_LIABILITY': return 'NSSF Payable';
      case 'NHIF_LIABILITY': return 'NHIF Payable';
      case 'HOUSING_LEVY_LIABILITY': return 'Housing Levy Payable';
      case 'CASH_BANK': return 'Cash at Bank';
      default: return category;
    }
  }

  Future<void> _exportPayroll() async {
    if (_selectedPayPeriodId == null) {
      _showSnack('Please select a pay period', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final apiService = ApiService();
      final response = await apiService.exportPayrollToCSV(_selectedPayPeriodId!);
      final csvData = response.data['data'] as String;
      final filename = response.data['filename'] as String? ?? 'payroll_export.csv';

      // Convert CSV string to bytes and trigger download
      final bytes = utf8.encode(csvData);
      
      if (kIsWeb) {
        // Use web download helper
        downloadFileInBrowser(bytes, filename);
        if (mounted) {
          _showSnack('Downloaded: $filename');
        }
      } else {
        // For native platforms, save to documents
        if (mounted) {
          _showSnack('Exported: $filename');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Accounting Integration', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickExportSection(payPeriodsAsync),
            const SizedBox(height: 16),
            _buildAccountMappingsSection(),
            const SizedBox(height: 16),
            _buildIntegrationInfoSection(),
            const SizedBox(height: 32),
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
        decoration: _buildCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.file_download_outlined, color: Color(0xFF0891B2), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Export', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 4),
                      Text('Export payroll CSV for accounting', style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            payPeriodsAsync.when(
              data: (payPeriods) {
                final completedPeriods = payPeriods
                    .where((p) => p.status.toString().contains('COMPLETED') || p.status.toString().contains('CLOSED'))
                    .toList();

                if (completedPeriods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(child: Text('No completed pay periods available for export', style: TextStyle(color: Colors.brown))),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPayPeriodId,
                      hint: const Text('Select Period'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: completedPeriods.map((period) {
                        final startDate = DateFormat('MMM d').format(period.startDate);
                        final endDate = DateFormat('MMM d, y').format(period.endDate);
                        return DropdownMenuItem(value: period.id, child: Text('$startDate - $endDate'));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedPayPeriodId = value),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _exportPayroll,
                        icon: _isExporting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.download),
                        label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0891B2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading periods: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountMappingsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showMappings = !_showMappings),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chart of Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 4),
                      Text('Map usage to ledger codes', style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Icon(_showMappings ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (_showMappings) ...[
            const SizedBox(height: 24),
            ..._mappingControllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _getAccountName(entry.key),
                  helperText: entry.key.replaceAll('_', ' '),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),
            )),
            Row(
              children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {
                         _mappingControllers['SALARY_EXPENSE']!.text = '6100';
                         _mappingControllers['PAYE_LIABILITY']!.text = '2110';
                         _mappingControllers['NSSF_LIABILITY']!.text = '2120';
                         _mappingControllers['NHIF_LIABILITY']!.text = '2130';
                         _mappingControllers['HOUSING_LEVY_LIABILITY']!.text = '2140';
                         _mappingControllers['CASH_BANK']!.text = '1010';
                     },
                     style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                     child: const Text('Reset'),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: _saveAccountMappings,
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                     child: const Text('Save'),
                   ),
                 ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntegrationInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Coming Soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildComingSoonItem('QuickBooks Online', 'Direct sync', Icons.cloud_sync, Colors.green),
          const SizedBox(height: 12),
          _buildComingSoonItem('Xero', 'Automated billing', Icons.sync, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildComingSoonItem(String title, String desc, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }
}