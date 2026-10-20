import 'package:flutter/material.dart';
import '../../../../core/theme/pay_colors.dart';
import 'package:intl/intl.dart';
import '../models/payroll_breakdown.dart';
import 'payment_status_badge.dart';

/// Currency formatter for KES
final _currencyFormatter = NumberFormat('#,###');

/// Format amount as KES currency string
String formatKes(double amount) =>
    'KES ${_currencyFormatter.format(amount.abs())}';

// =============================================================================
// SUMMARY CARD
// =============================================================================

/// Summary card showing payroll totals with the shared primary color pair.
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Divider(color: colors.onPrimary.withValues(alpha: 0.24), height: 32),
          _buildDeductionsList(),
          Divider(color: colors.onPrimary.withValues(alpha: 0.24), height: 24),
          _buildTotalDeductions(),
          const SizedBox(height: 12),
          _buildWorkerCount(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 8,
      children: [
        Text(
          'Total Net Pay',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16,
          ),
        ),
        Text(
          formatKes(totals.netSalary),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
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
        _SummaryRow(label: 'Non-Cash Benefits', amount: totals.nonCashBenefits),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Tax Exempt Allowances',
          amount: totals.taxExemptAllowances,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'NSSF Contribution',
          amount: totals.nssfContribution,
          isDeduction: true,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'SHIF Contribution',
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
        _SummaryRow(label: 'PAYE Tax', amount: totals.paye, isDeduction: true),
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

  Widget _buildWorkerCount(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.people,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$workerCount workers',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

/// Summary row for the primary-colored summary card.
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

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '${isDeduction ? "- " : ""}${formatKes(amount)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
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
  final String? paymentStatus;

  const WorkerBreakdownCard({
    super.key,
    required this.name,
    this.jobTitle,
    required this.breakdown,
    required this.isExpanded,
    required this.onTap,
    this.paymentStatus,
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
          color: context.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? Theme.of(context).primaryColor
                : context.borderMuted,
          ),
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
          color: context.iconDefault,
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
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (paymentStatus != null) ...[
              PaymentStatusBadge(status: paymentStatus!, compact: true),
            ],
          ],
        ),
        Text(
          jobTitle ?? 'Employee',
          style: TextStyle(color: context.textSecondary, fontSize: 13),
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
          style: TextStyle(color: context.textTertiary, fontSize: 11),
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
          label: 'Non-Cash Benefits',
          amount: breakdown.nonCashBenefits,
        ),
        _BreakdownRow(
          label: 'Tax Exempt Allowances',
          amount: breakdown.taxExemptAllowances,
        ),
        _BreakdownRow(
          label: 'NSSF',
          amount: breakdown.nssfContribution,
          isDeduction: true,
        ),
        _BreakdownRow(
          label: 'SHIF',
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
              color: isBold ? context.textPrimary : context.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isDeduction ? "- " : ""}${formatKes(amount)}',
            style: TextStyle(
              color: isNet
                  ? Colors.green
                  : (isDeduction ? Colors.red.shade600 : context.textPrimary),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfacePrimary,
        border: Border(top: BorderSide(color: context.borderDefault)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Confirm & Pay ${formatKes(totalAmount)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
        color: context.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}
