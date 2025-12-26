import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_breakdown.dart';

/// Currency formatter for KES
final _currencyFormatter = NumberFormat('#,###');

/// Format amount as KES currency string
String formatKes(double amount) => 'KES ${_currencyFormatter.format(amount.abs())}';

// =============================================================================
// SUMMARY CARD
// =============================================================================

/// Gradient summary card showing payroll totals
class PayrollSummaryCard extends StatelessWidget {
  final PayrollBreakdown totals;
  final int workerCount;

  const PayrollSummaryCard({
    super.key,
    required this.totals,
    required this.workerCount,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(color: Colors.white24, height: 32),
          _buildDeductionsList(),
          const Divider(color: Colors.white24, height: 24),
          _buildTotalDeductions(),
          const SizedBox(height: 12),
          _buildWorkerCount(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total Net Pay',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          formatKes(totals.netSalary),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionsList() {
    return Column(
      children: [
        _SummaryRow(label: 'Gross Salary', amount: totals.grossSalary),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'NSSF Contribution',
          amount: totals.nssfContribution,
          isDeduction: true,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'NHIF/SHIF Contribution',
          amount: totals.nhifContribution,
          isDeduction: true,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Housing Levy',
          amount: totals.housingLevy,
          isDeduction: true,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'PAYE Tax',
          amount: totals.paye,
          isDeduction: true,
        ),
      ],
    );
  }

  Widget _buildTotalDeductions() {
    return _SummaryRow(
      label: 'Total Deductions',
      amount: totals.totalDeductions,
      isDeduction: true,
      isBold: true,
    );
  }

  Widget _buildWorkerCount() {
    return Row(
      children: [
        const Icon(Icons.people, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$workerCount workers',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

/// Summary row for the gradient card (white text)
class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDeduction;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isDeduction = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    // Hide zero amounts for cleaner UI
    if (amount.abs() < 0.01) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '${isDeduction ? "- " : ""}${formatKes(amount)}',
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WORKER BREAKDOWN CARD
// =============================================================================

/// Expandable card showing individual worker payroll breakdown
class WorkerBreakdownCard extends StatelessWidget {
  final String name;
  final String? jobTitle;
  final PayrollBreakdown breakdown;
  final bool isExpanded;
  final VoidCallback onTap;

  const WorkerBreakdownCard({
    super.key,
    required this.name,
    this.jobTitle,
    required this.breakdown,
    required this.isExpanded,
    required this.onTap,
  });

  String get _initials {
    if (name.isEmpty) return 'W';
    return name
        .split(' ')
        .where((n) => n.isNotEmpty)
        .take(2)
        .map((n) => n[0])
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            if (isExpanded) _buildExpandedContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(context),
        const SizedBox(width: 14),
        Expanded(child: _buildNameColumn(context)),
        _buildNetPayColumn(context),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNameColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          jobTitle ?? 'Employee',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildNetPayColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatKes(breakdown.netSalary),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 16,
          ),
        ),
        Text(
          'Net',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 24),
        _BreakdownRow(label: 'Gross Salary', amount: breakdown.grossSalary),
        _BreakdownRow(
          label: 'NSSF',
          amount: breakdown.nssfContribution,
          isDeduction: true,
        ),
        _BreakdownRow(
          label: 'NHIF/SHIF',
          amount: breakdown.nhifContribution,
          isDeduction: true,
        ),
        _BreakdownRow(
          label: 'Housing Levy',
          amount: breakdown.housingLevy,
          isDeduction: true,
        ),
        _BreakdownRow(
          label: 'PAYE Tax',
          amount: breakdown.paye,
          isDeduction: true,
        ),
        const Divider(height: 16),
        _BreakdownRow(
          label: 'Total Deductions',
          amount: breakdown.totalDeductions,
          isDeduction: true,
          isBold: true,
        ),
        _BreakdownRow(
          label: 'Net Salary',
          amount: breakdown.netSalary,
          isBold: true,
          isNet: true,
        ),
      ],
    );
  }
}

/// Breakdown row for worker cards (dark text)
class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDeduction;
  final bool isBold;
  final bool isNet;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    this.isDeduction = false,
    this.isBold = false,
    this.isNet = false,
  });

  @override
  Widget build(BuildContext context) {
    // Hide zero amounts unless it's Net Salary
    if (amount.abs() < 0.01 && !isNet) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isDeduction ? "- " : ""}${formatKes(amount)}',
            style: TextStyle(
              color: isNet
                  ? Colors.green
                  : (isDeduction ? Colors.red.shade600 : Colors.grey.shade900),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM ACTION BAR
// =============================================================================

/// Bottom action bar with confirm payment button
class PayrollBottomActionBar extends StatelessWidget {
  final double totalAmount;
  final bool isProcessing;
  final VoidCallback? onConfirm;

  const PayrollBottomActionBar({
    super.key,
    required this.totalAmount,
    required this.isProcessing,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Pay ${formatKes(totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION LABEL
// =============================================================================

/// Uppercase section label with letter spacing
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }
}
