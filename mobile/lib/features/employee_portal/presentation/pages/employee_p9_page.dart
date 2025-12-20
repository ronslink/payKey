import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/download_helper.dart';
import '../../../reports/data/models/report_models.dart';

// ============================================================================
// Constants
// ============================================================================

class _P9Colors {
  static const primary = Colors.green;
  static const statGross = Colors.blue;
  static const statPaye = Colors.green;

  static Color get primaryLight => Colors.green.shade50;
  static Color get primaryMedium => Colors.green.shade100;
  static Color get primaryDark => Colors.green.shade600;
  static Color get primaryDarker => Colors.green.shade700;
  static Color get primaryDarkest => Colors.green.shade800;
  static Color get primaryText => Colors.green.shade900;

  static Color get infoLight => Colors.blue.shade50;
  static Color get infoDark => Colors.blue.shade700;
  static Color get infoText => Colors.blue.shade800;

  static Color get greyLight => Colors.grey.shade50;
  static Color get greyMedium => Colors.grey.shade100;
  static Color get greyText => Colors.grey.shade600;
  static Color get greyDark => Colors.grey.shade700;
  static Color get greyDisabled => Colors.grey.shade400;
}

class _P9Styles {
  static const cardPadding = 20.0;
  static const sectionPadding = 16.0;
  static const iconRadius = 10.0;
  static const cardRadius = 12.0;
  static const smallRadius = 8.0;
}

// ============================================================================
// Currency Formatter
// ============================================================================

class _CurrencyFormatter {
  static final _format = NumberFormat('#,##0.00');

  static String format(double value) => 'KES ${_format.format(value)}';
  static String formatRaw(double value) => _format.format(value);
}

// ============================================================================
// Main Page Widget
// ============================================================================

class EmployeeP9Page extends ConsumerStatefulWidget {
  const EmployeeP9Page({super.key});

  @override
  ConsumerState<EmployeeP9Page> createState() => _EmployeeP9PageState();
}

class _EmployeeP9PageState extends ConsumerState<EmployeeP9Page> {
  int _selectedYear = DateTime.now().year;
  P9Report? _p9Report;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  List<int> get _availableYears => List.generate(5, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _loadP9Report();
  }

  // --------------------------------------------------------------------------
  // Data Operations
  // --------------------------------------------------------------------------

  Future<void> _loadP9Report() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().employeePortal.getMyP9Report(_selectedYear);
      if (response.statusCode == 200) {
        final data = response.data;
        _p9Report = (data is List && data.isNotEmpty) ? P9Report.fromJson(data[0]) : null;
      } else {
        _error = 'Failed to load P9 report';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _downloadP9Pdf() async {
    setState(() => _isDownloading = true);

    try {
      final bytes = await ApiService().employeePortal.downloadMyP9Pdf(_selectedYear);

      if (bytes.isNotEmpty && context.mounted) {
        final filename = 'P9_${_selectedYear}.pdf';
        
        if (kIsWeb) {
          // Trigger browser download
          downloadFileInBrowser(bytes, filename);
        }
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $filename'),
            backgroundColor: _P9Colors.primary,
          ),
        );
      }
    } catch (e) {
      _showError('Download failed: $e');
    } finally {
      _setDownloading(false);
    }
  }

  // --------------------------------------------------------------------------
  // State Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setDownloading(bool value) {
    if (mounted) setState(() => _isDownloading = value);
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _onYearChanged(int? year) {
    if (year != null && year != _selectedYear) {
      setState(() => _selectedYear = year);
      _loadP9Report();
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My P9 Tax Report'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadP9Report,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _YearSelector(
            selectedYear: _selectedYear,
            years: _availableYears,
            onChanged: _onYearChanged,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadP9Report);
    }
    if (_p9Report == null) {
      return _NoDataState(year: _selectedYear);
    }
    return _P9ReportContent(
      report: _p9Report!,
      year: _selectedYear,
      isDownloading: _isDownloading,
      onDownload: _downloadP9Pdf,
    );
  }
}

// ============================================================================
// Year Selector Component
// ============================================================================

