import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../subscriptions/presentation/providers/feature_access_provider.dart';
import '../../../../core/utils/download_utils.dart';
import '../../../../core/widgets/responsive_card_grid.dart';
import '../../widgets/finance_quick_actions.dart';
import '../../widgets/funding_sources_section.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
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
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(child: _buildHeroHeader(payPeriodsAsync)),

            // Funding Sources
            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) => settingsAsync.when(
                  data: (settings) => FundingSourcesSection(
                    isLoading: false,
                    data: FundingSourceData(
                      bankName: profile.bankName,
                      bankAccount: profile.bankAccount,
                      mpesaPhone: profile.mpesaPhone,
                      mpesaPaybill: profile.mpesaPaybill,
                      defaultPaymentMethod: settings.defaultPaymentMethod,
                      isDirectMPesa:
                          (profile.mpesaPaybill == null ||
                              profile.mpesaPaybill!.isEmpty) &&
                          (profile.mpesaPhone != null &&
                              profile.mpesaPhone!.isNotEmpty),
                    ),
                  ),
                  loading: () => const FundingSourcesSection(isLoading: true),
                  error: (_, __) => const FundingSourcesSection(
                    isLoading: false,
                  ), // Fallback to defaults
                ),
                loading: () => const FundingSourcesSection(isLoading: true),
                error: (e, s) => const FundingSourcesSection(
                  isLoading: false,
                  error: 'Failed to load profile',
                ),
              ),
            ),

            // Quick Actions Grid
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: FinanceQuickActions(
                onNavigate: (route) => context.push(route),
              ),
            ),

            // Financial Overview
            SliverToBoxAdapter(child: _buildFinancialOverview(payPeriodsAsync)),

            // Quick Export Section
            SliverToBoxAdapter(child: _buildQuickExportCard(payPeriodsAsync)),

            // Account Mappings
            SliverToBoxAdapter(child: _buildAccountMappingsCard()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            colors: [Color(0xFF0E7490), Color(0xFF155E75)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finance',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
    final completedPeriods = periods
        .where(
          (p) =>
              p.status == PayPeriodStatus.completed ||
              p.status == PayPeriodStatus.closed,
        )
        .toList();

    final totalGross = completedPeriods.fold<double>(
      0,
      (sum, p) => sum + (p.totalGrossAmount ?? 0),
    );
    final totalDeductions = completedPeriods.fold<double>(
      0,
      (sum, p) => sum + (p.totalGrossAmount ?? 0) - (p.totalNetAmount ?? 0),
    );
    final totalNet = completedPeriods.fold<double>(
      0,
      (sum, p) => sum + (p.totalNetAmount ?? 0),
    );

    return ResponsiveCardGrid(
      minColumnWidth: 92,
      children: [
        _buildStatItem(
          Icons.trending_up_rounded,
          _formatAmount(totalGross),
          'Total Gross',
        ),
        _buildStatItem(
          Icons.receipt_long_rounded,
          _formatAmount(totalDeductions),
          'Deductions',
        ),
        _buildStatItem(
          Icons.payments_rounded,
          _formatAmount(totalNet),
          'Net Paid',
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return ResponsiveCardGrid(
      minColumnWidth: 92,
      children: [
        _buildStatItem(Icons.trending_up_rounded, '--', 'Total Gross'),
        _buildStatItem(Icons.receipt_long_rounded, '--', 'Deductions'),
        _buildStatItem(Icons.payments_rounded, '--', 'Net Paid'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(AsyncValue<List<PayPeriod>> payPeriodsAsync) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
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
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'This year\'s payroll allocation',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
    final completedPeriods = periods
        .where(
          (p) =>
              p.status == PayPeriodStatus.completed ||
              p.status == PayPeriodStatus.closed,
        )
        .toList();

    if (completedPeriods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete a pay period to see breakdown',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalGross = completedPeriods.fold<double>(
      0,
      (sum, p) => sum + (p.totalGrossAmount ?? 0),
    );
    final totalNet = completedPeriods.fold<double>(
      0,
      (sum, p) => sum + (p.totalNetAmount ?? 0),
    );
    final totalDeductions = totalGross - totalNet;

    // Calculate percentages
    final netPercent = totalGross > 0 ? (totalNet / totalGross) : 0.0;
    final deductionsPercent = totalGross > 0
        ? (totalDeductions / totalGross)
        : 0.0;

    return Column(
      children: [
        _buildProgressRow(
          'Net Salaries',
          totalNet,
          netPercent,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildProgressRow(
          'Tax & Deductions',
          totalDeductions,
          deductionsPercent,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildProgressRow(
    String label,
    double value,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              'KES ${_formatAmount(value)} (${(percent * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
    // Check feature access
    final featureAccess = ref.watch(
      featureAccessProvider('accounting_integration'),
    );

    return featureAccess.when(
      data: (access) => _buildExportCardContent(payPeriodsAsync, access),
      loading: () =>
          _buildExportCardContent(payPeriodsAsync, FeatureAccessResult.full()),
      error: (_, __) =>
          _buildExportCardContent(payPeriodsAsync, FeatureAccessResult.full()),
    );
  }

  Widget _buildExportCardContent(
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
    FeatureAccessResult access,
  ) {
    final isPreview = access.isPreview;
    final hasAccess = access.hasAccess;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
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
                child: const Icon(
                  Icons.file_download_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export to Accounting',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Download payroll CSV',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Feature access indicator
              if (isPreview)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Preview notice banner
          if (isPreview)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      access.mockNotice ??
                          'This is sample data. Your real data is available on a paid plan.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Show export UI only if feature is accessible and not in preview mode
          if (hasAccess && !isPreview) ...[
            const SizedBox(height: 16),
            _buildExportPeriodDropdown(payPeriodsAsync),
          ],
        ],
      ),
    );
  }

  Widget _buildExportPeriodDropdown(
    AsyncValue<List<PayPeriod>> payPeriodsAsync,
  ) {
    return payPeriodsAsync.when(
      data: (periods) {
        final completed = periods
            .where(
              (p) =>
                  p.status == PayPeriodStatus.completed ||
                  p.status == PayPeriodStatus.closed,
            )
            .toList();

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
                Expanded(
                  child: Text(
                    'No completed periods to export',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedPayPeriodId,
              hint: const Text('Select pay period'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: completed.map((p) {
                final start = DateFormat('MMM d').format(p.startDate);
                final end = DateFormat('MMM d, y').format(p.endDate);
                return DropdownMenuItem(
                  value: p.id,
                  child: Text('$start - $end'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPayPeriodId = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportPayroll,
                icon: _isExporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(_isExporting ? 'Exporting...' : 'Download CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error loading periods'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountMappingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showAccountMappings = !_showAccountMappings),
            borderRadius: BorderRadius.circular(16),
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
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chart of Accounts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Configure ledger mappings',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAccountMappings
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ..._mappingControllers.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(
                          labelText: _getAccountName(e.key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetMappings,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reset Defaults'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveMappings,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
            crossFadeState: _showAccountMappings
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color:
          Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
    );
  }

  String _getAccountName(String category) {
    switch (category) {
      case 'SALARY_EXPENSE':
        return 'Salaries & Wages';
      case 'PAYE_LIABILITY':
        return 'PAYE Payable';
      case 'NSSF_LIABILITY':
        return 'NSSF Payable';
      case 'NHIF_LIABILITY':
        return 'SHIF Payable';
      case 'HOUSING_LEVY_LIABILITY':
        return 'Housing Levy';
      case 'CASH_BANK':
        return 'Cash at Bank';
      default:
        return category;
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
      final mappings = _mappingControllers.entries
          .map(
            (e) => {
              'category': e.key,
              'accountCode': e.value.text,
              'accountName': _getAccountName(e.key),
            },
          )
          .toList();

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
      final response = await ApiService().exportPayrollToCSV(
        _selectedPayPeriodId!,
      );
      final csvData = response.data['data'] as String;
      final filename =
          response.data['filename'] as String? ?? 'payroll_export.csv';

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
