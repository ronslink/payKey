import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../pay_periods/data/models/pay_period_model.dart';
import '../../../pay_periods/presentation/providers/pay_periods_provider.dart';
import '../../data/models/report_models.dart';
import '../providers/reports_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payPeriodsAsync = ref.watch(payPeriodsProvider);
    final reportParams = ref.watch(reportParamsProvider);
    final reportDataAsync = ref.watch(reportDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Report Type Selector
                DropdownButtonFormField<ReportType>(
                  initialValue: reportParams.type,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ReportType.payrollSummary,
                      child: Text('Payroll Summary'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.statutory,
                      child: Text('Statutory Report (P10)'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.musterRoll,
                      child: Text('Muster Roll'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(reportParamsProvider.notifier).state =
                          reportParams.copyWith(type: value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                                // Pay Period Selector
                payPeriodsAsync.when(
                  data: (periods) {
                    // Filter mainly for finalized ones maybe? Or all.
                    // Let's assume user wants report for any period.
                    final sortedPeriods = List<PayPeriodModel>.from(periods)
                      ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Descending strings works for ISO dates usually

                    if (sortedPeriods.isEmpty) {
                      return const Text('No pay periods available');
                    }

                    // Auto-select first if none selected
                    if (reportParams.payPeriodId == null && sortedPeriods.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(reportParamsProvider.notifier).state =
                            reportParams.copyWith(payPeriodId: sortedPeriods.first.id);
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: reportParams.payPeriodId,
                      decoration: const InputDecoration(
                        labelText: 'Pay Period',
                        border: OutlineInputBorder(),
                      ),
                      items: sortedPeriods.map((p) {
                         // Parse dates assuming they are ISO strings e.g. "2023-01-01"
                        final startDate = DateTime.tryParse(p.startDate) ?? DateTime.now();
                        final endDate = DateTime.tryParse(p.endDate) ?? DateTime.now();
                        
                        final dateStr = '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}';
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(dateStr),
                        );
                      }).toList(),
                      onChanged: (value) {
                        ref.read(reportParamsProvider.notifier).state =
                            reportParams.copyWith(payPeriodId: value);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Error loading periods: $err'),
                ),
              ],
            ),
          ),
          
          // Report Content
          Expanded(
            child: reportDataAsync.when(
              data: (data) {
                if (data == null) {
                  return const Center(child: Text('Select a pay period to view report'));
                }
                
                if (reportParams.type == ReportType.payrollSummary) {
                  return _PayrollSummaryView(report: data as PayrollSummaryReport);
                } else if (reportParams.type == ReportType.statutory) {
                  return _StatutoryReportView(report: data as StatutoryReport);
                } else {
                  // Muster Roll (reusing summary view for now as structure is same)
                  return _PayrollSummaryView(report: data as PayrollSummaryReport);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSummaryView extends StatelessWidget {
  final PayrollSummaryReport report;

  const _PayrollSummaryView({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards
          Row(
            children: [
              Expanded(child: _SummaryCard('Total Gross', report.totals.grossPay, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Net Pay', report.totals.netPay, Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard('PAYE', report.totals.paye, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Total Deductions', report.totals.totalDeductions, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Employee Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.records.length,
            itemBuilder: (context, index) {
              final record = report.records[index];
              return Card(
                child: ListTile(
                  title: Text(record.workerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Net: KES ${NumberFormat('#,##0.00').format(record.netPay)}'),
                  trailing: Text('Gross: KES ${NumberFormat('#,##0.00').format(record.grossPay)}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatutoryReportView extends StatelessWidget {
  final StatutoryReport report;

  const _StatutoryReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statutory Deductions (P10 Data)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Gross Pay')),
                DataColumn(label: Text('NSSF')),
                DataColumn(label: Text('NHIF')),
                DataColumn(label: Text('Housing Levy')),
                DataColumn(label: Text('PAYE')),
              ],
              rows: report.employees.map((e) {
                return DataRow(cells: [
                  DataCell(Text(e.name)),
                  DataCell(Text(e.grossPay.toStringAsFixed(2))),
                  DataCell(Text(e.nssf.toStringAsFixed(2))),
                  DataCell(Text(e.nhif.toStringAsFixed(2))),
                  DataCell(Text(e.housingLevy.toStringAsFixed(2))),
                  DataCell(Text(e.paye.toStringAsFixed(2))),
                ]);
              }).toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Total PAYE: ${report.totals.paye.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Total NSSF: ${report.totals.nssf.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard(this.title, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              NumberFormat('#,##0.00').format(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
