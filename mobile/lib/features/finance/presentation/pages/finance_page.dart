import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/utils/download_utils.dart';
import '../../widgets/funding_sources_section.dart';
import '../../../payroll/presentation/providers/pay_period_provider.dart';
import '../../../payroll/data/models/pay_period_model.dart';

/// Modern Finance page with premium dashboard design
class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedPayPeriodId;
  bool _isExporting = false;
  bool _showAccountMappings = false;

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
      final response = await ApiService().getAccountMappings();
      if (mounted && response.data['mappings'] != null) {
        final mappings = response.data['mappings']['mappings'] as List?;
        if (mappings != null) {
          for (var mapping in mappings) {
            final category = mapping['category'];
            if (_mappingControllers.containsKey(category)) {
              _mappingControllers[category]!.text = mapping['accountCode'];
            }
          }
        }
      }
    } catch (_) {
      // Use defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: _buildHeroHeader(payPeriodsAsync),
            ),

            // Funding Sources
            SliverToBoxAdapter(
              child: settingsAsync.when(
                data: (settings) => FundingSourcesSection(
                  isLoading: false,
                  data: FundingSourceData(
                    bankName: settings.bankName,
                    bankAccount: settings.bankAccount,
                    mpesaPhone: settings.mpesaPhone,
                    mpesaPaybill: settings.mpesaPaybill,
                    defaultPaymentMethod: settings.defaultPaymentMethod,
                    isDirectMPesa: (settings.mpesaPaybill == null || settings.mpesaPaybill!.isEmpty) && 
                                   (settings.mpesaPhone != null && settings.mpesaPhone!.isNotEmpty),
                  ),
                ),
                loading: () => const FundingSourcesSection(isLoading: true),
                error: (e, s) => const FundingSourcesSection(isLoading: false, error: 'Failed to load funding sources'),
              ),
            ),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: _buildQuickActionsGrid(context),
            ),

            // Financial Overview
            SliverToBoxAdapter(
              child: _buildFinancialOverview(payPeriodsAsync),
            ),

            // Quick Export Section
            SliverToBoxAdapter(
              child: _buildQuickExportCard(payPeriodsAsync),
            ),

            // Account Mappings
            SliverToBoxAdapter(
              child: _buildAccountMappingsCard(),
            ),

            // Integrations Coming Soon
            SliverToBoxAdapter(
              child: _buildIntegrationsCard(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats Row
            payPeriodsAsync.when(
              data: (periods) => _buildStatsRow(periods),
              loading: () => _buildStatsRowLoading(),
              error: (_, _) => _buildStatsRowLoading(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<PayPeriod> periods) {
    final completedPeriods = periods.where(
      (p) => p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed
    ).toList();
    
    final totalGross = completedPeriods.fold<double>(
      0, (sum, p) => sum + (p.totalGrossAmount ?? 0)
    );
    final totalDeductions = completedPeriods.fold<double>(
      0, (sum, p) => sum + (p.totalGrossAmount ?? 0) - (p.totalNetAmount ?? 0)
    );
    final totalNet = completedPeriods.fold<double>(
      0, (sum, p) => sum + (p.totalNetAmount ?? 0)
    );

    return Row(
      children: [
        Expanded(child: _buildStatItem(Icons.trending_up_rounded, _formatAmount(totalGross), 'Total Gross')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.receipt_long_rounded, _formatAmount(totalDeductions), 'Deductions')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.payments_rounded, _formatAmount(totalNet), 'Net Paid')),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return Row(
      children: [
        Expanded(child: _buildStatItem(Icons.trending_up_rounded, '--', 'Total Gross')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.receipt_long_rounded, '--', 'Deductions')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.payments_rounded, '--', 'Net Paid')),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.receipt_long_rounded,
              title: 'Tax Filing',
              subtitle: 'KRA submissions',
              gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
              onTap: () => context.push('/taxes'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.description_rounded,
              title: 'Reports',
              subtitle: 'Financial reports',
              gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              onTap: () => context.push('/reports'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Top Up',
              subtitle: 'Add funds',
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () => context.push('/finance/top-up'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    Text(
                      'This year\'s payroll allocation',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          payPeriodsAsync.when(
            data: (periods) => _buildBreakdownBars(periods),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text('Unable to load data'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBars(List<PayPeriod> periods) {
    final completedPeriods = periods.where(
      (p) => p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed
    ).toList();

    if (completedPeriods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF9CA3AF)),
            SizedBox(width: 12),
            Expanded(child: Text('Complete a pay period to see breakdown', style: TextStyle(color: Color(0xFF6B7280)))),
          ],
        ),
      );
    }

    final totalGross = completedPeriods.fold<double>(0, (sum, p) => sum + (p.totalGrossAmount ?? 0));
    final totalNet = completedPeriods.fold<double>(0, (sum, p) => sum + (p.totalNetAmount ?? 0));
    final totalDeductions = totalGross - totalNet;

    // Calculate percentages
    final netPercent = totalGross > 0 ? (totalNet / totalGross) : 0.0;
    final deductionsPercent = totalGross > 0 ? (totalDeductions / totalGross) : 0.0;

    return Column(
      children: [
        _buildProgressRow('Net Salaries', totalNet, netPercent, const Color(0xFF10B981)),
        const SizedBox(height: 12),
        _buildProgressRow('Tax & Deductions', totalDeductions, deductionsPercent, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildProgressRow(String label, double value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            Text(
              'KES ${_formatAmount(value)} (${(percent * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickExportCard(AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.file_download_rounded, color: Color(0xFF3B82F6), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export to Accounting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Download payroll CSV', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          payPeriodsAsync.when(
            data: (periods) {
              final completed = periods.where(
                (p) => p.status == PayPeriodStatus.completed || p.status == PayPeriodStatus.closed
              ).toList();

              if (completed.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('No completed periods to export', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPayPeriodId,
                    hint: const Text('Select pay period'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: completed.map((p) {
                      final start = DateFormat('MMM d').format(p.startDate);
                      final end = DateFormat('MMM d, y').format(p.endDate);
                      return DropdownMenuItem(value: p.id, child: Text('$start - $end'));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPayPeriodId = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportPayroll,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(_isExporting ? 'Exporting...' : 'Download CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountMappingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showAccountMappings = !_showAccountMappings),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_rounded, color: Color(0xFF8B5CF6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chart of Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Configure ledger mappings', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Icon(
                    _showAccountMappings ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  ..._mappingControllers.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: _getAccountName(e.key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetMappings,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reset Defaults'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveMappings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Save Mappings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _showAccountMappings ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF9CA3AF), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Integrations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Coming soon', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildIntegrationItem('QuickBooks Online', 'Automatic sync', Icons.sync_rounded, Colors.green),
          const SizedBox(height: 10),
          _buildIntegrationItem('Xero', 'Direct connection', Icons.link_rounded, Colors.blue),
          const SizedBox(height: 10),
          _buildIntegrationItem('Sage', 'Export support', Icons.upload_file_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildIntegrationItem(String name, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Soon', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _getAccountName(String category) {
    switch (category) {
      case 'SALARY_EXPENSE': return 'Salaries & Wages';
      case 'PAYE_LIABILITY': return 'PAYE Payable';
      case 'NSSF_LIABILITY': return 'NSSF Payable';
      case 'NHIF_LIABILITY': return 'NHIF Payable';
      case 'HOUSING_LEVY_LIABILITY': return 'Housing Levy';
      case 'CASH_BANK': return 'Cash at Bank';
      default: return category;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  void _resetMappings() {
    _mappingControllers['SALARY_EXPENSE']!.text = '6100';
    _mappingControllers['PAYE_LIABILITY']!.text = '2110';
    _mappingControllers['NSSF_LIABILITY']!.text = '2120';
    _mappingControllers['NHIF_LIABILITY']!.text = '2130';
    _mappingControllers['HOUSING_LEVY_LIABILITY']!.text = '2140';
    _mappingControllers['CASH_BANK']!.text = '1010';
    _showSnack('Reset to default values');
  }

  Future<void> _saveMappings() async {
    try {
      final mappings = _mappingControllers.entries.map((e) => {
        'category': e.key,
        'accountCode': e.value.text,
        'accountName': _getAccountName(e.key),
      }).toList();

      await ApiService().saveAccountMappings({'mappings': mappings});
      _showSnack('Account mappings saved');
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    }
  }

  Future<void> _exportPayroll() async {
    if (_selectedPayPeriodId == null) {
      _showSnack('Please select a pay period', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final response = await ApiService().exportPayrollToCSV(_selectedPayPeriodId!);
      final csvData = response.data['data'] as String;
      final filename = response.data['filename'] as String? ?? 'payroll_export.csv';

      // Convert CSV string to bytes and trigger download
      final bytes = utf8.encode(csvData);
      
      await DownloadUtils.downloadFile(
        filename: filename,
        bytes: bytes,
        mimeType: 'text/csv',
      );
      
      _showSnack('Downloaded: $filename');
    } catch (e) {
      _showSnack('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
}
