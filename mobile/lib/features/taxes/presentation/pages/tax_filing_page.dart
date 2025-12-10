import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/tax_provider.dart';
import '../../data/models/monthly_tax_summary.dart';

class TaxFilingPage extends ConsumerWidget {
  const TaxFilingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(monthlyTaxSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Filing'),
        elevation: 0,
      ),
      body: summariesAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tax submissions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Process payroll to generate tax submissions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(monthlyTaxSummariesProvider.notifier).loadSummaries();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                final isFiled = summary.status == 'FILED';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${summary.monthName} ${summary.year}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${summary.submissions.length} pay periods included',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isFiled
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isFiled ? 'FILED' : 'PENDING',
                                style: TextStyle(
                                  color: isFiled ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTaxRow('PAYE', summary.totalPaye),
                        _buildTaxRow('NSSF', summary.totalNssf),
                        _buildTaxRow('NHIF/SHIF', summary.totalNhif),
                        _buildTaxRow('Housing Levy', summary.totalHousingLevy),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Tax',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'KES ${NumberFormat('#,##0.00').format(summary.totalTax)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                          if (!isFiled) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: PopupMenuButton<String>(
                                  onSelected: (value) => _downloadReturn(context, ref, value, summary),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'KRA_P10_CSV',
                                      child: Row(
                                        children: [
                                          Icon(Icons.description_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('KRA P10 (CSV)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'NSSF_RETURN_EXCEL',
                                      child: Row(
                                        children: [
                                          Icon(Icons.table_chart_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('NSSF Return'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'SHIF_RETURN_EXCEL',
                                      child: Row(
                                        children: [
                                          Icon(Icons.health_and_safety_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('SHIF Return'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Theme.of(context).primaryColor),
                                      borderRadius: BorderRadius.circular(100), // Capsule shape like typical buttons
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.download, color: Theme.of(context).primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Download Returns',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showMarkAsFiledConfirmation(
                                    context,
                                    ref,
                                    summary,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark as Filed'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load tax summaries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(monthlyTaxSummariesProvider.notifier).loadSummaries();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'KES ${NumberFormat('#,##0.00').format(amount)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReturn(
    BuildContext context,
    WidgetRef ref,
    String exportType,
    MonthlyTaxSummary summary,
  ) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating return...')),
        );
      }

      final bytes = await ref
          .read(monthlyTaxSummariesProvider.notifier)
          .downloadReturn(exportType, summary.year, summary.month);

      if (bytes.isEmpty) {
        throw Exception('Download failed: Empty file');
      }

      // Determine file extension
      final extension = exportType.contains('CSV') ? 'csv' : 'csv'; // For MVP all are CSVs
      final fileName = '${exportType}_${summary.month}_${summary.year}.$extension';

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Open file
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
        // Try opening automatically
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMarkAsFiledConfirmation(
    BuildContext context,
    WidgetRef ref,
    MonthlyTaxSummary summary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Monthly Returns'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark returns for ${summary.monthName} ${summary.year} as filed?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Please ensure you have downloaded and submitted the following returns:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildChecklistItem('KRA P10 Return'),
            _buildChecklistItem('NSSF Return'),
            _buildChecklistItem('SHIF Return'),
            _buildChecklistItem('Housing Levy Return'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              try {
                // Determine which API to call based on the summary logic
                // For now, we assume standard monthly filing
                await ref
                    .read(monthlyTaxSummariesProvider.notifier)
                    .markMonthAsFiled(summary.year, summary.month);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Successfully marked ${summary.monthName} returns as filed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error filing returns: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Filed'),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
