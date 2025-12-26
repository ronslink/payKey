import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Use the canonical Freezed-based PayPeriod model
import '../../../payroll/data/models/pay_period_model.dart';
import '../../../pay_periods/presentation/providers/pay_periods_provider.dart';
import '../../data/models/report_models.dart';
import '../providers/reports_provider.dart';
import '../providers/export_provider.dart';


class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportParams = ref.watch(reportParamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(reportDataProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Report Type Selector - Card Style
          _buildReportTypeSelector(context, ref, reportParams),

          // Report Content
          Expanded(
            child: reportParams.type == ReportType.p9Report
                ? _P9ReportView()
                : _buildPayPeriodBasedReport(context, ref, reportParams),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(
      BuildContext context, WidgetRef ref, ReportParams params) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Report Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReportTypeChip(
                  context,
                  ref,
                  'Payroll Summary',
                  Icons.account_balance_wallet,
                  ReportType.payrollSummary,
                  params.type,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildReportTypeChip(
                  context,
                  ref,
                  'Statutory (P10)',
                  Icons.gavel,
                  ReportType.statutory,
                  params.type,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildReportTypeChip(
                  context,
                  ref,
                  'Muster Roll',
                  Icons.people,
                  ReportType.musterRoll,
                  params.type,
                  Colors.purple,
                ),
                const SizedBox(width: 8),
                _buildReportTypeChip(
                  context,
                  ref,
                  'P9 Tax Cards',
                  Icons.description,
                  ReportType.p9Report,
                  params.type,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    ReportType type,
    ReportType currentType,
    Color color,
  ) {
    final isSelected = type == currentType;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? color : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            ref.read(reportParamsProvider.notifier).update(
                ref.read(reportParamsProvider).copyWith(type: type));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayPeriodBasedReport(
      BuildContext context, WidgetRef ref, ReportParams reportParams) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final reportDataAsync = ref.watch(reportDataProvider);

    return Column(
      children: [
        // Pay Period Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: payPeriodsAsync.when(
            data: (periods) {
              final sortedPeriods = List<PayPeriod>.from(periods)
                ..sort((a, b) => b.startDate.compareTo(a.startDate));

              if (sortedPeriods.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pay periods available'),
                  ),
                );
              }

              // Auto-select removed to prevent loops
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: reportParams.payPeriodId,
                    decoration: const InputDecoration(
                      labelText: 'Pay Period',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    items: sortedPeriods.map((p) {
                      final dateStr =
                          '${DateFormat('MMM d').format(p.startDate)} - ${DateFormat('MMM d, y').format(p.endDate)}';
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(dateStr),
                      );
                    }).toList(),
                    onChanged: (value) {
                      ref.read(reportParamsProvider.notifier).update(
                          reportParams.copyWith(payPeriodId: value));
                    },
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Error loading periods: $err'),
          ),
        ),

        // Report Content
        Expanded(
          child: reportDataAsync.when(
            data: (data) {
              if (data == null) {
                return _buildEmptyState(
                  'Select Pay Period',
                  'Choose a pay period from the dropdown above to view the report',
                  Icons.calendar_today,
                );
              }

              if (reportParams.type == ReportType.payrollSummary ||
                  reportParams.type == ReportType.musterRoll) {
                return _PayrollSummaryView(report: data as PayrollSummaryReport);
              } else if (reportParams.type == ReportType.statutory) {
                return _StatutoryReportView(report: data as StatutoryReport);
              }
              return const SizedBox.shrink();
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(reportDataProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// P9 REPORT VIEW
// =============================================================================

class _P9ReportView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedP9YearProvider);
    final p9ReportsAsync = ref.watch(p9ReportsProvider(selectedYear));
    final selectedWorker = ref.watch(selectedP9WorkerProvider);

    return Column(
      children: [
        // Year Selector
        _buildYearSelector(context, ref, selectedYear),

        // Content
        Expanded(
          child: selectedWorker != null
              ? _P9WorkerDetailView(
                  report: selectedWorker,
                  onBack: () =>
                      ref.read(selectedP9WorkerProvider.notifier).set(null),
                )
              : p9ReportsAsync.when(
                  data: (reports) => _buildP9List(context, ref, reports),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _buildErrorState(context, ref, err),
                ),
        ),
      ],
    );
  }

  Widget _buildYearSelector(BuildContext context, WidgetRef ref, int year) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Tax Year:', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              DropdownButton<int>(
                value: year,
                underline: const SizedBox.shrink(),
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(selectedP9YearProvider.notifier).set(value);
                    ref.read(selectedP9WorkerProvider.notifier).set(null);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildP9List(
      BuildContext context, WidgetRef ref, List<P9Report> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No P9 Reports Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'P9 reports are generated from finalized payroll data.\nProcess payroll to generate P9 tax cards.',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat('#,##0.00');
    final totalPaye = reports.fold(0.0, (sum, r) => sum + r.totalPaye);
    final totalGross = reports.fold(0.0, (sum, r) => sum + r.totalGross);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Workers',
                  '${reports.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total PAYE',
                  'KES ${currencyFormat.format(totalPaye)}',
                  Icons.account_balance,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            context,
            'Total Gross Earnings',
            'KES ${currencyFormat.format(totalGross)}',
            Icons.payments,
            Colors.orange,
            fullWidth: true,
          ),

          const SizedBox(height: 24),

          // Download Action
          Card(
            color: Colors.green.shade50,
            child: InkWell(
              onTap: () => _downloadP9Zip(context, ref),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.download, color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download All P9 Forms',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get a ZIP file with P9A PDFs for all workers',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.green.shade600),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Workers List Header
          Row(
            children: [
              const Icon(Icons.people, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Employee P9 Cards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Workers List
          ...reports.map((report) => _buildWorkerP9Card(context, ref, report)),

          const SizedBox(height: 24),

          // Tips Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'P9 Form Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• P9A is a Tax Deduction Card issued by employers\n'
                    '• Required for employees to file annual tax returns\n'
                    '• Must be issued by end of February each year\n'
                    '• Contains monthly PAYE deductions and total tax paid',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fullWidth ? 18 : 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerP9Card(
      BuildContext context, WidgetRef ref, P9Report report) {
    final currencyFormat = NumberFormat('#,##0.00');
    final activeMonths = report.activeMonths.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(selectedP9WorkerProvider.notifier).set(report);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.person, color: Colors.green.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.workerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KRA PIN: ${report.kraPin.isNotEmpty ? report.kraPin : 'Not set'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeMonths months processed',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${currencyFormat.format(report.totalPaye)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total PAYE',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading P9 reports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final year = ref.read(selectedP9YearProvider);
              ref.invalidate(p9ReportsProvider(year));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _downloadP9Zip(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.green),
            SizedBox(width: 12),
            Text('Download P9 Forms'),
          ],
        ),
        content: const Text(
          'This will download a ZIP file containing P9A PDFs for all workers. '
          'You can then distribute these to employees for their annual tax filing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              final year = ref.read(selectedP9YearProvider);
              ref.read(taxExportProvider.notifier).downloadP9Zip(year: year);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// P9 WORKER DETAIL VIEW
// =============================================================================

class _P9WorkerDetailView extends StatelessWidget {
  final P9Report report;
  final VoidCallback onBack;

  const _P9WorkerDetailView({required this.report, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to List'),
          ),
          const SizedBox(height: 8),

          // Worker Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(Icons.person,
                            color: Colors.green.shade700, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.workerName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KRA PIN: ${report.kraPin.isNotEmpty ? report.kraPin : 'Not set'}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Gross',
                        'KES ${currencyFormat.format(report.totalGross)}',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Total PAYE',
                        'KES ${currencyFormat.format(report.totalPaye)}',
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Months',
                        '${report.activeMonths.length}',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // P9 Header
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'KENYA REVENUE AUTHORITY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  Text(
                    'P9A - TAX DEDUCTION CARD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Monthly Breakdown
          Text(
            'Monthly Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...report.months.map((month) => _buildMonthCard(context, month)),

          const SizedBox(height: 24),

          // Totals Card
          Card(
            color: Colors.green.shade100,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annual Totals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTotalRow(
                      'Basic Salary', report.totals.basicSalary, currencyFormat),
                  _buildTotalRow(
                      'Gross Pay', report.totals.grossPay, currencyFormat),
                  const Divider(color: Colors.green),
                  _buildTotalRow('Total PAYE', report.totals.paye, currencyFormat,
                      isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(BuildContext context, P9MonthData month) {
    final currencyFormat = NumberFormat('#,##0.00');
    final hasData = month.grossPay > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: hasData ? null : Colors.grey.shade100,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasData
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            month.monthName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasData ? Colors.green.shade700 : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          month.fullMonthName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: hasData ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          hasData
              ? 'Gross: KES ${currencyFormat.format(month.grossPay)}'
              : 'No payroll data',
          style: TextStyle(
            color: hasData ? Colors.grey.shade600 : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: hasData
            ? Text(
                'PAYE: ${currencyFormat.format(month.paye)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              )
            : const Text('-'),
        children: hasData
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                          'Basic Salary', month.basicSalary, currencyFormat),
                      _buildDetailRow(
                          'Benefits', month.benefits, currencyFormat),
                      _buildDetailRow(
                          'Gross Pay', month.grossPay, currencyFormat),
                      const Divider(),
                      _buildDetailRow('NSSF Contribution', month.contribution,
                          currencyFormat),
                      _buildDetailRow(
                          'Taxable Pay', month.taxablePay, currencyFormat),
                      _buildDetailRow(
                          'Tax Charged', month.taxCharged, currencyFormat),
                      _buildDetailRow(
                          'Personal Relief', month.relief, currencyFormat),
                      const Divider(),
                      _buildDetailRow('PAYE Payable', month.paye, currencyFormat,
                          isBold: true),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, NumberFormat format,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'KES ${format.format(value)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, NumberFormat format,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            'KES ${format.format(value)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAYROLL SUMMARY VIEW
// =============================================================================

class _PayrollSummaryView extends StatelessWidget {
  final PayrollSummaryReport report;

  const _PayrollSummaryView({required this.report});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  'Total Gross',
                  currencyFormat.format(report.totals.grossPay),
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  'Net Pay',
                  currencyFormat.format(report.totals.netPay),
                  Colors.green,
                  Icons.payments,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  'PAYE',
                  currencyFormat.format(report.totals.paye),
                  Colors.orange,
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  'Total Deductions',
                  currencyFormat.format(report.totals.totalDeductions),
                  Colors.red,
                  Icons.remove_circle_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Employee Breakdown Header
          Row(
            children: [
              const Icon(Icons.people, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Employee Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${report.records.length} employees',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Employee Cards
          ...report.records.map((record) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    record.workerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Net: KES ${currencyFormat.format(record.netPay)}',
                  ),
                  trailing: Text(
                    'KES ${currencyFormat.format(record.grossPay)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// =============================================================================
// STATUTORY REPORT VIEW
// =============================================================================

class _StatutoryReportView extends ConsumerWidget {
  final StatutoryReport report;

  const _StatutoryReportView({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat('#,##0.00');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.orange.shade700, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statutory Deductions Report',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'P10-style statutory summary',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDownloadButtons(context, ref),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Totals Row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  'PAYE',
                  currencyFormat.format(report.totals.paye),
                  Colors.orange,
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  'NSSF',
                  currencyFormat.format(report.totals.nssf),
                  Colors.blue,
                  Icons.security,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  'NHIF',
                  currencyFormat.format(report.totals.nhif),
                  Colors.green,
                  Icons.health_and_safety,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  'Housing Levy',
                  currencyFormat.format(report.totals.housingLevy),
                  Colors.purple,
                  Icons.home,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Employee Table
          Text(
            'Employee Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateColor.resolveWith(
                    (states) => Colors.orange.shade50),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Gross')),
                  DataColumn(label: Text('NSSF')),
                  DataColumn(label: Text('NHIF')),
                  DataColumn(label: Text('Housing')),
                  DataColumn(label: Text('PAYE')),
                ],
                rows: report.employees.map((e) {
                  return DataRow(cells: [
                    DataCell(Text(e.name)),
                    DataCell(Text(currencyFormat.format(e.grossPay))),
                    DataCell(Text(currencyFormat.format(e.nssf))),
                    DataCell(Text(currencyFormat.format(e.nhif))),
                    DataCell(Text(currencyFormat.format(e.housingLevy))),
                    DataCell(Text(
                      currencyFormat.format(e.paye),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButtons(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(taxExportProvider);

    // Listen for export state changes to show snackbars
    ref.listen(taxExportProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export Failed: ${next.error}'), backgroundColor: Colors.red),
          );
        }
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
          );
        }
      }
    });

    if (exportState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildExportButton(
            context,
            ref,
            'KRA P10 CSV',
            Icons.download,
            Colors.green,
            'KRA_P10_CSV',
          ),
          const SizedBox(width: 8),
          _buildExportButton(
            context,
            ref,
            'NSSF Excel',
            Icons.table_chart,
            Colors.blue,
            'NSSF_RETURN_EXCEL',
          ),
          const SizedBox(width: 8),
          _buildExportButton(
            context,
            ref,
            'SHIF Excel',
            Icons.health_and_safety,
            Colors.purple,
            'SHIF_RETURN_EXCEL',
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    Color color,
    String exportType,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        final startDate = DateTime.parse(report.payPeriod.startDate);
        final endDate = DateTime.parse(report.payPeriod.endDate);

        ref.read(taxExportProvider.notifier).downloadStatutoryReport(
              exportType: exportType,
              startDate: startDate,
              endDate: endDate,
              title: label,
            );
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// =============================================================================
// COMMON WIDGETS
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard(this.title, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
