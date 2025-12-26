import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/finance_constants.dart';

/// Currency formatter for KES
final _currencyFormatter = NumberFormat('#,###');

/// Format amount with currency
String formatCurrency(num amount, {String currency = FinanceConstants.currencyCode}) {
  return '$currency ${_currencyFormatter.format(amount)}';
}

/// Section label for finance groups
class FinanceSectionLabel extends StatelessWidget {
  final String label;

  const FinanceSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FinanceTheme.pagePadding,
        FinanceTheme.sectionLabelTopPadding,
        FinanceTheme.pagePadding,
        FinanceTheme.sectionLabelBottomPadding,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Quick action button
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FinanceTheme.actionButtonPadding),
        decoration: FinanceTheme.cardDecoration(),
        child: Column(
          children: [
            _buildIcon(context),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

/// Row of quick action buttons
class QuickActionsRow extends StatelessWidget {
  final List<QuickActionItem> items;
  final void Function(String route) onItemTap;

  const QuickActionsRow({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FinanceTheme.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 6 : 0,
                right: index < items.length - 1 ? 6 : 0,
              ),
              child: QuickActionButton(
                icon: item.icon,
                label: item.label,
                onTap: () => onItemTap(item.route),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Funding source card (Bank/M-Pesa)
class FundingSourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDefault;

  const FundingSourceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isDefault = false,
    this.isDirect = false,
  });

  final bool isDirect;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FinanceTheme.cardDecoration(
        isActive: isDefault,
        activeColor: primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildLabel(context),
          const SizedBox(height: 2),
          _buildValue(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          icon,
          size: 22,
          color: isDefault
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
        ),
        if (isDefault) _buildDefaultBadge(),
      ],
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FinanceTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          color: FinanceTheme.successColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildValue(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Empty state for transactions
class EmptyTransactionsState extends StatelessWidget {
  final VoidCallback onRunPayroll;

  const EmptyTransactionsState({
    super.key,
    required this.onRunPayroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: FinanceTheme.pagePadding),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FinanceTheme.cardBackground,
        borderRadius: BorderRadius.circular(FinanceTheme.cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text('No completed payroll runs yet'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRunPayroll,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Run First Payroll'),
          ),
        ],
      ),
    );
  }
}

/// Transaction list item
class TransactionListItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final double amount;
  final bool showDivider;

  const TransactionListItem({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo(context)),
              _buildAmount(context),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FinanceTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.check_circle,
        color: FinanceTheme.successColor,
        size: 20,
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          DateFormat('MMM d, yyyy').format(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
        ),
      ],
    );
  }

  Widget _buildAmount(BuildContext context) {
    return Text(
      formatCurrency(amount),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }
}

/// Generic error state with retry
class FinanceErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const FinanceErrorState({
    super.key,
    this.message = 'Failed to load',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic loading state
class FinanceLoadingState extends StatelessWidget {
  final double height;
  final Color? color;

  const FinanceLoadingState({
    super.key,
    this.height = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          color: color,
        ),
      ),
    );
  }
}