class _YearSelector extends StatelessWidget {
  final int selectedYear;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  const _YearSelector({
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_P9Styles.sectionPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              const Text('Tax Year:', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              _buildDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _P9Colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_P9Styles.iconRadius),
      ),
      child: Icon(Icons.calendar_today, color: _P9Colors.primaryDark),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _P9Colors.greyMedium,
        borderRadius: BorderRadius.circular(_P9Styles.smallRadius),
      ),
      child: DropdownButton<int>(
        value: selectedYear,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: years
            .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ============================================================================
// State Views
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load P9',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: _P9Colors.greyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  final int year;

  const _NoDataState({required this.year});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: _P9Colors.greyDisabled),
            const SizedBox(height: 16),
            const Text(
              'No P9 Data Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your P9 tax deduction card for $year is not yet available.\n\n'
              'P9 reports are generated from finalized payroll data.',
              style: TextStyle(color: _P9Colors.greyText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// P9 Report Content
// ============================================================================

class _P9ReportContent extends StatelessWidget {
  final P9Report report;
  final int year;
  final bool isDownloading;
  final VoidCallback onDownload;

  const _P9ReportContent({
    required this.report,
    required this.year,
    required this.isDownloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_P9Styles.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KraHeaderCard(year: year),
          const SizedBox(height: 16),
          _EmployeeInfoCard(report: report),
          const SizedBox(height: 16),
          _SummaryStats(report: report),
          const SizedBox(height: 24),
          _DownloadCard(isDownloading: isDownloading, onDownload: onDownload),
          const SizedBox(height: 24),
          const _MonthlyBreakdownHeader(),
          const SizedBox(height: 12),
          ...report.months.map((month) => _MonthCard(month: month)),
          const SizedBox(height: 24),
          _AnnualTotalsCard(totals: report.totals),
          const SizedBox(height: 24),
          const _InfoCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// Header Cards
// ============================================================================

class _KraHeaderCard extends StatelessWidget {
  final int year;

  const _KraHeaderCard({required this.year});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _P9Colors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(_P9Styles.cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                Image.network(
                  'https://www.kra.go.ke/images/kra-logo.png',
                  height: 40,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.account_balance,
                    size: 40,
                    color: _P9Colors.primaryDarker,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KENYA REVENUE AUTHORITY',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'P9A - TAX DEDUCTION CARD',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_P9Styles.smallRadius),
              ),
              child: Text(
                'Year: $year',
                style: TextStyle(fontWeight: FontWeight.bold, color: _P9Colors.primaryDarkest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeInfoCard extends StatelessWidget {
  final P9Report report;

  const _EmployeeInfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_P9Styles.cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _P9Colors.primaryMedium,
              child: Icon(Icons.person, color: _P9Colors.primaryDarker, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.workerName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KRA PIN: ${report.kraPin.isNotEmpty ? report.kraPin : 'Not set'}',
                    style: TextStyle(color: _P9Colors.greyText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Summary Stats
// ============================================================================

class _SummaryStats extends StatelessWidget {
  final P9Report report;

  const _SummaryStats({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Gross',
            value: _CurrencyFormatter.format(report.totalGross),
            icon: Icons.payments,
            color: _P9Colors.statGross,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total PAYE',
            value: _CurrencyFormatter.format(report.totalPaye),
            icon: Icons.account_balance,
            color: _P9Colors.statPaye,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_P9Styles.sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(_P9Styles.smallRadius),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: _P9Colors.greyText, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Download Card
// ============================================================================

class _DownloadCard extends StatelessWidget {
  final bool isDownloading;
  final VoidCallback onDownload;

  const _DownloadCard({required this.isDownloading, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _P9Colors.primaryLight,
      child: InkWell(
        onTap: isDownloading ? null : onDownload,
        borderRadius: BorderRadius.circular(_P9Styles.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(_P9Styles.sectionPadding),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(child: _buildText()),
              Icon(Icons.chevron_right, color: _P9Colors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _P9Colors.primaryMedium,
        borderRadius: BorderRadius.circular(_P9Styles.cardRadius),
      ),
      child: isDownloading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.download, color: _P9Colors.primaryDarker),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download P9 PDF',
          style: TextStyle(fontWeight: FontWeight.bold, color: _P9Colors.primaryDarkest),
        ),
        const SizedBox(height: 4),
        Text(
          'Get your official P9A tax deduction card',
          style: TextStyle(color: _P9Colors.primaryDark, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================================
// Monthly Breakdown
// ============================================================================

class _MonthlyBreakdownHeader extends StatelessWidget {
  const _MonthlyBreakdownHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_view_month, color: _P9Colors.greyText),
        const SizedBox(width: 8),
        const Text(
          'Monthly Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  final P9MonthData month;

  const _MonthCard({required this.month});

  bool get _hasData => month.grossPay > 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: _hasData ? null : _P9Colors.greyLight,
      child: ExpansionTile(
        leading: _buildLeadingIcon(),
        title: Text(
          month.fullMonthName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _hasData ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          _hasData
              ? 'Gross: ${_CurrencyFormatter.format(month.grossPay)}'
              : 'No payroll data',
          style: TextStyle(
            color: _hasData ? _P9Colors.greyText : _P9Colors.greyDisabled,
            fontSize: 12,
          ),
        ),
        trailing: _buildTrailing(),
        children: _hasData ? [_MonthDetails(month: month)] : [],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (_hasData ? _P9Colors.primary : Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_P9Styles.iconRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        month.monthName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _hasData ? _P9Colors.primaryDarker : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (!_hasData) {
      return Text('-', style: TextStyle(color: _P9Colors.greyDisabled));
    }
    return Text(
      'PAYE: ${_CurrencyFormatter.formatRaw(month.paye)}',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: _P9Colors.primaryDarker,
        fontSize: 13,
      ),
    );
  }
}

class _MonthDetails extends StatelessWidget {
  final P9MonthData month;

  const _MonthDetails({required this.month});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_P9Styles.sectionPadding),
      child: Column(
        children: [
          _DetailRow(label: 'Basic Salary', value: month.basicSalary),
          _DetailRow(label: 'Benefits', value: month.benefits),
          _DetailRow(label: 'Gross Pay', value: month.grossPay),
          const Divider(),
          _DetailRow(label: 'NSSF Contribution', value: month.contribution),
          _DetailRow(label: 'Taxable Pay', value: month.taxablePay),
          _DetailRow(label: 'Tax Charged', value: month.taxCharged),
          _DetailRow(label: 'Personal Relief', value: month.relief),
          const Divider(),
          _DetailRow(label: 'PAYE Payable', value: month.paye, isBold: true),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _P9Colors.greyDark,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _CurrencyFormatter.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? _P9Colors.primaryDarker : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Annual Totals Card
// ============================================================================

class _AnnualTotalsCard extends StatelessWidget {
  final P9Totals totals;

  const _AnnualTotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _P9Colors.primaryMedium,
      child: Padding(
        padding: const EdgeInsets.all(_P9Styles.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Totals',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _P9Colors.primaryDarkest,
              ),
            ),
            const SizedBox(height: 16),
            _TotalRow(label: 'Basic Salary', value: totals.basicSalary),
            _TotalRow(label: 'Gross Pay', value: totals.grossPay),
            Divider(color: _P9Colors.primary),
            _TotalRow(label: 'Total PAYE Deducted', value: totals.paye, isBold: true),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _P9Colors.primaryDarkest,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 14,
            ),
          ),
          Text(
            _CurrencyFormatter.format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _P9Colors.primaryText,
              fontSize: isBold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Info Card
// ============================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  static const _infoPoints = [
    'P9A is your Tax Deduction Card from your employer',
    'Use this form when filing your annual tax returns',
    'The form shows all PAYE deducted during the year',
    'Keep a copy for your records',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _P9Colors.infoLight,
      child: Padding(
        padding: const EdgeInsets.all(_P9Styles.sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: _P9Colors.infoDark),
                const SizedBox(width: 8),
                Text(
                  'About P9 Form',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _P9Colors.infoText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _infoPoints.map((p) => '• $p').join('\n'),
              style: TextStyle(color: _P9Colors.infoDark, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}